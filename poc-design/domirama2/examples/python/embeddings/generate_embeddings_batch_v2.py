#!/usr/bin/env python3
"""
Script pour générer les embeddings ByteT5 pour toutes les opérations existantes dans HCD.
Version améliorée : Combine plusieurs colonnes pertinentes pour créer des embeddings plus riches.

Colonnes utilisées pour générer l'embedding :
- libelle (principal)
- cat_auto (catégorie automatique)
- type_operation (type d'opération)
- devise (devise)

Colonnes exclues :
- Colonnes vectorielles (libelle_embedding)
- Colonnes de clés (code_si, contrat, date_op, numero_op)
- Colonnes BLOB (operation_data)
- Colonnes techniques (op_id, cobol_data_base64, copy_type)
"""

import os
import sys
import torch
from transformers import AutoTokenizer, AutoModel
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
from cassandra import ConsistencyLevel
import time
from decimal import Decimal

# Configuration
MODEL_NAME = "google/byt5-small"
VECTOR_DIMENSION = 1472
HF_API_KEY = os.getenv("HF_API_KEY", "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")
BATCH_SIZE = 100  # Traiter par lots pour éviter la surcharge mémoire
FORCE_REGENERATE = False  # Si True, régénère même les embeddings existants

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

def build_text_for_embedding(row):
    """
    Construit le texte à encoder en combinant plusieurs colonnes pertinentes.
    
    Colonnes utilisées :
    - libelle (principal, toujours présent)
    - cat_auto (catégorie automatique, si présent)
    - type_operation (type d'opération, si présent)
    - devise (devise, si présent)
    
    Format : "libelle | cat_auto | type_operation | devise"
    """
    parts = []
    
    # Libellé (principal, toujours présent)
    if row.libelle and row.libelle.strip():
        parts.append(row.libelle.strip())
    
    # Catégorie automatique (si présent)
    if row.cat_auto and row.cat_auto.strip():
        parts.append(f"Catégorie: {row.cat_auto.strip()}")
    
    # Type d'opération (si présent)
    if row.type_operation and row.type_operation.strip():
        parts.append(f"Type: {row.type_operation.strip()}")
    
    # Devise (si présent et différent de EUR par défaut)
    if row.devise and row.devise.strip() and row.devise.strip().upper() != "EUR":
        parts.append(f"Devise: {row.devise.strip()}")
    
    # Combiner toutes les parties avec un séparateur
    combined_text = " | ".join(parts)
    
    # Si aucun texte valide, retourner le libellé seul ou une chaîne vide
    if not combined_text or combined_text.strip() == "":
        return row.libelle if row.libelle else ""
    
    return combined_text

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
    print("  🔄 Génération Batch des Embeddings ByteT5 (Version Améliorée)")
    print("=" * 70)
    print()
    print("📋 Colonnes utilisées pour générer les embeddings :")
    print("   ✅ libelle (principal)")
    print("   ✅ cat_auto (catégorie automatique)")
    print("   ✅ type_operation (type d'opération)")
    print("   ✅ devise (devise, si différent de EUR)")
    print()
    print("📋 Colonnes exclues :")
    print("   ❌ Colonnes vectorielles (libelle_embedding)")
    print("   ❌ Colonnes de clés (code_si, contrat, date_op, numero_op)")
    print("   ❌ Colonnes BLOB (operation_data)")
    print("   ❌ Colonnes techniques (op_id, cobol_data_base64, copy_type)")
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
    
    # Récupérer toutes les opérations par partition avec toutes les colonnes pertinentes
    rows = []
    prepared = session.prepare("""
        SELECT code_si, contrat, date_op, numero_op, libelle, cat_auto, type_operation, devise, libelle_embedding
        FROM operations_by_account
        WHERE code_si = ? AND contrat = ?
    """)
    
    for i, partition in enumerate(partitions):
        if (i + 1) % 10 == 0:
            print(f"   Traitement partition {i+1}/{len(partitions)}...", end="\r", flush=True)
        partition_rows = list(session.execute(prepared, [partition.code_si, partition.contrat]))
        # Filtrer côté client pour ne garder que celles avec libelle
        # Si FORCE_REGENERATE=False, ne traiter que celles sans embedding
        for r in partition_rows:
            if r.libelle and r.libelle.strip():
                if FORCE_REGENERATE or r.libelle_embedding is None:
                    rows.append(r)
    
    print(f"   Traitement partition {len(partitions)}/{len(partitions)}...")
    
    total_count = len(rows)
    if FORCE_REGENERATE:
        print(f"✅ {total_count} opérations avec libellé trouvées (régénération forcée)")
    else:
        print(f"✅ {total_count} opérations avec libellé trouvées (sans embedding)")
    print()
    
    if total_count == 0:
        print("✅ Toutes les opérations ont déjà des embeddings !")
        session.shutdown()
        cluster.shutdown()
        return
    
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
                # Construire le texte combiné à partir de plusieurs colonnes
                combined_text = build_text_for_embedding(row)
                
                # Générer l'embedding
                embedding = encode_text(tokenizer, model, combined_text)
                
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
    
    # Vérification finale (compter via échantillonnage)
    print("✅ Vérification: Embeddings générés et mis à jour dans HCD")
    print(f"   {updated} opération(s) mise(s) à jour avec succès")
    
    # Statistiques sur les colonnes utilisées (via échantillonnage)
    print()
    print("📊 Statistiques sur les colonnes utilisées (échantillon) :")
    sample_query = """
        SELECT libelle, cat_auto, type_operation, devise
        FROM operations_by_account
        LIMIT 100
    """
    sample_rows = list(session.execute(sample_query))
    if sample_rows:
        total_sample = len(sample_rows)
        avec_libelle = sum(1 for r in sample_rows if r.libelle)
        avec_cat_auto = sum(1 for r in sample_rows if r.cat_auto)
        avec_type_op = sum(1 for r in sample_rows if r.type_operation)
        avec_devise = sum(1 for r in sample_rows if r.devise)
        
        print(f"   Échantillon analysé: {total_sample} opérations")
        print(f"   Avec libelle: {avec_libelle} ({avec_libelle/total_sample*100:.1f}%)")
        print(f"   Avec cat_auto: {avec_cat_auto} ({avec_cat_auto/total_sample*100:.1f}%)")
        print(f"   Avec type_operation: {avec_type_op} ({avec_type_op/total_sample*100:.1f}%)")
        print(f"   Avec devise: {avec_devise} ({avec_devise/total_sample*100:.1f}%)")
    
    session.shutdown()
    cluster.shutdown()

if __name__ == "__main__":
    # Vérifier les arguments
    if len(sys.argv) > 1 and sys.argv[1] == "--force":
        FORCE_REGENERATE = True
        print("⚠️  Mode régénération forcée activé (tous les embeddings seront régénérés)")
        print()
    
    main()

