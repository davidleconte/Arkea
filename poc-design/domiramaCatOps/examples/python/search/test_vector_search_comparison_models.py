#!/usr/bin/env python3
"""
Test comparatif entre ByteT5-small et multilingual-e5-large.
Compare les performances et la pertinence des résultats.
"""

import time

from test_vector_search_base import (
    KEYSPACE,
    connect_to_hcd,
    encode_text,
    get_test_account,
    load_model,
    vector_search,
)
from test_vector_search_relevance_check import check_relevance

# Essayer d'importer e5-large (optionnel)
try:
    from sentence_transformers import SentenceTransformer

    E5_AVAILABLE = True
except ImportError:
    E5_AVAILABLE = False
    print("⚠️  sentence-transformers non installé - Tests e5-large non disponibles")
    print("   Installer avec: pip install sentence-transformers")


def test_e5_search(session, query: str, code_si: str, contrat: str, limit: int = 5):
    """Teste la recherche avec e5-large."""
    if not E5_AVAILABLE:
        return []

    model = SentenceTransformer("intfloat/multilingual-e5-large")
    embedding = model.encode(query, normalize_embeddings=True)

    import json

    from cassandra.query import SimpleStatement

    cql_query = f"""
    SELECT libelle, montant, cat_auto, cat_user, cat_confidence
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY libelle_embedding_e5 ANN OF {json.dumps(embedding.tolist())}
    LIMIT {limit}
    """

    try:
        statement = SimpleStatement(cql_query)
        results = list(session.execute(statement))
        return results
    except Exception as e:
        print(f"   ❌ Erreur e5: {str(e)}")
        return []


def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🔀 Comparaison ByteT5 vs multilingual-e5-large")
    print("=" * 70)
    print()

    # Charger le modèle ByteT5
    tokenizer, model_byt5 = load_model()
    print()

    # Connexion HCD
    print("📡 Connexion à HCD...")
    cluster, session = connect_to_hcd()
    print("✅ Connecté à HCD")
    print()

    # Récupérer un compte de test
    account = get_test_account(session)
    if not account:
        print("⚠️  Aucune opération trouvée")
        session.shutdown()
        cluster.shutdown()
        return

    code_si, contrat = account
    print(f"📋 Tests sur: code_si={code_si}, contrat={contrat}")
    print()

    # Requêtes de test
    test_queries = [
        "LOYER IMPAYE",
        "VIREMENT SALAIRE",
        "PAIEMENT CARTE",
        "CARREFOUR PARIS",
    ]

    print("=" * 70)
    print("  📊 Résultats Comparatifs")
    print("=" * 70)
    print()

    for query in test_queries:
        print(f"🔍 Requête: '{query}'")
        print()

        # Test ByteT5
        start = time.time()
        embedding_byt5 = encode_text(tokenizer, model_byt5, query)
        results_byt5 = vector_search(session, embedding_byt5, code_si, contrat, limit=5)
        latency_byt5 = (time.time() - start) * 1000

        relevance_byt5 = check_relevance(query, results_byt5)

        print("   📊 ByteT5-small ({latency_byt5:.1f} ms):")
        print(f"      Résultats : {len(results_byt5)}")
        print(
            f"      Pertinence : {relevance_byt5['relevant_count']}/{relevance_byt5['total_count']} ({relevance_byt5['relevance_rate']:.1%})"
        )
        for i, row in enumerate(results_byt5[:3], 1):
            libelle = row.libelle[:50] if row.libelle else "N/A"
            print(f"      {i}. {libelle}")
        print()

        # Test e5-large (si disponible)
        if E5_AVAILABLE:
            start = time.time()
            results_e5 = test_e5_search(session, query, code_si, contrat, limit=5)
            latency_e5 = (time.time() - start) * 1000

            relevance_e5 = check_relevance(query, results_e5)

            print("   📊 multilingual-e5-large ({latency_e5:.1f} ms):")
            print(f"      Résultats : {len(results_e5)}")
            print(
                f"      Pertinence : {relevance_e5['relevant_count']}/{relevance_e5['total_count']} ({relevance_e5['relevance_rate']:.1%})"
            )
            for i, row in enumerate(results_e5[:3], 1):
                libelle = row.libelle[:50] if row.libelle else "N/A"
                print(f"      {i}. {libelle}")

            # Comparaison
            if relevance_e5["relevance_rate"] > relevance_byt5["relevance_rate"]:
                print(
                    f"      ✅ e5-large plus pertinent (+{((relevance_e5['relevance_rate'] - relevance_byt5['relevance_rate']) * 100):.1f}%)"
                )
            elif relevance_byt5["relevance_rate"] > relevance_e5["relevance_rate"]:
                print(
                    f"      ⚠️  ByteT5 plus pertinent (+{((relevance_byt5['relevance_rate'] - relevance_e5['relevance_rate']) * 100):.1f}%)"
                )
            else:
                print(f"      ➡️  Pertinence équivalente")
        else:
            print("   ⚠️  e5-large non disponible (sentence-transformers non installé)")

        print()
        print("-" * 70)
        print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Comparaison terminée !")
    print("=" * 70)


if __name__ == "__main__":
    main()
