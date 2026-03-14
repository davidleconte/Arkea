#!/usr/bin/env python3
"""
Tests de robustesse pour la recherche vectorielle.
Teste la gestion des requêtes malformées, NULL, injection SQL, etc.
"""


from test_vector_search_base import (
    connect_to_hcd,
    encode_text,
    get_test_account,
    load_model,
    vector_search,
)


def test_null_query(session, tokenizer, model, code_si: str, contrat: str):
    """Teste une requête NULL."""
    print("🛡️  Test 1 : Requête NULL")
    print("-" * 70)

    try:
        query_embedding = encode_text(tokenizer, model, None)
        results = vector_search(session, query_embedding, code_si, contrat, limit=5)
        print(f"   ✅ Requête NULL gérée : {len(results)} résultat(s)")
    except Exception as e:
        print(f"   ⚠️  Erreur avec requête NULL : {e}")
    print()


def test_sql_injection(session, tokenizer, model, code_si: str, contrat: str):
    """Teste la protection contre l'injection SQL."""
    print("🛡️  Test 2 : Protection injection SQL")
    print("-" * 70)

    malicious_queries = [
        "'; DROP TABLE operations_by_account; --",
        "' OR '1'='1",
        "'; SELECT * FROM operations_by_account; --",
    ]

    for query in malicious_queries:
        try:
            query_embedding = encode_text(tokenizer, model, query)
            results = vector_search(session, query_embedding, code_si, contrat, limit=5)
            print(
                f"   ✅ Requête malveillante '{query[:30]}...' gérée : {len(results)} résultat(s)"
            )
        except Exception as e:
            print(f"   ⚠️  Erreur avec requête malveillante : {e}")
    print()


def test_unicode_chars(session, tokenizer, model, code_si: str, contrat: str):
    """Teste des requêtes avec caractères Unicode."""
    print("🛡️  Test 3 : Caractères Unicode")
    print("-" * 70)

    unicode_queries = ["PAIEMENT CAFÉ", "RESTAURANT PARÎS", "VIREMENT COMPTÉ", "LOYER PAYÉ"]

    for query in unicode_queries:
        try:
            query_embedding = encode_text(tokenizer, model, query)
            results = vector_search(session, query_embedding, code_si, contrat, limit=5)
            print(f"   Requête '{query}' : {len(results)} résultat(s)")
        except Exception as e:
            print(f"   ❌ Erreur avec requête '{query}' : {e}")
    print()


def test_multiple_spaces(session, tokenizer, model, code_si: str, contrat: str):
    """Teste des requêtes avec espaces multiples."""
    print("🛡️  Test 4 : Espaces multiples")
    print("-" * 70)

    queries_spaces = ["LOYER   IMPAYE", "PAIEMENT    CARTE", "  VIREMENT  ", "CB   1234"]

    for query in queries_spaces:
        try:
            query_embedding = encode_text(tokenizer, model, query)
            results = vector_search(session, query_embedding, code_si, contrat, limit=5)
            print(f"   Requête '{query}' : {len(results)} résultat(s)")
        except Exception as e:
            print(f"   ❌ Erreur avec requête '{query}' : {e}")
    print()


def test_emoji(session, tokenizer, model, code_si: str, contrat: str):
    """Teste des requêtes avec emojis."""
    print("🛡️  Test 5 : Emojis")
    print("-" * 70)

    emoji_queries = ["PAIEMENT 😊", "VIREMENT ✅", "LOYER 💰"]

    for query in emoji_queries:
        try:
            query_embedding = encode_text(tokenizer, model, query)
            results = vector_search(session, query_embedding, code_si, contrat, limit=5)
            print(f"   Requête '{query}' : {len(results)} résultat(s)")
        except Exception as e:
            print(f"   ⚠️  Erreur avec requête '{query}' : {e}")
    print()


def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🛡️  Tests de Robustesse - Recherche Vectorielle")
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
    test_null_query(session, tokenizer, model, code_si, contrat)
    test_sql_injection(session, tokenizer, model, code_si, contrat)
    test_unicode_chars(session, tokenizer, model, code_si, contrat)
    test_multiple_spaces(session, tokenizer, model, code_si, contrat)
    test_emoji(session, tokenizer, model, code_si, contrat)

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Tests de robustesse terminés !")
    print("=" * 70)


if __name__ == "__main__":
    main()
