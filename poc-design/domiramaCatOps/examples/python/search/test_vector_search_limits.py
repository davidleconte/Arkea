#!/usr/bin/env python3
"""
Tests de limites pour la recherche vectorielle.
Teste les cas limites : requêtes vides, très longues, très courtes, etc.
"""

import sys
from test_vector_search_base import (
    load_model, encode_text, vector_search,
    connect_to_hcd, get_test_account
)

def test_limit_values(session, tokenizer, model, code_si: str, contrat: str):
    """Teste différentes valeurs de LIMIT."""
    print("🔢 Test 1 : Valeurs de LIMIT")
    print("-" * 70)
    
    query = "LOYER IMPAYE"
    query_embedding = encode_text(tokenizer, model, query)
    
    limits = [1, 5, 10, 50, 100]
    for limit in limits:
        results = vector_search(session, query_embedding, code_si, contrat, limit=limit)
        print(f"   LIMIT {limit:3d} : {len(results)} résultat(s)")
    print()

def test_empty_query(session, tokenizer, model, code_si: str, contrat: str):
    """Teste une requête vide."""
    print("🔢 Test 2 : Requête vide")
    print("-" * 70)
    
    try:
        query_embedding = encode_text(tokenizer, model, "")
        results = vector_search(session, query_embedding, code_si, contrat, limit=5)
        print(f"   ✅ Requête vide gérée : {len(results)} résultat(s)")
    except Exception as e:
        print(f"   ❌ Erreur avec requête vide : {e}")
    print()

def test_very_long_query(session, tokenizer, model, code_si: str, contrat: str):
    """Teste une requête très longue."""
    print("🔢 Test 3 : Requête très longue (500+ caractères)")
    print("-" * 70)
    
    long_query = "LOYER IMPAYE " * 50  # ~650 caractères
    try:
        query_embedding = encode_text(tokenizer, model, long_query)
        results = vector_search(session, query_embedding, code_si, contrat, limit=5)
        print(f"   ✅ Requête longue gérée : {len(results)} résultat(s)")
    except Exception as e:
        print(f"   ❌ Erreur avec requête longue : {e}")
    print()

def test_very_short_query(session, tokenizer, model, code_si: str, contrat: str):
    """Teste une requête très courte."""
    print("🔢 Test 4 : Requête très courte (1 caractère)")
    print("-" * 70)
    
    short_queries = ["L", "P", "V", "C"]
    for query in short_queries:
        try:
            query_embedding = encode_text(tokenizer, model, query)
            results = vector_search(session, query_embedding, code_si, contrat, limit=5)
            print(f"   Requête '{query}' : {len(results)} résultat(s)")
        except Exception as e:
            print(f"   ❌ Erreur avec requête '{query}' : {e}")
    print()

def test_query_with_numbers(session, tokenizer, model, code_si: str, contrat: str):
    """Teste des requêtes avec chiffres."""
    print("🔢 Test 5 : Requêtes avec chiffres")
    print("-" * 70)
    
    queries_with_numbers = [
        "CB 1234",
        "PAIEMENT 50",
        "VIREMENT 1000",
        "LOYER 500"
    ]
    
    for query in queries_with_numbers:
        try:
            query_embedding = encode_text(tokenizer, model, query)
            results = vector_search(session, query_embedding, code_si, contrat, limit=5)
            print(f"   Requête '{query}' : {len(results)} résultat(s)")
        except Exception as e:
            print(f"   ❌ Erreur avec requête '{query}' : {e}")
    print()

def test_query_with_special_chars(session, tokenizer, model, code_si: str, contrat: str):
    """Teste des requêtes avec caractères spéciaux."""
    print("🔢 Test 6 : Requêtes avec caractères spéciaux")
    print("-" * 70)
    
    queries_special = [
        "PAIEMENT #123",
        "VIREMENT-URGENT",
        "LOYER (IMPAYE)",
        "CB*1234"
    ]
    
    for query in queries_special:
        try:
            query_embedding = encode_text(tokenizer, model, query)
            results = vector_search(session, query_embedding, code_si, contrat, limit=5)
            print(f"   Requête '{query}' : {len(results)} résultat(s)")
        except Exception as e:
            print(f"   ❌ Erreur avec requête '{query}' : {e}")
    print()

def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🔢 Tests de Limites - Recherche Vectorielle")
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
    
    # Exécuter tous les tests
    test_limit_values(session, tokenizer, model, code_si, contrat)
    test_empty_query(session, tokenizer, model, code_si, contrat)
    test_very_long_query(session, tokenizer, model, code_si, contrat)
    test_very_short_query(session, tokenizer, model, code_si, contrat)
    test_query_with_numbers(session, tokenizer, model, code_si, contrat)
    test_query_with_special_chars(session, tokenizer, model, code_si, contrat)
    
    session.shutdown()
    cluster.shutdown()
    
    print("=" * 70)
    print("  ✅ Tests de limites terminés !")
    print("=" * 70)

if __name__ == "__main__":
    main()

