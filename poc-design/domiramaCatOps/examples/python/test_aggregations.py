#!/usr/bin/env python3
"""
Test Complexe P2-05 : Tests d'Agrégations
- Agrégations temporelles (COUNT, SUM, AVG par période)
- Agrégations par catégorie (groupement)
- Agrégations combinées (date + catégorie)
- Performance agrégations
"""

import statistics
import sys
from datetime import datetime

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


def test_aggregations_temporelles(session, code_si: str, contrat: str):
    """Test 1 : Agrégations temporelles (COUNT par période)"""
    print("📋 TEST 1 : Agrégations Temporelles")
    print("-" * 70)

    # Récupérer les opérations et grouper par jour
    query_ops = f"""
    SELECT date_op, montant
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    LIMIT 100
    """

    try:
        result = session.execute(query_ops)
        rows = list(result)

        if not rows:
            return None

        # Grouper par jour (côté client)
        daily_stats = {}
        for row in rows:
            if row.date_op:
                if isinstance(row.date_op, datetime):
                    date_op = row.date_op
                else:
                    date_op = datetime.fromtimestamp(row.date_op / 1000)
                day_key = date_op.strftime("%Y-%m-%d")

                if day_key not in daily_stats:
                    daily_stats[day_key] = {"count": 0, "sum": 0.0, "amounts": []}

                daily_stats[day_key]["count"] += 1
                if row.montant:
                    montant_val = float(row.montant)
                    daily_stats[day_key]["sum"] += montant_val
                    daily_stats[day_key]["amounts"].append(montant_val)

        # Calculer les statistiques
        print("   📊 Statistiques par jour :")
        for day, stats in sorted(daily_stats.items())[:10]:  # Afficher les 10 premiers jours
            avg = statistics.mean(stats["amounts"]) if stats["amounts"] else 0
            print(f"      {day} : COUNT={stats['count']}, SUM={stats['sum']:.2f}, AVG={avg:.2f}")

        return {"daily_stats": daily_stats, "total_days": len(daily_stats)}
    except Exception as e:
        print(f"   ⚠️  Erreur : {e}")
        return None


def test_aggregations_categorie(session, code_si: str, contrat: str):
    """Test 2 : Agrégations par catégorie"""
    print("\n📋 TEST 2 : Agrégations par Catégorie")
    print("-" * 70)

    query_ops = f"""
    SELECT cat_auto, montant
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    LIMIT 100
    """

    try:
        result = session.execute(query_ops)
        rows = list(result)

        if not rows:
            return None

        # Grouper par catégorie (côté client)
        category_stats = {}
        for row in rows:
            if row.cat_auto:
                cat = row.cat_auto

                if cat not in category_stats:
                    category_stats[cat] = {"count": 0, "sum": 0.0, "amounts": []}

                category_stats[cat]["count"] += 1
                if row.montant:
                    montant_val = float(row.montant)
                    category_stats[cat]["sum"] += montant_val
                    category_stats[cat]["amounts"].append(montant_val)

        # Calculer les statistiques
        print("   📊 Statistiques par catégorie :")
        for cat, stats in sorted(category_stats.items()):
            avg = statistics.mean(stats["amounts"]) if stats["amounts"] else 0
            print(f"      {cat} : COUNT={stats['count']}, SUM={stats['sum']:.2f}, AVG={avg:.2f}")

        return {"category_stats": category_stats, "total_categories": len(category_stats)}
    except Exception as e:
        print(f"   ⚠️  Erreur : {e}")
        return None


