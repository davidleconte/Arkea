#!/usr/bin/env python3
"""
Tests avec seuils de similarité pour la recherche vectorielle.
Teste différents seuils pour filtrer les résultats.
"""

from test_vector_search_base import (
    calculate_cosine_similarity,
    connect_to_hcd,
    encode_text,
    get_test_account,
    load_model,
)


def vector_search_with_threshold(
    session, query_embedding, code_si: str, contrat: str, threshold: float = 0.7, limit: int = 5
):
    """Recherche vectorielle avec seuil de similarité."""
    from cassandra.query import SimpleStatement

    # Récupérer plus de résultats pour filtrer par seuil
    # Note: HCD ne supporte pas directement le filtrage par seuil dans la requête ANN
    # On récupère plus de résultats et on filtre côté client
    cql_query = """
    SELECT libelle, montant, cat_auto, cat_user, cat_confidence, libelle_embedding
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
    LIMIT {limit * 3}
    """

    try:
        statement = SimpleStatement(cql_query)
        results = list(session.execute(statement))

        # Filtrer par seuil de similarité
        filtered = []
        for row in results:
            if hasattr(row, "libelle_embedding") and row.libelle_embedding:
                similarity = calculate_cosine_similarity(query_embedding, row.libelle_embedding)
                if similarity >= threshold:
                    filtered.append((row, similarity))

        # Trier par similarité décroissante
        filtered.sort(key=lambda x: x[1], reverse=True)

        return [row for row, _ in filtered[:limit]]
    except Exception as e:
        print(f"   ❌ Erreur: {str(e)}")
        return []


def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🎯 Tests avec Seuils de Similarité - Recherche Vectorielle")
    print("=" * 70)
    print()

    # Charger le modèle
    tokenizer, model = load_model()
    print()

    # Connexion à HCD
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
    test_queries = ["LOYER IMPAYE", "loyr impay", "PAIEMENT CARTE"]

    # Seuils à tester
    thresholds = [0.9, 0.7, 0.5, 0.3]

    print("=" * 70)
    print("  📊 Résultats des Tests")
    print("=" * 70)
    print()

    for query in test_queries:
        print(f"🔍 Requête: '{query}'")
        print()

        query_embedding = encode_text(tokenizer, model, query)

        for threshold in thresholds:
            print(f"   🎯 Seuil {threshold:.1f}:")
            results = vector_search_with_threshold(
                session, query_embedding, code_si, contrat, threshold=threshold, limit=5
            )
            print(f"      {len(results)} résultat(s) avec similarité >= {threshold:.1f}")

            if results:
                for i, row in enumerate(results[:3], 1):
                    libelle = row.libelle[:40] if row.libelle else "N/A"
                    print(f"      {i}. {libelle}")
            print()

        print("-" * 70)
        print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Tests avec seuils terminés !")
    print("=" * 70)


if __name__ == "__main__":
    main()
