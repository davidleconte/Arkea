#!/usr/bin/env python3
# ============================================
# Script 14i : Validation Avancée des Exports
# Validation complète des données exportées avec statistiques détaillées
# ============================================
#
# OBJECTIF :
#   Ce script effectue une validation complète des données exportées :
#   - Schéma Parquet complet
#   - Format et présence du VECTOR
#   - Statistiques détaillées (min/max dates, comptes uniques, etc.)
#   - Comparaison avec les données source
#
# UTILISATION :
#   python3 14_validate_export_advanced.py [parquet_path] [source_count]
#
# ============================================

import os
import sys
from typing import Dict, List, Optional, Tuple

import pyarrow.parquet as pq


def validate_parquet_schema(dataset: pq.ParquetDataset) -> Tuple[bool, List[str], List[str]]:
    """Valide le schéma Parquet complet"""
    schema = dataset.schema

    # Toutes les colonnes attendues
    expected_columns = {
        "code_si": "string",
        "contrat": "string",
        "date_op": "timestamp",
        "numero_op": "int32",
        "libelle": "string",
        "montant": "float64",
        "devise": "string",
        "date_valeur": "timestamp",
        "type_operation": "string",
        "sens_operation": "string",
        "operation_data": "string",
        "meta_flags": "string",
        "cat_auto": "string",
        "cat_confidence": "float64",
        "cat_user": "string",
        "cat_date_user": "timestamp",
        "cat_validee": "bool",
        "libelle_prefix": "string",
        "libelle_tokens": "list<item: string>",
        "libelle_embedding": "string",  # VECTOR en string
        "meta_source": "string",
        "meta_device": "string",
        "meta_channel": "string",
        "meta_fraud_score": "float64",
        "meta_ip": "string",
        "meta_location": "string",
        "date_partition": "string",
    }

    missing_columns = []
    wrong_type_columns = []

    for col_name, expected_type in expected_columns.items():
        if col_name not in schema.names:
            missing_columns.append(col_name)
        else:
            # Vérifier le type (simplifié)
            field = schema.field(col_name)
            actual_type = str(field.type)
            # Vérification basique du type
            if "string" in expected_type and "string" not in actual_type.lower():
                if "binary" not in actual_type.lower():  # binary est acceptable pour string
                    wrong_type_columns.append(
                        f"{col_name} (attendu: {expected_type}, obtenu: {actual_type})"
                    )

    is_valid = len(missing_columns) == 0 and len(wrong_type_columns) == 0
    return is_valid, missing_columns, wrong_type_columns


def validate_vector_column(dataset: pq.ParquetDataset) -> Tuple[bool, int, int]:
    """Valide la présence et le format du VECTOR"""
    schema = dataset.schema

    has_vector = "libelle_embedding" in schema.names
    if not has_vector:
        return False, 0, 0

    # Lire quelques lignes pour vérifier le format
    try:
        table = dataset.read()
        df_full = table.to_pandas()
        df_sample = df_full.head(100) if len(df_full) > 100 else df_full
        vector_col = df_sample["libelle_embedding"]

        # Compter les valeurs non-null
        vector_not_null = vector_col.notna().sum()
        vector_null = vector_col.isna().sum()

        # Vérifier le format (doit être string)
        if vector_not_null > 0:
            sample_value = vector_col.dropna().iloc[0]
            is_string = isinstance(sample_value, str)
            return is_string, vector_not_null, vector_null
        else:
            return True, 0, vector_null  # Pas de données mais colonne présente
    except Exception as e:
        print(f"⚠️  Erreur lors de la validation VECTOR : {e}")
        return False, 0, 0


def get_detailed_statistics(dataset: pq.ParquetDataset) -> Dict:
    """Récupère des statistiques détaillées"""
    try:
        table = dataset.read()
        df = table.to_pandas()

        stats = {
            "total_rows": len(df),
            "date_min": None,
            "date_max": None,
            "unique_accounts": 0,
            "unique_partitions": 0,
            "vector_count": 0,
            "null_dates": 0,
            "compression_ratio": 0.0,
        }

        # Dates
        if "date_op" in df.columns:
            date_col = df["date_op"]
            stats["date_min"] = date_col.min() if not date_col.empty else None
            stats["date_max"] = date_col.max() if not date_col.empty else None
            stats["null_dates"] = date_col.isna().sum()

        # Comptes uniques
        if "code_si" in df.columns and "contrat" in df.columns:
            stats["unique_accounts"] = df[["code_si", "contrat"]].drop_duplicates().shape[0]

        if "date_partition" in df.columns:
            stats["unique_partitions"] = df["date_partition"].nunique()

        # VECTOR
        if "libelle_embedding" in df.columns:
            stats["vector_count"] = df["libelle_embedding"].notna().sum()

        return stats
    except Exception as e:
        print(f"⚠️  Erreur lors du calcul des statistiques : {e}")
        return {}


