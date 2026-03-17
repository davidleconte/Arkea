# 🔗 Synthèse : Impacts de la Table `domirama-meta-categories` sur le POC

**Date** : 2025-01-XX
**Dernière mise à jour** : 2025-01-XX
**Version** : 2.0
**Objectif** : Analyser les impacts de la deuxième table HBase sur le POC de la première table
**Tables** :
- Table 1 : `B997X04:domirama` (Column Family `category`)
- Table 2 : `B997X04:domirama-meta-categories`

---

## 📑 Table des Matières

1. [Vue d'Ensemble](#-vue-densemble)
2. [PARTIE 1 : IMPACTS SUR `operations_by_account`](#-partie-1--impacts-sur-operations_by_account)
3. [PARTIE 2 : IMPACTS SUR LES TABLES META-CATEGORIES](#-partie-2--impacts-sur-les-tables-meta-categories)
4. [PARTIE 3 : COHÉRENCE MULTI-TABLES](#-partie-3--cohérence-multi-tables)
5. [PARTIE 4 : SYNTHÈSE](#-partie-4--synthèse)

---

## 🎯 Vue d'Ensemble

La table `domirama-meta-categories` complète la table `domirama.category` en fournissant :
- **Configurations** : Acceptations, oppositions, règles personnalisées
- **Feedbacks** : Statistiques de catégorisation (moteur vs client)
- **Historiques** : Traçabilité des changements

**Impact principal** : Le POC doit démontrer la **cohérence et l'intégration** entre les 8 tables HCD.

---

## 📊 PARTIE 1 : IMPACTS SUR `operations_by_account`

### 1.1 Vérification Acceptation/Opposition

**Avant catégorisation** :
- Vérifier `acceptation_client` (si accepté)
- Vérifier `opposition_categorisation` (si non opposé)

**Impact sur le POC** :
- ✅ Scripts de démonstration doivent inclure ces vérifications
- ✅ Tests de non-catégorisation si opposition
- ✅ Démonstration du flux complet : vérification → catégorisation → affichage

**Scripts à modifier/créer** :
- `07_load_category_data_realtime.sh` : Ajouter vérification acceptation/opposition
- `09_test_acceptation_opposition.sh` : Nouveau script de test

---

### 1.2 Application des Règles Personnalisées

**Avant catégorisation automatique** :
- Vérifier `regles_personnalisees` pour le client/libellé
- Appliquer la règle si existe (priorité sur catégorisation automatique)

**Impact sur le POC** :
- ✅ Démonstration de l'application des règles
- ✅ Tests de priorité (règle > catégorisation automatique)
- ✅ Logique applicative : règle → cat_auto → cat_user

**Scripts à modifier/créer** :
- `05_load_operations_data_parquet.sh` : Appliquer règles lors du chargement
- `10_test_regles_personnalisees.sh` : Nouveau script de test

---

### 1.3 Mise à Jour des Feedbacks

**Après catégorisation** :
- Incrémenter `feedback_par_libelle.count_engine` (batch)
- Incrémenter `feedback_par_libelle.count_client` (correction client)
- Même logique pour `feedback_par_ics`

**Impact sur le POC** :
- ✅ Démonstration des compteurs atomiques (INCREMENT équivalent)
- ✅ Tests de cohérence (opération → feedback)
- ✅ Validation que chaque catégorisation met à jour les feedbacks

**Scripts à modifier/créer** :
- `05_load_operations_data_parquet.sh` : Mettre à jour feedbacks après catégorisation
- `07_load_category_data_realtime.sh` : Mettre à jour feedbacks après correction client
- `11_test_feedbacks_counters.sh` : Nouveau script de test

---

## 📊 PARTIE 2 : IMPACTS SUR LES SCRIPTS DE DÉMONSTRATION

### 2.1 Scripts à Ajouter (7 nouveaux scripts)

1. **`03_setup_meta_categories_tables.sh`**
   - Création des 7 tables meta-categories
   - Documentation complète

2. **`06_load_meta_categories_data_parquet.sh`**
   - Chargement des métadonnées depuis Parquet
   - Chargement dans les 7 tables

3. **`09_test_acceptation_opposition.sh`**
   - Tests acceptation client
   - Tests opposition catégorisation
   - Impact sur catégorisation

4. **`10_test_regles_personnalisees.sh`**
   - Tests règles personnalisées
   - Application des règles
   - Tests de priorité

5. **`11_test_feedbacks_counters.sh`**
   - Tests compteurs atomiques
   - Tests INCREMENT équivalent
   - Tests de cohérence

6. **`12_test_historique_opposition.sh`**
   - Tests historique opposition
   - Remplace VERSIONS => '50'
   - Tests de traçabilité

7. **`15_test_coherence_multi_tables.sh`**
   - Tests de cohérence entre les 8 tables
   - Validation des contraintes métier
   - Tests d'intégration

---

### 2.2 Scripts à Modifier (3 scripts existants)

1. **`05_load_operations_data_parquet.sh`**
   - Ajouter : Application des règles personnalisées
   - Ajouter : Mise à jour des feedbacks (count_engine)

2. **`07_load_category_data_realtime.sh`**
   - Ajouter : Vérification acceptation/opposition
   - Ajouter : Mise à jour des feedbacks (count_client)

3. **`08_test_category_search.sh`**
   - Ajouter : Tests avec règles personnalisées
   - Ajouter : Tests avec acceptation/opposition

---

## 📊 PARTIE 3 : IMPACTS SUR LE DATA MODEL

### 3.1 Relations Fonctionnelles

#### 3.1.1 Flux de Catégorisation

```
1. Vérification acceptation_client → Si non accepté, pas de catégorisation
2. Vérification opposition_categorisation → Si opposé, pas de catégorisation
3. Vérification regles_personnalisees → Si règle existe, utiliser categorie_cible
4. Sinon, catégorisation automatique → cat_auto
5. Client peut corriger → cat_user
6. Mise à jour feedbacks → count_engine ou count_client
```

**Impact POC** :
- ✅ Démonstration du flux complet
- ✅ Tests de chaque étape
- ✅ Validation de la cohérence

---

### 3.2 Contraintes Métier

**Contraintes à respecter** :
1. Si `opposition_categorisation.opposed = true` → pas de catégorisation
2. Si `regles_personnalisees` existe → utiliser `categorie_cible`
3. Chaque catégorisation → mettre à jour feedbacks
4. Historique opposition → traçabilité complète

**Impact POC** :
- ✅ Tests de cohérence multi-tables
- ✅ Validation des contraintes métier
- ✅ Script de validation dédié (`15_test_coherence_multi_tables.sh`)

---

## 📊 PARTIE 4 : IMPACTS SUR LA MIGRATION

### 4.1 Migration des Données

**HBase → HCD** :
- 2 tables HBase → 8 tables HCD
- Extraction depuis 2 tables HBase
- Chargement dans 8 tables HCD
- Validation de cohérence entre tables

**Impact POC** :
- ✅ Script de migration complet (`20_migrate_hbase_to_hcd.sh`)
- ✅ Validation multi-tables (`21_validate_migration.sh`)

---

### 4.2 Format Source Parquet

**Spécification** : Parquet uniquement (pas de SequenceFile)

**Implications** :
- 8 fichiers Parquet (un par table HCD)
- Structure Parquet doit correspondre aux schémas HCD
- Chargement depuis Parquet dans HCD

**Impact POC** :
- ✅ Scripts de chargement depuis Parquet uniquement
- ✅ Pas de conversion SequenceFile → Parquet

---

## 🎯 PARTIE 5 : RÉSUMÉ DES IMPACTS

### 5.1 Impacts Fonctionnels

| Impact | Description | Scripts Concernés |
|--------|-------------|-------------------|
| **Vérification Acceptation/Opposition** | Avant catégorisation | `07_load_category_data_realtime.sh`, `09_test_acceptation_opposition.sh` |
| **Application Règles Personnalisées** | Priorité sur cat_auto | `05_load_operations_data_parquet.sh`, `10_test_regles_personnalisees.sh` |
| **Mise à Jour Feedbacks** | Après catégorisation | `05_load_operations_data_parquet.sh`, `07_load_category_data_realtime.sh`, `11_test_feedbacks_counters.sh` |
| **Historique Opposition** | Traçabilité | `12_test_historique_opposition.sh` |
| **Cohérence Multi-Tables** | Validation contraintes | `15_test_coherence_multi_tables.sh` |

---

### 5.2 Impacts Techniques

| Impact | Description | Solution |
|--------|-------------|----------|
| **8 Tables HCD** | Explosion de `domirama-meta-categories` | 7 tables distinctes + 1 table operations |
| **Compteurs Atomiques** | INCREMENT équivalent | Tables avec type `counter` |
| **Historique** | VERSIONS => '50' équivalent | Table d'historique avec TIMEUUID |
| **Format Source** | Parquet uniquement | Chargement direct depuis Parquet |

---

### 5.3 Impacts sur le Plan d'Action

**Scripts totaux** : **21 scripts** (au lieu de 12 initialement prévus)

**Répartition** :
- Setup : 4 scripts (au lieu de 2)
- Ingestion : 3 scripts (au lieu de 2)
- Tests : 8 scripts (au lieu de 3)
- Fonctionnalités : 4 scripts (inchangé)
- Migration : 2 scripts (au lieu de 1)

---

## 🎯 CONCLUSION

Les impacts de la deuxième table `domirama-meta-categories` sont **significatifs** :

1. ✅ **Complexité accrue** : 8 tables HCD au lieu de 1
2. ✅ **Relations fonctionnelles** : Cohérence entre tables nécessaire
3. ✅ **Scripts supplémentaires** : 9 nouveaux scripts (7 nouveaux + 2 modifications)
4. ✅ **Tests de cohérence** : Validation multi-tables essentielle

**Le POC doit démontrer** :
- ✅ La migration complète des 2 tables HBase vers 8 tables HCD
- ✅ La cohérence fonctionnelle entre toutes les tables
- ✅ Les fonctionnalités spécifiques (compteurs, historique, règles)
- ✅ La performance et la scalabilité de l'ensemble

---

**Date** : 2025-01-XX
**Dernière mise à jour** : 2025-01-XX
**Version** : 2.0
**Version** : 1.0
