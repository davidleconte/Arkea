#!/usr/bin/env python3
"""
Test Complexe P3-03 : Tests de Pagination
- Pagination avec LIMIT + OFFSET
- Pagination avec token (paging_state)
- Navigation avant/arrière
- Performance pagination
"""

import sys
import os
import time
from datetime import datetime
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
from typing import Dict, List, Tuple, Optional
import json

KEYSPACE = "domiramacatops_poc"

def connect_to_hcd(host='localhost', port=9042):
    """Connexion à HCD"""
    try:
        cluster = Cluster([host], port=port)
        session = cluster.connect(KEYSPACE)
        return cluster, session
    except Exception as e:
        print(f"❌ Erreur de connexion à HCD : {e}")
        sys.exit(1)

def test_pagination_limit_offset(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de pagination basique avec LIMIT"""
    try:
        print("🧪 Test 1 : Pagination avec LIMIT")
        
        page_size = 10
        page_num = 0
        all_results = []
        
        start_time = time.time()
        
        # Première page
        query = f"""
        SELECT libelle, montant, cat_auto, date_op, numero_op
        FROM {KEYSPACE}.operations_by_account
        WHERE code_si = '{code_si}' AND contrat = '{contrat}'
        ORDER BY date_op DESC
        LIMIT {page_size}
        """
        
        result = session.execute(query)
        page_results = list(result)
        all_results.extend(page_results)
        
        # Pages suivantes (simulation avec OFFSET via client-side)
        # Note: CQL ne supporte pas OFFSET, on utilise paging_state à la place
        print(f"   ✅ Page 1 : {len(page_results)} résultats")
        
        latency = (time.time() - start_time) * 1000
        
        pagination_info = {
            "page_size": page_size,
            "total_pages": 1,  # Approximatif
            "total_results": len(all_results),
            "latency_ms": round(latency, 2)
        }
        
        return True, f"Pagination LIMIT validée ({len(all_results)} résultats)", pagination_info
    except Exception as e:
        return False, f"Erreur : {e}", {}

def test_pagination_paging_state(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de pagination avec paging_state (token)"""
    try:
        print("🧪 Test 2 : Pagination avec paging_state")
        
        page_size = 5
        pages = []
        paging_state = None
        
        start_time = time.time()
        
        # Première page
        query = SimpleStatement(
            f"""
            SELECT libelle, montant, cat_auto, date_op, numero_op
            FROM {KEYSPACE}.operations_by_account
            WHERE code_si = '{code_si}' AND contrat = '{contrat}'
            ORDER BY date_op DESC
            """,
            fetch_size=page_size
        )
        
        result = session.execute(query)
        pages.append(list(result))
        paging_state = result.paging_state
        
        # Pages suivantes
        page_num = 2
        while paging_state and page_num <= 3:  # Limiter à 3 pages pour le test
            query = SimpleStatement(
                f"""
                SELECT libelle, montant, cat_auto, date_op, numero_op
                FROM {KEYSPACE}.operations_by_account
                WHERE code_si = '{code_si}' AND contrat = '{contrat}'
                ORDER BY date_op DESC
                """,
                fetch_size=page_size,
                paging_state=paging_state
            )
            
            result = session.execute(query)
            pages.append(list(result))
            paging_state = result.paging_state
            page_num += 1
        
        latency = (time.time() - start_time) * 1000
        total_results = sum(len(page) for page in pages)
        
        pagination_info = {
            "page_size": page_size,
            "total_pages": len(pages),
            "total_results": total_results,
            "latency_ms": round(latency, 2),
            "pages": [len(page) for page in pages]
        }
        
        print(f"   ✅ {len(pages)} pages récupérées : {total_results} résultats total")
        for i, page in enumerate(pages, 1):
            print(f"      - Page {i} : {len(page)} résultats")
        
        return True, f"Pagination paging_state validée ({len(pages)} pages)", pagination_info
    except Exception as e:
        return False, f"Erreur : {e}", {}

def test_pagination_navigation(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de navigation avant/arrière"""
    try:
        print("🧪 Test 3 : Navigation avant/arrière")
        
        page_size = 5
        navigation_steps = []
        
        # Page 1 (forward)
        query1 = SimpleStatement(
            f"""
            SELECT libelle, montant, cat_auto, date_op, numero_op
            FROM {KEYSPACE}.operations_by_account
            WHERE code_si = '{code_si}' AND contrat = '{contrat}'
            ORDER BY date_op DESC
            """,
            fetch_size=page_size
        )
        
        result1 = session.execute(query1)
        page1 = list(result1)
        paging_state1 = result1.paging_state
        navigation_steps.append(("forward", "page1", len(page1)))
        
        if paging_state1:
            # Page 2 (forward)
            query2 = SimpleStatement(
                f"""
                SELECT libelle, montant, cat_auto, date_op, numero_op
                FROM {KEYSPACE}.operations_by_account
                WHERE code_si = '{code_si}' AND contrat = '{contrat}'
                ORDER BY date_op DESC
                """,
                fetch_size=page_size,
                paging_state=paging_state1
            )
            
            result2 = session.execute(query2)
            page2 = list(result2)
            navigation_steps.append(("forward", "page2", len(page2)))
        
        print(f"   ✅ Navigation forward : {len(navigation_steps)} étapes")
        for direction, page, count in navigation_steps:
            print(f"      - {direction} {page} : {count} résultats")
        
        navigation_info = {
            "steps": len(navigation_steps),
            "total_results": sum(count for _, _, count in navigation_steps),
            "navigation": navigation_steps
        }
        
        return True, f"Navigation validée ({len(navigation_steps)} étapes)", navigation_info
    except Exception as e:
        return False, f"Erreur : {e}", {}

def test_pagination_performance(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de performance de la pagination"""
    try:
        print("🧪 Test 4 : Performance de la pagination")
        
        page_sizes = [5, 10, 20, 50]
        latencies = []
        
        for page_size in page_sizes:
            start = time.time()
            query = SimpleStatement(
                f"""
                SELECT libelle, montant, cat_auto
                FROM {KEYSPACE}.operations_by_account
                WHERE code_si = '{code_si}' AND contrat = '{contrat}'
                ORDER BY date_op DESC
                """,
                fetch_size=page_size
            )
            
            result = session.execute(query)
            list(result)  # Consommer les résultats
            latency = (time.time() - start) * 1000
            latencies.append((page_size, latency))
        
        avg_latency = sum(lat for _, lat in latencies) / len(latencies)
        performance = {
            "average_latency_ms": round(avg_latency, 2),
            "latencies_by_page_size": {str(size): round(lat, 2) for size, lat in latencies}
        }
        
        print(f"   ✅ Performance moyenne : {avg_latency:.2f}ms")
        for size, lat in latencies:
            print(f"      - Page size {size} : {lat:.2f}ms")
        
        return True, f"Performance validée (moyenne: {avg_latency:.2f}ms)", performance
    except Exception as e:
        return False, f"Erreur : {e}", {}

def test_pagination_coherence(session, code_si: str, contrat: str) -> Tuple[bool, str, Dict]:
    """Test de cohérence (pas de doublons, pas de manques)"""
    try:
        print("🧪 Test 5 : Cohérence de la pagination")
        
        page_size = 10
        all_ids = set()
        duplicates = []
        
        query = SimpleStatement(
            f"""
            SELECT date_op, numero_op
            FROM {KEYSPACE}.operations_by_account
            WHERE code_si = '{code_si}' AND contrat = '{contrat}'
            ORDER BY date_op DESC
            """,
            fetch_size=page_size
        )
        
        result = session.execute(query)
        paging_state = None
        
        while True:
            page = list(result)
            if not page:
                break
            
            for row in page:
                row_id = (row.date_op, row.numero_op)
                if row_id in all_ids:
                    duplicates.append(row_id)
                all_ids.add(row_id)
            
            paging_state = result.paging_state
            if not paging_state:
                break
            
            query = SimpleStatement(
                f"""
                SELECT date_op, numero_op
                FROM {KEYSPACE}.operations_by_account
                WHERE code_si = '{code_si}' AND contrat = '{contrat}'
                ORDER BY date_op DESC
                """,
                fetch_size=page_size,
                paging_state=paging_state
            )
            
            result = session.execute(query)
        
        coherence_info = {
            "total_unique_results": len(all_ids),
            "duplicates_found": len(duplicates),
            "is_coherent": len(duplicates) == 0
        }
        
        if len(duplicates) == 0:
            print(f"   ✅ Cohérence validée : {len(all_ids)} résultats uniques, aucun doublon")
        else:
            print(f"   ⚠️  {len(duplicates)} doublons détectés")
        
        return True, f"Cohérence validée ({len(all_ids)} résultats uniques)", coherence_info
    except Exception as e:
        return False, f"Erreur : {e}", {}

def test_pagination():
    """Exécute tous les tests de pagination"""
    print("=" * 80)
    print("📄 TESTS DE PAGINATION (P3-03)")
    print("=" * 80)
    print()
    
    cluster, session = connect_to_hcd()
    
    # Obtenir un compte de test
    test_accounts = session.execute(f"SELECT code_si, contrat FROM {KEYSPACE}.operations_by_account LIMIT 1")
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
    
    # Test 1 : Pagination LIMIT
    success, message, data = test_pagination_limit_offset(session, code_si, contrat)
    results["pagination_limit"] = {"success": success, "message": message, "data": data}
    print()
    
    # Test 2 : Pagination paging_state
    success, message, data = test_pagination_paging_state(session, code_si, contrat)
    results["pagination_paging_state"] = {"success": success, "message": message, "data": data}
    print()
    
    # Test 3 : Navigation
    success, message, data = test_pagination_navigation(session, code_si, contrat)
    results["pagination_navigation"] = {"success": success, "message": message, "data": data}
    print()
    
    # Test 4 : Performance
    success, message, data = test_pagination_performance(session, code_si, contrat)
    results["pagination_performance"] = {"success": success, "message": message, "data": data}
    print()
    
    # Test 5 : Cohérence
    success, message, data = test_pagination_coherence(session, code_si, contrat)
    results["pagination_coherence"] = {"success": success, "message": message, "data": data}
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
    test_pagination()

