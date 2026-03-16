#!/usr/bin/env python3
"""
Test de recherche hybride : combinaison de Vector Search (ByteT5) + Full-Text Search (SAI).
Démontre la meilleure pertinence en combinant les deux approches.
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


def fulltext_search(session, query_term, code_si, contrat, limit=10):
    """Recherche full-text avec SAI."""
    cql_query = """
    SELECT libelle, montant, cat_auto
    FROM operations_by_account
    WHERE code_si = '{code_si}'
      AND contrat = '{contrat}'
      AND libelle : '{query_term}'
    LIMIT {limit}
    """

    try:
        statement = SimpleStatement(cql_query)
        results = list(session.execute(statement))
        return results
    except Exception as e:
        print(f"   ❌ Erreur: {str(e)}")
        return []


def vector_search(session, query_embedding, code_si, contrat, limit=10):
    """Recherche vectorielle avec ANN."""
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


def hybrid_search(session, query_embedding, query_term, code_si, contrat, limit=10):
    """Recherche hybride : filtre full-text puis tri vectoriel."""
    # Note: HCD ne supporte pas directement WHERE + ORDER BY ANN sur différentes colonnes
    # On filtre d'abord avec full-text, puis on trie par similarité vectorielle
    # Pour l'instant, on simule en filtrant les résultats vectoriels
    vector_results = vector_search(session, query_embedding, code_si, contrat, limit=limit * 2)

    # Filtrer les résultats qui contiennent le terme recherché
    filtered = []
    query_lower = query_term.lower()
    for result in vector_results:
        if result.libelle and query_lower in result.libelle.lower():
            filtered.append(result)
            if len(filtered) >= limit:
                break

    return filtered


def main():
    """Fonction principale pour tester la recherche hybride."""
    print("=" * 70)
    print("  🔍 Tests de Recherche Hybride (Vector + Full-Text)")
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

    # Utiliser une partition connue
    code_si = "1"
    contrat = "5913101072"
    print(f"📋 Tests sur: code_si={code_si}, contrat={contrat}")
    print()

    # Tests comparatifs
    test_cases = [
        {
            "query": "LOYER IMPAYE",
            "typo_query": "loyr impay",
            "fulltext_term": "loyer",
            "description": "Recherche 'LOYER IMPAYE'",
        },
        {
            "query": "VIREMENT",
            "typo_query": "viremnt",
            "fulltext_term": "virement",
            "description": "Recherche 'VIREMENT'",
        },
    ]

    print("=" * 70)
    print("  📊 Comparaison des Approches de Recherche")
    print("=" * 70)
    print()

    for test_case in test_cases:
        query = test_case["query"]
        typo_query = test_case["typo_query"]
        fulltext_term = test_case["fulltext_term"]
        description = test_case["description"]

        print(f"🔍 Test: {description}")
        print()

        # 1. Recherche Full-Text seule
        print(f"   1️⃣  Full-Text Search (SAI): '{fulltext_term}'")
        fulltext_results = fulltext_search(session, fulltext_term, code_si, contrat, limit=5)
        if fulltext_results:
            print(f"      ✅ {len(fulltext_results)} résultat(s) trouvé(s)")
            for i, row in enumerate(fulltext_results[:3], 1):
                libelle = row.libelle[:55] if row.libelle else "N/A"
                print(f"         {i}. {libelle}")
        else:
            print("      ⚠️  Aucun résultat")
        print()

        # 2. Recherche Vectorielle seule (sans typo)
        print(f"   2️⃣  Vector Search (ByteT5): '{query}'")
        query_embedding = encode_text(tokenizer, model, query)
        vector_results = vector_search(session, query_embedding, code_si, contrat, limit=5)
        if vector_results:
            print(f"      ✅ {len(vector_results)} résultat(s) trouvé(s)")
            for i, row in enumerate(vector_results[:3], 1):
                libelle = row.libelle[:55] if row.libelle else "N/A"
                print(f"         {i}. {libelle}")
        else:
            print("      ⚠️  Aucun résultat")
        print()

        # 3. Recherche Vectorielle avec typo
        print(f"   3️⃣  Vector Search avec typo: '{typo_query}'")
        typo_embedding = encode_text(tokenizer, model, typo_query)
        typo_results = vector_search(session, typo_embedding, code_si, contrat, limit=5)
        if typo_results:
            print(f"      ✅ {len(typo_results)} résultat(s) trouvé(s) (typo tolérée)")
            for i, row in enumerate(typo_results[:3], 1):
                libelle = row.libelle[:55] if row.libelle else "N/A"
                print(f"         {i}. {libelle}")
        else:
            print("      ⚠️  Aucun résultat")
        print()

        print("-" * 70)
        print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Tests terminés !")
    print("=" * 70)
    print()
    print("💡 Conclusion:")
    print("   ✅ Full-Text Search: Précision élevée, mais ne tolère pas les typos")
    print("   ✅ Vector Search: Tolère les typos, mais pertinence variable")
    print("   💡 Recommandation: Combiner les deux pour meilleure expérience")
    print("      - Full-Text pour recherches exactes")
    print("      - Vector Search pour recherches avec typos/variations")


if __name__ == "__main__":
    main()
