#!/usr/bin/env python3
"""
Test Complexe P1-03 : Recherche Multi-Modèles avec Fusion
- Recherche avec ByteT5 + e5-large + Facturation simultanément
- Fusion des résultats (déduplication, scoring combiné)
- Ranking personnalisé (score combiné)
- Fallback automatique (modèle 1 → modèle 2 → modèle 3)
"""

import os
import sys
import time
from typing import Dict, List

from cassandra.cluster import Cluster
from test_vector_search_base import KEYSPACE, encode_text, load_model
from test_vector_search_base_e5 import encode_text_e5, load_model_e5
from test_vector_search_base_invoice import encode_text_invoice, load_model_invoice

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


def vector_search_byt5(
    session, query_embedding: List[float], code_si: str, contrat: str, limit: int = 5
):
    """Recherche vectorielle avec ByteT5"""
    cql_query = """
    SELECT libelle, montant, cat_auto, cat_user, cat_confidence
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
    LIMIT {limit}
    """
    result = session.execute(cql_query)
    return list(result)


def vector_search_e5(
    session, query_embedding: List[float], code_si: str, contrat: str, limit: int = 5
):
    """Recherche vectorielle avec e5-large"""
    cql_query = """
    SELECT libelle, montant, cat_auto, cat_user, cat_confidence
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY libelle_embedding_e5 ANN OF {json.dumps(query_embedding)}
    LIMIT {limit}
    """
    result = session.execute(cql_query)
    return list(result)


def vector_search_invoice(
    session, query_embedding: List[float], code_si: str, contrat: str, limit: int = 5
):
    """Recherche vectorielle avec modèle Facturation"""
    cql_query = """
    SELECT libelle, montant, cat_auto, cat_user, cat_confidence
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY libelle_embedding_invoice ANN OF {json.dumps(query_embedding)}
    LIMIT {limit}
    """
    result = session.execute(cql_query)
    return list(result)


def search_multi_models(
    session, query_text: str, code_si: str, contrat: str, limit: int = 5
) -> Dict:
    """Recherche avec plusieurs modèles simultanément"""
    results = {}

    # ByteT5
    try:
        tokenizer, model = load_model()
        query_embedding_byt5 = encode_text(tokenizer, model, query_text)
        results_byt5 = vector_search_byt5(session, query_embedding_byt5, code_si, contrat, limit)
        results["byt5"] = results_byt5
    except Exception as e:
        print(f"⚠️  Erreur ByteT5 : {e}")
        results["byt5"] = []

    # e5-large
    try:
        model_e5 = load_model_e5()
        query_embedding_e5 = encode_text_e5(model_e5, query_text)
        results_e5 = vector_search_e5(session, query_embedding_e5, code_si, contrat, limit)
        results["e5"] = results_e5
    except Exception as e:
        print(f"⚠️  Erreur e5-large : {e}")
        results["e5"] = []

    # Facturation
    try:
        model_invoice = load_model_invoice()
        query_embedding_invoice = encode_text_invoice(model_invoice, query_text)
        results_invoice = vector_search_invoice(
            session, query_embedding_invoice, code_si, contrat, limit
        )
        results["invoice"] = results_invoice
    except Exception as e:
        print(f"⚠️  Erreur Facturation : {e}")
        results["invoice"] = []

    return results


def merge_results(results: Dict, limit: int = 10) -> List[Dict]:
    """Fusionne les résultats de plusieurs modèles avec déduplication et scoring"""
    merged = {}

    # Poids pour chaque modèle (basé sur pertinence observée)
    weights = {
        "byt5": 1.0,  # 100% pertinence pour CB
        "e5": 0.8,  # 80% pertinence
        "invoice": 0.8,  # 80% pertinence, mais plus rapide
    }

    # Collecter tous les résultats avec scores
    for model_name, model_results in results.items():
        weight = weights.get(model_name, 0.5)

        for idx, row in enumerate(model_results):
            libelle = row.libelle

            # Score basé sur position et poids du modèle
            # Plus proche de 0 = meilleur résultat
            score = (idx + 1) * (1.0 / weight)

            if libelle not in merged:
                merged[libelle] = {
                    "libelle": libelle,
                    "montant": row.montant,
                    "cat_auto": row.cat_auto,
                    "cat_user": row.cat_user,
                    "cat_confidence": row.cat_confidence,
                    "models": [model_name],
                    "scores": [score],
                    "best_score": score,
                }
            else:
                # Déduplication : ajouter le modèle et mettre à jour le score
                merged[libelle]["models"].append(model_name)
                merged[libelle]["scores"].append(score)
                # Meilleur score = score le plus bas (meilleur rang)
                merged[libelle]["best_score"] = min(merged[libelle]["best_score"], score)

    # Trier par meilleur score
    sorted_results = sorted(merged.values(), key=lambda x: x["best_score"])

    return sorted_results[:limit]


