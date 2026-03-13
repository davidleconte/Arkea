#!/usr/bin/env python3
"""
Exemple 3 : Mise à jour de catégorie client via Data API
Équivalent à : UPDATE operations_by_account SET cat_user = ?, cat_date_user = now() WHERE ...
"""
import os
from datetime import datetime

from astrapy import DataAPIClient
from astrapy.authentication import UsernamePasswordTokenProvider
from astrapy.constants import Environment

API_ENDPOINT = os.getenv("DATA_API_ENDPOINT", "http://localhost:8080")
USERNAME = os.getenv("DATA_API_USERNAME", "cassandra")
PASSWORD = os.getenv("DATA_API_PASSWORD", "cassandra")


def main() -> None:
    """Point d'entrée principal."""
    print("=" * 80)
    print("✏️  Mise à jour de catégorie client via Data API")
    print("=" * 80)
    print()

    # Connexion
    client = DataAPIClient(environment=Environment.HCD)
    database = client.get_database(
        API_ENDPOINT,
        token=UsernamePasswordTokenProvider(USERNAME, PASSWORD),
    )

    # Obtenir la table
    table = database.get_table("operations_by_account", keyspace="domirama2_poc")

    # Exemple : Mise à jour d'une opération
    code_si = "DEMO_MV"
    contrat = "DEMO_001"
    date_op = "2024-01-15T10:00:00Z"  # Format ISO
    numero_op = 1
    new_category = "LOISIRS"  # Catégorie corrigée par le client

    print("📝 Mise à jour de la catégorie pour :")
    print(f"   Code SI : {code_si}")
    print(f"   Contrat : {contrat}")
    print(f"   Date Op : {date_op}")
    print(f"   Numéro Op : {numero_op}")
    print(f"   Nouvelle catégorie : {new_category}")
    print()

    try:
        # Mise à jour avec primary key
        # Note : La syntaxe exacte dépend de l'implémentation Data API
        # Ici, on utilise une mise à jour par primary key
        table.update_one(
            filter={
                "code_si": code_si,
                "contrat": contrat,
                "date_op": date_op,
                "numero_op": numero_op,
            },
            update={
                "$set": {
                    "cat_user": new_category,
                    "cat_date_user": datetime.now().isoformat() + "Z",
                }
            },
        )

        print("✅ Catégorie mise à jour avec succès")
        print()

        # Vérification : lire l'opération mise à jour
        print("🔍 Vérification de la mise à jour...")
        updated = table.find_one(
            filter={
                "code_si": code_si,
                "contrat": contrat,
                "date_op": date_op,
                "numero_op": numero_op,
            }
        )

        if updated:
            print(f"   Catégorie auto : {updated.get('cat_auto', 'N/A')}")
            print(f"   Catégorie user : {updated.get('cat_user', 'N/A')}")
            print(f"   Date user : {updated.get('cat_date_user', 'N/A')}")

        print("=" * 80)
        print("✅ Mise à jour terminée")
        print("=" * 80)

    except Exception as e:
        print(f"❌ Erreur : {e}")
        print()
        print("💡 Note : La syntaxe exacte peut varier selon la version de l'API")
        print("   Consultez la documentation Data API pour les opérations UPDATE")


if __name__ == "__main__":
    main()
