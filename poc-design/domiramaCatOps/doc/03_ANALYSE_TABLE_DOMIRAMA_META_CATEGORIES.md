# 📊 Analyse Détaillée : Table `B997X04:domirama-meta-categories`

**Date** : 2024-11-27  
**Table HBase** : `B997X04:domirama-meta-categories`  
**Objectif** : Analyser en détail cette table et ses impacts sur le POC DomiramaCatOps  
**Source** : Spécification HBase fournie

---

## 🎯 Vue d'Ensemble

### Description Générale

La table `domirama-meta-categories` est une table HBase dédiée aux métadonnées et configurations de catégorisation. Elle complète la table `domirama` (Column Family `category`) en stockant :

- **Configurations** : Acceptations, oppositions, règles personnalisées
- **Feedbacks** : Statistiques de catégorisation (moteur vs client)
- **Historiques** : Historique des oppositions
- **Décisions** : Méthodes de catégorisation spécifiques (salaires)

### Architecture HBase

**Table** : `B997X04:domirama-meta-categories`

**Column Families** :

- `config` : Configurations générales (REPLICATION_SCOPE => '1')
- `cpt_customer` : Compteurs clients (VERSIONS => '50', REPLICATION_SCOPE => '1')
- `cpt_engine` : Compteurs moteur (VERSIONS => '50', REPLICATION_SCOPE => '1')

**Design Pattern** : Plusieurs "KeySpaces" logiques dans une seule table physique (pour éviter de créer plusieurs petites tables).

---

## 📋 Structure Détaillée par "KeySpace" Logique

### 1. ACCEPT - Acceptation de l'affichage par le client

**RowKey Pattern** :

```
ACCEPT:{code_efs}:{no_contrat}:{no_pse}
```

**Colonnes** :

- Valeurs textuelles, numériques ou booléennes
- Indique si le client a accepté l'affichage/catégorisation

**Usage** :

- Vérification avant affichage des catégories
- Contrôle d'accès fonctionnel

**Accès** :

- GET direct par RowKey
- PUT pour mise à jour

---

### 2. OPPOSITION - Opposition à la catégorisation

**RowKey Pattern** :

```
OPPOSITION:{code_efs}:{no_pse}
```

**Colonnes** :

- Valeurs booléennes ou textuelles
- Indique qu'un client s'oppose à la catégorisation automatique

**Usage** :

- Désactivation de la catégorisation pour un client
- Respect du consentement client

**Accès** :

- GET direct par RowKey
- PUT pour activation/désactivation

---

### 3. HISTO_OPPOSITION - Historique des oppositions

**RowKey Pattern** :

```
HISTO_OPPOSITION:{code_efs}:{no_pse}:{timestamp}
```

**Colonnes** :

- Valeurs textuelles (statut, raison, etc.)
- Historique des changements d'opposition

**Usage** :

- Traçabilité des changements d'opposition
- Audit et conformité

**Accès** :

- GET par RowKey (dernière opposition)
- SCAN pour historique complet
- PUT pour ajout d'événement

**Note** : Utilise VERSIONS => '50' pour stocker l'historique dans HBase

---

### 4. ANALYZE_LABEL - Feedbacks moteur/clients par libellé

**RowKey Pattern** :

```
ANALYZE_LABEL:{type_operation}:{sens_operation}:{libellé_simplifié}
```

**Colonnes Dynamiques** :

- Colonnes dynamiques par catégorie (ex: `cat_ALIMENTATION`, `cat_RESTAURANT`)
- Compteurs HBase (INCREMENT/DECREMENT) pour chaque catégorie
- Deux compteurs par catégorie :
  - `cpt_customer.{catégorie}` : Compteur client (Column Family `cpt_customer`)
  - `cpt_engine.{catégorie}` : Compteur moteur (Column Family `cpt_engine`)

**Usage** :

- Distribution des catégories affectées à un libellé
- Statistiques de catégorisation (moteur vs client)
- Feedback pour amélioration du modèle

