# 📋 Liste des Fichiers Obsolètes - domirama2/doc

**Date** : 2025-01-XX
**Objectif** : Identifier les fichiers obsolètes, redondants ou remplacés dans `domirama2/doc/`
**Statut** : ✅ **Actions terminées** - Fichiers archivés, renommés et références mises à jour

---

## 🔍 Catégories de Fichiers Obsolètes

### 1. Audits Multiples/Redondants

Ces fichiers sont des audits successifs qui se chevauchent. Le plus récent (`AUDIT_COMPLET_2025.md`) devrait être conservé comme référence principale.

| Fichier | Date | Statut | Raison |
|---------|------|--------|--------|
| `27_AUDIT_COMPLET_DOMIRAMA2.md` | 2024-11-27 | ⚠️ **OBSOLÈTE** | Audit initial, remplacé par `29_AUDIT_FINAL_DOMIRAMA2.md` |
| `29_AUDIT_FINAL_DOMIRAMA2.md` | 2024-11-27 | ⚠️ **OBSOLÈTE** | Audit final après réorganisation, remplacé par `AUDIT_COMPLET_2025.md` |
| `40_AUDIT_DOCUMENTATION_MD.md` | 2025-11-25 | ⚠️ **OBSOLÈTE** | Audit de documentation, remplacé par `41_AUDIT_MD_COMPLET.md` |
| `41_AUDIT_MD_COMPLET.md` | 2025-11-25 | ⚠️ **PARTIELLEMENT OBSOLÈTE** | Version corrigée de 40, mais `AUDIT_COMPLET_2025.md` est plus récent et complet |
| `AUDIT_COMPLET_2025.md` | 2025-01-XX | ✅ **ACTUEL** | Audit le plus récent et complet |

**Recommandation** :

- ✅ Conserver `AUDIT_COMPLET_2025.md` comme référence principale
- ⚠️ Archiver ou supprimer `27_AUDIT_COMPLET_DOMIRAMA2.md` et `29_AUDIT_FINAL_DOMIRAMA2.md` (historiques)
- ⚠️ Archiver `40_AUDIT_DOCUMENTATION_MD.md` et `41_AUDIT_MD_COMPLET.md` (spécialisés, peuvent être utiles pour référence)

---

### 2. Documents d'Organisation Redondants

| Fichier | Date | Statut | Raison |
|---------|------|--------|--------|
| `35_ORGANISATION_DOC.md` | Non daté | ⚠️ **OBSOLÈTE** | Version simplifiée, remplacée par `00_ORGANISATION_DOC.md` |
| `00_ORGANISATION_DOC.md` | 2024-11-27 | ✅ **ACTUEL** | Version complète et à jour |

**Recommandation** :

- ✅ Conserver `00_ORGANISATION_DOC.md`
- ⚠️ Supprimer `35_ORGANISATION_DOC.md` (redondant)

---

### 3. Documents de Réorganisation (Historiques)

| Fichier | Date | Statut | Raison |
|---------|------|--------|--------|
| `28_REORGANISATION_COMPLETE.md` | 2025-11-25 | ⚠️ **HISTORIQUE** | Documente une réorganisation passée, utile pour historique mais pas pour usage courant |

**Recommandation** :

- ⚠️ Conserver pour historique (documente les actions de réorganisation)
- ⚠️ Ou archiver dans un sous-répertoire `archive/` ou `historique/`

---

### 4. Documents avec Références Obsolètes

Ces documents ne sont pas obsolètes eux-mêmes, mais contiennent des références à des scripts obsolètes. Ils doivent être mis à jour.

| Fichier | Problème | Action Requise |
|---------|----------|----------------|
| `03_GAPS_ANALYSIS.md` | Références à scripts inexistants (`27_export_incremental_orc.sh`, etc.) | ⚠️ **Mettre à jour** les références |
| `04_BILAN_ECARTS_FONCTIONNELS.md` | Références à versions obsolètes de scripts (`31_demo_bloomfilter_equivalent.sh` sans `_v2`) | ⚠️ **Mettre à jour** les références |
| `14_README_BLOOMFILTER_EQUIVALENT.md` | Référence à version obsolète | ⚠️ **Mettre à jour** la référence |
| `15_README_COLONNES_DYNAMIQUES.md` | Référence à version obsolète | ⚠️ **Mettre à jour** la référence |
| `16_README_REPLICATION_SCOPE.md` | Référence à version obsolète | ⚠️ **Mettre à jour** la référence |

**Note** : Selon `41_AUDIT_MD_COMPLET.md`, ces références ont été corrigées, mais il faut vérifier.

**Recommandation** :

- ⚠️ Vérifier que toutes les références sont à jour
- ⚠️ Si corrigées, ces documents ne sont pas obsolètes

---

### 5. Documents Potentiellement Redondants

Ces documents peuvent avoir un contenu similaire ou se chevaucher. À examiner pour décider s'ils doivent être fusionnés.

| Fichier 1 | Fichier 2 | Relation | Action |
|-----------|-----------|----------|--------|
| `03_GAPS_ANALYSIS.md` | `04_BILAN_ECARTS_FONCTIONNELS.md` | Contenu similaire | ⚠️ **Examiner** pour fusion possible |
| `04_BILAN_ECARTS_FONCTIONNELS.md` | `05_AUDIT_COMPLET_GAP_FONCTIONNEL.md` | Contenu similaire | ⚠️ **Examiner** pour fusion possible |
| `44_GUIDE_AMELIORATION_SCRIPTS.md` | `44_RESUME_MISE_A_JOUR_2024_11_27.md` | Même numéro (44) | ⚠️ **Examiner** la relation |

**Recommandation** :

