#!/usr/bin/env python3
"""
Tests comparatifs entre Vector Search et Full-Text Search.
Compare les résultats, la latence et la pertinence.
"""

import sys
import time

from test_vector_search_base import (
    connect_to_hcd,
    encode_text,
    fulltext_search,
    get_test_account,
    load_model,
    vector_search,
)


def compare_searches(session, tokenizer, model, query: str, code_si: str, contrat: str):
    """Compare Vector Search et Full-Text Search pour une requête."""
    results = {
        "vector": {"results": [], "time": 0, "count": 0},
        "fulltext": {"results": [], "time": 0, "count": 0},
    }

    # Vector Search
    start_vector = time.time()
    query_embedding = encode_text(tokenizer, model, query)
    vector_results = vector_search(session, query_embedding, code_si, contrat, limit=5)
    vector_time = (time.time() - start_vector) * 1000  # ms
    results["vector"] = {
        "results": vector_results,
        "time": vector_time,
        "count": len(vector_results),
    }

    # Full-Text Search
    start_ft = time.time()
    ft_results = fulltext_search(session, query, code_si, contrat, limit=5)
    ft_time = (time.time() - start_ft) * 1000  # ms
    results["fulltext"] = {"results": ft_results, "time": ft_time, "count": len(ft_results)}

    return results


def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🔀 Tests Comparatifs - Vector Search vs Full-Text Search")
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
    test_queries = [
        ("LOYER IMPAYE", "Recherche correcte"),
        ("loyr impay", "Typo: caractères manquants"),
        ("PAIEMENT CARTE", "Recherche correcte"),
        ("paiemnt cart", "Typo: caractères manquants"),
        ("CARREFOUR", "Recherche correcte"),
        ("carrefur", "Typo: caractère inversé"),
    ]

    print("=" * 70)
    print("  📊 Résultats Comparatifs")
    print("=" * 70)
    print()

    for query_text, description in test_queries:
        print(f"🔍 Requête: '{query_text}'")
        print(f"   {description}")
        print()

        comparison = compare_searches(session, tokenizer, model, query_text, code_si, contrat)

        # Afficher résultats Vector
        print(
            f"   📊 Vector Search ({comparison['vector']['count']} résultats, {comparison['vector']['time']:.2f} ms):"
        )
        for i, row in enumerate(comparison["vector"]["results"][:3], 1):
            libelle = row.libelle[:40] if row.libelle else "N/A"
            print(f"      {i}. {libelle}")
        print()

        # Afficher résultats Full-Text
        print(
            f"   📊 Full-Text Search ({comparison['fulltext']['count']} résultats, {comparison['fulltext']['time']:.2f} ms):"
        )
        if comparison["fulltext"]["results"]:
            for i, row in enumerate(comparison["fulltext"]["results"][:3], 1):
                libelle = row.libelle[:40] if row.libelle else "N/A"
                print(f"      {i}. {libelle}")
        else:
            print("      ⚠️  Aucun résultat trouvé")
        print()

        # Comparaison
        if comparison["fulltext"]["count"] == 0 and comparison["vector"]["count"] > 0:
            print("   ✅ Vector Search trouve des résultats (typo tolérée)")
        elif comparison["fulltext"]["count"] > 0 and comparison["vector"]["count"] > 0:
            if comparison["fulltext"]["time"] < comparison["vector"]["time"]:
                print(
                    f"   ⚠️  Full-Text plus rapide ({comparison['fulltext']['time']:.2f} ms vs {comparison['vector']['time']:.2f} ms)"
                )
            else:
                print(
                    f"   ⚠️  Vector plus rapide ({comparison['vector']['time']:.2f} ms vs {comparison['fulltext']['time']:.2f} ms)"
                )
        print()
        print("-" * 70)
        print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Tests comparatifs terminés !")
    print("=" * 70)


if __name__ == "__main__":
    main()