**Accès** :

- GET par RowKey pour un libellé spécifique
- INCREMENT atomique sur compteurs
- PUT pour mise à jour

**Exemple** :

```
RowKey: ANALYZE_LABEL:CB:DEBIT:CARREFOUR
Colonnes dynamiques:
  cpt_customer:cat_ALIMENTATION = 150
  cpt_engine:cat_ALIMENTATION = 200
  cpt_customer:cat_RESTAURANT = 10
  cpt_engine:cat_RESTAURANT = 5
```

---

### 5. ICS_DECISION - Feedbacks moteur/clients par ICS

**RowKey Pattern** :

```
ICS_DECISION:{type_operation}:{sens_operation}:{no_ICS}
```

**Colonnes Dynamiques** :

- Même structure que ANALYZE_LABEL
- Compteurs par catégorie (cpt_customer et cpt_engine)

**Usage** :

- Distribution des catégories par code ICS
- Statistiques de catégorisation par ICS

**Accès** :

- GET par RowKey
- INCREMENT atomique sur compteurs

---

### 6. CUSTOM_RULE - Règles catégorisation spécifiques client

**RowKey Pattern** :

```
CUSTOM_RULE:{code_efs}:{type_operation}:{sens_operation}:{libellé_simplifié}
```

**Colonnes** :

- Valeurs textuelles (catégorie cible, priorité, etc.)
- Règles de catégorisation personnalisées par client

**Usage** :

- Surcharge de catégorisation pour un client spécifique
- Règles métier personnalisées

**Accès** :

- GET par RowKey
- PUT pour création/modification
- DELETE pour suppression

---

### 7. SALARY_DECISION - Méthode de catégorisation sur libellés taggés salaires

**RowKey Pattern** :

```
SALARY_DECISION:{libellé_simplifié}
```

**Colonnes** :

- Valeurs textuelles (méthode utilisée, modèle, etc.)
- Configuration pour libellés de type "salaire"

**Usage** :

- Traitement spécial pour opérations de salaire
- Méthode de catégorisation spécifique

**Accès** :

- GET par RowKey
- PUT pour mise à jour

---

## 🔍 Fonctionnalités HBase Utilisées

### 1. VERSIONS => '50'

**Column Families** : `cpt_customer`, `cpt_engine`

**Usage** :

- Historique des 50 dernières versions de chaque compteur
- Traçabilité des changements de feedbacks
- Utilisé notamment pour HISTO_OPPOSITION

**Impact Migration HCD** :

- HCD n'a pas de versions automatiques
- Solution : Table d'historique dédiée ou colonnes timestamp

---

### 2. INCREMENT Atomique

**Usage** :

- Incrément/décrément atomique des compteurs de feedback
- Opérations concurrentes sécurisées
- Utilisé pour ANALYZE_LABEL et ICS_DECISION

**Exemple** :

```hbase
INCREMENT 'domirama-meta-categories', 'ANALYZE_LABEL:CB:DEBIT:CARREFOUR', 'cpt_customer:cat_ALIMENTATION', 1
```

**Impact Migration HCD** :

- HCD supporte les compteurs (type `counter`)
- Tables de compteurs dédiées nécessaires

---

### 3. Colonnes Dynamiques

**Usage** :

- Colonnes créées dynamiquement par catégorie
- Pas de schéma fixe
- Flexibilité maximale

**Exemple** :

- `cpt_customer:cat_ALIMENTATION`
- `cpt_customer:cat_RESTAURANT`
- `cpt_engine:cat_ALIMENTATION`

**Impact Migration HCD** :

- HCD nécessite un schéma fixe
- Solution : Table avec clustering key sur catégorie

---

### 4. REPLICATION_SCOPE => '1'

**Toutes les Column Families** :

- Réplication vers autres clusters
- Haute disponibilité

**Impact Migration HCD** :

