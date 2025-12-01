#!/usr/bin/env python3
"""
Test comparatif entre ByteT5-small, multilingual-e5-large, et modèle spécialisé facturation.
Compare les performances et la pertinence des résultats.
"""

import sys
import time
from test_vector_search_base import (
    load_model, encode_text, vector_search,
    connect_to_hcd, get_test_account, KEYSPACE
)
from test_vector_search_base_e5 import load_model_e5, encode_text_e5, vector_search_e5
from test_vector_search_base_invoice import (
    load_model_invoice, encode_text_invoice, vector_search_invoice
)
from test_vector_search_relevance_check import check_relevance

def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🔀 Comparaison : ByteT5 vs e5-large vs Modèle Facturation")
    print("=" * 70)
    print()
    
    # Charger les modèles
    print("📥 Chargement des modèles...")
    tokenizer, model_byt5 = load_model()
    print()
    
    try:
        model_e5 = load_model_e5()
        E5_AVAILABLE = True
    except:
        E5_AVAILABLE = False
        print("⚠️  e5-large non disponible")
    
    try:
        model_invoice = load_model_invoice()
        INVOICE_AVAILABLE = True
    except:
        INVOICE_AVAILABLE = False
        print("⚠️  Modèle facturation non disponible")
    
    print()
    
    # Connexion HCD
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
    
    # Requêtes de test (focus sur facturation)
    test_queries = [
        "LOYER IMPAYE",
        "VIREMENT SALAIRE",
        "PAIEMENT CARTE",
        "TAXE FONCIERE",
        "ASSURANCE HABITATION",
    ]
    
    print("=" * 70)
    print("  📊 Résultats Comparatifs")
    print("=" * 70)
    print()
    
    for query in test_queries:
        print(f"🔍 Requête: '{query}'")
        print()
        
        results = {}
        
        # Test ByteT5
        start = time.time()
        embedding_byt5 = encode_text(tokenizer, model_byt5, query)
        results_byt5 = vector_search(session, embedding_byt5, code_si, contrat, limit=5)
        latency_byt5 = (time.time() - start) * 1000
        relevance_byt5 = check_relevance(query, results_byt5)
        results['ByteT5'] = {
            'latency': latency_byt5,
            'relevance': relevance_byt5,
            'results': results_byt5
        }
        
        print(f"   📊 ByteT5-small ({latency_byt5:.1f} ms):")
        print(f"      Résultats : {len(results_byt5)}")
        print(f"      Pertinence : {relevance_byt5['relevant_count']}/{relevance_byt5['total_count']} ({relevance_byt5['relevance_rate']:.1%})")
        for i, row in enumerate(results_byt5[:3], 1):
            libelle = row.libelle[:50] if row.libelle else "N/A"
            print(f"      {i}. {libelle}")
        print()
        
        # Test e5-large (si disponible)
        if E5_AVAILABLE:
            start = time.time()
            embedding_e5 = encode_text_e5(model_e5, query)
            results_e5 = vector_search_e5(session, embedding_e5, code_si, contrat, limit=5)
            latency_e5 = (time.time() - start) * 1000
            relevance_e5 = check_relevance(query, results_e5)
            results['e5-large'] = {
                'latency': latency_e5,
                'relevance': relevance_e5,
                'results': results_e5
            }
            
            print(f"   📊 multilingual-e5-large ({latency_e5:.1f} ms):")
            print(f"      Résultats : {len(results_e5)}")
            print(f"      Pertinence : {relevance_e5['relevant_count']}/{relevance_e5['total_count']} ({relevance_e5['relevance_rate']:.1%})")
            for i, row in enumerate(results_e5[:3], 1):
                libelle = row.libelle[:50] if row.libelle else "N/A"
                print(f"      {i}. {libelle}")
            print()
        
        # Test modèle facturation (si disponible)
        if INVOICE_AVAILABLE:
            start = time.time()
            embedding_invoice = encode_text_invoice(model_invoice, query)
            results_invoice = vector_search_invoice(session, embedding_invoice, code_si, contrat, limit=5)
            latency_invoice = (time.time() - start) * 1000
            relevance_invoice = check_relevance(query, results_invoice)
            results['Invoice'] = {
                'latency': latency_invoice,
                'relevance': relevance_invoice,
                'results': results_invoice
            }
            
            print(f"   📊 Modèle Facturation ({latency_invoice:.1f} ms):")
            print(f"      Résultats : {len(results_invoice)}")
            print(f"      Pertinence : {relevance_invoice['relevant_count']}/{relevance_invoice['total_count']} ({relevance_invoice['relevance_rate']:.1%})")
            for i, row in enumerate(results_invoice[:3], 1):
                libelle = row.libelle[:50] if row.libelle else "N/A"
                print(f"      {i}. {libelle}")
            print()
        
        # Comparaison
        if E5_AVAILABLE and INVOICE_AVAILABLE:
            rates = {
                'ByteT5': relevance_byt5['relevance_rate'],
                'e5-large': relevance_e5['relevance_rate'],
                'Invoice': relevance_invoice['relevance_rate']
            }
            best = max(rates, key=rates.get)
            best_rate = rates[best]
            
            print(f"   🏆 Meilleur modèle : {best} ({best_rate:.1%})")
            for model_name, rate in rates.items():
                if model_name != best:
                    diff = (best_rate - rate) * 100
                    if diff > 0:
                        print(f"      +{diff:.1f}% vs {model_name}")
        
        print()
        print("-" * 70)
        print()
    
    session.shutdown()
    cluster.shutdown()
    
    print("=" * 70)
    print("  ✅ Comparaison terminée !")
    print("=" * 70)

if __name__ == "__main__":
    main()

