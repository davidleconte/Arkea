#!/usr/bin/env python3
"""
Script de test pour la recherche vectorielle avec ByteT5.
Teste la recherche floue avec des typos et compare les résultats.
"""

import os

import torch
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
from transformers import AutoModel, AutoTokenizer

# Configuration
MODEL_NAME = "google/byt5-small"
VECTOR_DIMENSION = 1472
HF_API_KEY = os.getenv("HF_API_KEY")


def load_model():
    """Charge le modèle ByteT5."""
    print(f"📥 Chargement du modèle {MODEL_NAME}...")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, token=HF_API_KEY)
    model = AutoModel.from_pretrained(MODEL_NAME, token=HF_API_KEY)
    model.eval()
    print("✅ Modèle chargé")
    return tokenizer, model


def encode_text(tokenizer, model, text):
    """Encode un texte en vecteur d'embedding."""
    if not text or text.strip() == "":
        return [0.0] * VECTOR_DIMENSION

    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True, max_length=512)
    with torch.no_grad():
        encoder_outputs = model.encoder(**inputs)
        embeddings = encoder_outputs.last_hidden_state.mean(dim=1)
    return embeddings[0].tolist()


def vector_search(session, query_embedding, code_si, contrat, limit=5):
    """Effectue une recherche vectorielle avec ANN."""
    # Construire la requête CQL avec ANN
    cql_query = """
    SELECT libelle, montant, cat_auto
    FROM operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
    LIMIT {limit}
    """

    try:
        statement = SimpleStatement(cql_query)
        results = list(session.execute(statement))
        return results
    except Exception as e:
        print(f"   ❌ Erreur: {str(e)}")
        return []


def main():
    """Fonction principale pour tester la recherche vectorielle."""
    print("=" * 70)
    print("  🔍 Tests de Recherche Vectorielle avec ByteT5")
    print("=" * 70)
    print()

    # Charger le modèle
    tokenizer, model = load_model()
    print()

    # Connexion à HCD
    print("📡 Connexion à HCD...")
    cluster = Cluster(["localhost"], port=9042)
    session = cluster.connect("domirama2_poc")
    print("✅ Connecté à HCD")
    print()

    # Récupérer un code_si et contrat pour les tests
    sample_query = "SELECT code_si, contrat FROM operations_by_account LIMIT 1"
    sample = session.execute(sample_query).one()
    if not sample:
        print("⚠️  Aucune opération trouvée")
        session.shutdown()
        cluster.shutdown()
        return

    code_si = sample.code_si
    contrat = sample.contrat
    print(f"📋 Tests sur: code_si={code_si}, contrat={contrat}")
    print()

    # Tests avec différentes requêtes (avec et sans typos)
    # Recherches ciblées sur des libellés spécifiques
    test_queries = [
        ("LOYER IMPAYE", "Recherche correcte: 'LOYER IMPAYE'"),
        (
            "loyr impay",
            "Typo: caractères manquants ('loyr impay' au lieu de 'loyer impayé')",
        ),
        ("LOYER PARIS", "Recherche correcte: 'LOYER PARIS'"),
        (
            "loyr parsi",
            "Typo: caractères manquants/inversés ('loyr parsi' au lieu de 'loyer paris')",
        ),
        ("VIREMENT IMPAYE", "Recherche correcte: 'VIREMENT IMPAYE'"),
        (
            "viremnt impay",
            "Typo: caractères manquants ('viremnt impay' au lieu de 'virement impayé')",
        ),
        ("CARREFOUR", "Recherche correcte: 'CARREFOUR'"),
        ("carrefur", "Typo: caractère inversé ('carrefur' au lieu de 'carrefour')"),
        ("PAIEMENT CARTE", "Recherche correcte: 'PAIEMENT CARTE'"),
        (
            "paiemnt cart",
            "Typo: caractères manquants ('paiemnt cart' au lieu de 'paiement carte')",
        ),
    ]

    print("=" * 70)
    print("  📊 Résultats des Tests")
    print("=" * 70)
    print()

    for query_text, description in test_queries:
        print(f"🔍 Requête: '{query_text}'")
        print(f"   {description}")

        # Générer l'embedding de la requête
        query_embedding = encode_text(tokenizer, model, query_text)

        # Effectuer la recherche vectorielle
        results = vector_search(session, query_embedding, code_si, contrat, limit=5)

        if results:
            print(f"   📊 Résultats ({len(results)} trouvés):")
            for i, row in enumerate(results, 1):
                libelle = row.libelle[:50] if row.libelle else "N/A"
                montant = row.montant if row.montant else "N/A"
                cat = row.cat_auto if row.cat_auto else "N/A"
                print(f"      {i}. {libelle} | {montant} | {cat}")
        else:
            print("   ⚠️  Aucun résultat trouvé")

        print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Tests terminés !")
    print("=" * 70)


if __name__ == "__main__":
    main()