- NetworkTopologyStrategy
- Configuration par datacenter

---

## 🔗 Relations avec la Table `domirama` (CF `category`)

### Relations Fonctionnelles

1. **Catégorisation** :
   - `domirama.category` : Catégorie assignée à chaque opération
   - `domirama-meta-categories.ANALYZE_LABEL` : Statistiques par libellé

2. **Configuration Client** :
   - `domirama-meta-categories.ACCEPT` : Acceptation d'affichage
   - `domirama-meta-categories.OPPOSITION` : Opposition à catégorisation
   - Impact sur l'affichage des catégories dans `domirama.category`

3. **Règles Personnalisées** :
   - `domirama-meta-categories.CUSTOM_RULE` : Règles spécifiques client
   - Utilisées pour surcharger la catégorisation dans `domirama.category`

4. **Feedbacks** :
   - `domirama.category.cat_auto` : Catégorie proposée par moteur
   - `domirama-meta-categories.ANALYZE_LABEL` : Statistiques de feedback
   - Utilisées pour améliorer le modèle de catégorisation

---

## 📊 Patterns d'Accès

### Écriture

1. **PUT Direct** :
   - ACCEPT, OPPOSITION, CUSTOM_RULE, SALARY_DECISION
   - Mise à jour de configurations

2. **INCREMENT Atomique** :
   - ANALYZE_LABEL, ICS_DECISION
   - Mise à jour des compteurs de feedback

3. **PUT avec Timestamp** :
   - HISTO_OPPOSITION
   - Ajout d'événement historique

### Lecture

1. **GET Direct** :
   - Tous les KeySpaces
   - Accès par RowKey complet

2. **SCAN** :
   - HISTO_OPPOSITION (historique complet)
   - Recherche par préfixe (ex: tous les ACCEPT d'un code_efs)

---

## 🎯 Implications pour le POC HCD

### 1. Explosion en Plusieurs Tables

**HBase** : 1 table avec 7 "KeySpaces" logiques  
**HCD** : 7 tables distinctes (bonnes pratiques CQL)

**Tables à créer** :

1. `acceptation_client`
2. `opposition_categorisation`
3. `historique_opposition`
4. `feedback_par_libelle`
5. `feedback_par_ics`
6. `regles_personnalisees`
7. `decisions_salaires`

### 2. Gestion des Compteurs

**HBase** : Colonnes dynamiques + INCREMENT atomique  
**HCD** : Tables de compteurs dédiées (type `counter`)

**Tables de compteurs** :

- `feedback_par_libelle` : Table avec colonnes `counter`
- `feedback_par_ics` : Table avec colonnes `counter`

### 3. Historique (VERSIONS => '50')

**HBase** : Versions automatiques  
**HCD** : Table d'historique avec timestamp

**Table** : `historique_opposition` avec clustering key `timestamp`

### 4. Colonnes Dynamiques

**HBase** : Colonnes créées dynamiquement  
**HCD** : Clustering key sur catégorie

**Exemple** : `feedback_par_libelle` avec `PRIMARY KEY ((type_op, sens_op, libelle), categorie)`

---

## 📋 Résumé des Besoins à Démontrer

### Pour chaque "KeySpace"

1. ✅ **Création de la table HCD correspondante**
2. ✅ **Migration des données depuis HBase**
3. ✅ **Opérations d'écriture (PUT/INCREMENT)**
4. ✅ **Opérations de lecture (GET/SCAN)**
5. ✅ **Fonctionnalités spécifiques (compteurs, historique)**

### Fonctionnalités Globales

1. ✅ **Compteurs atomiques** (INCREMENT équivalent)
2. ✅ **Historique** (VERSIONS équivalent)
3. ✅ **Colonnes dynamiques** (clustering key équivalent)
4. ✅ **REPLICATION_SCOPE** (NetworkTopologyStrategy)

---

**Date** : 2024-11-27  
**Version** : 1.0