def test_aggregations_combinees(session, code_si: str, contrat: str):
    """Test 3 : Agrégations combinées (date + catégorie)"""
    print("\n📋 TEST 3 : Agrégations Combinées (Date + Catégorie)")
    print("-" * 70)

    query_ops = f"""
    SELECT date_op, cat_auto, montant
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    LIMIT 100
    """

    try:
        result = session.execute(query_ops)
        rows = list(result)

        if not rows:
            return None

        # Grouper par date + catégorie (côté client)
        combined_stats = {}
        for row in rows:
            if row.date_op and row.cat_auto:
                if isinstance(row.date_op, datetime):
                    date_op = row.date_op
                else:
                    date_op = datetime.fromtimestamp(row.date_op / 1000)
                day_key = date_op.strftime("%Y-%m-%d")
                key = f"{day_key}_{row.cat_auto}"

                if key not in combined_stats:
                    combined_stats[key] = {
                        "count": 0,
                        "sum": 0.0,
                        "day": day_key,
                        "category": row.cat_auto,
                    }

                combined_stats[key]["count"] += 1
                if row.montant:
                    montant_val = float(row.montant)
                    combined_stats[key]["sum"] += montant_val

        # Afficher les statistiques
        print("   📊 Statistiques combinées (date + catégorie) :")
        for key, stats in sorted(combined_stats.items())[:10]:  # Afficher les 10 premiers
            print(
                f"      {stats['day']} - {stats['category']} : "
                f"COUNT={stats['count']}, SUM={stats['sum']:.2f}"
            )

        return {"combined_stats": combined_stats, "total_combinations": len(combined_stats)}
    except Exception as e:
        print(f"   ⚠️  Erreur : {e}")
        return None


def test_performance_aggregations(session, code_si: str, contrat: str):
    """Test 4 : Performance agrégations"""
    print("\n📋 TEST 4 : Performance Agrégations")
    print("-" * 70)

    import time

    # Test avec différentes limites
    limits = [10, 50, 100, 500]
    results = {}

    for limit in limits:
        query_ops = f"""
        SELECT date_op, cat_auto, montant
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' AND contrat = '{contrat}'
        LIMIT {limit}
        """

        start_time = time.time()
        result = session.execute(query_ops)
        rows = list(result)

        # Agrégation côté client
        category_stats = {}
        for row in rows:
            if row.cat_auto:
                cat = row.cat_auto
                if cat not in category_stats:
                    category_stats[cat] = {"count": 0, "sum": 0.0}
                category_stats[cat]["count"] += 1
                if row.montant:
                    montant_val = float(row.montant)
                    category_stats[cat]["sum"] += montant_val

        elapsed = time.time() - start_time

        results[limit] = {
            "rows": len(rows),
            "categories": len(category_stats),
            "time": elapsed,
            "throughput": len(rows) / elapsed if elapsed > 0 else 0,
        }

        print(
            f"   Limite {limit} : {len(rows)} lignes, "
            f"{len(category_stats)} catégories, {elapsed:.3f}s"
        )

    return results


def test_aggregations():
    """Test principal d'agrégations"""
    print("=" * 70)
    print("  🔍 Test Complexe P2-05 : Tests d'Agrégations")
    print("=" * 70)
    print()

    cluster, session = connect_to_hcd()

    test_code_si = "6"
    test_contrat = "600000041"

    results = {}

    # Test 1 : Agrégations temporelles
    result1 = test_aggregations_temporelles(session, test_code_si, test_contrat)
    if result1:
        results["temporelles"] = result1

    # Test 2 : Agrégations par catégorie
    result2 = test_aggregations_categorie(session, test_code_si, test_contrat)
    if result2:
        results["categorie"] = result2

    # Test 3 : Agrégations combinées
    result3 = test_aggregations_combinees(session, test_code_si, test_contrat)
    if result3:
        results["combinees"] = result3

    # Test 4 : Performance agrégations
    result4 = test_performance_aggregations(session, test_code_si, test_contrat)
    if result4:
        results["performance"] = result4

    # Résumé
    print("\n" + "=" * 70)
    print("  📊 RÉSUMÉ")
    print("=" * 70)

    if "temporelles" in results:
        print(f"✅ Agrégations temporelles : {results['temporelles']['total_days']} jours")
    if "categorie" in results:
        print(
            f"✅ Agrégations par catégorie : {results['categorie']['total_categories']} catégories"
        )
    if "combinees" in results:
        print(
            f"✅ Agrégations combinées : {results['combinees']['total_combinations']} combinaisons"
        )
    if "performance" in results:
        print(f"✅ Performance testée : {len(results['performance'])} limites")

    cluster.shutdown()

    return {"success": len(results) == 4, "results": results}


if __name__ == "__main__":
    result = test_aggregations()
    sys.exit(0 if result["success"] else 1)
