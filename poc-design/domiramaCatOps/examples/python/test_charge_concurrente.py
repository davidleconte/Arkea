#!/usr/bin/env python3
"""
Test Complexe P1-02 : Tests de Charge Concurrente
- Charge lecture (100+ requêtes simultanées)
- Charge écriture (100+ insertions simultanées)
- Charge mixte (50% lecture, 50% écriture)
- Mesure latence (p50, p95, p99) et throughput
"""

import os
import statistics
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime

from cassandra.cluster import Cluster
from test_vector_search_base import KEYSPACE, encode_text, load_model

# Ajouter le répertoire parent au PYTHONPATH
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(SCRIPT_DIR, "search"))


def connect_to_hcd(host="localhost", port=9042):
    """Connexion à HCD"""
    try:
        cluster = Cluster([host], port=port)
        session = cluster.connect(KEYSPACE)
        return cluster, session
    except Exception as e:
        print(f"❌ Erreur de connexion à HCD : {e}")
        sys.exit(1)


def vector_search_query(session, query_text: str, code_si: str, contrat: str, limit: int = 5):
    """Exécute une recherche vectorielle"""
    tokenizer, model = load_model()
    encode_text(tokenizer, model, query_text)

    cql_query = """
    SELECT libelle, montant, cat_auto
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
    LIMIT {limit}
    """

    start_time = time.time()
    result = session.execute(cql_query)
    latency = (time.time() - start_time) * 1000  # ms

    return latency, list(result)


def read_workload(session, code_si: str, contrat: str, num_queries: int = 100):
    """Charge de lecture : exécute des requêtes de recherche vectorielle"""
    queries = [
        "LOYER IMPAYE",
        "PAIEMENT CARTE",
        "VIREMENT SALAIRE",
        "TAXE FONCIERE",
        "CB RESTAURANT",
    ]

    latencies = []
    errors = 0

    for i in range(num_queries):
        query_text = queries[i % len(queries)]
        try:
            latency, _ = vector_search_query(session, query_text, code_si, contrat)
            latencies.append(latency)
        except Exception as e:
            errors += 1
            print(f"⚠️  Erreur requête {i+1}: {e}")

    return latencies, errors


def write_workload(session, code_si: str, contrat: str, num_inserts: int = 100):
    """Charge d'écriture : insère des opérations"""
    latencies = []
    errors = 0

    base_date = int(datetime.now().timestamp() * 1000)

    for i in range(num_inserts):
        base_date + i * 1000
        i + 10000

        cql_query = """
        INSERT INTO {KEYSPACE}.operations_by_account
        (code_si, contrat, date_op, numero_op, libelle, montant, cat_auto)
        VALUES ('{code_si}', '{contrat}', {date_op}, {numero_op},
                'TEST CHARGE {i}', 100.0, 'TEST')
        """

        start_time = time.time()
        try:
            session.execute(cql_query)
            latency = (time.time() - start_time) * 1000  # ms
            latencies.append(latency)
        except Exception as e:
            errors += 1
            print(f"⚠️  Erreur insertion {i+1}: {e}")

    return latencies, errors


def concurrent_read_test(
    session, code_si: str, contrat: str, num_threads: int = 10, queries_per_thread: int = 10
):
    """Test de charge lecture concurrente"""
    print(
        f"📋 TEST 1 : Charge Lecture Concurrente ({num_threads} threads, {queries_per_thread} requêtes/thread)"
    )
    print("-" * 70)

    all_latencies = []
    all_errors = 0

    def worker(thread_id):
        latencies, errors = read_workload(session, code_si, contrat, queries_per_thread)
        return latencies, errors

    start_time = time.time()

    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        futures = [executor.submit(worker, i) for i in range(num_threads)]

        for future in as_completed(futures):
            latencies, errors = future.result()
            all_latencies.extend(latencies)
            all_errors += errors

    total_time = time.time() - start_time
    total_queries = num_threads * queries_per_thread

    if all_latencies:
        p50 = statistics.median(all_latencies)
        p95 = sorted(all_latencies)[int(len(all_latencies) * 0.95)]
        p99 = sorted(all_latencies)[int(len(all_latencies) * 0.99)]
        avg = statistics.mean(all_latencies)
        throughput = total_queries / total_time

        print(f"   ✅ Requêtes exécutées : {total_queries}")
        print(f"   ✅ Erreurs : {all_errors}")
        print(f"   ✅ Temps total : {total_time:.2f}s")
        print(f"   ✅ Throughput : {throughput:.2f} req/s")
        print(f"   ✅ Latence moyenne : {avg:.2f}ms")
        print(f"   ✅ Latence p50 : {p50:.2f}ms")
        print(f"   ✅ Latence p95 : {p95:.2f}ms")
        print(f"   ✅ Latence p99 : {p99:.2f}ms")

        return {
            "type": "read",
            "total_queries": total_queries,
            "errors": all_errors,
            "total_time": total_time,
            "throughput": throughput,
            "latencies": {"avg": avg, "p50": p50, "p95": p95, "p99": p99},
        }
    else:
        print("   ❌ Aucune requête réussie")
        return None


