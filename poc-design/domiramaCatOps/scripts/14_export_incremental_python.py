#!/usr/bin/env python3
# ============================================
# Script 14f : Export Incrémental Parquet (Version Python)
# Exporte les données depuis HCD vers Parquet en itérant sur les partitions
# Alternative à DSBulk pour éviter les problèmes avec les requêtes WHERE
# ============================================
#
# OBJECTIF :
#   Ce script exporte les données depuis HCD vers Parquet en utilisant
#   le driver Python Cassandra pour itérer sur les partitions.
#   Cette approche évite les problèmes avec DSBulk et les requêtes WHERE.
#
# UTILISATION :
#   python3 14_export_incremental_python.py [start_date] [end_date]
#       [output_path] [compression] [code_si] [contrat]
#
# PARAMÈTRES :
#   start_date : Date de début (format: YYYY-MM-DD, optionnel, défaut: 2024-06-01)
#   end_date : Date de fin (format: YYYY-MM-DD, optionnel, défaut: 2024-07-01)
#   output_path : Chemin de sortie (optionnel,
#       défaut: /tmp/exports/domiramaCatOps/incremental_python)
#   compression : Compression (optionnel, défaut: snappy)
#   code_si : Code SI pour filtrage (optionnel, si non fourni, itère sur tous)
#   contrat : Contrat pour filtrage (optionnel, si non fourni, itère sur tous)
#
# ============================================

import argparse
import os
import sys
from datetime import datetime
from typing import List, Optional, Tuple

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from cassandra.cluster import Cluster
from cassandra.query import SimpleStatement


def parse_args():
    """Parse les arguments de ligne de commande"""
    parser = argparse.ArgumentParser(description="Export incrémental Parquet depuis HCD")
    parser.add_argument(
        "start_date", nargs="?", default="2024-06-01", help="Date de début (YYYY-MM-DD)"
    )
    parser.add_argument(
        "end_date", nargs="?", default="2024-07-01", help="Date de fin (YYYY-MM-DD)"
    )
    parser.add_argument(
        "output_path",
        nargs="?",
        default="/tmp/exports/domiramaCatOps/incremental_python",
        help="Chemin de sortie",
    )
    parser.add_argument(
        "compression", nargs="?", default="snappy", help="Compression (snappy, gzip, lz4)"
    )
    parser.add_argument(
        "code_si", nargs="?", default=None, help="Code SI pour filtrage (optionnel)"
    )
    parser.add_argument(
        "contrat", nargs="?", default=None, help="Contrat pour filtrage (optionnel)"
    )
    return parser.parse_args()


def connect_to_hcd(host="localhost", port=9042):
    """Connexion à HCD"""
    try:
        cluster = Cluster([host], port=port)
        session = cluster.connect()
        return cluster, session
    except Exception as e:
        print(f"❌ Erreur de connexion à HCD : {e}")
        sys.exit(1)


def get_partitions(
    session, code_si_filter: Optional[str] = None, contrat_filter: Optional[str] = None
) -> List[Tuple[str, str]]:
    """Récupère la liste des partitions (code_si, contrat)"""
    partitions = []

    try:
        if code_si_filter and contrat_filter:
            # Partition spécifique
            partitions = [(code_si_filter, contrat_filter)]
        elif code_si_filter:
            # Tous les contrats pour ce code_si
            query = (
                f"SELECT DISTINCT code_si, contrat FROM "
                f"domiramacatops_poc.operations_by_account "
                f"WHERE code_si = '{code_si_filter}' ALLOW FILTERING"
            )
            result = session.execute(query)
            partitions = [(row.code_si, row.contrat) for row in result]
        else:
            # Toutes les partitions (peut être lent)
            query = (
                "SELECT DISTINCT code_si, contrat FROM "
                "domiramacatops_poc.operations_by_account ALLOW FILTERING"
            )
            result = session.execute(query)
            partitions = [(row.code_si, row.contrat) for row in result]

        return partitions
    except Exception as e:
        print(f"⚠️  Erreur lors de la récupération des partitions : {e}")
        print("   Utilisation de partitions par défaut (TEST_EXPORT, TEST_CONTRAT)")
        return [("TEST_EXPORT", "TEST_CONTRAT")]


