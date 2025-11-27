#!/usr/bin/env python3
"""
Script pour générer les embeddings ByteT5 pour toutes les opérations existantes dans HCD.
Lit les données depuis HCD, génère les embeddings, et met à jour la colonne libelle_embedding.
"""

import os
import sys
import torch
from transformers import AutoTokenizer, AutoModel
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
from cassandra import ConsistencyLevel
import time

# Configuration
MODEL_NAME = "google/byt5-small"
VECTOR_DIMENSION = 1472
HF_API_KEY = os.getenv("HF_API_KEY", "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")
BATCH_SIZE = 100  # Traiter par lots pour éviter la surcharge mémoire

def load_model():
    """Charge le modèle ByteT5 et le tokenizer."""
    print(f"📥 Chargement du modèle {MODEL_NAME}...")
    print(f"   Utilisation de la clé API Hugging Face")
    
    tokenizer = AutoTokenizer.from_pretrained(
        MODEL_NAME,
        token=HF_API_KEY
    )
    model = AutoModel.from_pretrained(
        MODEL_NAME,
        token=HF_API_KEY
    )
    model.eval()
    print(f"✅ Modèle chargé (dimension: {VECTOR_DIMENSION})")
    return tokenizer, model

def encode_text(tokenizer, model, text):
    """Encode un texte en vecteur d'embedding."""
    if not text or text.strip() == "":
        return [0.0] * VECTOR_DIMENSION
    
    inputs = tokenizer(
        text,
        return_tensors="pt",
        truncation=True,
        padding=True,
        max_length=512
    )
    
    with torch.no_grad():
        encoder_outputs = model.encoder(**inputs)
        embeddings = encoder_outputs.last_hidden_state.mean(dim=1)
    
    return embeddings[0].tolist()

def main():
    """Fonction principale pour générer les embeddings en batch."""
    print("=" * 70)
    print("  🔄 Génération Batch des Embeddings ByteT5")
    print("=" * 70)
    print()
    
    # Charger le modèle
    tokenizer, model = load_model()
    print()
    
    # Connexion à HCD
    print("📡 Connexion à HCD...")
    cluster = Cluster(['localhost'], port=9042)
    session = cluster.connect('domirama2_poc')
    session.default_consistency_level = ConsistencyLevel.ONE
    print("✅ Connecté à HCD")
    print()
    
    # Récupérer toutes les opérations (on filtre côté client)
    print("📊 Analyse des données...")
    print("📥 Lecture des opérations depuis HCD...")
    
    # Récupérer un échantillon pour estimer le total
    sample_query = "SELECT code_si, contrat FROM operations_by_account LIMIT 10"
    sample = list(session.execute(sample_query))
    
    if not sample:
        print("⚠️  Aucune opération trouvée")
        session.shutdown()
        cluster.shutdown()
        return
    
    # Pour chaque partition, récupérer les opérations
    print("   Récupération des partitions...")
    partitions_query = "SELECT DISTINCT code_si, contrat FROM operations_by_account"
    partitions = list(session.execute(partitions_query))
    print(f"   {len(partitions)} partition(s) trouvée(s)")
    print()
    
    # Récupérer toutes les opérations par partition
    rows = []
    prepared = session.prepare("""
        SELECT code_si, contrat, date_op, numero_op, libelle
        FROM operations_by_account
        WHERE code_si = ? AND contrat = ?
    """)
    
    for i, partition in enumerate(partitions):
        if (i + 1) % 10 == 0:
            print(f"   Traitement partition {i+1}/{len(partitions)}...", end="\r", flush=True)
        partition_rows = list(session.execute(prepared, [partition.code_si, partition.contrat]))
        # Filtrer côté client pour ne garder que celles avec libelle
        rows.extend([r for r in partition_rows if r.libelle and r.libelle.strip()])
    
    print(f"   Traitement partition {len(partitions)}/{len(partitions)}...")
    
    total_count = len(rows)
    print(f"✅ {total_count} opérations avec libellé trouvées")
    print()
    
    # Préparer la requête UPDATE
    update_prepared = session.prepare("""
        UPDATE operations_by_account
        SET libelle_embedding = ?
        WHERE code_si = ? AND contrat = ? AND date_op = ? AND numero_op = ?
    """)
    
    # Générer les embeddings par lots
    print(f"🔄 Génération des embeddings (lots de {BATCH_SIZE})...")
    processed = 0
    updated = 0
    errors = 0
    
    start_time = time.time()
    
    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i:i + BATCH_SIZE]
        batch_num = (i // BATCH_SIZE) + 1
        total_batches = (len(rows) + BATCH_SIZE - 1) // BATCH_SIZE
        
        print(f"   Lot {batch_num}/{total_batches} ({len(batch)} opérations)...", end=" ", flush=True)
        
        batch_start = time.time()
        
        for row in batch:
            try:
                # Générer l'embedding
                embedding = encode_text(tokenizer, model, row.libelle)
                
                # Mettre à jour dans HCD
                session.execute(
                    update_prepared,
                    [embedding, row.code_si, row.contrat, row.date_op, row.numero_op]
                )
                updated += 1
                
            except Exception as e:
                print(f"\n      ❌ Erreur pour {row.code_si}/{row.contrat}: {str(e)}")
                errors += 1
        
        processed += len(batch)
        batch_time = time.time() - batch_start
        elapsed = time.time() - start_time
        avg_time = elapsed / processed if processed > 0 else 0
        remaining = (len(rows) - processed) * avg_time
        
        print(f"✅ ({batch_time:.1f}s) | Total: {processed}/{len(rows)} | "
              f"Temps restant: ~{remaining/60:.1f}min")
    
    total_time = time.time() - start_time
    
    print()
    print("=" * 70)
    print("  ✅ Génération terminée !")
    print("=" * 70)
    print(f"📊 Statistiques:")
    print(f"   Total traité: {processed}")
    print(f"   Mis à jour: {updated}")
    print(f"   Erreurs: {errors}")
    print(f"   Temps total: {total_time/60:.2f} minutes")
    print(f"   Vitesse: {processed/total_time:.1f} opérations/seconde")
    print()
    
    # Vérification finale
    final_count = session.execute(
        "SELECT COUNT(*) FROM operations_by_account WHERE libelle_embedding IS NOT NULL ALLOW FILTERING"
    ).one()[0]
    print(f"✅ Vérification: {final_count} opérations avec embedding dans HCD")
    
    session.shutdown()
    cluster.shutdown()

if __name__ == "__main__":
    main()

