#!/usr/bin/env python3
"""
Tests avec filtres temporels combinés pour la recherche vectorielle.
Teste la recherche vectorielle + filtres sur date_op, montant, catégorie.
"""

import sys
import json
from datetime import datetime, timedelta
from cassandra.query import SimpleStatement
from test_vector_search_base import (
    load_model, encode_text,
    connect_to_hcd, get_test_account, KEYSPACE
)

def vector_search_with_filters(session, query_embedding, code_si: str, contrat: str,
                                date_start=None, date_end=None,
                                montant_min=None, montant_max=None,
                                categorie=None, limit: int = 5):
    """Recherche vectorielle avec filtres additionnels.
    
    Note: HCD nécessite que les colonnes filtrées soient indexées avec SAI
    ou qu'on utilise une approche en deux étapes pour les filtres temporels.
    """
    # Approche en deux étapes pour les filtres temporels :
    # 1. D'abord récupérer les résultats vectoriels
    # 2. Ensuite filtrer côté client par date/montant/catégorie
    
    # Étape 1 : Recherche vectorielle (sans filtres additionnels)
    # On récupère plus de résultats pour compenser le filtrage client
    cql_query = f"""
    SELECT libelle, montant, cat_auto, date_op, libelle_embedding
    FROM {KEYSPACE}.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
    ORDER BY libelle_embedding ANN OF {json.dumps(query_embedding)}
    LIMIT {limit * 10}
    """
    
    try:
        statement = SimpleStatement(cql_query)
        all_results = list(session.execute(statement))
        
        # Étape 2 : Filtrer côté client
        filtered_results = []
        for row in all_results:
            # Filtre date
            if date_start and date_end:
                if not hasattr(row, 'date_op') or not row.date_op:
                    continue
                # Gérer différents formats de date_op (timestamp en ms ou datetime)
                if isinstance(row.date_op, datetime):
                    row_date = row.date_op
                elif isinstance(row.date_op, (int, float)):
                    # Timestamp en millisecondes
                    row_date = datetime.fromtimestamp(row.date_op / 1000)
                else:
                    continue
                if row_date < date_start or row_date >= date_end:
                    continue
            
            # Filtre montant
            if montant_min is not None:
                if not hasattr(row, 'montant') or not row.montant:
                    continue
                if row.montant < montant_min:
                    continue
            
            if montant_max is not None:
                if not hasattr(row, 'montant') or not row.montant:
                    continue
                if row.montant > montant_max:
                    continue
            
            # Filtre catégorie
            if categorie:
                if not hasattr(row, 'cat_auto') or not row.cat_auto:
                    continue
                if row.cat_auto != categorie:
                    continue
            
            filtered_results.append(row)
            if len(filtered_results) >= limit:
                break
        
        return filtered_results
    except Exception as e:
        print(f"   ❌ Erreur: {str(e)}")
        return []

def main():
    """Fonction principale."""
    print("=" * 70)
    print("  📅 Tests avec Filtres Temporels Combinés - Recherche Vectorielle")
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
    
    query = "LOYER IMPAYE"
    query_embedding = encode_text(tokenizer, model, query)
    
    # Test 1 : Vector seul
    print("🔍 Test 1 : Recherche vectorielle seule")
    print("-" * 70)
    results = vector_search_with_filters(session, query_embedding, code_si, contrat, limit=5)
    print(f"   {len(results)} résultat(s)")
    for i, row in enumerate(results[:3], 1):
        libelle = row.libelle[:40] if row.libelle else "N/A"
        print(f"   {i}. {libelle}")
    print()
    
    # Test 2 : Vector + Filtre temporel (30 derniers jours)
    print("🔍 Test 2 : Vector + Filtre temporel (30 derniers jours)")
    print("-" * 70)
    date_end = datetime.now()
    date_start = date_end - timedelta(days=30)
    results = vector_search_with_filters(session, query_embedding, code_si, contrat,
                                         date_start=date_start, date_end=date_end, limit=5)
    print(f"   Période : {date_start.strftime('%Y-%m-%d')} à {date_end.strftime('%Y-%m-%d')}")
    print(f"   {len(results)} résultat(s)")
    for i, row in enumerate(results[:3], 1):
        libelle = row.libelle[:40] if row.libelle else "N/A"
        date_op = datetime.fromtimestamp(row.date_op / 1000) if hasattr(row, 'date_op') and row.date_op else None
        date_str = date_op.strftime('%Y-%m-%d') if date_op else "N/A"
        print(f"   {i}. {libelle} | {date_str}")
    print()
    
    # Test 3 : Vector + Filtre montant
    print("🔍 Test 3 : Vector + Filtre montant (>= 100)")
    print("-" * 70)
    results = vector_search_with_filters(session, query_embedding, code_si, contrat,
                                         montant_min=100, limit=5)
    print(f"   {len(results)} résultat(s)")
    for i, row in enumerate(results[:3], 1):
        libelle = row.libelle[:40] if row.libelle else "N/A"
        montant = row.montant if hasattr(row, 'montant') and row.montant else "N/A"
        print(f"   {i}. {libelle} | {montant}")
    print()
    
    # Test 4 : Vector + Filtre catégorie
    print("🔍 Test 4 : Vector + Filtre catégorie")
    print("-" * 70)
    results = vector_search_with_filters(session, query_embedding, code_si, contrat,
                                         categorie="HABITATION", limit=5)
    print(f"   Catégorie : HABITATION")
    print(f"   {len(results)} résultat(s)")
    for i, row in enumerate(results[:3], 1):
        libelle = row.libelle[:40] if row.libelle else "N/A"
        cat = row.cat_auto if hasattr(row, 'cat_auto') and row.cat_auto else "N/A"
        print(f"   {i}. {libelle} | {cat}")
    print()
    
    session.shutdown()
    cluster.shutdown()
    
    print("=" * 70)
    print("  ✅ Tests avec filtres temporels terminés !")
    print("=" * 70)

if __name__ == "__main__":
    main()