def export_partition(
    session, code_si: str, contrat: str, start_date: str, end_date: str
) -> pd.DataFrame:
    """Exporte une partition spécifique"""
    # Convertir les dates en timestamps
    start_dt = datetime.strptime(start_date, "%Y-%m-%d")
    end_dt = datetime.strptime(end_date, "%Y-%m-%d")
    start_ts = int(start_dt.timestamp() * 1000)
    end_ts = int(end_dt.timestamp() * 1000)

    # Requête CQL sans ALLOW FILTERING (utilise les partition keys)
    query = f"""
    SELECT code_si, contrat, date_op, numero_op, libelle, montant, devise,
           date_valeur, type_operation, sens_operation, operation_data,
           meta_flags, cat_auto, cat_confidence, cat_user, cat_date_user,
           cat_validee, libelle_prefix, libelle_tokens, libelle_embedding,
           meta_source, meta_device, meta_channel, meta_fraud_score, meta_ip,
           meta_location
    FROM domiramacatops_poc.operations_by_account
    WHERE code_si = '{code_si}' AND contrat = '{contrat}'
      AND date_op >= {start_ts} AND date_op < {end_ts}
    """

    try:
        statement = SimpleStatement(query, fetch_size=1000)
        result = session.execute(statement)

        # Convertir en liste de dictionnaires
        rows = []
        for row in result:
            row_dict = {
                "code_si": row.code_si,
                "contrat": row.contrat,
                "date_op": row.date_op,
                "numero_op": row.numero_op,
                "libelle": row.libelle,
                "montant": float(row.montant) if row.montant else None,
                "devise": row.devise,
                "date_valeur": row.date_valeur,
                "type_operation": row.type_operation,
                "sens_operation": row.sens_operation,
                "operation_data": row.operation_data.hex() if row.operation_data else None,
                "meta_flags": str(row.meta_flags) if row.meta_flags else None,
                "cat_auto": row.cat_auto,
                "cat_confidence": float(row.cat_confidence) if row.cat_confidence else None,
                "cat_user": row.cat_user,
                "cat_date_user": row.cat_date_user,
                "cat_validee": bool(row.cat_validee) if row.cat_validee is not None else None,
                "libelle_prefix": row.libelle_prefix,
                "libelle_tokens": list(row.libelle_tokens) if row.libelle_tokens else None,
                "libelle_embedding": (
                    str(row.libelle_embedding) if row.libelle_embedding else None
                ),  # VECTOR en string
                "meta_source": row.meta_source,
                "meta_device": row.meta_device,
                "meta_channel": row.meta_channel,
                "meta_fraud_score": float(row.meta_fraud_score) if row.meta_fraud_score else None,
                "meta_ip": row.meta_ip,
                "meta_location": row.meta_location,
            }
            rows.append(row_dict)

        if not rows:
            return pd.DataFrame()

        # Convertir en DataFrame
        df = pd.DataFrame(rows)

        # Convertir date_op en datetime si nécessaire
        if "date_op" in df.columns:
            df["date_op"] = pd.to_datetime(df["date_op"])

        # Créer colonne date_partition
        if "date_op" in df.columns:
            df["date_partition"] = df["date_op"].dt.strftime("%Y-%m-%d")
        else:
            df["date_partition"] = "unknown"

        return df
    except Exception as e:
        print(f"⚠️  Erreur lors de l'export de la partition ({code_si}, {contrat}) : {e}")
        return pd.DataFrame()


def export_to_parquet(df: pd.DataFrame, output_path: str, compression: str):
    """Exporte le DataFrame vers Parquet"""
    if df.empty:
        print("⚠️  Aucune donnée à exporter")
        return

    # Nettoyer le répertoire de sortie s'il existe déjà
    if os.path.exists(output_path):
        import shutil

        shutil.rmtree(output_path)
        print(f"🗑️  Répertoire de sortie nettoyé : {output_path}")

    os.makedirs(output_path, exist_ok=True)

    # Définir le schéma Parquet
    schema = pa.schema(
        [
            pa.field("code_si", pa.string()),
            pa.field("contrat", pa.string()),
            pa.field("date_op", pa.timestamp("ns")),
            pa.field("numero_op", pa.int32()),
            pa.field("libelle", pa.string()),
            pa.field("montant", pa.float64()),
            pa.field("devise", pa.string()),
            pa.field("date_valeur", pa.timestamp("ns")),
            pa.field("type_operation", pa.string()),
            pa.field("sens_operation", pa.string()),
            pa.field("operation_data", pa.string()),
            pa.field("meta_flags", pa.string()),
            pa.field("cat_auto", pa.string()),
            pa.field("cat_confidence", pa.float64()),
            pa.field("cat_user", pa.string()),
            pa.field("cat_date_user", pa.timestamp("ns")),
            pa.field("cat_validee", pa.bool_()),
            pa.field("libelle_prefix", pa.string()),
            pa.field("libelle_tokens", pa.list_(pa.string())),
            pa.field("libelle_embedding", pa.string()),  # VECTOR en string
            pa.field("meta_source", pa.string()),
            pa.field("meta_device", pa.string()),
            pa.field("meta_channel", pa.string()),
            pa.field("meta_fraud_score", pa.float64()),
            pa.field("meta_ip", pa.string()),
            pa.field("meta_location", pa.string()),
            pa.field("date_partition", pa.string()),
        ]
    )

    # Convertir en Table PyArrow
    table = pa.Table.from_pandas(df, schema=schema)

    # Écrire en Parquet avec partitionnement
    pq.write_to_dataset(
        table,
        root_path=output_path,
        partition_cols=["date_partition"],
        compression=compression,
        use_dictionary=True,
    )

    print(f"✅ {len(df)} opérations exportées vers {output_path}")


