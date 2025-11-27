# 📋 Plan d'Amélioration : Documentation des Scripts Shell

**Date** : 2025-11-25  
**Objectif** : Planifier l'amélioration de la documentation de tous les scripts shell

---

## ✅ Scripts Déjà Améliorés (8 scripts)

| Script | Statut | Score |
|--------|--------|-------|
| `10_setup_domirama10_setup_domirama2_poc.sh` | ✅ Amélioré | **9/10** |
| `11_load_domirama11_load_domirama2_data_parquet.sh` | ✅ Amélioré | **9/10** |
| `12_test_domirama12_test_domirama2_search.sh` | ✅ Amélioré | **9/10** |
| `13_test_domirama13_test_domirama2_api_client.sh` | ✅ Amélioré | **9/10** |
| `14_generate_parquet_from_csv.sh` | ✅ Amélioré | **9/10** |
| `25_test_hybrid_search.sh` | ✅ Amélioré | **9/10** |
| `27_export_incremental_parquet.sh` | ✅ Amélioré | **9/10** |
| `36_setup_data_api.sh` | ✅ Amélioré | **9/10** |

---

## ⚠️ Scripts à Améliorer (30 scripts)

### Priorité 1 : Scripts de Base (15-24)

| Script | Problèmes | Action Requise |
|--------|-----------|----------------|
| `15_test_fulltext_complex.sh` | ⚠️ En-tête minimal | Ajouter OBJECTIF, PRÉREQUIS, EXEMPLE |
| `16_setup_advanced_indexes.sh` | ⚠️ PRÉREQUIS peu détaillé | Détailler les prérequis Python/SAI |
| `17_test_advanced_search.sh` | ⚠️ Manque EXEMPLE | Ajouter exemple d'utilisation |
| `18_demonstration_complete.sh` | ⚠️ En-tête minimal | Enrichir avec tous les éléments |
| `19_setup_typo_tolerance.sh` | ⚠️ Documentation basique | Enrichir l'en-tête |
| `20_test_typo_tolerance.sh` | ⚠️ Documentation basique | Enrichir l'en-tête |
| `21_setup_fuzzy_search.sh` | ⚠️ PRÉREQUIS peu détaillé | Détailler les prérequis Python/transformers |
| `22_generate_embeddings.sh` | ⚠️ Documentation minimale | Enrichir avec détails techniques |
| `23_test_fuzzy_search.sh` | ⚠️ Documentation basique | Enrichir l'en-tête |
| `24_demonstration_fuzzy_search.sh` | ⚠️ Documentation basique | Enrichir l'en-tête |

### Priorité 2 : Scripts de Démonstration (26-35)

| Script | Problèmes | Action Requise |
|--------|-----------|----------------|
| `26_test_multi_version_time_travel.sh` | ⚠️ Manque PRÉREQUIS détaillés | Détailler les prérequis |
| `27_export_incremental_parquet_spark_shell.sh` | ⚠️ Manque OBJECTIF | Ajouter OBJECTIF détaillé |
| `28_demo_fenetre_glissante.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS complets |
| `28_demo_fenetre_glissante_spark_submit.sh` | ⚠️ Manque OBJECTIF | Ajouter OBJECTIF détaillé |
| `29_demo_requetes_fenetre_glissante.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS complets |
| `30_demo_requetes_startrow_stoprow.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS complets |
| `31_demo_bloomfilter_equivalent_v2.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS complets |
| `32_demo_performance_comparison.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS complets |
| `33_demo_colonnes_dynamiques_v2.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS complets |
| `34_demo_replication_scope_v2.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS complets |
| `35_demo_dsbulk_v2.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS complets |

### Priorité 3 : Scripts Data API (37-41)

| Script | Problèmes | Action Requise |
|--------|-----------|----------------|
| `37_demo_data_api.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS complets |
| `38_verifier_endpoint_data_api.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS complets |
| `39_deploy_stargate.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS Podman |
| `40_demo_data_api_complete.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS complets |
| `41_demo_complete_podman.sh` | ⚠️ Manque PRÉREQUIS | Ajouter PRÉREQUIS Podman |

### Priorité 4 : Scripts Divers

| Script | Problèmes | Action Requise |
|--------|-----------|----------------|
| `11_load_domirama11_load_domirama11_load_domirama2_data_parquet.sh` | ⚠️ Variante CSV (obsolète ?) | Améliorer ou archiver |
| `11_load_domirama2_data_fixed.sh` | ⚠️ Variante (obsolète ?) | Améliorer ou archiver |
| `demo_data_api_http.sh` | ⚠️ Manque OBJECTIF | Ajouter OBJECTIF détaillé |
| `demo_multi_version_complete_v2.sh` | ⚠️ Manque OBJECTIF | Ajouter OBJECTIF détaillé |

---

## 📋 Template Standard à Appliquer

Voir `doc/36_STANDARDS_SCRIPTS_SHELL.md` pour le template complet.

**Éléments obligatoires** :
1. ✅ **OBJECTIF** : 3-5 lignes expliquant ce que fait le script
2. ✅ **PRÉREQUIS** : Liste exhaustive des prérequis (HCD, schéma, données, dépendances)
3. ✅ **UTILISATION** : Syntaxe d'utilisation avec paramètres
4. ✅ **PARAMÈTRES** : Description de chaque paramètre (si applicable)
5. ✅ **EXEMPLE** : Exemple concret d'utilisation
6. ✅ **SORTIE** : Ce que le script produit
7. ✅ **PROCHAINES ÉTAPES** : Scripts à exécuter après

---

## 🎯 Objectif Final

**Score cible** : **9/10** pour tous les scripts

**Critères** :
- ✅ En-tête complet avec tous les éléments
- ✅ Prérequis détaillés et vérifiables
- ✅ Exemples concrets d'utilisation
- ✅ Messages d'erreur explicites avec solutions
- ✅ Compréhensible par un développeur externe

---

## 📊 Progression

- ✅ **Scripts améliorés** : 8/38 (21%)
- ⚠️ **Scripts à améliorer** : 30/38 (79%)
- 🎯 **Objectif** : 38/38 (100%)

---

**✅ Plan d'amélioration établi : 30 scripts restants à améliorer**



