#!/usr/bin/env python3
"""
Tests avec accents et diacritiques pour la recherche vectorielle.
Vérifie la robustesse aux accents (é, è, ê, î, etc.).
"""

import sys
from test_vector_search_base import (
    load_model, encode_text, vector_search,
    connect_to_hcd, get_test_account
)

def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🔤 Tests avec Accents/Diacritiques - Recherche Vectorielle")
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
    
    # Tests avec/sans accents
    test_cases = [
        ("PAIEMENT CAFE", "PAIEMENT CAFÉ", "accent aigu"),
        ("RESTAURANT PARIS", "RESTAURANT PARÎS", "accent circonflexe"),
        ("VIREMENT COMPTE", "VIREMENT COMPTÉ", "accent aigu final"),
        ("LOYER PAYE", "LOYER PAYÉ", "accent aigu"),
        ("CARTE CREDIT", "CARTE CRÉDIT", "accent aigu"),
    ]
    
    print("=" * 70)
    print("  📊 Résultats des Tests")
    print("=" * 70)
    print()
    
    for query_no_accent, query_with_accent, description in test_cases:
        print(f"🔍 Test : {description}")
        print(f"   Sans accent : '{query_no_accent}'")
        print(f"   Avec accent : '{query_with_accent}'")
        print()
        
        # Recherche sans accent
        embedding_no_accent = encode_text(tokenizer, model, query_no_accent)
        results_no_accent = vector_search(session, embedding_no_accent, code_si, contrat, limit=3)
        
        # Recherche avec accent
        embedding_with_accent = encode_text(tokenizer, model, query_with_accent)
        results_with_accent = vector_search(session, embedding_with_accent, code_si, contrat, limit=3)
        
        print(f"   📊 Sans accent : {len(results_no_accent)} résultat(s)")
        for i, row in enumerate(results_no_accent[:2], 1):
            libelle = row.libelle[:40] if row.libelle else "N/A"
            print(f"      {i}. {libelle}")
        print()
        
        print(f"   📊 Avec accent : {len(results_with_accent)} résultat(s)")
        for i, row in enumerate(results_with_accent[:2], 1):
            libelle = row.libelle[:40] if row.libelle else "N/A"
            print(f"      {i}. {libelle}")
        print()
        
        # Comparaison
        if len(results_no_accent) > 0 and len(results_with_accent) > 0:
            print("   ✅ Les deux variantes retournent des résultats")
        elif len(results_no_accent) == 0 and len(results_with_accent) == 0:
            print("   ⚠️  Aucun résultat pour les deux variantes")
        else:
            print("   ⚠️  Différence entre les deux variantes")
        print()
        print("-" * 70)
        print()
    
    session.shutdown()
    cluster.shutdown()
    
    print("=" * 70)
    print("  ✅ Tests avec accents terminés !")
    print("=" * 70)

if __name__ == "__main__":
    main()

