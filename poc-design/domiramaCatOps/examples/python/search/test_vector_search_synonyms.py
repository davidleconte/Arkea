#!/usr/bin/env python3
"""
Tests avec synonymes pour la recherche vectorielle.
Vérifie la compréhension sémantique (synonymes).
"""

import sys
from test_vector_search_base import (
    load_model, encode_text, vector_search,
    connect_to_hcd, get_test_account, calculate_cosine_similarity
)
from test_vector_search_relevance_check import check_relevance

def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🔤 Tests avec Synonymes - Recherche Vectorielle")
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
    
    # Tests avec synonymes
    test_cases = [
        ("LOYER", "LOCATION", "LOUER"),
        ("PAIEMENT", "REGLEMENT", "VERSEMENT"),
        ("RESTAURANT", "BRASSERIE", "BISTROT"),
        ("SUPERMARCHE", "HYPERMARCHE", "EPICERIE"),
        ("VIREMENT", "TRANSFERT", "VERSEMENT"),
    ]
    
    print("=" * 70)
    print("  📊 Résultats des Tests")
    print("=" * 70)
    print()
    
    for word1, word2, word3 in test_cases:
        print(f"🔍 Synonymes : '{word1}', '{word2}', '{word3}'")
        print()
        
        # Recherche avec chaque synonyme
        embedding1 = encode_text(tokenizer, model, word1)
        results1 = vector_search(session, embedding1, code_si, contrat, limit=3)
        
        embedding2 = encode_text(tokenizer, model, word2)
        results2 = vector_search(session, embedding2, code_si, contrat, limit=3)
        
        # Comparaison de similarité
        similarity = calculate_cosine_similarity(embedding1, embedding2)
        
        print(f"   📊 '{word1}' : {len(results1)} résultat(s)")
        for i, row in enumerate(results1[:2], 1):
            libelle = row.libelle[:40] if row.libelle else "N/A"
            print(f"      {i}. {libelle}")
        print()
        
        print(f"   📊 '{word2}' : {len(results2)} résultat(s)")
        for i, row in enumerate(results2[:2], 1):
            libelle = row.libelle[:40] if row.libelle else "N/A"
            print(f"      {i}. {libelle}")
        print()
        
        # Vérifier la pertinence des résultats
        relevance1 = check_relevance(word1, results1)
        relevance2 = check_relevance(word2, results2)
        
        print(f"   📊 Similarité entre '{word1}' et '{word2}' : {similarity:.3f}")
        if similarity >= 0.6:
            print("   ✅ Similarité acceptable (>= 0.6) - Synonymes détectés")
        else:
            print("   ⚠️  Similarité faible (< 0.6) - Synonymes non détectés")
        
        # Afficher la pertinence
        if not relevance1['is_mostly_relevant'] or not relevance2['is_mostly_relevant']:
            print(f"   ⚠️  Pertinence faible : Les résultats peuvent ne pas être pertinents")
            print(f"   💡 Note : Vérifiez que les données de test contiennent des libellés pertinents")
        
        print()
        print("-" * 70)
        print()
    
    session.shutdown()
    cluster.shutdown()
    
    print("=" * 70)
    print("  ✅ Tests avec synonymes terminés !")
    print("=" * 70)

if __name__ == "__main__":
    main()

