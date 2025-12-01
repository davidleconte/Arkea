#!/usr/bin/env python3
"""
Génère les embeddings ByteT5 (google/byt5-small) pour les lignes de operations_by_account
et met à jour la colonne libelle_embedding.

Usage:
  python3 generate_embeddings_domiramaCatOps.py [--force]

Pré requis:
  - HF_API_KEY dans l'environnement (optionnel si modèle public accessible)
  - transformers, torch et cassandra-driver installés
"""
import os
import sys
import time
import math
import torch
from transformers import AutoTokenizer, AutoModel
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
from cassandra import ConsistencyLevel

MODEL_NAME = "google/byt5-small"
VECTOR_DIMENSION = 1472
BATCH_SIZE = 100
HF_API_KEY = os.environ.get("HF_API_KEY", None)
FORCE_REGENERATE = "--force" in sys.argv

def load_model():
    print(f'📥 Chargement du modèle {MODEL_NAME}...')
    kwargs = {}
    if HF_API_KEY:
        kwargs["use_auth_token"] = HF_API_KEY
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, **kwargs)
    model = AutoModel.from_pretrained(MODEL_NAME, **kwargs)
    model.eval()
    print(f'✅ Modèle chargé (dimension attendue ~{VECTOR_DIMENSION})')
    return tokenizer, model

def build_text_for_embedding(row):
    parts = []
    lib = getattr(row, "libelle", None)
    if lib:
        lib = lib.strip()
        if lib:
            parts.append(lib)
    cat = getattr(row, "cat_auto", None)
    if cat:
        cat = cat.strip()
        if cat:
            parts.append(f"Catégorie: {cat}")
    typ = getattr(row, "type_operation", None)
    if typ:
        typ = typ.strip()
        if typ:
            parts.append(f"Type: {typ}")
    devise = getattr(row, "devise", None)
    if devise:
        dv = devise.strip().upper()
        if dv and dv != "EUR":
            parts.append(f"Devise: {devise.strip()}")
    if parts:
        return " | ".join(parts)
    return lib if lib else ""

def encode_text(tokenizer, model, text):
    if not text:
        return [0.0] * VECTOR_DIMENSION
    try:
        # Tokenize single string; ensure tensors on cpu (no CUDA assumption)
        inputs = tokenizer(text, return_tensors="pt", truncation=True, max_length=512, padding=True)
        
        # ByteT5 is an encoder-decoder model, use encoder only for embeddings
        with torch.no_grad():
            # Get encoder from model (ByteT5 has encoder attribute)
            if hasattr(model, 'encoder'):
                encoder = model.encoder
            elif hasattr(model, 'get_encoder'):
                encoder = model.get_encoder()
            else:
                # Fallback: try direct model call but only with encoder inputs
                encoder = model
            
            # Use only encoder_input_ids (not decoder inputs)
            encoder_inputs = {"input_ids": inputs["input_ids"]}
            if "attention_mask" in inputs:
                encoder_inputs["attention_mask"] = inputs["attention_mask"]
            
            encoder_outputs = encoder(**encoder_inputs)
            
            # Extract embeddings from encoder outputs
            if hasattr(encoder_outputs, "last_hidden_state"):
                vec = encoder_outputs.last_hidden_state.mean(dim=1).squeeze().tolist()
            elif isinstance(encoder_outputs, tuple) and len(encoder_outputs) > 0:
                vec = encoder_outputs[0].mean(dim=1).squeeze().tolist()
            else:
                # Fallback
                vec = encoder_outputs.mean(dim=1).squeeze().tolist()
        
        # Ensure length VECTOR_DIMENSION (best-effort)
        if len(vec) != VECTOR_DIMENSION:
            # pad or truncate
            if len(vec) < VECTOR_DIMENSION:
                vec.extend([0.0] * (VECTOR_DIMENSION - len(vec)))
            else:
                vec = vec[:VECTOR_DIMENSION]
        return vec
    except Exception as e:
        print(f"⚠️ Erreur encodage pour {text[:50]}: {e}")
        return [0.0] * VECTOR_DIMENSION

