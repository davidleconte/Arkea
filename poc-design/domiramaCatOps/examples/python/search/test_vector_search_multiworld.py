#!/usr/bin/env python3
"""
Tests multi-mots vs mots uniques pour la recherche vectorielle.
Compare la pertinence selon le nombre de mots.
"""

from test_vector_search_base import (
    connect_to_hcd,
    encode_text,
    get_test_account,
    load_model,
    vector_search,
)
from test_vector_search_relevance_check import check_relevance


def main():
    """Fonction principale."""
    print("=" * 70)
    print("  📝 Tests Multi-Mots vs Mots Uniques - Recherche Vectorielle")
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

    # Tests avec différents nombres de mots
    test_cases = [
        ("LOYER", "Mot unique"),
        ("LOYER IMPAYE", "Deux mots"),
        ("LOYER IMPAYE PARIS", "Trois mots"),
        ("VIREMENT", "Mot unique"),
        ("VIREMENT COMPTE", "Deux mots"),
        ("VIREMENT COMPTE BANCAIRE", "Trois mots"),
        ("PAIEMENT", "Mot unique"),
        ("PAIEMENT CARTE", "Deux mots"),
        ("PAIEMENT CARTE BANCAIRE", "Trois mots"),
    ]

    print("=" * 70)
    print("  📊 Résultats des Tests")
    print("=" * 70)
    print()

    for query, description in test_cases:
        print(f"🔍 {description} : '{query}'")
        print()

        query_embedding = encode_text(tokenizer, model, query)
        results = vector_search(session, query_embedding, code_si, contrat, limit=5)

        # Vérifier la pertinence
        relevance = check_relevance(query, results)

        print("   📊 Résultats ({len(results)} trouvés):")
        for i, row in enumerate(results[:3], 1):
            libelle = row.libelle[:50] if row.libelle else "N/A"
            cat = row.cat_auto if row.cat_auto else "N/A"
            print(f"      {i}. {libelle} | {cat}")
        print()

        # Afficher la pertinence
        if relevance["is_mostly_relevant"]:
            print(
                "   ✅ Pertinence OK : {relevance['relevant_count']}/{relevance['total_count']} résultats pertinents"
            )
        else:
            print(
                f"   ⚠️  Pertinence faible : {relevance['relevant_count']}/{relevance['total_count']} résultats pertinents"
            )
            print(
                f"   💡 Note : Les résultats peuvent ne pas être pertinents si les données de test ne contiennent pas de libellés correspondants"
            )

        # Analyse
        word_count = len(query.split())
        if word_count == 1:
            print("   📊 Analyse : Mot unique - Meilleur recall, précision variable")
        elif word_count == 2:
            print("   📊 Analyse : Deux mots - Bon compromis recall/précision")
        else:
            print("   📊 Analyse : Plusieurs mots - Meilleure précision, recall limité")
        print()
        print("-" * 70)
        print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Tests multi-mots terminés !")
    print("=" * 70)


if __name__ == "__main__":
    main()
