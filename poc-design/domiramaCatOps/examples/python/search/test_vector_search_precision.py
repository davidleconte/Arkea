#!/usr/bin/env python3
"""
Tests de précision/recall pour la recherche vectorielle.
Évalue la qualité des résultats retournés.
Note: Nécessite un jeu de test annoté manuellement pour une évaluation complète.
"""

from test_vector_search_base import (
    connect_to_hcd,
    encode_text,
    get_test_account,
    load_model,
    vector_search,
)


def evaluate_precision_recall(expected_results: list, actual_results: list) -> dict:
    """Calcule précision, recall et F1-score."""
    if not actual_results:
        return {"precision": 0.0, "recall": 0.0, "f1": 0.0}

    if not expected_results:
        return {"precision": 0.0, "recall": 0.0, "f1": 0.0}

    # Convertir en sets de libellés pour comparaison
    expected_set = set(expected_results)
    actual_set = set([r.libelle for r in actual_results if r.libelle])

    # Calculer intersection
    relevant_found = len(expected_set & actual_set)

    # Précision : résultats pertinents / résultats retournés
    precision = relevant_found / len(actual_set) if actual_set else 0.0

    # Recall : résultats pertinents / résultats attendus
    recall = relevant_found / len(expected_set) if expected_set else 0.0

    # F1-score
    f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0.0

    return {
        "precision": precision,
        "recall": recall,
        "f1": f1,
        "relevant_found": relevant_found,
        "total_expected": len(expected_set),
        "total_returned": len(actual_set),
    }


def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🎯 Tests de Précision/Recall - Recherche Vectorielle")
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

    # Exemple de jeu de test (à remplacer par des données annotées réelles)
    # Format : (requête, [libellés attendus])
    test_cases = [
        ("LOYER IMPAYE", []),  # À annoter manuellement
        ("PAIEMENT CARTE", []),  # À annoter manuellement
    ]

    # Vérifier si au moins un test est annoté
    has_annotated_tests = any(expected for _, expected in test_cases if expected)

    print("=" * 70)
    print("  📊 Résultats des Tests")
    print("=" * 70)
    print()

    if not has_annotated_tests:
        print("ℹ️  Note : Ce test nécessite un jeu de test annoté manuellement")
        print("   Pour calculer les métriques de précision/recall, il faut :")
        print("   1. Définir pour chaque requête les libellés attendus (pertinents)")
        print("   2. Comparer avec les résultats obtenus")
        print("   3. Calculer précision, recall, F1-score, MRR, NDCG")
        print()
        print("   Exemple d'annotation :")
        print("   test_cases = [")
        print("       ('LOYER IMPAYE', ['LOYER IMPAYE PARIS', 'LOYER IMPAYE LYON']),")
        print("       ('PAIEMENT CARTE', ['CB RESTAURANT', 'CB SUPERMARCHE']),")
        print("   ]")
        print()
        print("-" * 70)
        print()

    for query, expected_libelles in test_cases:
        print(f"🔍 Requête: '{query}'")
        print()

        # Recherche vectorielle
        query_embedding = encode_text(tokenizer, model, query)
        actual_results = vector_search(session, query_embedding, code_si, contrat, limit=5)

        print(f"   📊 Résultats obtenus ({len(actual_results)}):")
        for i, row in enumerate(actual_results, 1):
            libelle = row.libelle[:50] if row.libelle else "N/A"
            print(f"      {i}. {libelle}")
        print()

        if expected_libelles:
            # Évaluation
            metrics = evaluate_precision_recall(expected_libelles, actual_results)
            print("   📊 Métriques:")
            print(f"      Précision : {metrics['precision']:.3f}")
            print(f"      Recall : {metrics['recall']:.3f}")
            print(f"      F1-Score : {metrics['f1']:.3f}")
            print(
                f"      Pertinents trouvés : {metrics['relevant_found']}/{metrics['total_expected']}"
            )
        elif not has_annotated_tests:
            # Message déjà affiché au début, pas besoin de répéter
            pass
        else:
            print("   ⚠️  Jeu de test non annoté pour cette requête - Métriques non calculables")
        print()
        print("-" * 70)
        print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Tests de précision/recall terminés !")
    print("=" * 70)
    print()
    print("💡 Pour améliorer ces tests :")
    print("   1. Créer un jeu de test avec 50+ requêtes")
    print("   2. Annoter manuellement les résultats attendus pour chaque requête")
    print("   3. Exécuter les tests et comparer avec les résultats attendus")
    print("   4. Calculer précision, recall, F1-score, MRR, NDCG")


if __name__ == "__main__":
    main()
