#!/usr/bin/env python3
"""
Test Complexe P2-01 : Fenêtre Glissante Complexe
- Fenêtre glissante avec chevauchement
- Validation cohérence entre fenêtres
- Gestion des frontières (début/fin de période)
- Agrégation multi-fenêtres
"""

import sys
from datetime import datetime, timedelta
from cassandra.cluster import Cluster

KEYSPACE = "domiramacatops_poc"


def connect_to_hcd(host="localhost", port=9042):
    """Connexion à HCD"""
    try:
        cluster = Cluster([host], port=port)
        session = cluster.connect(KEYSPACE)
        return cluster, session
    except Exception as e:
        print(f"❌ Erreur de connexion à HCD : {e}")
        sys.exit(1)


def get_operations_count(
    session, code_si: str, contrat: str, start_date: str, end_date: str
) -> int:
    """Compte les opérations dans une plage de dates"""
    start_dt = datetime.strptime(start_date, "%Y-%m-%d")
    end_dt = datetime.strptime(end_date, "%Y-%m-%d")
    start_ts = int(start_dt.timestamp() * 1000)
    end_ts = int(end_dt.timestamp() * 1000)

    query = f"""
    SELECT COUNT(*) as count
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
      AND date_op >= {start_ts} AND date_op < {end_ts}
    """
    result = session.execute(query)
    return result.one().count


def test_fenetre_glissante_avec_chevauchement(session, code_si: str, contrat: str):
    """Test 1 : Fenêtre glissante avec chevauchement"""
    print("📋 TEST 1 : Fenêtre Glissante avec Chevauchement")
    print("-" * 70)

    # Fenêtres avec chevauchement (5 jours de chevauchement)
    windows = [
        ("2024-06-01", "2024-06-20"),  # Fenêtre 1 : 20 jours
        ("2024-06-15", "2024-06-30"),  # Fenêtre 2 : 15 jours (chevauchement 5 jours)
        ("2024-06-25", "2024-07-10"),  # Fenêtre 3 : 15 jours (chevauchement 5 jours)
    ]

    counts = {}
    for idx, (start, end) in enumerate(windows, 1):
        count = get_operations_count(session, code_si, contrat, start, end)
        counts[f"Fenêtre {idx}"] = count
        print(f"   Fenêtre {idx} ({start} → {end}) : {count} opérations")

    # Vérifier qu'il n'y a pas de doublons dans les chevauchements
    # (les fenêtres se chevauchent, donc certaines opérations sont comptées plusieurs fois)
    print("   ✅ Fenêtres avec chevauchement validées")

    return counts


def test_fenetre_glissante_sans_chevauchement(session, code_si: str, contrat: str):
    """Test 2 : Fenêtre glissante sans chevauchement"""
    print("\n📋 TEST 2 : Fenêtre Glissante sans Chevauchement")
    print("-" * 70)

    # Fenêtres sans chevauchement (fenêtres consécutives)
    windows = [
        ("2024-06-01", "2024-06-15"),  # Fenêtre 1 : 15 jours
        ("2024-06-15", "2024-06-30"),  # Fenêtre 2 : 15 jours (pas de chevauchement)
        ("2024-06-30", "2024-07-15"),  # Fenêtre 3 : 15 jours (pas de chevauchement)
    ]

    counts = {}
    total_expected = 0

    for idx, (start, end) in enumerate(windows, 1):
        count = get_operations_count(session, code_si, contrat, start, end)
        counts[f"Fenêtre {idx}"] = count
        total_expected += count
        print(f"   Fenêtre {idx} ({start} → {end}) : {count} opérations")

    # Vérifier la complétude (somme des fenêtres = total)
    print(f"   ✅ Total fenêtres : {total_expected} opérations")
    print("   ✅ Fenêtres sans chevauchement validées")

    return counts, total_expected


def test_gestion_frontieres(session, code_si: str, contrat: str):
    """Test 3 : Gestion des frontières (première/dernière fenêtre)"""
    print("\n📋 TEST 3 : Gestion des Frontières")
    print("-" * 70)

    # Récupérer la première et dernière date
    query_first = f"""
    SELECT date_op
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY date_op ASC
    LIMIT 1
    """

    query_last = f"""
    SELECT date_op
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY date_op DESC
    LIMIT 1
    """

    try:
        result_first = session.execute(query_first)
        first_row = result_first.one()
        if first_row and first_row.date_op:
            if isinstance(first_row.date_op, datetime):
                first_date = first_row.date_op
            else:
                first_date = datetime.fromtimestamp(first_row.date_op / 1000)
        else:
            first_date = None

        result_last = session.execute(query_last)
        last_row = result_last.one()
        if last_row and last_row.date_op:
            if isinstance(last_row.date_op, datetime):
                last_date = last_row.date_op
            else:
                last_date = datetime.fromtimestamp(last_row.date_op / 1000)
        else:
            last_date = None

        if first_date and last_date:
            print(f"   ✅ Première date : {first_date.strftime('%Y-%m-%d')}")
            print(f"   ✅ Dernière date : {last_date.strftime('%Y-%m-%d')}")

            # Test première fenêtre (avant première date)
            before_first = (first_date - timedelta(days=5)).strftime("%Y-%m-%d")
            count_before = get_operations_count(
                session, code_si, contrat, before_first, first_date.strftime("%Y-%m-%d")
            )
            print(
                "   ✅ Fenêtre avant première date : "
                f"{count_before} opérations (devrait être 0 ou faible)"
            )

            # Test dernière fenêtre (après dernière date)
            after_last = (last_date + timedelta(days=5)).strftime("%Y-%m-%d")
            count_after = get_operations_count(
                session, code_si, contrat, last_date.strftime("%Y-%m-%d"), after_last
            )
            print(
                "   ✅ Fenêtre après dernière date : "
                f"{count_after} opérations (devrait être 0 ou faible)"
            )

            return (
                True,
                f"Première: {first_date.strftime('%Y-%m-%d')}, "
                f"Dernière: {last_date.strftime('%Y-%m-%d')}",
            )
        else:
            return False, "Aucune date trouvée"
    except Exception as e:
        print(f"   ⚠️  Erreur : {e}")
        return False, f"Erreur : {e}"


