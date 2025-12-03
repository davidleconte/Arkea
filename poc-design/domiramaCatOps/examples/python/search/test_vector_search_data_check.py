#!/usr/bin/env python3
"""
Script pour vérifier la présence de données pertinentes pour les tests fuzzy search.
"""

from cassandra.query import SimpleStatement
from test_vector_search_base import KEYSPACE, connect_to_hcd


def check_relevant_data(session, code_si: str, contrat: str):
    """Vérifie la présence de données pertinentes pour les tests."""
    queries = [
        ("LOYER", ["LOYER", "LOCATION", "LOUER"]),
        ("IMPAYE", ["IMPAYE", "IMPAY", "NON PAYE"]),
        ("LOYER IMPAYE", ["LOYER", "IMPAYE"]),
        ("VIREMENT", ["VIREMENT", "TRANSFERT"]),
        ("PAIEMENT CARTE", ["PAIEMENT", "CARTE", "CB"]),
        ("CARREFOUR", ["CARREFOUR"]),
    ]

    print("=" * 70)
    print("  🔍 Vérification des Données Pertinentes")
    print("=" * 70)
    print()

    # Récupérer tous les libellés
    query = f"""
    SELECT libelle FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    LIMIT 1000
    """

    statement = SimpleStatement(query)
    all_libelles = [
        row.libelle.upper() if row.libelle else "" for row in session.execute(statement)
    ]

    print(f"📊 Total de libellés dans le compte : {len(all_libelles)}")
    print()

    for query_text, keywords in queries:
        print(f"🔍 Requête : '{query_text}'")
        print(f"   Mots-clés recherchés : {', '.join(keywords)}")

        # Chercher les libellés pertinents
        relevant = []
        for libelle in all_libelles:
            if any(keyword in libelle for keyword in keywords):
                relevant.append(libelle)

        print(f"   Libellés pertinents trouvés : {len(relevant)}")
        if relevant:
            print(f"   Exemples :")
            for i, lib in enumerate(relevant[:5], 1):
                print(f"      {i}. {lib[:60]}")
        else:
            print(f"   ⚠️  AUCUN libellé pertinent trouvé !")
        print()

    return len(all_libelles)


if __name__ == "__main__":
    cluster, session = connect_to_hcd()
    account_query = f"SELECT code_si, contrat FROM {KEYSPACE}.operations_by_account LIMIT 1"
    result = list(session.execute(account_query))
    if result:
        code_si, contrat = result[0].code_si, result[0].contrat
        check_relevant_data(session, code_si, contrat)
    session.shutdown()
    cluster.shutdown()
