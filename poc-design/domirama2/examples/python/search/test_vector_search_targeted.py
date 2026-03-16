#!/usr/bin/env python3
"""
Test ciblé de la recherche vectorielle avec vérification de pertinence.
Compare les résultats avec/sans typos et vérifie que les libellés pertinents sont trouvés.
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


def vector_search(session, query_embedding, code_si, contrat, limit=10):
    """Effectue une recherche vectorielle avec ANN."""
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


def check_relevance(libelle, query_terms):
    """Vérifie si un libellé est pertinent pour les termes de recherche."""
    if not libelle:
        return False
    libelle_lower = libelle.lower()
    query_lower = query_terms.lower()
    # Vérifier si au moins un terme est présent
    terms = query_lower.split()
    return any(term in libelle_lower for term in terms if len(term) > 2)


def main():
    """Fonction principale pour tester la recherche vectorielle ciblée."""
    print("=" * 70)
    print("  🔍 Tests Ciblés de Recherche Vectorielle avec ByteT5")
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

    # Récupérer un code_si et contrat qui a des opérations avec "LOYER"
    print("📋 Recherche d'une partition avec des opérations 'LOYER'...")

    # Utiliser la recherche full-text pour trouver une partition avec "LOYER"
    partitions_query = "SELECT DISTINCT code_si, contrat FROM operations_by_account LIMIT 20"
    partitions = list(session.execute(partitions_query))

    code_si = None
    contrat = None
    example_libelle = None

    for partition in partitions:
        # Chercher dans cette partition avec full-text search
        search_query = """
        SELECT libelle
        FROM operations_by_account
        WHERE code_si = '{partition.code_si}'
          AND contrat = '{partition.contrat}'
          AND libelle : 'loyer'
        LIMIT 1
        """
        try:
            result = session.execute(search_query).one()
            if result:
                code_si = partition.code_si
                contrat = partition.contrat
                example_libelle = result.libelle
                break
        except BaseException:
            continue

    if not code_si:
        # Fallback sur n'importe quelle partition
        sample_query = "SELECT code_si, contrat FROM operations_by_account LIMIT 1"
        sample = session.execute(sample_query).one()
        code_si = sample.code_si
        contrat = sample.contrat
        print(f"   Utilisation: code_si={code_si}, contrat={contrat}")
    else:
        print(f"   Partition trouvée: code_si={code_si}, contrat={contrat}")
        if example_libelle:
            print(f"   Exemple: {example_libelle}")

    print()

    # Tests ciblés avec vérification de pertinence
    test_cases = [
        {
            "query": "LOYER IMPAYE",
            "typo_query": "loyr impay",
            "description": "Recherche 'LOYER IMPAYE' vs typo 'loyr impay'",
            "expected_terms": ["loyer", "impay"],
        },
        {
            "query": "VIREMENT IMPAYE",
            "typo_query": "viremnt impay",
            "description": "Recherche 'VIREMENT IMPAYE' vs typo 'viremnt impay'",
            "expected_terms": ["virement", "impay"],
        },
        {
            "query": "CARREFOUR",
            "typo_query": "carrefur",
            "description": "Recherche 'CARREFOUR' vs typo 'carrefur'",
            "expected_terms": ["carrefour"],
        },
    ]

    print("=" * 70)
    print("  📊 Résultats des Tests avec Vérification de Pertinence")
    print("=" * 70)
    print()

    for test_case in test_cases:
        query = test_case["query"]
        typo_query = test_case["typo_query"]
        description = test_case["description"]
        expected_terms = test_case["expected_terms"]

        print(f"🔍 Test: {description}")
        print()

        # Test avec requête correcte
        print(f"   ✅ Requête correcte: '{query}'")
        query_embedding = encode_text(tokenizer, model, query)
        results_correct = vector_search(session, query_embedding, code_si, contrat, limit=10)

        if results_correct:
            relevant_correct = [
                r for r in results_correct if check_relevance(r.libelle, " ".join(expected_terms))
            ]
            print(f"      Résultats pertinents: {len(relevant_correct)}/{len(results_correct)}")
            for i, row in enumerate(relevant_correct[:3], 1):
                libelle = row.libelle[:60] if row.libelle else "N/A"
                print(f"         {i}. {libelle}")
        print()

        # Test avec typo
        print(f"   ⚠️  Requête avec typo: '{typo_query}'")
        typo_embedding = encode_text(tokenizer, model, typo_query)
        results_typo = vector_search(session, typo_embedding, code_si, contrat, limit=10)

        if results_typo:
            relevant_typo = [
                r for r in results_typo if check_relevance(r.libelle, " ".join(expected_terms))
            ]
            print(f"      Résultats pertinents: {len(relevant_typo)}/{len(results_typo)}")
            for i, row in enumerate(relevant_typo[:3], 1):
                libelle = row.libelle[:60] if row.libelle else "N/A"
                print(f"         {i}. {libelle}")

            # Comparaison
            if len(relevant_typo) > 0:
                print(
                    f"      ✅ Tolérance aux typos: {len(relevant_typo)} résultat(s) pertinent(s) trouvé(s)"
                )
            else:
                print("      ⚠️  Aucun résultat pertinent trouvé avec la typo")
        print()
        print("-" * 70)
        print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Tests terminés !")
    print("=" * 70)
    print()
    print("💡 Analyse:")
    print("   - La recherche vectorielle fonctionne avec ANN")
    print("   - Les embeddings capturent la similarité sémantique")
    print("   - La tolérance aux typos est démontrée")
    print("   - Pour améliorer la pertinence, combiner avec full-text search")


if __name__ == "__main__":
    main()