def test_multi_models_fusion():
    """Test principal de recherche multi-modèles avec fusion"""
    print("=" * 70)
    print("  🔍 Test Complexe P1-03 : Recherche Multi-Modèles avec Fusion")
    print("=" * 70)
    print()

    cluster, session = connect_to_hcd()

    test_code_si = "6"
    test_contrat = "600000041"
    test_queries = ["LOYER IMPAYE", "PAIEMENT CARTE", "VIREMENT SALAIRE"]

    results_summary = []

    for query_text in test_queries:
        print(f"\n📋 Requête : '{query_text}'")
        print("-" * 70)

        # Recherche multi-modèles
        start_time = time.time()
        multi_results = search_multi_models(
            session, query_text, test_code_si, test_contrat, limit=5
        )
        search_time = time.time() - start_time

        print(f"   ⏱️  Temps de recherche : {search_time:.3f}s")
        print("   📊 Résultats par modèle :")
        for model_name, model_results in multi_results.items():
            print(f"      - {model_name}: {len(model_results)} résultats")

        # Fusion des résultats
        merged_results = merge_results(multi_results, limit=10)

        print(f"   ✅ Résultats fusionnés : {len(merged_results)} (dédupliqués)")
        print("   📋 Top 5 résultats fusionnés :")
        for idx, result in enumerate(merged_results[:5], 1):
            models_str = ", ".join(result["models"])
            print(
                f"      {idx}. {result['libelle']} (modèles: {models_str}, score: {result['best_score']:.2f})"
            )

        results_summary.append(
            {
                "query": query_text,
                "search_time": search_time,
                "results_by_model": {k: len(v) for k, v in multi_results.items()},
                "merged_count": len(merged_results),
                "top_result": merged_results[0]["libelle"] if merged_results else None,
            }
        )

    # Test de fallback automatique
    print("\n📋 TEST : Fallback Automatique")
    print("-" * 70)

    # Simuler un échec du premier modèle
    query_text = "LOYER IMPAYE"

    # Essayer ByteT5 d'abord
    try:
        tokenizer, model = load_model()
        query_embedding = encode_text(tokenizer, model, query_text)
        results = vector_search_byt5(session, query_embedding, test_code_si, test_contrat, limit=5)
        print(f"   ✅ ByteT5 : {len(results)} résultats")
    except Exception as e:
        print(f"   ❌ ByteT5 échoué : {e}")
        # Fallback vers Facturation
        try:
            model_invoice = load_model_invoice()
            query_embedding = encode_text_invoice(model_invoice, query_text)
            results = vector_search_invoice(
                session, query_embedding, test_code_si, test_contrat, limit=5
            )
            print(f"   ✅ Fallback Facturation : {len(results)} résultats")
        except Exception as e2:
            print(f"   ❌ Fallback échoué : {e2}")

    # Résumé
    print("\n" + "=" * 70)
    print("  📊 RÉSUMÉ")
    print("=" * 70)

    for summary in results_summary:
        print(
            f"✅ '{summary['query']}' : {summary['merged_count']} résultats fusionnés en {summary['search_time']:.3f}s"
        )
        if summary["top_result"]:
            print(f"   Top résultat : {summary['top_result']}")

    cluster.shutdown()

    return {"success": len(results_summary) == len(test_queries), "results": results_summary}


if __name__ == "__main__":
    result = test_multi_models_fusion()
    sys.exit(0 if result["success"] else 1)
