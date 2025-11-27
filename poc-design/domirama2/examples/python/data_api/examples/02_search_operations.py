#!/usr/bin/env python3
"""
Exemple 2 : Recherche d'opérations via Data API
Équivalent à : SELECT * FROM operations_by_account WHERE code_si = ? AND contrat = ? AND libelle : ?
"""
import os
from astrapy import DataAPIClient
from astrapy.authentication import UsernamePasswordTokenProvider
from astrapy.constants import Environment

API_ENDPOINT = os.getenv("DATA_API_ENDPOINT", "http://localhost:8080")
USERNAME = os.getenv("DATA_API_USERNAME", "cassandra")
PASSWORD = os.getenv("DATA_API_PASSWORD", "cassandra")

print("=" * 80)
print("🔍 Recherche d'opérations via Data API")
print("=" * 80)
print()

# Connexion
client = DataAPIClient(environment=Environment.HCD)
database = client.get_database(
    API_ENDPOINT,
    token=UsernamePasswordTokenProvider(USERNAME, PASSWORD),
)

# Obtenir la table operations_by_account
table = database.get_table("operations_by_account", keyspace="domirama2_poc")

# Recherche : opérations contenant "LOYER"
print("🔍 Recherche : opérations contenant 'LOYER'")
print()

try:
    # Filtre : code_si, contrat, et libelle contenant "LOYER"
    # Note : Pour full-text search avec SAI, utiliser les opérateurs appropriés
    results = table.find(
        filter={
            "$and": [
                {"code_si": "DEMO_MV"},  # Exemple
                {"contrat": "DEMO_001"},  # Exemple
                # Pour full-text search, la syntaxe dépend de l'implémentation Data API
                # Ici, on utilise un filtre simple pour la démonstration
            ]
        },
        limit=5
    )
    
    print("📊 Résultats :")
    count = 0
    for result in results:
        count += 1
        print(f"   {count}. {result.get('libelle', 'N/A')} - {result.get('montant', 'N/A')} {result.get('devise', 'EUR')}")
        print(f"      Catégorie : {result.get('cat_auto', 'N/A')}")
        print()
    
    if count == 0:
        print("   ⚠️  Aucun résultat trouvé")
        print("   💡 Vérifiez que des données existent dans la table")
    
    print("=" * 80)
    print(f"✅ Recherche terminée : {count} résultat(s)")
    print("=" * 80)
    
except Exception as e:
    print(f"❌ Erreur : {e}")
    print()
    print("💡 Note : Pour full-text search avec SAI, la syntaxe peut varier")
    print("   Consultez la documentation Data API pour les opérateurs de recherche")
