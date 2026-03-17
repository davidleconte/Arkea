#!/usr/bin/env python3
"""
Script pour générer les embeddings spécialisés facturation pour les opérations existantes.
Génère les embeddings et les met à jour dans HCD.
"""

from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement
from test_vector_search_base_invoice import KEYSPACE, encode_text_invoice, load_model_invoice


def main():
    """Fonction principale."""
    print("=" * 70)
    print("  🔄 Génération des Embeddings Facturation")
    print("=" * 70)
    print()

    # Charger le modèle
    model = load_model_invoice()
    print()

    # Connexion HCD
    print("📡 Connexion à HCD...")
    cluster = Cluster(["localhost"])
    session = cluster.connect(KEYSPACE)
    print("✅ Connecté à HCD")
    print()

    # Récupérer toutes les opérations
    print("📊 Récupération des opérations...")
    query = """
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

    # Générer les embeddings
    print("🔄 Génération des embeddings...")
    update_query = """
    UPDATE {KEYSPACE}.operations_by_account
    SET libelle_embedding_invoice = ?
    WHERE code_si = ? AND contrat = ? AND date_op = ? AND numero_op = ?
    """

    prepared = session.prepare(update_query)
    batch_size = 50
    total = len(rows)

    for i, row in enumerate(rows, 1):
        try:
            # Générer l'embedding
            embedding = encode_text_invoice(model, row.libelle)

            # Mettre à jour dans HCD
            session.execute(
                prepared, (embedding.tolist(), row.code_si, row.contrat, row.date_op, row.numero_op)
            )

            if i % batch_size == 0:
                print(f"   {i}/{total} embeddings générés...")
        except Exception as e:
            print(f"   ⚠️  Erreur pour opération {row.code_si}/{row.contrat}/{row.numero_op}: {e}")
            continue

    print(f"✅ {total} embeddings générés avec succès")
    print()

    session.shutdown()
    cluster.shutdown()

    print("=" * 70)
    print("  ✅ Génération terminée !")
    print("=" * 70)


if __name__ == "__main__":
    main()
