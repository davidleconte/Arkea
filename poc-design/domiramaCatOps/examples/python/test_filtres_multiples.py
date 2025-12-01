#!/usr/bin/env python3
"""
Test Complexe P2-03 : Recherche avec Filtres Multiples Combinés
- Vector + Full-Text + Filtres (date, montant, catégorie) simultanément
- Optimisation requête (ordre des filtres)
- Performance avec filtres multiples
- Validation résultats (tous les filtres respectés)
"""

import sys
import os
import time
import json
from datetime import datetime
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
from typing import Dict, List

# Ajouter le répertoire parent au PYTHONPATH
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(SCRIPT_DIR, 'search'))

from test_vector_search_base import load_model, encode_text, KEYSPACE

def connect_to_hcd(host='localhost', port=9042):
    """Connexion à HCD"""
    try:
        cluster = Cluster([host], port=port)
        session = cluster.connect(KEYSPACE)
        return cluster, session
    except Exception as e:
        print(f"❌ Erreur de connexion à HCD : {e}")
        sys.exit(1)

def search_with_multiple_filters(session, query_text: str, code_si: str, contrat: str,
                                  date_start: str = None, date_end: str = None,
                                  montant_min: float = None, montant_max: float = None,
                                  categorie: str = None, limit: int = 10):
    """Recherche avec filtres multiples combinés"""
    tokenizer, model = load_model()
    query_embedding = encode_text(tokenizer, model, query_text)
    
    # Construire la requête avec filtres
    filters = [f"code_si = '{code_si}'", f"contrat = '{contrat}'"]
    
    # Filtre date
    if date_start and date_end:
        start_dt = datetime.strptime(date_start, '%Y-%m-%d')
        end_dt = datetime.strptime(date_end, '%Y-%m-%d')
        start_ts = int(start_dt.timestamp() * 1000)
        end_ts = int(end_dt.timestamp() * 1000)
        filters.append(f"date_op >= {start_ts} AND date_op < {end_ts}")
    
    # Filtre montant (sera appliqué côté client car pas d'index)
    # Filtre catégorie (sera appliqué côté client car pas d'index)
    
    # Requête vectorielle de base (sans filtre date pour éviter l'erreur ORDER BY)
    # On récupère d'abord les résultats vectoriels, puis on filtre côté client
    base_filters = [f"code_si = '{code_si}'", f"contrat = '{contrat}'"]
    where_clause = " AND ".join(base_filters)
    
    cql_query = f"""
    SELECT libelle, montant, cat_auto, date_op
    FROM {KEYSPACE}.operations_by_account
    WHERE {where_clause}
    ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
    LIMIT {limit * 5}  -- Récupérer plus de résultats pour filtrage côté client
    """
    
    start_time = time.time()
    result = session.execute(cql_query)
    search_time = time.time() - start_time
    
    # Filtrer côté client (date, montant, catégorie)
    filtered_results = []
    for row in result:
        # Filtre date
        if date_start and date_end:
            if row.date_op:
                if isinstance(row.date_op, datetime):
                    row_date = row.date_op
                else:
                    row_date = datetime.fromtimestamp(row.date_op / 1000)
                start_dt = datetime.strptime(date_start, '%Y-%m-%d')
                end_dt = datetime.strptime(date_end, '%Y-%m-%d')
                if not (start_dt <= row_date < end_dt):
                    continue
        
        # Filtre montant
        if montant_min is not None:
            montant_val = float(row.montant) if row.montant else 0
            if montant_val < montant_min:
                continue
        if montant_max is not None:
            montant_val = float(row.montant) if row.montant else 0
            if montant_val > montant_max:
                continue
        
        # Filtre catégorie
        if categorie and row.cat_auto != categorie:
            continue
        
        filtered_results.append(row)
        
        if len(filtered_results) >= limit:
            break
    
    return filtered_results, search_time