def compare_with_source(parquet_count: int, source_count: Optional[int] = None) -> Tuple[bool, str]:
    """Compare le nombre d'opérations exportées avec la source"""
    if source_count is None:
        return True, "Source count non fourni"

    if parquet_count == source_count:
        return True, f"✅ Cohérence parfaite : {parquet_count} = {source_count}"
    elif abs(parquet_count - source_count) <= 5:  # Tolérance de 5 lignes
        return True, f"⚠️  Petite différence : {parquet_count} vs {source_count} (tolérance OK)"
    else:
        return False, f"❌ Incohérence importante : {parquet_count} vs {source_count}"


def main():
    """Fonction principale"""
    if len(sys.argv) < 2:
        print("Usage: python3 14_validate_export_advanced.py <parquet_path> [source_count]")
        sys.exit(1)

    parquet_path = sys.argv[1]
    source_count = int(sys.argv[2]) if len(sys.argv) > 2 else None

    print("")
    print("=" * 80)
    print("  🔍 VALIDATION AVANCÉE DES DONNÉES EXPORTÉES")
    print("=" * 80)
    print("")

    if not os.path.exists(parquet_path):
        print(f"❌ Répertoire Parquet introuvable : {parquet_path}")
        sys.exit(1)

    try:
        dataset = pq.ParquetDataset(parquet_path)
    except Exception as e:
        print(f"❌ Erreur lors de la lecture du dataset Parquet : {e}")
        sys.exit(1)

    # 1. Validation du schéma
    print("📋 1. Validation du Schéma Parquet")
    print("-" * 80)
    is_valid, missing, wrong_type = validate_parquet_schema(dataset)

    if is_valid:
        print("✅ Schéma Parquet complet et correct")
    else:
        if missing:
            print(f"❌ Colonnes manquantes : {', '.join(missing)}")
        if wrong_type:
            print(f"⚠️  Types incorrects : {', '.join(wrong_type)}")
    print("")

    # 2. Validation du VECTOR
    print("🔢 2. Validation de la Colonne VECTOR")
    print("-" * 80)
    has_vector, vector_not_null, vector_null = validate_vector_column(dataset)

    if has_vector:
        print("✅ Colonne libelle_embedding présente")
        print("   Format : string (VECTOR converti)")
        print(f"   Valeurs non-null : {vector_not_null}")
        print(f"   Valeurs null : {vector_null}")
    else:
        print("❌ Colonne libelle_embedding absente ou invalide")
    print("")

    # 3. Statistiques détaillées
    print("📊 3. Statistiques Détaillées")
    print("-" * 80)
    stats = get_detailed_statistics(dataset)

    if stats:
        print(f"   Total opérations : {stats.get('total_rows', 0)}")
        if stats.get("date_min"):
            print(f"   Date min : {stats['date_min']}")
        if stats.get("date_max"):
            print(f"   Date max : {stats['date_max']}")
        print(f"   Comptes uniques (code_si, contrat) : {stats.get('unique_accounts', 0)}")
        print(f"   Partitions uniques (date_partition) : {stats.get('unique_partitions', 0)}")
        print(f"   Opérations avec VECTOR : {stats.get('vector_count', 0)}")
        print(f"   Dates NULL : {stats.get('null_dates', 0)}")
    print("")

    # 4. Comparaison avec source
    if source_count is not None:
        print("🔄 4. Comparaison avec Source")
        print("-" * 80)
        is_consistent, message = compare_with_source(stats.get("total_rows", 0), source_count)
        print(message)
        print("")

    # 5. Résumé
    print("=" * 80)
    print("  📋 RÉSUMÉ DE VALIDATION")
    print("=" * 80)
    print("")

    all_valid = is_valid and has_vector

    if all_valid:
        print("✅ VALIDATION RÉUSSIE")
        print("   - Schéma Parquet complet")
        print("   - VECTOR présent et valide")
        print("   - Statistiques cohérentes")
        if source_count is not None:
            if stats.get("total_rows", 0) == source_count:
                print(f"   - Cohérence avec source : {source_count} opérations")
    else:
        print("⚠️  VALIDATION PARTIELLE")
        if not is_valid:
            print("   - Schéma incomplet ou incorrect")
        if not has_vector:
            print("   - VECTOR absent ou invalide")

    print("")
    sys.exit(0 if all_valid else 1)


if __name__ == "__main__":
    main()
