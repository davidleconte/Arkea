"""
Exemple d'implémentation du fall-back libelle → libelle_prefix

Stratégie :
1. Recherche principale sur libelle (terme complet, meilleure pertinence)
2. Fall-back sur libelle_prefix si aucun résultat (recherche partielle, tolérance typos)
"""

from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
import sys

def search_with_fallback(session, code_si, contrat, search_term, limit=10):
    """
    Recherche avec fall-back libelle → libelle_prefix
    
    Args:
        session: Session Cassandra
        code_si: Code SI de la partition
        contrat: Contrat de la partition
        search_term: Terme de recherche
        limit: Nombre de résultats maximum
    
    Returns:
        Liste de résultats (tuples)
    """
    # ============================================
    # Tentative 1 : Recherche sur libelle (terme complet)
    # ============================================
    # Avantages : Meilleure pertinence (stemming, asciifolding)
    #             Performance optimale
    #             Résultats les plus précis
    query1 = f"""
        SELECT code_si, contrat, libelle, montant, cat_auto, date_op
        FROM operations_by_account
        WHERE code_si = '{code_si}'
          AND contrat = '{contrat}'
          AND libelle : '{search_term}'
        LIMIT {limit}
    """
    
    try:
        statement1 = SimpleStatement(query1)
        results1 = list(session.execute(statement1))
        
        if results1:
            print(f"✅ Recherche sur libelle : {len(results1)} résultat(s) trouvé(s)")
            return results1
    except Exception as e:
        print(f"⚠️  Erreur recherche libelle : {e}")
        # Continue avec le fall-back
    
    # ============================================
    # Fall-back : Recherche sur libelle_prefix (partielle)
    # ============================================
    # Se déclenche seulement si la recherche principale échoue
    # Avantages : Recherche partielle
    #             Tolérance aux typos
    #             Autocomplétion
    query2 = f"""
        SELECT code_si, contrat, libelle, montant, cat_auto, date_op
        FROM operations_by_account
        WHERE code_si = '{code_si}'
          AND contrat = '{contrat}'
          AND libelle_prefix : '{search_term}'
        LIMIT {limit}
    """
    
    try:
        statement2 = SimpleStatement(query2)
        results2 = list(session.execute(statement2))
        
        if results2:
            print(f"✅ Fall-back sur libelle_prefix : {len(results2)} résultat(s) trouvé(s)")
            return results2
        else:
            print(f"⚠️  Aucun résultat trouvé (ni libelle ni libelle_prefix)")
            return []
    except Exception as e:
        print(f"❌ Erreur recherche libelle_prefix : {e}")
        return []


def search_combined(session, code_si, contrat, search_term, limit=10):
    """
    Recherche combinée : libelle OU libelle_prefix
    Déduplique et trie par pertinence (libelle en premier)
    
    Args:
        session: Session Cassandra
        code_si: Code SI de la partition
        contrat: Contrat de la partition
        search_term: Terme de recherche
        limit: Nombre de résultats maximum
    
    Returns:
        Liste de résultats triés par pertinence
    """
    all_results = {}
    
    # ============================================
    # Recherche sur libelle
    # ============================================
    query1 = f"""
        SELECT code_si, contrat, libelle, montant, cat_auto, date_op
        FROM operations_by_account
        WHERE code_si = '{code_si}'
          AND contrat = '{contrat}'
          AND libelle : '{search_term}'
        LIMIT {limit * 2}
    """
    
    try:
        statement1 = SimpleStatement(query1)
        results1 = list(session.execute(statement1))
        
        # Marquer les résultats de libelle avec priorité 1 (plus pertinents)
        for result in results1:
            key = (result.code_si, result.contrat, result.date_op, result.libelle)
            if key not in all_results:
                all_results[key] = (result, 1)  # Priorité 1 = libelle
    except Exception as e:
        print(f"⚠️  Erreur recherche libelle : {e}")
    
    # ============================================
    # Recherche sur libelle_prefix
    # ============================================
    query2 = f"""
        SELECT code_si, contrat, libelle, montant, cat_auto, date_op
        FROM operations_by_account
        WHERE code_si = '{code_si}'
          AND contrat = '{contrat}'
          AND libelle_prefix : '{search_term}'
        LIMIT {limit * 2}
    """
    
    try:
        statement2 = SimpleStatement(query2)
        results2 = list(session.execute(statement2))
        
        # Ajouter les résultats de libelle_prefix avec priorité 2 (moins pertinents)
        for result in results2:
            key = (result.code_si, result.contrat, result.date_op, result.libelle)
            if key not in all_results:
                all_results[key] = (result, 2)  # Priorité 2 = libelle_prefix
    except Exception as e:
        print(f"⚠️  Erreur recherche libelle_prefix : {e}")
    
    # ============================================
    # Trier par pertinence (libelle en premier)
    # ============================================
    sorted_results = sorted(
        all_results.values(),
        key=lambda x: (x[1], x[0].date_op),  # Trier par priorité, puis date
        reverse=True
    )
    
    # Extraire uniquement les résultats (sans la priorité)
    final_results = [result for result, _ in sorted_results[:limit]]
    
    print(f"✅ Recherche combinée : {len(final_results)} résultat(s) trouvé(s)")
    return final_results


def main():
    """Exemple d'utilisation"""
    # Connexion à Cassandra
    cluster = Cluster(['localhost'])
    session = cluster.connect('domirama2_poc')
    
    code_si = '1'
    contrat = '5913101072'
    
    print("=" * 60)
    print("🔍 DÉMONSTRATION : Fall-back libelle → libelle_prefix")
    print("=" * 60)
    print()
    
    # Test 1 : Recherche terme complet (devrait trouver sur libelle)
    print("📋 Test 1 : Recherche terme complet 'virement'")
    print("-" * 60)
    results1 = search_with_fallback(session, code_si, contrat, 'virement', limit=5)
    for result in results1[:3]:
        print(f"  - {result.libelle} ({result.montant})")
    print()
    
    # Test 2 : Recherche partielle (devrait fall-back sur libelle_prefix)
    print("📋 Test 2 : Recherche partielle 'carref'")
    print("-" * 60)
    results2 = search_with_fallback(session, code_si, contrat, 'carref', limit=5)
    for result in results2[:3]:
        print(f"  - {result.libelle} ({result.montant})")
    print()
    
    # Test 3 : Recherche combinée
    print("📋 Test 3 : Recherche combinée 'loyer'")
    print("-" * 60)
    results3 = search_combined(session, code_si, contrat, 'loyer', limit=5)
    for result in results3[:3]:
        print(f"  - {result.libelle} ({result.montant})")
    print()
    
    session.shutdown()
    cluster.shutdown()


if __name__ == '__main__':
    main()