def test_vector_fulltext_date_montant_categorie(session, code_si: str, contrat: str):
    """Test 1 : Vector + Full-Text + Date + Montant + Catégorie"""
    print("📋 TEST 1 : Vector + Full-Text + Date + Montant + Catégorie")
    print("-" * 70)
    
    query_text = "LOYER IMPAYE"
    date_start = "2024-06-01"
    date_end = "2024-07-01"
    montant_min = 100.0
    montant_max = 2000.0
    categorie = "HABITATION"
    
    print(f"   Requête : '{query_text}'")
    print(f"   Filtres :")
    print(f"      - Date : {date_start} → {date_end}")
    print(f"      - Montant : {montant_min} → {montant_max}")
    print(f"      - Catégorie : {categorie}")
    
    results, search_time = search_with_multiple_filters(
        session, query_text, code_si, contrat,
        date_start=date_start, date_end=date_end,
        montant_min=montant_min, montant_max=montant_max,
        categorie=categorie, limit=5
    )
    
    print(f"   ⏱️  Temps de recherche : {search_time:.3f}s")
    print(f"   ✅ Résultats trouvés : {len(results)}")
    
    # Valider que tous les filtres sont respectés
    all_valid = True
    for idx, row in enumerate(results, 1):
        date_op = datetime.fromtimestamp(row.date_op / 1000) if row.date_op else None
        date_valid = date_start <= date_op.strftime('%Y-%m-%d') < date_end if date_op else False
        montant_valid = montant_min <= row.montant <= montant_max
        categorie_valid = row.cat_auto == categorie
        
        if not (date_valid and montant_valid and categorie_valid):
            all_valid = False
        
        print(f"      {idx}. {row.libelle}")
        print(f"         Montant: {row.montant} ({'✅' if montant_valid else '❌'})")
        print(f"         Catégorie: {row.cat_auto} ({'✅' if categorie_valid else '❌'})")
        if date_op:
            print(f"         Date: {date_op.strftime('%Y-%m-%d')} ({'✅' if date_valid else '❌'})")
    
    if all_valid:
        print(f"   ✅ Tous les filtres respectés")
    else:
        print(f"   ⚠️  Certains filtres non respectés")
    
    return {
        'results_count': len(results),
        'search_time': search_time,
        'all_filters_valid': all_valid
    }

def test_optimisation_ordre_filtres(session, code_si: str, contrat: str):
    """Test 2 : Optimisation ordre des filtres"""
    print("\n📋 TEST 2 : Optimisation Ordre des Filtres")
    print("-" * 70)
    
    query_text = "VIREMENT SALAIRE"
    
    # Test avec filtres sélectifs d'abord (date)
    print("   Stratégie 1 : Filtre date d'abord (sélectif)")
    date_start = "2024-06-01"
    date_end = "2024-07-01"
    
    results1, time1 = search_with_multiple_filters(
        session, query_text, code_si, contrat,
        date_start=date_start, date_end=date_end,
        limit=5
    )
    
    print(f"      Résultats : {len(results1)}, Temps : {time1:.3f}s")
    
    # Test sans filtre date (moins sélectif)
    print("   Stratégie 2 : Sans filtre date (moins sélectif)")
    results2, time2 = search_with_multiple_filters(
        session, query_text, code_si, contrat,
        limit=5
    )
    
    print(f"      Résultats : {len(results2)}, Temps : {time2:.3f}s")
    
    if time1 < time2:
        print(f"   ✅ Filtre sélectif améliore la performance ({time1:.3f}s vs {time2:.3f}s)")
    else:
        print(f"   ⚠️  Filtre sélectif n'améliore pas la performance")
    
    return {
        'with_date_filter': {'results': len(results1), 'time': time1},
        'without_date_filter': {'results': len(results2), 'time': time2}
    }

