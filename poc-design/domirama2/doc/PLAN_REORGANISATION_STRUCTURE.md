# 📋 Plan d'Action : Réorganisation de la Structure domirama2

**Date** : 2025-01-XX  
**Objectif** : Mettre en œuvre la structure organisée de `domiramaCatOps` pour `domirama2`  
**Référence** : `ANALYSE_STRUCTURE_DOMIRAMACATOPS.md`

---

## 🎯 Objectif Final

Réorganiser `domirama2` pour avoir la même structure claire et organisée que `domiramaCatOps` :

```
domirama2/
├── README.md
├── .poc-config.sh
├── doc/
│   ├── INDEX.md                    # Index de navigation
│   ├── 00_ORGANISATION_DOC.md      # Guide de lecture
│   ├── design/                     # Design et architecture
│   ├── guides/                     # Guides et références
│   ├── implementation/             # Implémentations
│   ├── results/                    # Résultats de tests
│   ├── corrections/                # Corrections appliquées
│   ├── audits/                     # Audits et analyses
│   ├── demonstrations/             # Rapports auto-générés
│   ├── templates/                  # Templates réutilisables
│   └── archive/                    # Archives
├── schemas/                        # Schémas CQL
├── scripts/                        # Scripts shell (nouveau)
├── examples/                        # Exemples
├── data/                           # Données de test
└── utils/                          # Utilitaires
```

---

## 📊 État Actuel vs État Cible

### Documentation (`doc/`)

| État Actuel | État Cible |
|-------------|------------|
| 88 fichiers .md à la racine | Organisés en 7 catégories |
| Pas d'INDEX.md | INDEX.md pour navigation |
| Navigation difficile | Navigation intuitive |

### Scripts

| État Actuel | État Cible |
|-------------|------------|
| 61 scripts .sh à la racine | Tous dans `scripts/` |
| Dispersés | Centralisés |

---

## 📝 Plan d'Action Détaillé

### Phase 1 : Préparation (15 min)

#### 1.1 Créer les répertoires de catégories

```bash
cd /Users/david.leconte/Documents/Arkea/poc-design/domirama2/doc
mkdir -p design guides implementation results corrections audits
```

#### 1.2 Créer le répertoire scripts

```bash
cd /Users/david.leconte/Documents/Arkea/poc-design/domirama2
mkdir -p scripts
```

---

### Phase 2 : Catégorisation de la Documentation (30 min)

#### 2.1 Mapping des fichiers vers les catégories

