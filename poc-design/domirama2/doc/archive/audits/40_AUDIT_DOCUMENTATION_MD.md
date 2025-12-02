# 🔍 Audit : Documentation MD vs Scripts/CQL

**Date** : 2025-11-25  
**Objectif** : Vérifier que tous les fichiers MD sont à jour avec les scripts *.sh et *.cql

---

## 📊 Résultats de l'Audit

### Problèmes Identifiés

#### 1. Références à des Scripts Inexistants ou Obsolètes

| Fichier MD | Script Référencé | Problème | Solution |
|------------|------------------|----------|----------|
| `01_README.md` | `03_start_hcd.sh` | Script à la racine, pas dans domirama2 | Corriger la référence |
| `01_README.md` | `11_load_domirama11_load_domirama11_load_domirama2_data_parquet.sh` | Existe mais `11_load_domirama11_load_domirama2_data_parquet.sh` est recommandé | Mettre à jour |
| `03_GAPS_ANALYSIS.md` | `27_export_incremental_orc.sh` | N'existe pas (Parquet utilisé) | Supprimer ou corriger |
| `03_GAPS_ANALYSIS.md` | `29_demo_dsbulk_import.sh` | N'existe pas | Corriger vers `35_demo_dsbulk_v2.sh` |
| `03_GAPS_ANALYSIS.md` | `30_comparaison_dsbulk_vs_spark.sh` | N'existe pas | Supprimer |
| `04_BILAN_ECARTS_FONCTIONNELS.md` | `31_demo_bloomfilter_equivalent.sh` | Version obsolète | Corriger vers `31_demo_bloomfilter_equivalent_v2.sh` |
| `04_BILAN_ECARTS_FONCTIONNELS.md` | `32_demo_colonnes_dynamiques.sh` | Version obsolète | Corriger vers `33_demo_colonnes_dynamiques_v2.sh` |
| `04_BILAN_ECARTS_FONCTIONNELS.md` | `33_demo_dsbulk_bulkload.sh` | N'existe pas | Corriger vers `35_demo_dsbulk_v2.sh` |
| `14_README_BLOOMFILTER_EQUIVALENT.md` | `31_demo_bloomfilter_equivalent.sh` | Version obsolète | Corriger vers `31_demo_bloomfilter_equivalent_v2.sh` |
| `15_README_COLONNES_DYNAMIQUES.md` | `33_demo_colonnes_dynamiques.sh` | Version obsolète | Corriger vers `33_demo_colonnes_dynamiques_v2.sh` |
| `16_README_REPLICATION_SCOPE.md` | `34_demo_replication_scope.sh` | Version obsolète | Corriger vers `34_demo_replication_scope_v2.sh` |

#### 2. Références à des Fichiers CQL avec Anciens Chemins

| Fichier MD | Fichier CQL Référencé | Problème | Solution |
|------------|----------------------|----------|----------|
| `01_README.md` | `schemas/01_create_domirama2_schema.cql` | Ancien chemin | Corriger vers `schemas/01_create_domirama2_schema.cql` |
| `01_README.md` | `schemas/04_domirama2_search_test.cql` | Ancien chemin | Corriger vers `schemas/04_domirama2_search_test.cql` |
| `01_README.md` | `schemas/08_domirama2_api_correction_client.cql` | Ancien chemin | Corriger vers `schemas/08_domirama2_api_correction_client.cql` |
| `27_AUDIT_COMPLET_DOMIRAMA2.md` | `schemas/01_create_domirama2_schema.cql` | Ancien chemin | Corriger vers `schemas/01_create_domirama2_schema.cql` |
| `28_REORGANISATION_COMPLETE.md` | `schemas/01_create_domirama2_schema.cql` | Ancien chemin | Corriger vers `schemas/01_create_domirama2_schema.cql` |

#### 3. Références à des Scripts avec Noms Incomplets