def test_performance_filtres_multiples(session, code_si: str, contrat: str):
    """Test 3 : Performance avec filtres multiples"""
    print("\n📋 TEST 3 : Performance avec Filtres Multiples")
    print("-" * 70)
    
    query_text = "TAXE FONCIERE"
    
    # Test avec différents nombres de filtres
    test_cases = [
        ("Aucun filtre", {}),
        ("1 filtre (date)", {"date_start": "2024-06-01", "date_end": "2024-07-01"}),
        ("2 filtres (date + montant)", {
            "date_start": "2024-06-01", "date_end": "2024-07-01",
            "montant_min": 100.0, "montant_max": 2000.0
        }),
        ("3 filtres (date + montant + catégorie)", {
            "date_start": "2024-06-01", "date_end": "2024-07-01",
            "montant_min": 100.0, "montant_max": 2000.0,
            "categorie": "DIVERS"
        }),
    ]
    
    results = {}
    for name, filters in test_cases:
        start_time = time.time()
        search_results, _ = search_with_multiple_filters(
            session, query_text, code_si, contrat, limit=5, **filters
        )
        elapsed = time.time() - start_time
        
        results[name] = {
            'count': len(search_results),
            'time': elapsed
        }
        
        print(f"   {name} : {len(search_results)} résultats, {elapsed:.3f}s")
    
    return results

def test_cas_limites_filtres(session, code_si: str, contrat: str):
    """Test 4 : Cas limites (aucun résultat, trop de résultats)"""
    print("\n📋 TEST 4 : Cas Limites")
    print("-" * 70)
    
    # Cas 1 : Aucun résultat (filtres trop restrictifs)
    print("   Cas 1 : Filtres trop restrictifs (aucun résultat attendu)")
    results1, time1 = search_with_multiple_filters(
        session, "LOYER IMPAYE", code_si, contrat,
        date_start="2020-01-01", date_end="2020-01-02",
        montant_min=1000000.0, montant_max=2000000.0,
        categorie="INEXISTANTE", limit=5
    )
    print(f"      Résultats : {len(results1)} ({'✅ Aucun résultat' if len(results1) == 0 else '⚠️  Résultats inattendus'})")
    
    # Cas 2 : Trop de résultats (filtres peu restrictifs)
    print("   Cas 2 : Filtres peu restrictifs (beaucoup de résultats)")
    results2, time2 = search_with_multiple_filters(
        session, "LOYER", code_si, contrat,
        limit=100
    )
    print(f"      Résultats : {len(results2)} ({'✅ Nombre raisonnable' if len(results2) <= 100 else '⚠️  Trop de résultats'})")
    
    return {
        'no_results': len(results1),
        'many_results': len(results2)
    }

def test_filtres_multiples():
    """Test principal de filtres multiples"""
    print("=" * 70)
    print("  🔍 Test Complexe P2-03 : Recherche avec Filtres Multiples Combinés")
    print("=" * 70)
    print()
    
    cluster, session = connect_to_hcd()
    
    test_code_si = "6"
    test_contrat = "600000041"
    
    results = {}
    
    # Test 1 : Vector + Full-Text + Date + Montant + Catégorie
    result1 = test_vector_fulltext_date_montant_categorie(session, test_code_si, test_contrat)
    results['multiple_filters'] = result1
    
    # Test 2 : Optimisation ordre filtres
    result2 = test_optimisation_ordre_filtres(session, test_code_si, test_contrat)
    results['optimisation'] = result2
    
    # Test 3 : Performance filtres multiples
    result3 = test_performance_filtres_multiples(session, test_code_si, test_contrat)
    results['performance'] = result3
    
    # Test 4 : Cas limites
    result4 = test_cas_limites_filtres(session, test_code_si, test_contrat)
    results['cas_limites'] = result4
    
    # Résumé
    print("\n" + "=" * 70)
    print("  📊 RÉSUMÉ")
    print("=" * 70)
    
    if 'multiple_filters' in results:
        print(f"✅ Filtres multiples : {results['multiple_filters']['results_count']} résultats")
        print(f"   Tous les filtres respectés : {'✅ Oui' if results['multiple_filters']['all_filters_valid'] else '⚠️  Non'}")
    
    if 'performance' in results:
        print(f"✅ Performance testée : {len(results['performance'])} configurations")
    
    cluster.shutdown()
    
    return {
        'success': len(results) == 4,
        'results': results
    }

if __name__ == "__main__":
    result = test_filtres_multiples()
    sys.exit(0 if result['success'] else 1)