def concurrent_write_test(
    session, code_si: str, contrat: str, num_threads: int = 10, inserts_per_thread: int = 10
):
    """Test de charge écriture concurrente"""
    print(
        f"\n📋 TEST 2 : Charge Écriture Concurrente ({num_threads} threads, {inserts_per_thread} insertions/thread)"
    )
    print("-" * 70)

    all_latencies = []
    all_errors = 0

    def worker(thread_id):
        latencies, errors = write_workload(session, code_si, contrat, inserts_per_thread)
        return latencies, errors

    start_time = time.time()

    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        futures = [executor.submit(worker, i) for i in range(num_threads)]

        for future in as_completed(futures):
            latencies, errors = future.result()
            all_latencies.extend(latencies)
            all_errors += errors

    total_time = time.time() - start_time
    total_inserts = num_threads * inserts_per_thread

    if all_latencies:
        p50 = statistics.median(all_latencies)
        p95 = sorted(all_latencies)[int(len(all_latencies) * 0.95)]
        p99 = sorted(all_latencies)[int(len(all_latencies) * 0.99)]
        avg = statistics.mean(all_latencies)
        throughput = total_inserts / total_time

        print(f"   ✅ Insertions exécutées : {total_inserts}")
        print(f"   ✅ Erreurs : {all_errors}")
        print(f"   ✅ Temps total : {total_time:.2f}s")
        print(f"   ✅ Throughput : {throughput:.2f} inserts/s")
        print(f"   ✅ Latence moyenne : {avg:.2f}ms")
        print(f"   ✅ Latence p50 : {p50:.2f}ms")
        print(f"   ✅ Latence p95 : {p95:.2f}ms")
        print(f"   ✅ Latence p99 : {p99:.2f}ms")

        return {
            "type": "write",
            "total_inserts": total_inserts,
            "errors": all_errors,
            "total_time": total_time,
            "throughput": throughput,
            "latencies": {"avg": avg, "p50": p50, "p95": p95, "p99": p99},
        }
    else:
        print("   ❌ Aucune insertion réussie")
        return None


def mixed_workload_test(
    session, code_si: str, contrat: str, num_threads: int = 10, ops_per_thread: int = 10
):
    """Test de charge mixte (50% lecture, 50% écriture)"""
    print("\n📋 TEST 3 : Charge Mixte (50% lecture, 50% écriture)")
    print("-" * 70)

    read_latencies = []
    write_latencies = []
    read_errors = 0
    write_errors = 0

    def read_worker(thread_id):
        latencies, errors = read_workload(session, code_si, contrat, ops_per_thread)
        return latencies, errors

    def write_worker(thread_id):
        latencies, errors = write_workload(session, code_si, contrat, ops_per_thread)
        return latencies, errors

    start_time = time.time()

    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        # 50% threads lecture
        read_futures = [executor.submit(read_worker, i) for i in range(num_threads // 2)]
        # 50% threads écriture
        write_futures = [
            executor.submit(write_worker, i) for i in range(num_threads // 2, num_threads)
        ]

        for future in as_completed(read_futures):
            latencies, errors = future.result()
            read_latencies.extend(latencies)
            read_errors += errors

        for future in as_completed(write_futures):
            latencies, errors = future.result()
            write_latencies.extend(latencies)
            write_errors += errors

    total_time = time.time() - start_time
    total_ops = (num_threads // 2) * ops_per_thread * 2  # lecture + écriture

    if read_latencies and write_latencies:
        read_avg = statistics.mean(read_latencies)
        write_avg = statistics.mean(write_latencies)
        throughput = total_ops / total_time

        print(f"   ✅ Opérations totales : {total_ops}")
        print(f"   ✅ Lectures : {(num_threads // 2) * ops_per_thread} (erreurs: {read_errors})")
        print(f"   ✅ Écritures : {(num_threads // 2) * ops_per_thread} (erreurs: {write_errors})")
        print(f"   ✅ Temps total : {total_time:.2f}s")
        print(f"   ✅ Throughput : {throughput:.2f} ops/s")
        print(f"   ✅ Latence lecture moyenne : {read_avg:.2f}ms")
        print(f"   ✅ Latence écriture moyenne : {write_avg:.2f}ms")

        return {
            "type": "mixed",
            "total_ops": total_ops,
            "read_errors": read_errors,
            "write_errors": write_errors,
            "total_time": total_time,
            "throughput": throughput,
            "read_latency_avg": read_avg,
            "write_latency_avg": write_avg,
        }
    else:
        print("   ❌ Test mixte échoué")
        return None


def test_charge_concurrente():
    """Test principal de charge concurrente"""
    print("=" * 70)
    print("  🔍 Test Complexe P1-02 : Tests de Charge Concurrente")
    print("=" * 70)
    print()

    cluster, session = connect_to_hcd()

    test_code_si = "6"
    test_contrat = "600000041"

    results = []

    # Test 1 : Charge lecture
    result1 = concurrent_read_test(
        session, test_code_si, test_contrat, num_threads=10, queries_per_thread=10
    )
    if result1:
        results.append(result1)

    # Test 2 : Charge écriture
    result2 = concurrent_write_test(
        session, test_code_si, test_contrat, num_threads=10, inserts_per_thread=10
    )
    if result2:
        results.append(result2)

    # Test 3 : Charge mixte
    result3 = mixed_workload_test(
        session, test_code_si, test_contrat, num_threads=10, ops_per_thread=5
    )
    if result3:
        results.append(result3)

    # Résumé
    print("\n" + "=" * 70)
    print("  📊 RÉSUMÉ")
    print("=" * 70)

    for result in results:
        if result["type"] == "read":
            print(
                f"✅ Lecture : {result['throughput']:.2f} req/s, p95={result['latencies']['p95']:.2f}ms"
            )
        elif result["type"] == "write":
            print(
                f"✅ Écriture : {result['throughput']:.2f} inserts/s, p95={result['latencies']['p95']:.2f}ms"
            )
        elif result["type"] == "mixed":
            print(f"✅ Mixte : {result['throughput']:.2f} ops/s")

    cluster.shutdown()

    return {"success": len(results) == 3, "results": results}


if __name__ == "__main__":
    result = test_charge_concurrente()
    sys.exit(0 if result["success"] else 1)
