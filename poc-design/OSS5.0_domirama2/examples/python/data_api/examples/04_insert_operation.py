#!/usr/bin/env python3
"""
Exemple 4 : Insertion d'opération via Data API
Équivalent à : INSERT INTO operations_by_account (...) VALUES (...)
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
    print("➕ Insertion d'opération via Data API")
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

    # Données d'exemple
    operation = {
        "code_si": "DEMO_API",
        "contrat": "DEMO_001",
        "date_op": datetime.now().isoformat() + "Z",
        "numero_op": 999,
        "libelle": "VIREMENT SEPA TEST DATA API",
        "montant": 1500.00,
        "devise": "EUR",
        "cat_auto": "TRANSFERT",
        "cat_confidence": 0.92,
    }

    print("📝 Insertion de l'opération :")
    for key, value in operation.items():
        print(f"   {key}: {value}")
    print()

    try:
        # Insertion
        table.insert_one(operation)
        print("✅ Opération insérée avec succès")
        print()

        # Vérification
        print("🔍 Vérification de l'insertion...")
        inserted = table.find_one(
            filter={
                "code_si": operation["code_si"],
                "contrat": operation["contrat"],
                "date_op": operation["date_op"],
                "numero_op": operation["numero_op"],
            }
        )

        if inserted:
            print("✅ Opération trouvée dans la base")
            print(f"   Libellé : {inserted.get('libelle', 'N/A')}")
            print(f"   Montant : {inserted.get('montant', 'N/A')} {inserted.get('devise', 'EUR')}")

        print("=" * 80)
        print("✅ Insertion terminée")
        print("=" * 80)

    except Exception as e:
        print(f"❌ Erreur : {e}")
        print()
        print("💡 Vérifiez que la table existe et que les colonnes sont correctes")


if __name__ == "__main__":
    main()
