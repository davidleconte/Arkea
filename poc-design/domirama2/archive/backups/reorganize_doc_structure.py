#!/usr/bin/env python3
"""
Script de réorganisation de la documentation domirama2
Déplace les fichiers .md vers les catégories appropriées
"""

import os
import shutil
from pathlib import Path

# Configuration
BASE_DIR = Path(__file__).parent
DOC_DIR = BASE_DIR / "doc"

# Mapping des fichiers vers les catégories
MAPPING = {
    "design": [
        "02_VALUE_PROPOSITION_DOMIRAMA2.md",
        "03_GAPS_ANALYSIS.md",
        "04_BILAN_ECARTS_FONCTIONNELS.md",
        "05_AUDIT_COMPLET_GAP_FONCTIONNEL.md",
        "24_PARQUET_VS_ORC_ANALYSIS.md",
        "25_ANALYSE_DEPENDANCES_POC2.md",
        "26_ANALYSE_MIGRATION_CSV_PARQUET.md",
        "43_SYNTHESE_COMPLETE_ANALYSE_2024.md",
        "57_POURQUOI_PAS_NGRAM_SUR_LIBELLE.md",
        "58_ANALYSE_TEST_20_LIBELLE_PREFIX.md",
        "59_ANALYSE_TESTS_4_15_18.md",
        "60_ANALYSE_FALLBACK_LIBELLE_PREFIX.md",
        "61_ANALYSE_LIBELLE_TOKENS_COLLECTION.md",
        "83_README_PARQUET_10000.md",
        "84_RESUME_MISE_A_JOUR_2024_11_27.md",
    ],
    "guides": [
        "01_README.md",
        "06_README_INDEX_AVANCES.md",
        "07_README_FUZZY_SEARCH.md",
        "08_README_HYBRID_SEARCH.md",
        "09_README_MULTI_VERSION.md",
        "11_README_EXPORT_INCREMENTAL.md",
        "12_README_EXPORT_SPARK_SUBMIT.md",
        "13_README_REQUETES_TIMERANGE_STARTROW.md",
        "14_README_BLOOMFILTER_EQUIVALENT.md",
        "15_README_COLONNES_DYNAMIQUES.md",
        "16_README_REPLICATION_SCOPE.md",
        "17_README_DSBULK.md",
        "18_README_DATA_API.md",
        "30_README_STARGATE.md",
        "34_GUIDE_DEPLOIEMENT_DATA_API_POC.md",
    ],
    "implementation": [
        "10_TIME_TRAVEL_IMPLEMENTATION.md",
        "19_VALEUR_AJOUTEE_DATA_API.md",
        "20_IMPLEMENTATION_OFFICIELLE_DATA_API.md",
        "21_STATUT_DATA_API.md",
        "31_CLARIFICATION_DATA_API.md",
        "32_CONFORMITE_DATA_API_HCD.md",
        "33_PREUVE_CRUD_DATA_API.md",
        "81_AMELIORATIONS_PERTINENCE_IMPLENTEES.md",
    ],
    "results": [
        "22_DEMONSTRATION_RESUME.md",
        "23_DEMONSTRATION_VALIDATION.md",
        "42_DEMONSTRATION_COMPLETE_DOMIRAMA.md",
    ],
    "corrections": [
        "44_GUIDE_AMELIORATION_SCRIPTS.md",
        "45_GUIDE_GENERALISATION_CAPTURE_RESULTATS.md",
        "46_RESUME_GENERALISATION_CAPTURE.md",
        "69_AMELIORATION_SCRIPTS_16_17_18.md",
        "70_AMELIORATIONS_SCRIPTS_B19SH.md",
    ],
    "audits": [
        "AUDIT_COMPLET_2025.md",
        "AUDIT_SCRIPTS_SHELL_2025.md",
        "36_STANDARDS_SCRIPTS_SHELL.md",
        "37_AUDIT_DOCUMENTATION_SCRIPTS.md",
        "38_PLAN_AMELIORATION_SCRIPTS.md",
        "39_STANDARDS_FICHIERS_CQL.md",
        "48_ANALYSE_SCRIPT_10_ET_TEMPLATE.md",
        "49_ANALYSE_SCRIPT_11_ET_TEMPLATE.md",
        "51_ANALYSE_SCRIPT_11_PARQUET_ET_TEMPLATE.md",
        "52_ANALYSE_SCRIPT_11_DATA_SH.md",
        "53_ANALYSE_SCRIPT_12_ET_TEMPLATE.md",
        "54_ANALYSE_SCRIPT_13_ET_TEMPLATE.md",
        "55_ANALYSE_SCRIPT_15_ET_TEMPLATE.md",
        "56_ANALYSE_SCRIPT_17_ET_TEMPLATE.md",
        "62_ANALYSE_SCRIPT_18_ET_TEMPLATE.md",
        "64_ANALYSE_COMPARATIVE_SCRIPT_17_VS_18.md",
        "65_ENRICHISSEMENT_SCRIPT_18.md",
        "66_ANALYSE_SCRIPT_19.md",
        "68_ANALYSE_VALEUR_AJOUTEE_SCRIPT_19.md",
        "71_ANALYSE_SCRIPT_20_ET_TEMPLATE.md",
        "72_ANALYSE_SCRIPT_27_ET_TEMPLATE.md",
        "73_ANALYSE_SCRIPT_21_ET_TEMPLATE.md",
        "74_ANALYSE_SCRIPT_23_ET_ENRICHISSEMENT.md",
        "75_ANALYSE_SCRIPT_24_ET_ENRICHISSEMENT.md",
        "76_ANALYSE_COHERENCE_RESULTATS_SCRIPT_24.md",
        "77_ANALYSE_CAUSES_INCOHERENCES.md",
        "78_ANALYSE_SCRIPT_25_ET_TEMPLATE.md",
        "79_PROPOSITION_CAS_COMPLEXES_RECHERCHE_HYBRIDE.md",
        "80_PROPOSITION_AMELIORATION_PERTINENCE.md",
        "82_ANALYSE_SCRIPT_26_ET_TEMPLATE.md",
        "85_ANALYSE_VALEUR_AJOUTEE_SCRIPT_20.md",
        "86_TOMBSTONES_EXPORT_BEST_PRACTICES.md",
        "87_COMPACTION_PREREQUISITES.md",
        "88_ANALYSE_SCRIPT_28_ET_TEMPLATE.md",
        "89_ANALYSE_COMPARATIVE_SCRIPTS_28.md",
        "90_ANALYSE_SCRIPT_29_ET_TEMPLATE.md",
        "91_ANALYSE_SCRIPT_30_ET_TEMPLATE.md",
    ],
}

