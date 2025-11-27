#!/usr/bin/env python3
"""
Exemple 1 : Connexion à HCD via Data API
Conforme au quickstart officiel : https://docs.datastax.com/en/hyper-converged-database/1.2/api-reference/quickstart.html
"""
import os
from astrapy import DataAPIClient
from astrapy.authentication import UsernamePasswordTokenProvider
from astrapy.constants import Environment

# Configuration depuis variables d'environnement
# Note : Pour POC local, utiliser DATA_API_ENDPOINT (fallback)
# Pour production Kubernetes, utiliser API_ENDPOINT (conforme quickstart)
API_ENDPOINT = os.getenv("API_ENDPOINT") or os.getenv("DATA_API_ENDPOINT", "http://localhost:8080")
USERNAME = os.getenv("USERNAME") or os.getenv("DATA_API_USERNAME", "cassandra")
PASSWORD = os.getenv("PASSWORD") or os.getenv("DATA_API_PASSWORD", "cassandra")

print("=" * 80)
print("🔌 Connexion à HCD via Data API")
print("=" * 80)
print()

# 1. Instancier le client
print("📦 Instanciation du client Data API...")
client = DataAPIClient(environment=Environment.HCD)
print("✅ Client créé")

# 2. Se connecter à la base de données
print(f"🔗 Connexion à la base : {API_ENDPOINT}")
try:
    database = client.get_database(
        API_ENDPOINT,
        token=UsernamePasswordTokenProvider(USERNAME, PASSWORD),
    )
    print("✅ Connexion réussie")
    print()
    
    # 3. Lister les keyspaces disponibles
    print("📋 Keyspaces disponibles :")
    admin = database.get_admin()
    keyspaces = admin.list_keyspaces()
    for ks in keyspaces:
        print(f"   - {ks}")
    print()
    
    print("=" * 80)
    print("✅ Connexion Data API réussie !")
    print("=" * 80)
    
except Exception as e:
    print(f"❌ Erreur de connexion : {e}")
    print()
    print("💡 Vérifiez que :")
    print("   1. HCD est démarré")
    print("   2. La Data API (Stargate) est configurée et accessible")
    print("   3. L'endpoint est correct (http://CLUSTER_HOST:GATEWAY_PORT)")
    exit(1)
