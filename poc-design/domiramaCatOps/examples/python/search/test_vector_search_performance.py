#!/usr/bin/env python3
"""
Tests de performance pour la recherche vectorielle.
Mesure la latence, le débit et les temps de génération d'embedding.
"""

import statistics
import time

from test_vector_search_base import (
    connect_to_hcd,
    encode_text,
    get_test_account,
    load_model,
    vector_search,
)


def benchmark_embedding_generation(tokenizer, model, queries: list, iterations: int = 100):
    """Benchmark la génération d'embeddings."""
    print("⏱️  Benchmark génération d'embeddings...")
    latencies = []

    for _ in range(iterations):
        for query in queries:
            start = time.time()
            encode_text(tokenizer, model, query)
            latency = (time.time() - start) * 1000  # ms
            latencies.append(latency)

    return {
        "mean": statistics.mean(latencies),
        "median": statistics.median(latencies),
        "p95": statistics.quantiles(latencies, n=20)[18] if len(latencies) >= 20 else latencies[-1],
        "p99": (
            statistics.quantiles(latencies, n=100)[98] if len(latencies) >= 100 else latencies[-1]
        ),
        "min": min(latencies),
        "max": max(latencies),
        "count": len(latencies),
    }


def benchmark_vector_search(
    session, tokenizer, model, queries: list, code_si: str, contrat: str, iterations: int = 100
):
    """Benchmark la recherche vectorielle complète."""
    print("⏱️  Benchmark recherche vectorielle...")
    latencies = []
    embedding_times = []
    search_times = []

    for _ in range(iterations):
        for query in queries:
            # Temps total
            start_total = time.time()

            # Génération embedding
            start_embedding = time.time()
            query_embedding = encode_text(tokenizer, model, query)
            embedding_time = (time.time() - start_embedding) * 1000
            embedding_times.append(embedding_time)

            # Recherche HCD
            start_search = time.time()
            results = vector_search(session, query_embedding, code_si, contrat, limit=5)
            search_time = (time.time() - start_search) * 1000
            search_times.append(search_time)

            # Temps total
            total_time = (time.time() - start_total) * 1000
            latencies.append(total_time)

    return {
        "total": {
            "mean": statistics.mean(latencies),
            "median": statistics.median(latencies),
            "p95": (
                statistics.quantiles(latencies, n=20)[18] if len(latencies) >= 20 else latencies[-1]
            ),
            "p99": (
                statistics.quantiles(latencies, n=100)[98]
                if len(latencies) >= 100
                else latencies[-1]
            ),
            "min": min(latencies),
            "max": max(latencies),
        },
        "embedding": {
            "mean": statistics.mean(embedding_times),
            "median": statistics.median(embedding_times),
        },
        "search": {
            "mean": statistics.mean(search_times),
            "median": statistics.median(search_times),
        },
        # req/s
        "throughput": len(queries) * iterations / (sum(latencies) / 1000),
    }


def main():
    """Fonction principale."""
    print("=" * 70)
    print("  ⏱️  Tests de Performance - Recherche Vectorielle")
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
        "LOYER IMPAYE",
        "loyr impay",
        "PAIEMENT CARTE",
        "paiemnt cart",
        "VIREMENT",
        "CARREFOUR",
    ]

    # Benchmark génération d'embeddings
    print("📊 Benchmark 1 : Génération d'embeddings")
    print("-" * 70)
    embedding_stats = benchmark_embedding_generation(tokenizer, model, test_queries, iterations=50)
    print(f"   Temps moyen : {embedding_stats['mean']:.2f} ms")
    print(f"   Médiane : {embedding_stats['median']:.2f} ms")
    print(f"   P95 : {embedding_stats['p95']:.2f} ms")
    print(f"   P99 : {embedding_stats['p99']:.2f} ms")
    print(f"   Min : {embedding_stats['min']:.2f} ms")
    print(f"   Max : {embedding_stats['max']:.2f} ms")
    print()

    # Benchmark recherche vectorielle complète
    print("📊 Benchmark 2 : Recherche vectorielle complète")
    print("-" * 70)
    search_stats = benchmark_vector_search(
        session, tokenizer, model, test_queries, code_si, contrat, iterations=50
    )
    print(f"   Temps total moyen : {search_stats['total']['mean']:.2f} ms")
    print(f"   Temps total médian : {search_stats['total']['median']:.2f} ms")
    print(f"   Temps total P95 : {search_stats['total']['p95']:.2f} ms")
    print(f"   Temps total P99 : {search_stats['total']['p99']:.2f} ms")
    print(f"   Temps embedding moyen : {search_stats['embedding']['mean']:.2f} ms")
    print(f"   Temps recherche HCD moyen : {search_stats['search']['mean']:.2f} ms")
    print(f"   Débit : {search_stats['throughput']:.2f} requêtes/seconde")
    print()

    # Validation des seuils
    print("📊 Validation des seuils de performance")
    print("-" * 70)
    if search_stats["total"]["mean"] < 100:
        print(f"   ✅ Latence moyenne OK : {search_stats['total']['mean']:.2f} ms < 100 ms")
    else:
        print(f"   ⚠️  Latence moyenne élevée : {search_stats['total']['mean']:.2f} ms >= 100 ms")

    if search_stats["total"]["p95"] < 200:
        print(f"   ✅ Latence P95 OK : {search_stats['total']['p95']:.2f} ms < 200 ms")
    else:
        print(f"   ⚠️  Latence P95 élevée : {search_stats['total']['p95']:.2f} ms >= 200 ms")

    if search_stats["throughput"] > 10:
        print(f"   ✅ Débit OK : {search_stats['throughput']:.2f} req/s > 10 req/s")
    else:
        print(f"   ⚠️  Débit faible : {search_stats['throughput']:.2f} req/s <= 10 req/s")
    print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Tests de performance terminés !")
    print("=" * 70)


if __name__ == "__main__":
    main()