| Fichier MD | Script Référencé | Problème | Solution |
|------------|------------------|----------|----------|
| `01_README.md` | `13_test_domirama2_api_client.sh` | Nom incomplet | Corriger vers `13_test_domirama13_test_domirama2_api_client.sh` |
| `01_README.md` | `11_load_domirama11_load_domirama2_data_parquet.sh` | Nom incomplet | Corriger vers `11_load_domirama11_load_domirama2_data_parquet.sh` |
| `01_README.md` | `10_setup_domirama2_poc.sh` | Nom incomplet | Corriger vers `10_setup_domirama10_setup_domirama2_poc.sh` |
| `01_README.md` | `12_test_domirama2_search.sh` | Nom incomplet | Corriger vers `12_test_domirama12_test_domirama2_search.sh` |
| `05_AUDIT_COMPLET_GAP_FONCTIONNEL.md` | `11_load_domirama2_data_parquet.sh` | Nom incomplet | Corriger vers `11_load_domirama11_load_domirama2_data_parquet.sh` |
| `05_AUDIT_COMPLET_GAP_FONCTIONNEL.md` | `10_setup_domirama2_poc.sh` | Nom incomplet | Corriger vers `10_setup_domirama10_setup_domirama2_poc.sh` |
| `05_AUDIT_COMPLET_GAP_FONCTIONNEL.md` | `12_test_domirama2_search.sh` | Nom incomplet | Corriger vers `12_test_domirama12_test_domirama2_search.sh` |
| `17_README_DSBULK.md` | `11_load_domirama2_data_parquet.sh` | Nom incomplet | Corriger vers `11_load_domirama11_load_domirama2_data_parquet.sh` |

---

## 📋 Plan de Correction

### Phase 1 : Correction des Références de Scripts

1. **Scripts avec versions obsolètes** : Remplacer toutes les références `*_demo_*.sh` (sans `_v2`) par `*_demo_*_v2.sh`
2. **Scripts inexistants** : Supprimer ou corriger les références
3. **Noms incomplets** : Compléter les noms de scripts

### Phase 2 : Correction des Références de Fichiers CQL

1. **Anciens chemins** : Remplacer tous les chemins relatifs par `schemas/XX_*.cql`
2. **Anciens noms** : Remplacer les noms sans préfixe numérique par les noms numérotés

### Phase 3 : Vérification des Scripts

1. **Scripts critiques** : Vérifier que les scripts 10-13 fonctionnent
2. **Scripts de démonstration** : Vérifier que les scripts 27-41 fonctionnent

---

## ✅ Actions à Effectuer

### Fichiers MD à Corriger (Priorité Haute)

1. ✅ `01_README.md` - Références multiples à corriger
2. ✅ `03_GAPS_ANALYSIS.md` - Scripts obsolètes
3. ✅ `04_BILAN_ECARTS_FONCTIONNELS.md` - Versions obsolètes
4. ✅ `05_AUDIT_COMPLET_GAP_FONCTIONNEL.md` - Noms incomplets
5. ✅ `14_README_BLOOMFILTER_EQUIVALENT.md` - Version obsolète
6. ✅ `15_README_COLONNES_DYNAMIQUES.md` - Version obsolète
7. ✅ `16_README_REPLICATION_SCOPE.md` - Version obsolète
8. ✅ `17_README_DSBULK.md` - Nom incomplet
9. ✅ `27_AUDIT_COMPLET_DOMIRAMA2.md` - Chemins CQL obsolètes
10. ✅ `28_REORGANISATION_COMPLETE.md` - Chemins CQL obsolètes

---

## 🎯 Objectif

**Mettre à jour tous les fichiers MD pour refléter :**
- ✅ Les nouveaux chemins (`schemas/`, `examples/`)
- ✅ Les noms numérotés des fichiers CQL (`01_*.cql`, `02_*.cql`, etc.)
- ✅ Les versions `_v2` des scripts de démonstration
- ✅ Les noms complets des scripts (avec préfixes numériques)

---

**✅ Audit terminé : 10 fichiers MD à corriger**