def main():
    print("🔗 Connexion à HCD (localhost:9042)...")
    cluster = Cluster(['localhost'], port=9042)
    session = cluster.connect()
    # Use keyspace explicitly
    KEYSPACE = os.environ.get("KEYSPACE", "domiramacatops_poc")
    session.set_keyspace(KEYSPACE)
    session.default_consistency_level = ConsistencyLevel.LOCAL_QUORUM
    
    print("📥 Récupération des partitions (code_si, contrat)...")
    partitions = list(session.execute("SELECT DISTINCT code_si, contrat FROM operations_by_account"))
    print(f"✅ {len(partitions)} partition(s) trouvée(s)")
    
    # Prepare select and update statements
    select_prep = session.prepare("""
        SELECT code_si, contrat, date_op, numero_op, libelle, cat_auto, type_operation, devise, libelle_embedding
        FROM operations_by_account WHERE code_si = ? AND contrat = ?
    """)
    
    update_prep = session.prepare("""
        UPDATE operations_by_account SET libelle_embedding = ? WHERE code_si = ? AND contrat = ? AND date_op = ? AND numero_op = ?
    """)
    
    # Collect rows to process
    rows_to_process = []
    for i, p in enumerate(partitions):
        if (i + 1) % 50 == 0:
            print(f"   Partition {i+1}/{len(partitions)}...")
        res = list(session.execute(select_prep, [p.code_si, p.contrat]))
        for r in res:
            if getattr(r, "libelle", None) and str(getattr(r, "libelle")).strip():
                if FORCE_REGENERATE or getattr(r, "libelle_embedding", None) in (None, []):
                    rows_to_process.append(r)
    
    total = len(rows_to_process)
    if total == 0:
        print("✅ Aucune ligne à traiter (tous les libelle_embedding sont présents).")
        session.shutdown()
        cluster.shutdown()
        return
    
    print(f"✅ {total} opération(s) à traiter")
    
    tokenizer, model = load_model()
    
    processed = 0
    updated = 0
    errors = 0
    start = time.time()
    
    # Process in batches
    for i in range(0, total, BATCH_SIZE):
        batch = rows_to_process[i:i+BATCH_SIZE]
        embeddings = []
        for row in batch:
            try:
                text = build_text_for_embedding(row)
                emb = encode_text(tokenizer, model, text)
                embeddings.append((row, emb))
            except Exception as e:
                print(f"⚠️ Erreur encodage pour {getattr(row,'code_si',None)}/{getattr(row,'contrat',None)}: {e}")
                errors += 1
        
        # Update sequentially (CQL batch could be considered but beware batch size limits)
        for row, emb in embeddings:
            try:
                # store embedding as list<float>
                session.execute(update_prep, [emb, row.code_si, row.contrat, row.date_op, row.numero_op])
                updated += 1
            except Exception as e:
                print(f"⚠️ Erreur UPDATE pour {row.code_si}/{row.contrat}: {e}")
                errors += 1
        
        processed += len(batch)
        if processed % (BATCH_SIZE * 2) == 0 or processed == total:
            elapsed = time.time() - start
            rate = processed / elapsed if elapsed > 0 else 0.0
            print(f"Progression: {processed}/{total} ({rate:.1f} op/s)")
    
    elapsed = time.time() - start
    print("✅ Génération terminée !")
    print(f"Traitées: {processed}")
    print(f"Mises à jour: {updated}")
    print(f"Erreurs: {errors}")
    print(f"Temps: {elapsed:.1f}s")
    print(f"Débit: {processed/elapsed:.1f} op/s" if elapsed > 0 else "Débit: 0 op/s")
    
    session.shutdown()
    cluster.shutdown()

if __name__ == "__main__":
    main()