- ⚠️ Examiner le contenu pour déterminer s'ils doivent être fusionnés
- ⚠️ Si redondants, fusionner en un seul document
- ⚠️ Si complémentaires, clarifier les différences dans les titres

---

### 6. Documents avec Numérotation Dupliquée

| Fichier 1 | Fichier 2 | Problème | Action |
|-----------|-----------|----------|--------|
| `29_AUDIT_FINAL_DOMIRAMA2.md` | `29_README_PARQUET_10000.md` | Même numéro (29) | ⚠️ **Renommer** l'un des deux |
| `44_GUIDE_AMELIORATION_SCRIPTS.md` | `44_RESUME_MISE_A_JOUR_2024_11_27.md` | Même numéro (44) | ⚠️ **Renommer** l'un des deux |
| `72_ANALYSE_SCRIPT_27_ET_TEMPLATE.md` | `72_ANALYSE_VALEUR_AJOUTEE_SCRIPT_20.md` | Même numéro (72) | ⚠️ **Renommer** l'un des deux |
| `73_ANALYSE_SCRIPT_21_ET_TEMPLATE.md` | `73_TOMBSTONES_EXPORT_BEST_PRACTICES.md` | Même numéro (73) | ⚠️ **Renommer** l'un des deux |
| `74_ANALYSE_SCRIPT_23_ET_ENRICHISSEMENT.md` | `74_COMPACTION_PREREQUISITES.md` | Même numéro (74) | ⚠️ **Renommer** l'un des deux |
| `75_ANALYSE_SCRIPT_24_ET_ENRICHISSEMENT.md` | `75_ANALYSE_SCRIPT_28_ET_TEMPLATE.md` | Même numéro (75) | ⚠️ **Renommer** l'un des deux |
| `76_ANALYSE_COHERENCE_RESULTATS_SCRIPT_24.md` | `76_ANALYSE_COMPARATIVE_SCRIPTS_28.md` | Même numéro (76) | ⚠️ **Renommer** l'un des deux |
| `77_ANALYSE_CAUSES_INCOHERENCES.md` | `77_ANALYSE_SCRIPT_29_ET_TEMPLATE.md` | Même numéro (77) | ⚠️ **Renommer** l'un des deux |
| `78_ANALYSE_SCRIPT_25_ET_TEMPLATE.md` | `78_ANALYSE_SCRIPT_30_ET_TEMPLATE.md` | Même numéro (78) | ⚠️ **Renommer** l'un des deux |

**Recommandation** :

- ⚠️ Renommer les fichiers pour éviter les conflits de numérotation
- ⚠️ Utiliser des numéros séquentiels uniques

---

## 📊 Résumé des Actions Recommandées

### Priorité 1 : Supprimer/Archiver (Vraiment Obsolètes)

1. ✅ **`35_ORGANISATION_DOC.md`** - Supprimer (remplacé par `00_ORGANISATION_DOC.md`)
2. ⚠️ **`27_AUDIT_COMPLET_DOMIRAMA2.md`** - Archiver (remplacé par `29_AUDIT_FINAL_DOMIRAMA2.md`)
3. ⚠️ **`29_AUDIT_FINAL_DOMIRAMA2.md`** - Archiver (remplacé par `AUDIT_COMPLET_2025.md`)
4. ⚠️ **`40_AUDIT_DOCUMENTATION_MD.md`** - Archiver (remplacé par `41_AUDIT_MD_COMPLET.md`)

### Priorité 2 : Renommer (Conflits de Numérotation)

1. ⚠️ Renommer les fichiers avec numérotation dupliquée (voir section 6)
2. ⚠️ Utiliser une numérotation séquentielle unique

### Priorité 3 : Mettre à Jour (Références Obsolètes)

1. ⚠️ Vérifier et mettre à jour les références dans :
   - `03_GAPS_ANALYSIS.md`
   - `04_BILAN_ECARTS_FONCTIONNELS.md`
   - `14_README_BLOOMFILTER_EQUIVALENT.md`
   - `15_README_COLONNES_DYNAMIQUES.md`
   - `16_README_REPLICATION_SCOPE.md`

### Priorité 4 : Examiner (Potentiellement Redondants)

1. ⚠️ Examiner les documents avec contenu similaire pour décider de fusionner ou clarifier

---

## 📁 Structure Recommandée pour Archive

Si vous créez un répertoire `archive/` dans `doc/` :

```
doc/
├── archive/
│   ├── audits/
│   │   ├── 27_AUDIT_COMPLET_DOMIRAMA2.md
│   │   ├── 29_AUDIT_FINAL_DOMIRAMA2.md
│   │   ├── 40_AUDIT_DOCUMENTATION_MD.md
│   │   └── 41_AUDIT_MD_COMPLET.md
│   ├── historique/
│   │   └── 28_REORGANISATION_COMPLETE.md
│   └── obsolètes/
│       └── 35_ORGANISATION_DOC.md
```

---

## ✅ Fichiers à Conserver (Non Obsolètes)

Les fichiers suivants sont **actuels** et doivent être **conservés** :

- ✅ `00_ORGANISATION_DOC.md` - Guide de lecture actuel
- ✅ `01_README.md` - Vue d'ensemble principale
- ✅ `AUDIT_COMPLET_2025.md` - Audit le plus récent
- ✅ Tous les autres fichiers numérotés (sauf ceux listés ci-dessus)
- ✅ Tous les fichiers dans `demonstrations/` et `templates/`

---

## 🎯 Actions Immédiates

1. **Créer un répertoire `archive/`** dans `doc/` si nécessaire
2. **Déplacer les fichiers obsolètes** vers `archive/`
3. **Renommer les fichiers** avec numérotation dupliquée
4. **Vérifier les références** dans les documents restants
5. **Mettre à jour cette liste** après les actions

---

**✅ Liste créée le 2025-01-XX**