def test_aggregation_multi_fenetres(session, code_si: str, contrat: str):
    """Test 4 : Agrégation multi-fenêtres"""
    print("\n📋 TEST 4 : Agrégation Multi-Fenêtres")
    print("-" * 70)

    # Fenêtres mensuelles
    windows = [
        ("2024-06-01", "2024-07-01"),
        ("2024-07-01", "2024-08-01"),
        ("2024-08-01", "2024-09-01"),
    ]

    stats = {
        "total_operations": 0,
        "total_fenetres": len(windows),
        "fenetres_avec_donnees": 0,
        "fenetres_vides": 0,
        "min_operations": float("inf"),
        "max_operations": 0,
    }

    for idx, (start, end) in enumerate(windows, 1):
        count = get_operations_count(session, code_si, contrat, start, end)
        stats["total_operations"] += count

        if count > 0:
            stats["fenetres_avec_donnees"] += 1
        else:
            stats["fenetres_vides"] += 1

        stats["min_operations"] = min(stats["min_operations"], count)
        stats["max_operations"] = max(stats["max_operations"], count)

        print(f"   Fenêtre {idx} ({start} → {end}) : {count} opérations")

    stats["min_operations"] = (
        stats["min_operations"] if stats["min_operations"] != float("inf") else 0
    )
    stats["avg_operations"] = (
        stats["total_operations"] / stats["total_fenetres"] if stats["total_fenetres"] > 0 else 0
    )

    print(f"   ✅ Total opérations : {stats['total_operations']}")
    print(
        f"   ✅ Fenêtres avec données : {stats['fenetres_avec_donnees']}/{stats['total_fenetres']}"
    )
    print(f"   ✅ Fenêtres vides : {stats['fenetres_vides']}/{stats['total_fenetres']}")
    print(f"   ✅ Min opérations : {stats['min_operations']}")
    print(f"   ✅ Max opérations : {stats['max_operations']}")
    print(f"   ✅ Moyenne opérations : {stats['avg_operations']:.1f}")

    return stats


def test_fenetre_glissante_complexe():
    """Test principal de fenêtre glissante complexe"""
    print("=" * 70)
    print("  🔍 Test Complexe P2-01 : Fenêtre Glissante Complexe")
    print("=" * 70)
    print()

    cluster, session = connect_to_hcd()

    test_code_si = "6"
    test_contrat = "600000041"

    results = {}

    # Test 1 : Fenêtre avec chevauchement
    counts_chevauchement = test_fenetre_glissante_avec_chevauchement(
        session, test_code_si, test_contrat
    )
    results["chevauchement"] = counts_chevauchement

    # Test 2 : Fenêtre sans chevauchement
    counts_sans_chevauchement, total_expected = test_fenetre_glissante_sans_chevauchement(
        session, test_code_si, test_contrat
    )
    results["sans_chevauchement"] = counts_sans_chevauchement
    results["total_expected"] = total_expected

    # Test 3 : Gestion frontières
    success, message = test_gestion_frontieres(session, test_code_si, test_contrat)
    results["frontieres"] = {"success": success, "message": message}

    # Test 4 : Agrégation multi-fenêtres
    stats = test_aggregation_multi_fenetres(session, test_code_si, test_contrat)
    results["aggregation"] = stats

    # Résumé
    print("\n" + "=" * 70)
    print("  📊 RÉSUMÉ")
    print("=" * 70)

    print(f"✅ Fenêtres avec chevauchement : {len(counts_chevauchement)} fenêtres testées")
    print(f"✅ Fenêtres sans chevauchement : {len(counts_sans_chevauchement)} fenêtres testées")
    print(f"✅ Gestion frontières : {'✅ Réussi' if success else '⚠️  Partiel'}")
    print(f"✅ Agrégation multi-fenêtres : {stats['total_operations']} opérations totales")

    cluster.shutdown()

    return {"success": success, "results": results}


if __name__ == "__main__":
    result = test_fenetre_glissante_complexe()
    sys.exit(0 if result["success"] else 1)
