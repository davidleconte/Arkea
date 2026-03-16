#!/usr/bin/env python3
"""
Tests avec abréviations pour la recherche vectorielle.
Vérifie la compréhension des abréviations courantes.
"""


from test_vector_search_base import (
    calculate_cosine_similarity,
    connect_to_hcd,
    encode_text,
    get_test_account,
    load_model,
    vector_search,
)


def main():
    """Fonction principale."""
    print("=" * 70)
    print("  📝 Tests avec Abréviations - Recherche Vectorielle")
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

    # Tests avec abréviations
    test_cases = [
        ("CB", "CARTE BLEUE", "CARTE BANCAIRE"),
        ("VIRT", "VIREMENT", "VIR"),
        ("PAYMT", "PAIEMENT", "PAY"),
        ("RESTAU", "RESTAURANT", "REST"),
        ("SUPER", "SUPERMARCHE", "SUP"),
    ]

    print("=" * 70)
    print("  📊 Résultats des Tests")
    print("=" * 70)
    print()

    for abbrev, full1, full2 in test_cases:
        print(f"🔍 Abréviation : '{abbrev}'")
        print(f"   Formes complètes : '{full1}', '{full2}'")
        print()

        # Recherche avec abréviation
        embedding_abbrev = encode_text(tokenizer, model, abbrev)
        results_abbrev = vector_search(session, embedding_abbrev, code_si, contrat, limit=5)

        # Recherche avec forme complète
        embedding_full = encode_text(tokenizer, model, full1)
        results_full = vector_search(session, embedding_full, code_si, contrat, limit=5)

        print(f"   📊 Avec abréviation '{abbrev}' : {len(results_abbrev)} résultat(s)")
        for i, row in enumerate(results_abbrev[:3], 1):
            libelle = row.libelle[:40] if row.libelle else "N/A"
            print(f"      {i}. {libelle}")
        print()

        print(f"   📊 Avec forme complète '{full1}' : {len(results_full)} résultat(s)")
        for i, row in enumerate(results_full[:3], 1):
            libelle = row.libelle[:40] if row.libelle else "N/A"
            print(f"      {i}. {libelle}")
        print()

        # Comparaison de similarité
        similarity = calculate_cosine_similarity(embedding_abbrev, embedding_full)
        print(f"   📊 Similarité entre '{abbrev}' et '{full1}' : {similarity:.3f}")
        if similarity >= 0.7:
            print("   ✅ Similarité acceptable (>= 0.7)")
        else:
            print("   ⚠️  Similarité faible (< 0.7)")
        print()
        print("-" * 70)
        print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Tests avec abréviations terminés !")
    print("=" * 70)


if __name__ == "__main__":
    main()
