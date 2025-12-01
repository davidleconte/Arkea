#!/usr/bin/env python3
"""
Tests de cohérence pour la recherche vectorielle.
Vérifie que la même requête retourne les mêmes résultats.
"""

import sys
from test_vector_search_base import (
    load_model, encode_text, vector_search,
    connect_to_hcd, get_test_account
)
from test_vector_search_relevance_check import check_relevance

def test_consistency(session, tokenizer, model, query: str, code_si: str, contrat: str, iterations: int = 10):
    """Teste la cohérence des résultats pour une requête."""
    results_list = []
    
    for i in range(iterations):
        query_embedding = encode_text(tokenizer, model, query)
        results = vector_search(session, query_embedding, code_si, contrat, limit=5)
        results_list.append([r.libelle for r in results])
    
    # Vérifier que tous les résultats sont identiques
    first = results_list[0]
    all_same = all(r == first for r in results_list)
    
    # Vérifier l'ordre
    order_consistent = all(
        results_list[i] == results_list[i+1] 
        for i in range(len(results_list) - 1)
    )
    
    return {
        'all_same': all_same,
        'order_consistent': order_consistent,
        'results': results_list[0],
        'iterations': iterations
    }

def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🔄 Tests de Cohérence - Recherche Vectorielle")
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
        "PAIEMENT CARTE",
        "VIREMENT",
        "CARREFOUR"
    ]
    
    print("=" * 70)
    print("  📊 Résultats des Tests")
    print("=" * 70)
    print()
    
    for query in test_queries:
        print(f"🔍 Requête: '{query}'")
        print(f"   Répétition : 10 fois")
        print()
        
        consistency = test_consistency(session, tokenizer, model, query, code_si, contrat, iterations=10)
        
        # Vérifier la pertinence
        query_embedding = encode_text(tokenizer, model, query)
        first_results = vector_search(session, query_embedding, code_si, contrat, limit=5)
        relevance = check_relevance(query, first_results)
        
        if consistency['all_same']:
            print(f"   ✅ Cohérence OK : Tous les résultats identiques ({consistency['iterations']} itérations)")
        else:
            print(f"   ⚠️  Incohérence détectée : Résultats différents entre itérations")
            print(f"   💡 Note : Cela peut être dû à la non-déterminisme du modèle ou aux données")
        
        if consistency['order_consistent']:
            print(f"   ✅ Ordre stable : L'ordre des résultats est cohérent")
        else:
            print(f"   ⚠️  Ordre instable : L'ordre des résultats varie")
        
        # Afficher la pertinence
        if relevance['is_mostly_relevant']:
            print(f"   ✅ Pertinence OK : {relevance['relevant_count']}/{relevance['total_count']} résultats pertinents ({relevance['relevance_rate']:.1%})")
        else:
            print(f"   ⚠️  Pertinence faible : {relevance['relevant_count']}/{relevance['total_count']} résultats pertinents ({relevance['relevance_rate']:.1%})")
            print(f"   💡 Note : Les résultats peuvent ne pas être pertinents si les données de test ne contiennent pas de libellés correspondants")
        
        print(f"   📊 Résultats (première itération) :")
        for i, libelle in enumerate(consistency['results'][:5], 1):
            print(f"      {i}. {libelle[:50]}")
        print()
        print("-" * 70)
        print()
    
    session.shutdown()
    cluster.shutdown()
    
    print("=" * 70)
    print("  ✅ Tests de cohérence terminés !")
    print("=" * 70)

if __name__ == "__main__":
    main()

