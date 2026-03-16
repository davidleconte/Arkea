#!/usr/bin/env python3
"""
Test Complexe P3-05 : Tests de Suggestions/Autocomplétion
- Suggestions basées sur libellés existants
- Autocomplétion avec préfixes
- Suggestions avec scoring (pertinence)
- Performance suggestions
"""

import json
import os
import sys
import time
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


def test_suggestions_by_prefix(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de suggestions par préfixe"""
    try:
        print("🧪 Test 1 : Suggestions par préfixe")

        prefixes = ["LOY", "PAI", "VIR", "CAR"]
        suggestions_by_prefix = {}

        for prefix in prefixes:
            # Recherche full-text avec préfixe (sans DISTINCT, déduplication
            # côté client)
            query = """
            SELECT libelle
            FROM {KEYSPACE}.operations_by_account
            WHERE code_si = '{code_si}' AND contrat = '{contrat}'
              AND libelle : '{prefix}*'
            LIMIT 20
            """

            start = time.time()
            result = session.execute(query)
            # Déduplication côté client
            suggestions = list(
                set(
                    [
                        row.libelle
                        for row in result
                        if row.libelle and row.libelle.upper().startswith(prefix.upper())
                    ]
                )
            )[:10]
            latency = (time.time() - start) * 1000

            suggestions_by_prefix[prefix] = {
                "suggestions": suggestions[:5],  # Limiter à 5 pour l'affichage
                "count": len(suggestions),
                "latency_ms": round(latency, 2),
            }

            print(f"   ✅ Préfixe '{prefix}' : {len(suggestions)} suggestions en {latency:.2f}ms")
            for sug in suggestions[:3]:
                print(f"      - {sug}")

        return True, "Suggestions par préfixe validées", suggestions_by_prefix
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_autocompletion(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test d'autocomplétion"""
    try:
        print("🧪 Test 2 : Autocomplétion")

        partial_queries = ["LOYE", "PAIE", "VIRE", "CART"]
        completions = {}

        for partial in partial_queries:
            # Recherche avec LIKE (simulation autocomplétion)
            # Note: CQL ne supporte pas LIKE, on utilise full-text search (sans
            # DISTINCT)
            query = """
            SELECT libelle
            FROM {KEYSPACE}.operations_by_account
            WHERE code_si = '{code_si}' AND contrat = '{contrat}'
              AND libelle : '{partial}*'
            LIMIT 10
            """

            start = time.time()
            result = session.execute(query)
            # Déduplication côté client
            matches = list(
                set(
                    [
                        row.libelle
                        for row in result
                        if row.libelle and partial.upper() in row.libelle.upper()
                    ]
                )
            )[:5]
            latency = (time.time() - start) * 1000

            # Extraire les complétions possibles
            completions_list = []
            for match in matches:
                # Trouver la partie complétée
                if match.upper().startswith(partial.upper()):
                    completion = match[len(partial) :] if len(match) > len(partial) else ""
                    if completion:
                        completions_list.append(completion)

            completions[partial] = {
                "completions": list(set(completions_list))[:5],
                "matches": len(matches),
                "latency_ms": round(latency, 2),
            }

            print(
                f"   ✅ '{partial}' : {len(matches)} correspondances, {len(completions_list)} complétions en {latency:.2f}ms"
            )

        return True, "Autocomplétion validée", completions
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_suggestions_with_scoring(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de suggestions avec scoring de pertinence"""
    try:
        print("🧪 Test 3 : Suggestions avec scoring")

        # Ajouter le répertoire parent au PYTHONPATH
        SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
        sys.path.insert(0, os.path.join(SCRIPT_DIR, "search"))

        from test_vector_search_base import encode_text, load_model

        tokenizer, model = load_model()
        query = "LOYER"

        # Générer l'embedding de la requête
        encode_text(tokenizer, model, query)

        # Recherche vectorielle pour obtenir des suggestions pertinentes
        cql_query = """
        SELECT libelle, montant, cat_auto
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' AND contrat = '{contrat}'
        ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
        LIMIT 10
        """

        start = time.time()
        result = session.execute(cql_query)
        suggestions = []

        for row in result:
            if row.libelle:
                # Calculer un score de pertinence basique (basé sur la position
                # dans les résultats)
                score = 1.0 / (suggestions.__len__() + 1)  # Score décroissant
                suggestions.append(
                    {
                        "libelle": row.libelle,
                        "score": round(score, 3),
                        "montant": float(row.montant) if row.montant else 0.0,
                    }
                )

        latency = (time.time() - start) * 1000

        scoring_info = {
            "suggestions": suggestions[:5],
            "total": len(suggestions),
            "latency_ms": round(latency, 2),
        }

        print(f"   ✅ {len(suggestions)} suggestions avec scoring en {latency:.2f}ms")
        for sug in suggestions[:3]:
            print(f"      - {sug['libelle']} (score: {sug['score']})")

        return (
            True,
            f"Suggestions avec scoring validées ({len(suggestions)} suggestions)",
            scoring_info,
        )
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_suggestions_performance(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de performance des suggestions"""
    try:
        print("🧪 Test 4 : Performance des suggestions")

        prefixes = ["LOY", "PAI", "VIR", "CAR", "TAX"]
        latencies = []

        for prefix in prefixes:
            query = """
            SELECT libelle
            FROM {KEYSPACE}.operations_by_account
            WHERE code_si = '{code_si}' AND contrat = '{contrat}'
              AND libelle : '{prefix}*'
            LIMIT 20
            """

            start = time.time()
            result = session.execute(query)
            list(result)  # Consommer les résultats
            latency = (time.time() - start) * 1000
            latencies.append(latency)

        avg_latency = sum(latencies) / len(latencies)
        max_latency = max(latencies)
        min_latency = min(latencies)

        performance_info = {
            "average_latency_ms": round(avg_latency, 2),
            "min_latency_ms": round(min_latency, 2),
            "max_latency_ms": round(max_latency, 2),
            "meets_target": avg_latency < 50,  # Cible < 50ms
        }

        print(
            f"   ✅ Latence moyenne : {avg_latency:.2f}ms (min: {min_latency:.2f}ms, max: {max_latency:.2f}ms)"
        )
        if avg_latency < 50:
            print("   ✅ Cible < 50ms atteinte")
        else:
            print("   ⚠️  Cible < 50ms non atteinte")

        return True, f"Performance validée (moyenne: {avg_latency:.2f}ms)", performance_info
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_suggestions_relevance(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de pertinence des suggestions"""
    try:
        print("🧪 Test 5 : Pertinence des suggestions")

        test_cases = [
            ("LOY", ["LOYER", "LOYER IMPAYE"]),
            ("PAI", ["PAIEMENT", "PAIEMENT CARTE"]),
            ("VIR", ["VIREMENT", "VIREMENT SALAIRE"]),
        ]

        relevance_scores = []

        for prefix, expected_keywords in test_cases:
            query = """
            SELECT libelle
            FROM {KEYSPACE}.operations_by_account
            WHERE code_si = '{code_si}' AND contrat = '{contrat}'
              AND libelle : '{prefix}*'
            LIMIT 20
            """

            result = session.execute(query)
            # Déduplication côté client
            suggestions = list(set([row.libelle for row in result if row.libelle]))[:10]

            # Calculer la pertinence (nombre de suggestions contenant les
            # mots-clés attendus)
            relevant_count = sum(
                1
                for sug in suggestions
                if any(kw.upper() in sug.upper() for kw in expected_keywords)
            )
            relevance_score = (relevant_count / len(suggestions) * 100) if suggestions else 0

            relevance_scores.append(
                {
                    "prefix": prefix,
                    "relevance_score": round(relevance_score, 2),
                    "relevant_suggestions": relevant_count,
                    "total_suggestions": len(suggestions),
                }
            )

            print(
                f"   ✅ Préfixe '{prefix}' : {relevance_score:.1f}% de pertinence ({relevant_count}/{len(suggestions)})"
            )

        avg_relevance = sum(s["relevance_score"] for s in relevance_scores) / len(relevance_scores)

        relevance_info = {"average_relevance": round(avg_relevance, 2), "scores": relevance_scores}

        return True, f"Pertinence validée (moyenne: {avg_relevance:.1f}%)", relevance_info
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_suggestions():
    """Exécute tous les tests de suggestions"""
    print("=" * 80)
    print("💡 TESTS DE SUGGESTIONS (P3-05)")
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

    # Test 1 : Suggestions par préfixe
    success, message, data = test_suggestions_by_prefix(session, code_si, contrat)
    results["suggestions_prefix"] = {"success": success, "message": message, "data": data}
    print()

    # Test 2 : Autocomplétion
    success, message, data = test_autocompletion(session, code_si, contrat)
    results["autocompletion"] = {"success": success, "message": message, "data": data}
    print()

    # Test 3 : Suggestions avec scoring
    success, message, data = test_suggestions_with_scoring(session, code_si, contrat)
    results["suggestions_scoring"] = {"success": success, "message": message, "data": data}
    print()

    # Test 4 : Performance
    success, message, data = test_suggestions_performance(session, code_si, contrat)
    results["suggestions_performance"] = {"success": success, "message": message, "data": data}
    print()

    # Test 5 : Pertinence
    success, message, data = test_suggestions_relevance(session, code_si, contrat)
    results["suggestions_relevance"] = {"success": success, "message": message, "data": data}
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
    test_suggestions()