# Fichiers à conserver à la racine
KEEP_AT_ROOT = [
    "00_ORGANISATION_DOC.md",
    "LISTE_FICHIERS_OBSOLETES.md",
    "RESUME_MIGRATION_SCRIPTS_2025.md",
    "VALIDATION_MIGRATION_SCRIPTS.md",
    "ANALYSE_STRUCTURE_DOMIRAMACATOPS.md",
    "PLAN_REORGANISATION_STRUCTURE.md",
]


def main():
    """Déplace les fichiers selon le mapping"""
    moved = 0
    not_found = []

    print("🔄 Réorganisation de la documentation...")
    print()

    for category, files in MAPPING.items():
        category_dir = DOC_DIR / category
        category_dir.mkdir(exist_ok=True)

        print(f"📁 {category}/ ({len(files)} fichiers)")

        for filename in files:
            source = DOC_DIR / filename
            dest = category_dir / filename

            if source.exists():
                shutil.move(str(source), str(dest))
                print(f"  ✅ {filename}")
                moved += 1
            else:
                print(f"  ⚠️  {filename} (non trouvé)")
                not_found.append(filename)

    print()
    print(f"✅ {moved} fichiers déplacés")

    if not_found:
        print(f"⚠️  {len(not_found)} fichiers non trouvés:")
        for f in not_found:
            print(f"   - {f}")

    print()
    print("📋 Fichiers conservés à la racine:")
    for f in KEEP_AT_ROOT:
        if (DOC_DIR / f).exists():
            print(f"  ✅ {f}")
        else:
            print(f"  ⚠️  {f} (non trouvé)")


if __name__ == "__main__":
    main()
