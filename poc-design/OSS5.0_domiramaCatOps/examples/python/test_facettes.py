#!/usr/bin/env python3
"""
Test Complexe P3-02 : Tests de Facettes (Groupement)
- Groupement par catégorie (facettes)
- Groupement par date (facettes temporelles)
- Groupement combiné (multi-facettes)
- Performance facettes
"""

import json
import sys
import time
from datetime import datetime
from typing import Dict, Tuple

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


def test_facettes_categorie(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de facettes par catégorie"""
    try:
        print("🧪 Test 1 : Facettes par catégorie")

        # Récupérer toutes les opérations
        query = """
        SELECT cat_auto, COUNT(*) as cnt, SUM(montant) as total
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' AND contrat = '{contrat}'
        """

        start_time = time.time()
        result = session.execute(query)
        latency = (time.time() - start_time) * 1000

        # Grouper par catégorie (client-side car CQL ne supporte pas GROUP BY)
        categories = {}
        for row in result:
            cat = row.cat_auto or "NULL"
            if cat not in categories:
                categories[cat] = {"count": 0, "total": 0.0}
            categories[cat]["count"] += 1
            if row.total:
                categories[cat]["total"] += float(row.total)

        # Compter toutes les opérations pour calculer les pourcentages
        total_query = f"SELECT COUNT(*) as cnt FROM {KEYSPACE}.operations_by_account WHERE code_si = '{code_si}' AND contrat = '{contrat}'"
        total_result = session.execute(total_query)
        total_count = list(total_result)[0].cnt if total_result else 0

        facettes = {}
        for cat, stats in categories.items():
            percentage = (stats["count"] / total_count * 100) if total_count > 0 else 0
            facettes[cat] = {
                "count": stats["count"],
                "total": round(stats["total"], 2),
                "percentage": round(percentage, 2),
            }

        print(f"   ✅ {len(facettes)} catégories trouvées en {latency:.2f}ms")
        for cat, stats in sorted(facettes.items(), key=lambda x: x[1]["count"], reverse=True)[:5]:
            print(f"      - {cat} : {stats['count']} opérations ({stats['percentage']}%)")

        return True, f"Facettes catégorie validées ({len(facettes)} catégories)", facettes
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_facettes_temporelles(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de facettes temporelles (par jour, semaine, mois)"""
    try:
        print("🧪 Test 2 : Facettes temporelles")

        # Récupérer toutes les opérations avec dates
        query = """
        SELECT date_op, COUNT(*) as cnt
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' AND contrat = '{contrat}'
        """

        start_time = time.time()
        result = session.execute(query)
        latency = (time.time() - start_time) * 1000

        # Grouper par jour, semaine, mois
        by_day = {}
        by_week = {}
        by_month = {}

        for row in result:
            if row.date_op:
                # Convertir timestamp en datetime
                if isinstance(row.date_op, datetime):
                    dt = row.date_op
                else:
                    # Si c'est un timestamp en millisecondes
                    dt = datetime.fromtimestamp(int(row.date_op) / 1000)
                day_key = dt.strftime("%Y-%m-%d")
                week_key = dt.strftime("%Y-W%W")
                month_key = dt.strftime("%Y-%m")

                by_day[day_key] = by_day.get(day_key, 0) + 1
                by_week[week_key] = by_week.get(week_key, 0) + 1
                by_month[month_key] = by_month.get(month_key, 0) + 1

        facettes = {
            "by_day": {k: v for k, v in sorted(by_day.items())[:10]},
            "by_week": {k: v for k, v in sorted(by_week.items())[:5]},
            "by_month": {k: v for k, v in sorted(by_month.items())[:5]},
        }

        print(f"   ✅ Facettes temporelles calculées en {latency:.2f}ms")
        print(f"      - {len(by_day)} jours, {len(by_week)} semaines, {len(by_month)} mois")

        return True, "Facettes temporelles validées", facettes
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_facettes_combinees(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de facettes combinées (catégorie + date)"""
    try:
        print("🧪 Test 3 : Facettes combinées (catégorie + date)")

        # Récupérer toutes les opérations
        query = """
        SELECT cat_auto, date_op, COUNT(*) as cnt, SUM(montant) as total
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' AND contrat = '{contrat}'
        """

        start_time = time.time()
        result = session.execute(query)
        latency = (time.time() - start_time) * 1000

        # Grouper par catégorie + mois
        combined = {}
        for row in result:
            cat = row.cat_auto or "NULL"
            if row.date_op:
                # Convertir timestamp en datetime
                if isinstance(row.date_op, datetime):
                    dt = row.date_op
                else:
                    # Si c'est un timestamp en millisecondes
                    dt = datetime.fromtimestamp(int(row.date_op) / 1000)
                month_key = dt.strftime("%Y-%m")
                key = f"{cat}|{month_key}"

                if key not in combined:
                    combined[key] = {"count": 0, "total": 0.0, "category": cat, "month": month_key}
                combined[key]["count"] += 1
                if row.total:
                    combined[key]["total"] += float(row.total)

        facettes = {}
        for key, stats in sorted(combined.items(), key=lambda x: x[1]["count"], reverse=True)[:10]:
            facettes[key] = {
                "category": stats["category"],
                "month": stats["month"],
                "count": stats["count"],
                "total": round(stats["total"], 2),
            }

        print(f"   ✅ {len(combined)} combinaisons trouvées en {latency:.2f}ms")
        for key, stats in list(facettes.items())[:5]:
            print(f"      - {stats['category']} ({stats['month']}) : {stats['count']} opérations")

        return True, f"Facettes combinées validées ({len(combined)} combinaisons)", facettes
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_performance_facettes(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de performance des facettes"""
    try:
        print("🧪 Test 4 : Performance des facettes")

        latencies = []

        # Test 1 : Facettes catégorie
        start = time.time()
        session.execute(
            f"SELECT cat_auto FROM {KEYSPACE}.operations_by_account WHERE code_si = '{code_si}' AND contrat = '{contrat}'"
        )
        latencies.append(("catégorie", (time.time() - start) * 1000))

        # Test 2 : Facettes temporelles
        start = time.time()
        session.execute(
            f"SELECT date_op FROM {KEYSPACE}.operations_by_account WHERE code_si = '{code_si}' AND contrat = '{contrat}'"
        )
        latencies.append(("temporelle", (time.time() - start) * 1000))

        # Test 3 : Facettes combinées
        start = time.time()
        session.execute(
            f"SELECT cat_auto, date_op FROM {KEYSPACE}.operations_by_account WHERE code_si = '{code_si}' AND contrat = '{contrat}'"
        )
        latencies.append(("combinée", (time.time() - start) * 1000))

        avg_latency = sum(lat for _, lat in latencies) / len(latencies)
        max_latency = max(lat for _, lat in latencies)

        performance = {
            "average_latency_ms": round(avg_latency, 2),
            "max_latency_ms": round(max_latency, 2),
            "latencies": {name: round(lat, 2) for name, lat in latencies},
        }

        print(f"   ✅ Performance moyenne : {avg_latency:.2f}ms (max: {max_latency:.2f}ms)")

        return True, f"Performance validée (moyenne: {avg_latency:.2f}ms)", performance
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_facettes():
    """Exécute tous les tests de facettes"""
    print("=" * 80)
    print("🔍 TESTS DE FACETTES (P3-02)")
    print("=" * 80)
    print()

    cluster, session = connect_to_hcd()

    # Obtenir un compte de test
    test_accounts = session.execute(
        f"SELECT code_si, contrat FROM {KEYSPACE}.operations_by_account LIMIT 1"
    )
    account = list(test_accounts)[0] if test_accounts else None

    if not account:
        print("❌ Aucun compte de test trouvé")
        session.shutdown()
        cluster.shutdown()
        return

    code_si = account.code_si
    contrat = account.contrat

    print(f"📊 Compte de test : code_si={code_si}, contrat={contrat}")
    print()

    results = {}

    # Test 1 : Facettes catégorie
    success, message, data = test_facettes_categorie(session, code_si, contrat)
    results["facettes_categorie"] = {"success": success, "message": message, "data": data}
    print()

    # Test 2 : Facettes temporelles
    success, message, data = test_facettes_temporelles(session, code_si, contrat)
    results["facettes_temporelles"] = {"success": success, "message": message, "data": data}
    print()

    # Test 3 : Facettes combinées
    success, message, data = test_facettes_combinees(session, code_si, contrat)
    results["facettes_combinees"] = {"success": success, "message": message, "data": data}
    print()

    # Test 4 : Performance
    success, message, data = test_performance_facettes(session, code_si, contrat)
    results["performance"] = {"success": success, "message": message, "data": data}
    print()

    # Résumé
    print("=" * 80)
    print("📊 RÉSUMÉ DES TESTS")
    print("=" * 80)

    total = len(results)
    successful = sum(1 for r in results.values() if r["success"])

    for test_name, result in results.items():
        status = "✅" if result["success"] else "❌"
        print(f"{status} {test_name} : {result['message']}")

    print()
    print(f"📈 Score : {successful}/{total} ({successful*100//total}%)")

    session.shutdown()
    cluster.shutdown()

    # Retourner les résultats en JSON pour le script shell
    print()
    print(json.dumps(results, indent=2, default=str))


if __name__ == "__main__":
    test_facettes()