def main():
    """Fonction principale"""
    args = parse_args()

    print("")
    print("=" * 80)
    print("  🎯 Export Incrémental Parquet (Version Python)")
    print("=" * 80)
    print("")
    print(f"📅 Période : {args.start_date} → {args.end_date}")
    print(f"📁 Output : {args.output_path}")
    print(f"🗜️  Compression : {args.compression}")
    if args.code_si:
        print(f"🔍 Filtrage : code_si = {args.code_si}, contrat = {args.contrat or 'tous'}")
    else:
        print("🔍 Filtrage : toutes les partitions")
    print("")

    # Connexion à HCD
    print("🔌 Connexion à HCD...")
    cluster, session = connect_to_hcd()
    session.set_keyspace("domiramacatops_poc")
    print("✅ Connecté à HCD")
    print("")

    # Récupérer les partitions
    print("📊 Récupération des partitions...")
    partitions = get_partitions(session, args.code_si, args.contrat)
    print(f"✅ {len(partitions)} partition(s) trouvée(s)")
    print("")

    # Exporter chaque partition
    all_dataframes = []
    total_operations = 0

    for i, (code_si, contrat) in enumerate(partitions, 1):
        print(f"📦 Export partition {i}/{len(partitions)} : code_si={code_si}, contrat={contrat}")
        df = export_partition(session, code_si, contrat, args.start_date, args.end_date)

        if not df.empty:
            all_dataframes.append(df)
            total_operations += len(df)
            print(f"   ✅ {len(df)} opérations exportées")
        else:
            print("   ⚠️  Aucune opération trouvée")
        print("")

    # Combiner tous les DataFrames
    if all_dataframes:
        print("🔄 Combinaison des données...")
        combined_df = pd.concat(all_dataframes, ignore_index=True)

        # Dédupliquer les opérations (basé sur code_si, contrat, date_op, numero_op)
        initial_count = len(combined_df)

        # S'assurer que date_op est en datetime pour la comparaison
        if "date_op" in combined_df.columns:
            combined_df["date_op"] = pd.to_datetime(combined_df["date_op"])

        # Dédupliquer
        combined_df = combined_df.drop_duplicates(
            subset=["code_si", "contrat", "date_op", "numero_op"], keep="first"
        )
        duplicates_removed = initial_count - len(combined_df)

        if duplicates_removed > 0:
            print(f"⚠️  {duplicates_removed} doublon(s) supprimé(s)")

        print(f"✅ {len(combined_df)} opérations au total (après déduplication)")
        print("")

        # Export vers Parquet
        print("💾 Export vers Parquet...")
        export_to_parquet(combined_df, args.output_path, args.compression)
        print("")

        # Statistiques
        print("📊 Statistiques :")
        print(f"   Total opérations : {len(combined_df)}")
        if "date_op" in combined_df.columns:
            print(f"   Date min : {combined_df['date_op'].min()}")
            print(f"   Date max : {combined_df['date_op'].max()}")
        if "date_partition" in combined_df.columns:
            partitions_count = combined_df["date_partition"].nunique()
            print(f"   Partitions créées : {partitions_count}")
        print("")

        print("✅ Export terminé avec succès !")
    else:
        print("⚠️  Aucune donnée à exporter")

    # Fermer la connexion
    cluster.shutdown()
    print("")
    print("=" * 80)


if __name__ == "__main__":
    main()
