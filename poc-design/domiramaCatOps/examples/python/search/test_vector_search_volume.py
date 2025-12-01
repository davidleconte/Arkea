#!/usr/bin/env python3
"""
Tests avec données volumineuses pour la recherche vectorielle.
Teste la performance avec un grand volume de données.
"""

import sys
import time
import statistics
from test_vector_search_base import (
    load_model, encode_text, vector_search,
    connect_to_hcd, get_test_account
)

def count_operations(session, code_si: str, contrat: str) -> int:
    """Compte le nombre d'opérations pour un compte."""
    from cassandra.query import SimpleStatement
    from test_vector_search_base import KEYSPACE
    
    query = f"SELECT COUNT(*) FROM {KEYSPACE}.operations_by_account WHERE code_si = '{code_si}' AND contrat = '{contrat}'"
    try:
        result = session.execute(query).one()
        return result[0] if result else 0
    except:
        return 0

def benchmark_with_volume(session, tokenizer, model, query: str, code_si: str, contrat: str, iterations: int = 10):
    """Benchmark la recherche avec différentes volumes de données."""
    query_embedding = encode_text(tokenizer, model, query)
    latencies = []
    
    for _ in range(iterations):
        start = time.time()
        results = vector_search(session, query_embedding, code_si, contrat, limit=5)
        latency = (time.time() - start) * 1000  # ms
        latencies.append(latency)
    
    return {
        'mean': statistics.mean(latencies),
        'median': statistics.median(latencies),
        'p95': statistics.quantiles(latencies, n=20)[18] if len(latencies) >= 20 else latencies[-1],
        'min': min(latencies),
        'max': max(latencies),
        'count': len(latencies)
    }

def main():
    """Fonction principale."""
    print("=" * 70)
    print("  📊 Tests avec Données Volumineuses - Recherche Vectorielle")
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
    
    # Compter les opérations
    op_count = count_operations(session, code_si, contrat)
    print(f"📊 Volume de données : {op_count:,} opération(s)")
    print()
    
    # Classer le volume
    if op_count < 1000:
        volume_category = "Petit (< 1K)"
        expected_latency = 50
    elif op_count < 10000:
        volume_category = "Moyen (1K-10K)"
        expected_latency = 200
    elif op_count < 100000:
        volume_category = "Grand (10K-100K)"
        expected_latency = 500
    else:
        volume_category = "Très grand (100K+)"
        expected_latency = 2000
    
    print(f"📊 Catégorie : {volume_category}")
    print(f"📊 Latence attendue : < {expected_latency} ms")
    print()
    
    # Requête de test
    query = "LOYER IMPAYE"
    print(f"🔍 Requête de test : '{query}'")
    print()
    
    # Benchmark
    print("⏱️  Benchmark en cours...")
    stats = benchmark_with_volume(session, tokenizer, model, query, code_si, contrat, iterations=20)
    
    print("=" * 70)
    print("  📊 Résultats du Benchmark")
    print("=" * 70)
    print()
    print(f"   Latence moyenne : {stats['mean']:.2f} ms")
    print(f"   Latence médiane : {stats['median']:.2f} ms")
    print(f"   Latence P95 : {stats['p95']:.2f} ms")
    print(f"   Latence min : {stats['min']:.2f} ms")
    print(f"   Latence max : {stats['max']:.2f} ms")
    print()
    
    # Validation
    print("=" * 70)
    print("  ✅ Validation des Seuils")
    print("=" * 70)
    print()
    
    if stats['mean'] < expected_latency:
        print(f"   ✅ Latence moyenne OK : {stats['mean']:.2f} ms < {expected_latency} ms")
    else:
        print(f"   ⚠️  Latence moyenne élevée : {stats['mean']:.2f} ms >= {expected_latency} ms")
    
    if stats['p95'] < expected_latency * 2:
        print(f"   ✅ Latence P95 OK : {stats['p95']:.2f} ms < {expected_latency * 2} ms")
    else:
        print(f"   ⚠️  Latence P95 élevée : {stats['p95']:.2f} ms >= {expected_latency * 2} ms")
    print()
    
    # Recommandations
    print("=" * 70)
    print("  💡 Recommandations")
    print("=" * 70)
    print()
    
    if op_count < 10000:
        print("   ✅ Volume acceptable pour production")
        print("   ✅ Performance attendue : Excellente")
    elif op_count < 100000:
        print("   ⚠️  Volume important - Surveiller la performance")
        print("   💡 Considérer l'optimisation des index si latence > 500ms")
    else:
        print("   ⚠️  Volume très important - Performance à surveiller")
        print("   💡 Considérer le partitionnement ou l'optimisation des requêtes")
    print()
    
    session.shutdown()
    cluster.shutdown()
    
    print("=" * 70)
    print("  ✅ Tests avec données volumineuses terminés !")
    print("=" * 70)

if __name__ == "__main__":
    main()

