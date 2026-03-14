#!/usr/bin/env python3
"""
Script pour générer les embeddings e5-large pour les opérations existantes.
Génère les embeddings et les met à jour dans HCD.
"""

import sys

from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement

try:
    from sentence_transformers import SentenceTransformer

    SENTENCE_TRANSFORMERS_AVAILABLE = True
except ImportError:
    SENTENCE_TRANSFORMERS_AVAILABLE = False
    print("❌ sentence-transformers n'est pas installé")
    print("   Installation : pip install sentence-transformers")
    sys.exit(1)

from test_vector_search_base_e5 import KEYSPACE, load_model_e5, encode_text_e5


def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🔄 Génération des Embeddings e5-large")
    print("=" * 70)
    print()

    # Charger le modèle
    model = load_model_e5()
    print()

    # Connexion HCD
    print("📡 Connexion à HCD...")
    cluster = Cluster(["localhost"])
    session = cluster.connect(KEYSPACE)
    print("✅ Connecté à HCD")
    print()

    # Récupérer toutes les opérations
    print("📊 Récupération des opérations...")
    query = f"""
    SELECT code_si, contrat, date_op, numero_op, libelle
    FROM {KEYSPACE}.operations_by_account
    LIMIT 1000
    """

    statement = SimpleStatement(query)
    all_rows = list(session.execute(statement))

    # Filtrer côté client pour ne garder que celles avec libelle
    rows = [row for row in all_rows if row.libelle and row.libelle.strip()]
    print(f"✅ {len(rows)} opérations avec libellé récupérées (sur {len(all_rows)} total)")
    print()

    # Préparer la requête de mise à jour
    update_query = f"""
    UPDATE {KEYSPACE}.operations_by_account
    SET libelle_embedding_e5 = ?
    WHERE code_si = ? AND contrat = ? AND date_op = ? AND numero_op = ?
    """
    prepared = session.prepare(update_query)

    # Générer les embeddings
    print("🔄 Génération des embeddings...")
    updated = 0
    errors = 0

    for i, row in enumerate(rows, 1):
        if not row.libelle:
            continue

        try:
            # Générer l'embedding e5-large
            embedding = encode_text_e5(model, row.libelle)

            # Mettre à jour dans HCD
            session.execute(
                prepared, (embedding, row.code_si, row.contrat, row.date_op, row.numero_op)
            )

            updated += 1
            if updated % 50 == 0:
                print(f"   {updated}/{len(rows)} embeddings générés...")
        except Exception as e:
            errors += 1
            if errors <= 5:  # Afficher seulement les 5 premières erreurs
                print(f"   ⚠️  Erreur pour '{row.libelle[:40]}': {str(e)[:100]}")

    print()
    print(f"✅ {updated} embeddings générés avec succès")
    if errors > 0:
        print(f"⚠️  {errors} erreurs rencontrées")
    print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Génération terminée !")
    print("=" * 70)


if __name__ == "__main__":
    main()