**design/** (~15 fichiers) :
- `02_VALUE_PROPOSITION_DOMIRAMA2.md`
- `03_GAPS_ANALYSIS.md`
- `04_BILAN_ECARTS_FONCTIONNELS.md`
- `05_AUDIT_COMPLET_GAP_FONCTIONNEL.md`
- `24_PARQUET_VS_ORC_ANALYSIS.md`
- `25_ANALYSE_DEPENDANCES_POC2.md`
- `26_ANALYSE_MIGRATION_CSV_PARQUET.md`
- `43_SYNTHESE_COMPLETE_ANALYSE_2024.md`
- `57_POURQUOI_PAS_NGRAM_SUR_LIBELLE.md`
- `58_ANALYSE_TEST_20_LIBELLE_PREFIX.md`
- `59_ANALYSE_TESTS_4_15_18.md`
- `60_ANALYSE_FALLBACK_LIBELLE_PREFIX.md`
- `61_ANALYSE_LIBELLE_TOKENS_COLLECTION.md`
- `83_README_PARQUET_10000.md`
- `84_RESUME_MISE_A_JOUR_2024_11_27.md`

**guides/** (~10 fichiers) :
- `01_README.md`
- `06_README_INDEX_AVANCES.md`
- `07_README_FUZZY_SEARCH.md`
- `08_README_HYBRID_SEARCH.md`
- `09_README_MULTI_VERSION.md`
- `11_README_EXPORT_INCREMENTAL.md`
- `12_README_EXPORT_SPARK_SUBMIT.md`
- `13_README_REQUETES_TIMERANGE_STARTROW.md`
- `14_README_BLOOMFILTER_EQUIVALENT.md`
- `15_README_COLONNES_DYNAMIQUES.md`
- `16_README_REPLICATION_SCOPE.md`
- `17_README_DSBULK.md`
- `18_README_DATA_API.md`
- `30_README_STARGATE.md`
- `34_GUIDE_DEPLOIEMENT_DATA_API_POC.md`

**implementation/** (~8 fichiers) :
- `10_TIME_TRAVEL_IMPLEMENTATION.md`
- `19_VALEUR_AJOUTEE_DATA_API.md`
- `20_IMPLEMENTATION_OFFICIELLE_DATA_API.md`
- `21_STATUT_DATA_API.md`
- `31_CLARIFICATION_DATA_API.md`
- `32_CONFORMITE_DATA_API_HCD.md`
- `33_PREUVE_CRUD_DATA_API.md`
- `81_AMELIORATIONS_PERTINENCE_IMPLENTEES.md`

**results/** (~3 fichiers) :
- `22_DEMONSTRATION_RESUME.md`
- `23_DEMONSTRATION_VALIDATION.md`
- `42_DEMONSTRATION_COMPLETE_DOMIRAMA.md`

**corrections/** (~5 fichiers) :
- `44_GUIDE_AMELIORATION_SCRIPTS.md`
- `45_GUIDE_GENERALISATION_CAPTURE_RESULTATS.md`
- `46_RESUME_GENERALISATION_CAPTURE.md`
- `69_AMELIORATION_SCRIPTS_16_17_18.md`
- `70_AMELIORATIONS_SCRIPTS_B19SH.md`

**audits/** (~35 fichiers) :
- `AUDIT_COMPLET_2025.md`
- `AUDIT_SCRIPTS_SHELL_2025.md`
- `36_STANDARDS_SCRIPTS_SHELL.md`
- `37_AUDIT_DOCUMENTATION_SCRIPTS.md`
- `38_PLAN_AMELIORATION_SCRIPTS.md`
- `39_STANDARDS_FICHIERS_CQL.md`
- `48_ANALYSE_SCRIPT_10_ET_TEMPLATE.md`
- `49_ANALYSE_SCRIPT_11_ET_TEMPLATE.md`
- `51_ANALYSE_SCRIPT_11_PARQUET_ET_TEMPLATE.md`
- `52_ANALYSE_SCRIPT_11_DATA_SH.md`
- `53_ANALYSE_SCRIPT_12_ET_TEMPLATE.md`
- `54_ANALYSE_SCRIPT_13_ET_TEMPLATE.md`
- `55_ANALYSE_SCRIPT_15_ET_TEMPLATE.md`
- `56_ANALYSE_SCRIPT_17_ET_TEMPLATE.md`
- `62_ANALYSE_SCRIPT_18_ET_TEMPLATE.md`
- `64_ANALYSE_COMPARATIVE_SCRIPT_17_VS_18.md`
- `65_ENRICHISSEMENT_SCRIPT_18.md`
- `66_ANALYSE_SCRIPT_19.md`
- `68_ANALYSE_VALEUR_AJOUTEE_SCRIPT_19.md`
- `71_ANALYSE_SCRIPT_20_ET_TEMPLATE.md`
- `72_ANALYSE_SCRIPT_27_ET_TEMPLATE.md`
- `73_ANALYSE_SCRIPT_21_ET_TEMPLATE.md`
- `74_ANALYSE_SCRIPT_23_ET_ENRICHISSEMENT.md`
- `75_ANALYSE_SCRIPT_24_ET_ENRICHISSEMENT.md`
- `76_ANALYSE_COHERENCE_RESULTATS_SCRIPT_24.md`
- `77_ANALYSE_CAUSES_INCOHERENCES.md`
- `78_ANALYSE_SCRIPT_25_ET_TEMPLATE.md`
- `79_PROPOSITION_CAS_COMPLEXES_RECHERCHE_HYBRIDE.md`
- `80_PROPOSITION_AMELIORATION_PERTINENCE.md`
- `82_ANALYSE_SCRIPT_26_ET_TEMPLATE.md`
- `85_ANALYSE_VALEUR_AJOUTEE_SCRIPT_20.md`
- `86_TOMBSTONES_EXPORT_BEST_PRACTICES.md`
- `87_COMPACTION_PREREQUISITES.md`
- `88_ANALYSE_SCRIPT_28_ET_TEMPLATE.md`
- `89_ANALYSE_COMPARATIVE_SCRIPTS_28.md`
- `90_ANALYSE_SCRIPT_29_ET_TEMPLATE.md`
- `91_ANALYSE_SCRIPT_30_ET_TEMPLATE.md`

**Fichiers à conserver à la racine** :
- `00_ORGANISATION_DOC.md`
- `LISTE_FICHIERS_OBSOLETES.md`
- `RESUME_MIGRATION_SCRIPTS_2025.md`
- `VALIDATION_MIGRATION_SCRIPTS.md`
- `ANALYSE_STRUCTURE_DOMIRAMACATOPS.md` (ce fichier)
- `PLAN_REORGANISATION_STRUCTURE.md` (ce fichier)

---

### Phase 3 : Déplacement des Scripts (10 min)

#### 3.1 Déplacer tous les scripts .sh vers scripts/

```bash
cd /Users/david.leconte/Documents/Arkea/poc-design/domirama2
# Déplacer tous les scripts .sh (sauf ceux dans archive/)
mv *.sh scripts/ 2>/dev/null || true
```

**Exceptions** :
- Scripts dans `archive/` : Ne pas déplacer
- Scripts utilitaires (migrate_scripts.sh, etc.) : Peuvent rester à la racine ou aller dans `scripts/utils/`

---

### Phase 4 : Création de l'INDEX.md (20 min)

#### 4.1 Créer INDEX.md similaire à domiramaCatOps

Voir le modèle dans `domiramaCatOps/doc/INDEX.md`

---

### Phase 5 : Mise à Jour des Liens (30 min)

#### 5.1 Script de mise à jour automatique

Créer un script Python pour :
- Détecter tous les liens dans les fichiers .md
- Mettre à jour les chemins relatifs
- Générer un rapport des changements

---

### Phase 6 : Mise à Jour de la Documentation (15 min)

#### 6.1 Mettre à jour 00_ORGANISATION_DOC.md

- Refléter la nouvelle structure
- Mettre à jour les chemins
- Ajouter référence à INDEX.md

#### 6.2 Mettre à jour README.md principal

- Refléter la nouvelle structure
- Mettre à jour les chemins vers les scripts

---

### Phase 7 : Validation (15 min)

#### 7.1 Vérifications

- [ ] Tous les fichiers déplacés
- [ ] Tous les liens mis à jour
- [ ] INDEX.md créé et fonctionnel
- [ ] README.md mis à jour
- [ ] Structure cohérente avec domiramaCatOps

---

## 🛠️ Scripts d'Automatisation

### Script 1 : Création des répertoires

```bash
#!/bin/bash
# create_structure.sh

cd /Users/david.leconte/Documents/Arkea/poc-design/domirama2

# Créer les répertoires de catégories
mkdir -p doc/{design,guides,implementation,results,corrections,audits}

# Créer le répertoire scripts
mkdir -p scripts

echo "✅ Structure créée"
```

### Script 2 : Déplacement des fichiers (à créer)

Un script Python serait plus adapté pour :
- Catégoriser automatiquement les fichiers
- Déplacer les fichiers
- Mettre à jour les liens

---

## ⚠️ Points d'Attention

1. **Préserver la numérotation** : Garder les préfixes numériques dans les noms de fichiers
2. **Liens croisés** : Tous les liens doivent être mis à jour
3. **Scripts** : Les scripts qui référencent `doc/` doivent être mis à jour
4. **Backup** : Créer un backup avant de commencer

---

## 📊 Estimation du Temps

| Phase | Durée | Priorité |
|-------|-------|----------|
| Phase 1 : Préparation | 15 min | Haute |
| Phase 2 : Catégorisation | 30 min | Haute |
| Phase 3 : Déplacement scripts | 10 min | Haute |
| Phase 4 : INDEX.md | 20 min | Moyenne |
| Phase 5 : Mise à jour liens | 30 min | Haute |
| Phase 6 : Documentation | 15 min | Moyenne |
| Phase 7 : Validation | 15 min | Haute |
| **Total** | **~2h15** | |

---

## ✅ Checklist Finale

- [ ] Répertoires créés
- [ ] Fichiers déplacés vers les bonnes catégories
- [ ] Scripts déplacés vers `scripts/`
- [ ] INDEX.md créé
- [ ] Tous les liens mis à jour
- [ ] 00_ORGANISATION_DOC.md mis à jour
- [ ] README.md mis à jour
- [ ] Validation complète effectuée
- [ ] Document REORGANISATION_COMPLETE.md créé

---

**Date de création** : 2025-01-XX  
**Version** : 1.0  
**Statut** : 📋 Plan prêt pour exécution

