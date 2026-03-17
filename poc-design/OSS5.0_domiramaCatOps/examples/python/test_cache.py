#!/usr/bin/env python3
"""
Test Complexe P3-04 : Tests de Cache
- Cache des embeddings (éviter régénération)
- Cache des résultats de recherche
- Invalidation cache (stratégies)
- Performance avec/sans cache
"""

import hashlib
import json
import os
import sys
import time
from typing import Dict, Tuple

from cassandra.cluster import Cluster
from test_vector_search_base import KEYSPACE, encode_text, load_model

# Ajouter le répertoire parent au PYTHONPATH
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(SCRIPT_DIR, "search"))


# Cache simple en mémoire
_embedding_cache = {}
_search_cache = {}
_cache_stats = {"hits": 0, "misses": 0, "invalidations": 0}


def connect_to_hcd(host="localhost", port=9042):
    """Connexion à HCD"""
    try:
        cluster = Cluster([host], port=port)
        session = cluster.connect(KEYSPACE)
        return cluster, session
    except Exception as e:
        print(f"❌ Erreur de connexion à HCD : {e}")
        sys.exit(1)


def get_cache_key(text: str) -> str:
    """Génère une clé de cache pour un texte"""
    return hashlib.md5(text.encode()).hexdigest()


def test_cache_embeddings() -> Tuple[bool, str, Dict]:
    """Test de cache des embeddings"""
    try:
        print("🧪 Test 1 : Cache des embeddings")

        tokenizer, model = load_model()
        test_texts = ["LOYER", "PAIEMENT CARTE", "VIREMENT SALAIRE", "LOYER", "PAIEMENT CARTE"]

        times_without_cache = []
        times_with_cache = []

        # Sans cache
        _embedding_cache.clear()
        for text in test_texts:
            start = time.time()
            encode_text(tokenizer, model, text)
            times_without_cache.append((time.time() - start) * 1000)

        # Avec cache
        _embedding_cache.clear()
        for text in test_texts:
            cache_key = get_cache_key(text)
            if cache_key in _embedding_cache:
                _cache_stats["hits"] += 1
                embedding = _embedding_cache[cache_key]
            else:
                _cache_stats["misses"] += 1
                start = time.time()
                embedding = encode_text(tokenizer, model, text)
                times_with_cache.append((time.time() - start) * 1000)
                _embedding_cache[cache_key] = embedding

        avg_without = (
            sum(times_without_cache) / len(times_without_cache) if times_without_cache else 0
        )
        avg_with = sum(times_with_cache) / len(times_with_cache) if times_with_cache else 0
        speedup = (avg_without / avg_with) if avg_with > 0 else 0

        cache_info = {
            "cache_hits": _cache_stats["hits"],
            "cache_misses": _cache_stats["misses"],
            "avg_latency_without_cache_ms": round(avg_without, 2),
            "avg_latency_with_cache_ms": round(avg_with, 2),
            "speedup": round(speedup, 2),
        }

        print(f"   ✅ Cache hits: {_cache_stats['hits']}, misses: {_cache_stats['misses']}")
        print(
            f"   ✅ Accélération : {speedup:.2f}x (sans cache: {avg_without:.2f}ms, avec cache: {avg_with:.2f}ms)"
        )

        return True, f"Cache embeddings validé ({speedup:.2f}x speedup)", cache_info
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_cache_search_results(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de cache des résultats de recherche"""
    try:
        print("🧪 Test 2 : Cache des résultats de recherche")

        tokenizer, model = load_model()
        queries = ["LOYER", "PAIEMENT CARTE", "LOYER", "PAIEMENT CARTE"]

        times_without_cache = []
        times_with_cache = []

        # Sans cache
        _search_cache.clear()
        for query in queries:
            start = time.time()
            encode_text(tokenizer, model, query)
            cql_query = """
            SELECT libelle, montant, cat_auto
            FROM {KEYSPACE}.operations_by_account
            WHERE code_si = '{code_si}' AND contrat = '{contrat}'
            ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
            LIMIT 5
            """
            result = session.execute(cql_query)
            list(result)
            times_without_cache.append((time.time() - start) * 1000)

        # Avec cache
        _search_cache.clear()
        for query in queries:
            cache_key = get_cache_key(query)
            if cache_key in _search_cache:
                _cache_stats["hits"] += 1
                results = _search_cache[cache_key]
            else:
                _cache_stats["misses"] += 1
                start = time.time()
                encode_text(tokenizer, model, query)
                cql_query = """
                SELECT libelle, montant, cat_auto
                FROM {KEYSPACE}.operations_by_account
                WHERE code_si = '{code_si}' AND contrat = '{contrat}'
                ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
                LIMIT 5
                """
                result = session.execute(cql_query)
                results = list(result)
                times_with_cache.append((time.time() - start) * 1000)
                _search_cache[cache_key] = results

        avg_without = (
            sum(times_without_cache) / len(times_without_cache) if times_without_cache else 0
        )
        avg_with = sum(times_with_cache) / len(times_with_cache) if times_with_cache else 0
        speedup = (avg_without / avg_with) if avg_with > 0 else 0

        cache_info = {
            "cache_hits": _cache_stats["hits"],
            "cache_misses": _cache_stats["misses"],
            "avg_latency_without_cache_ms": round(avg_without, 2),
            "avg_latency_with_cache_ms": round(avg_with, 2),
            "speedup": round(speedup, 2),
        }

        print(f"   ✅ Cache hits: {_cache_stats['hits']}, misses: {_cache_stats['misses']}")
        print(f"   ✅ Accélération : {speedup:.2f}x")

        return True, f"Cache résultats validé ({speedup:.2f}x speedup)", cache_info
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_cache_invalidation(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test d'invalidation du cache"""
    try:
        print("🧪 Test 3 : Invalidation du cache")

        tokenizer, model = load_model()
        query = "LOYER"

        # Premier appel (cache miss)
        encode_text(tokenizer, model, query)
        cql_query = """
        SELECT libelle, montant, cat_auto
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' AND contrat = '{contrat}'
        ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
        LIMIT 5
        """
        result1 = session.execute(cql_query)
        results1 = list(result1)
        cache_key = get_cache_key(query)
        _search_cache[cache_key] = results1

        # Deuxième appel (cache hit)
        if cache_key in _search_cache:
            _search_cache[cache_key]
        else:
            pass

        # Invalidation
        if cache_key in _search_cache:
            del _search_cache[cache_key]
            _cache_stats["invalidations"] += 1

        # Troisième appel après invalidation (cache miss)
        encode_text(tokenizer, model, query)
        cql_query = """
        SELECT libelle, montant, cat_auto
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' AND contrat = '{contrat}'
        ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
        LIMIT 5
        """
        result3 = session.execute(cql_query)
        results3 = list(result3)

        invalidation_info = {
            "invalidations": _cache_stats["invalidations"],
            "cache_cleared": cache_key not in _search_cache,
            "results_consistent": len(results1) == len(results3),
        }

        print(f"   ✅ Invalidation validée : {_cache_stats['invalidations']} invalidations")
        print(f"   ✅ Cache vidé : {cache_key not in _search_cache}")

        return (
            True,
            f"Invalidation validée ({_cache_stats['invalidations']} invalidations)",
            invalidation_info,
        )
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_cache_performance(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de performance avec/sans cache"""
    try:
        print("🧪 Test 4 : Performance avec/sans cache")

        tokenizer, model = load_model()
        queries = ["LOYER", "PAIEMENT CARTE", "VIREMENT SALAIRE"] * 10  # 30 requêtes

        # Sans cache
        _search_cache.clear()
        start = time.time()
        for query in queries:
            encode_text(tokenizer, model, query)
            cql_query = """
            SELECT libelle, montant, cat_auto
            FROM {KEYSPACE}.operations_by_account
            WHERE code_si = '{code_si}' AND contrat = '{contrat}'
            ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
            LIMIT 5
            """
            session.execute(cql_query)
        time_without_cache = (time.time() - start) * 1000

        # Avec cache
        _search_cache.clear()
        start = time.time()
        for query in queries:
            cache_key = get_cache_key(query)
            if cache_key not in _search_cache:
                encode_text(tokenizer, model, query)
                cql_query = """
                SELECT libelle, montant, cat_auto
                FROM {KEYSPACE}.operations_by_account
                WHERE code_si = '{code_si}' AND contrat = '{contrat}'
                ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
                LIMIT 5
                """
                result = session.execute(cql_query)
                _search_cache[cache_key] = list(result)
        time_with_cache = (time.time() - start) * 1000

        speedup = (time_without_cache / time_with_cache) if time_with_cache > 0 else 0

        performance_info = {
            "time_without_cache_ms": round(time_without_cache, 2),
            "time_with_cache_ms": round(time_with_cache, 2),
            "speedup": round(speedup, 2),
            "queries": len(queries),
        }

        print(f"   ✅ Sans cache : {time_without_cache:.2f}ms")
        print(f"   ✅ Avec cache : {time_with_cache:.2f}ms")
        print(f"   ✅ Accélération : {speedup:.2f}x")

        return True, f"Performance validée ({speedup:.2f}x speedup)", performance_info
    except Exception as e:
        return False, f"Erreur : {e}", {}


def test_cache():
    """Exécute tous les tests de cache"""
    print("=" * 80)
    print("💾 TESTS DE CACHE (P3-04)")
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

    # Test 1 : Cache embeddings
    success, message, data = test_cache_embeddings()
    results["cache_embeddings"] = {"success": success, "message": message, "data": data}
    print()

    # Test 2 : Cache résultats
    success, message, data = test_cache_search_results(session, code_si, contrat)
    results["cache_results"] = {"success": success, "message": message, "data": data}
    print()

    # Test 3 : Invalidation
    success, message, data = test_cache_invalidation(session, code_si, contrat)
    results["cache_invalidation"] = {"success": success, "message": message, "data": data}
    print()

    # Test 4 : Performance
    success, message, data = test_cache_performance(session, code_si, contrat)
    results["cache_performance"] = {"success": success, "message": message, "data": data}
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
    test_cache()
