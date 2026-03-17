# 🔍 Analyse en Profondeur : Recherche Avancée sur les 8 Tables

**Date** : 2025-01-XX
**Dernière mise à jour** : 2025-01-XX
**Version** : 2.0
**Objectif** : Analyser en profondeur si les 8 tables bénéficient des fonctionnalités de recherche avancée et identifier les améliorations nécessaires
**Méthodologie** : Analyse table par table des colonnes texte, des cas d'usage, et des besoins de recherche

---

## 📑 Table des Matières

1. [Vue d'Ensemble](#-vue-densemble)
2. [PARTIE 1 : ANALYSE DÉTAILLÉE PAR TABLE](#-partie-1--analyse-détaillée-par-table)
3. [PARTIE 2 : RECOMMANDATIONS PAR TABLE](#-partie-2--recommandations-par-table)
4. [PARTIE 3 : SYNTHÈSE ET RECOMMANDATIONS FINALES](#-partie-3--synthèse-et-recommandations-finales)

---

## 🎯 Vue d'Ensemble

### Tables Analysées

1. ✅ **`operations_by_account`** : Opérations avec catégorisation
2. ⚠️ **`acceptation_client`** : Acceptations clients
3. ⚠️ **`opposition_categorisation`** : Oppositions
4. ⚠️ **`historique_opposition`** : Historique oppositions
5. ⚠️ **`feedback_par_libelle`** : Feedbacks par libellé (compteurs)
6. ⚠️ **`feedback_par_ics`** : Feedbacks par ICS (compteurs)
7. ⚠️ **`regles_personnalisees`** : Règles personnalisées
8. ⚠️ **`decisions_salaires`** : Décisions salaires

---

## 📊 PARTIE 1 : ANALYSE DÉTAILLÉE PAR TABLE

### 1.1 Table : `operations_by_account`

**Statut** : ✅ **COMPLET** - Toutes les fonctionnalités de recherche avancée intégrées

**Colonnes Texte** :
- `libelle TEXT` : Libellé de l'opération
- `libelle_prefix TEXT` : Préfixe pour recherche partielle
- `libelle_tokens SET<TEXT>` : Tokens/N-Grams pour CONTAINS
- `libelle_embedding VECTOR<FLOAT, 1472>` : Embeddings ByteT5

**Index SAI** :
- ✅ `idx_libelle_fulltext_advanced` : Full-text avec analyzers français
- ✅ `idx_libelle_prefix_ngram` : N-Gram pour recherche partielle
- ✅ `idx_libelle_tokens` : Collection pour CONTAINS
- ✅ `idx_libelle_embedding_vector` : Vector search (ANN)

**Cas d'Usage** :
- ✅ Recherche d'opérations par libellé (client Domirama)
- ✅ Recherche avec typos (fuzzy search)
- ✅ Recherche partielle (autocomplétion)
- ✅ Recherche sémantique (hybrid search)

**Conclusion** : ✅ **Aucune amélioration nécessaire** - Table complète avec toutes les fonctionnalités Domirama2

---

### 1.2 Table : `acceptation_client`

**Statut** : ⚠️ **PAS DE RECHERCHE AVANCÉE** - Pas de colonne texte

**Colonnes** :
- `code_efs TEXT` : Code entité (clé)
- `no_contrat TEXT` : Numéro contrat (clé)
- `no_pse TEXT` : Numéro PSE (clé)
- `accepted_at TIMESTAMP` : Date acceptation
- `accepted BOOLEAN` : Statut acceptation

**Colonnes Texte** : ❌ Aucune colonne texte significative

**Cas d'Usage** :
- Accès direct par clé primaire (`code_efs`, `no_contrat`, `no_pse`)
- Vérification booléenne (`accepted = true/false`)
- Pas de recherche textuelle nécessaire

**Index SAI Recommandés** :
- ❌ **Aucun index SAI nécessaire** - Pas de colonne texte

**Conclusion** : ✅ **Aucune amélioration nécessaire** - Table de configuration, pas de recherche textuelle

---

### 1.3 Table : `opposition_categorisation`

**Statut** : ⚠️ **PAS DE RECHERCHE AVANCÉE** - Pas de colonne texte

**Colonnes** :
- `code_efs TEXT` : Code entité (clé)
- `no_pse TEXT` : Numéro PSE (clé)
- `opposed BOOLEAN` : Statut opposition
- `opposed_at TIMESTAMP` : Date opposition

**Colonnes Texte** : ❌ Aucune colonne texte significative

**Cas d'Usage** :
- Accès direct par clé primaire (`code_efs`, `no_pse`)
- Vérification booléenne (`opposed = true/false`)
- Pas de recherche textuelle nécessaire

**Index SAI Recommandés** :
- ❌ **Aucun index SAI nécessaire** - Pas de colonne texte

**Conclusion** : ✅ **Aucune amélioration nécessaire** - Table de configuration, pas de recherche textuelle

---

### 1.4 Table : `historique_opposition`

**Statut** : ⚠️ **RECHERCHE AVANCÉE PARTIELLE** - Colonne `raison TEXT` présente mais non indexée

**Colonnes** :
- `code_efs TEXT` : Code entité (clé)
- `no_pse TEXT` : Numéro PSE (clé)
- `horodate TIMEUUID` : Clustering key
- `status TEXT` : Statut ('opposé' ou 'autorisé')
- `timestamp TIMESTAMP` : Date changement
- `raison TEXT` : **Raison du changement (optionnel)**

**Colonnes Texte** :
- ✅ `status TEXT` : Statut (valeurs fixes : 'opposé', 'autorisé')
- ✅ `raison TEXT` : Raison du changement (texte libre)

**Cas d'Usage** :
- Accès par clé primaire + horodate (historique chronologique)
- **Recherche dans les raisons** : "Trouver tous les changements d'opposition contenant 'RGPD'"
- **Recherche par statut** : Filtrer par 'opposé' ou 'autorisé'

**Index SAI Recommandés** :
- ✅ `idx_status` : Index SAI standard sur `status` (recherche par statut)
- ⚠️ `idx_raison_fulltext` : **Index SAI full-text sur `raison`** (si recherche dans raisons nécessaire)

**Justification** :
- **`status`** : Valeurs fixes, recherche exacte suffisante (index standard)
- **`raison`** : Texte libre, recherche full-text utile pour audit/compliance

**Amélioration Proposée** :
```cql
-- Index SAI standard sur status (recherche exacte)
CREATE CUSTOM INDEX idx_historique_status
ON historique_opposition(status)
USING 'StorageAttachedIndex';

-- Index SAI full-text sur raison (si recherche textuelle nécessaire)
CREATE CUSTOM INDEX idx_historique_raison_fulltext
ON historique_opposition(raison)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "asciiFolding"},
      {"name": "frenchLightStem"}
    ]
  }'
};
```

**Conclusion** : ⚠️ **Amélioration recommandée** - Ajouter index SAI sur `status` et `raison` si recherche textuelle nécessaire

---

### 1.5 Table : `feedback_par_libelle`

**Statut** : ⚠️ **RECHERCHE AVANCÉE MANQUANTE** - Colonne `libelle_simplifie TEXT` présente mais non indexée

**Colonnes** :
- `type_operation TEXT` : Type opération (clé)
- `sens_operation TEXT` : Sens opération (clé)
- `libelle_simplifie TEXT` : **Libellé simplifié (clé)**
- `categorie TEXT` : Catégorie (clustering key)
- `count_engine COUNTER` : Compteur moteur
- `count_client COUNTER` : Compteur client

**Colonnes Texte** :
- ✅ `libelle_simplifie TEXT` : Libellé simplifié (partie de la clé primaire)
- ✅ `categorie TEXT` : Catégorie (clustering key)

**Cas d'Usage** :
- Accès par clé primaire complète (`type_operation`, `sens_operation`, `libelle_simplifie`, `categorie`)
- **Recherche par libellé partiel** : "Trouver tous les feedbacks pour libellés contenant 'CARREFOUR'"
- **Recherche par catégorie** : Filtrer par catégorie
- **Analyse statistique** : "Quels libellés ont le plus de feedbacks ?"

**Index SAI Recommandés** :
- ✅ `idx_libelle_simplifie_fulltext` : **Index SAI full-text sur `libelle_simplifie`** (recherche partielle)
- ✅ `idx_categorie` : Index SAI standard sur `categorie` (filtrage rapide)

**Justification** :
- **`libelle_simplifie`** : Colonne texte, recherche partielle nécessaire pour analyse statistique
- **`categorie`** : Valeurs fixes, recherche exacte suffisante (index standard)

**Amélioration Proposée** :
```cql
-- Index SAI full-text sur libelle_simplifie (recherche partielle)
CREATE CUSTOM INDEX idx_feedback_libelle_fulltext
ON feedback_par_libelle(libelle_simplifie)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "asciiFolding"},
      {"name": "frenchLightStem"}
    ]
  }'
};

-- Index SAI standard sur categorie (filtrage rapide)
CREATE CUSTOM INDEX idx_feedback_categorie
ON feedback_par_libelle(categorie)
USING 'StorageAttachedIndex';
```

**Conclusion** : ⚠️ **Amélioration nécessaire** - Ajouter index SAI full-text sur `libelle_simplifie` et index standard sur `categorie`

---

### 1.6 Table : `feedback_par_ics`

**Statut** : ⚠️ **PAS DE RECHERCHE AVANCÉE** - Pas de colonne texte significative

**Colonnes** :
- `type_operation TEXT` : Type opération (clé)
- `sens_operation TEXT` : Sens opération (clé)
- `code_ics TEXT` : Code ICS (clé)
- `categorie TEXT` : Catégorie (clustering key)
- `count_engine COUNTER` : Compteur moteur
- `count_client COUNTER` : Compteur client

**Colonnes Texte** :
- ✅ `code_ics TEXT` : Code ICS (identifiant fixe, pas de recherche textuelle)
- ✅ `categorie TEXT` : Catégorie (clustering key)

**Cas d'Usage** :
- Accès par clé primaire complète (`type_operation`, `sens_operation`, `code_ics`, `categorie`)
- Recherche par code ICS exact (pas de recherche partielle nécessaire)
- Filtrage par catégorie

**Index SAI Recommandés** :
- ❌ **Pas d'index SAI sur `code_ics`** - Identifiant fixe, recherche exacte via clé primaire
- ✅ `idx_categorie` : Index SAI standard sur `categorie` (filtrage rapide)

**Justification** :
- **`code_ics`** : Identifiant fixe (ex: "123456"), recherche exacte via clé primaire suffisante
- **`categorie`** : Valeurs fixes, recherche exacte suffisante (index standard)

**Amélioration Proposée** :
```cql
-- Index SAI standard sur categorie (filtrage rapide)
CREATE CUSTOM INDEX idx_feedback_ics_categorie
ON feedback_par_ics(categorie)
USING 'StorageAttachedIndex';
```

**Conclusion** : ⚠️ **Amélioration mineure** - Ajouter index SAI standard sur `categorie` pour filtrage rapide

---

### 1.7 Table : `regles_personnalisees`

**Statut** : ⚠️ **RECHERCHE AVANCÉE MANQUANTE** - Colonne `libelle_simplifie TEXT` présente mais non indexée

**Colonnes** :
- `code_efs TEXT` : Code entité (clé)
- `type_operation TEXT` : Type opération (clustering key)
- `sens_operation TEXT` : Sens opération (clustering key)
- `libelle_simplifie TEXT` : **Libellé simplifié (clustering key)**
- `categorie_cible TEXT` : Catégorie cible
- `actif BOOLEAN` : Règle active
- `priorite INT` : Priorité
- `created_at TIMESTAMP` : Date création
- `updated_at TIMESTAMP` : Date mise à jour

**Colonnes Texte** :
- ✅ `libelle_simplifie TEXT` : Libellé simplifié (clustering key)
- ✅ `categorie_cible TEXT` : Catégorie cible

**Cas d'Usage** :
- Accès par clé primaire (`code_efs`, `type_operation`, `sens_operation`, `libelle_simplifie`)
- **Recherche par libellé partiel** : "Trouver toutes les règles pour libellés contenant 'LOYER'"
- **Recherche par catégorie cible** : Filtrer par catégorie cible
- **Gestion des règles** : "Quelles règles sont actives pour ce client ?"

**Index SAI Recommandés** :
- ✅ `idx_libelle_simplifie_fulltext` : **Index SAI full-text sur `libelle_simplifie`** (recherche partielle)
- ✅ `idx_categorie_cible` : Index SAI standard sur `categorie_cible` (filtrage rapide)
- ✅ `idx_actif` : Index SAI standard sur `actif` (filtrage règles actives)

**Justification** :
- **`libelle_simplifie`** : Colonne texte, recherche partielle nécessaire pour gestion des règles
- **`categorie_cible`** : Valeurs fixes, recherche exacte suffisante (index standard)
- **`actif`** : Booléen, index standard pour filtrage rapide

**Amélioration Proposée** :
```cql
-- Index SAI full-text sur libelle_simplifie (recherche partielle)
CREATE CUSTOM INDEX idx_regles_libelle_fulltext
ON regles_personnalisees(libelle_simplifie)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "asciiFolding"},
      {"name": "frenchLightStem"}
    ]
  }'
};

-- Index SAI standard sur categorie_cible (filtrage rapide)
CREATE CUSTOM INDEX idx_regles_categorie_cible
ON regles_personnalisees(categorie_cible)
USING 'StorageAttachedIndex';

-- Index SAI standard sur actif (filtrage règles actives)
CREATE CUSTOM INDEX idx_regles_actif
ON regles_personnalisees(actif)
USING 'StorageAttachedIndex';
```

**Conclusion** : ⚠️ **Amélioration nécessaire** - Ajouter index SAI full-text sur `libelle_simplifie` et index standards sur `categorie_cible` et `actif`

---

### 1.8 Table : `decisions_salaires`

**Statut** : ⚠️ **RECHERCHE AVANCÉE MANQUANTE** - Colonne `libelle_simplifie TEXT` présente mais non indexée

**Colonnes** :
- `libelle_simplifie TEXT` : **Libellé simplifié (clé primaire)**
- `methode_utilisee TEXT` : Méthode utilisée
- `modele TEXT` : Modèle
- `actif BOOLEAN` : Décision active
- `created_at TIMESTAMP` : Date création
- `updated_at TIMESTAMP` : Date mise à jour

**Colonnes Texte** :
- ✅ `libelle_simplifie TEXT` : Libellé simplifié (clé primaire)
- ✅ `methode_utilisee TEXT` : Méthode utilisée
- ✅ `modele TEXT` : Modèle

**Cas d'Usage** :
- Accès par clé primaire (`libelle_simplifie`)
- **Recherche par libellé partiel** : "Trouver toutes les décisions pour libellés contenant 'SALAIRE'"
- **Recherche par méthode** : Filtrer par méthode utilisée
- **Recherche par modèle** : Filtrer par modèle

**Index SAI Recommandés** :
- ⚠️ **Pas d'index SAI sur `libelle_simplifie`** - Clé primaire, recherche exacte via clé primaire
- ✅ `idx_methode_utilisee` : Index SAI standard sur `methode_utilisee` (filtrage rapide)
- ✅ `idx_modele` : Index SAI standard sur `modele` (filtrage rapide)
- ✅ `idx_actif` : Index SAI standard sur `actif` (filtrage décisions actives)

**Justification** :
- **`libelle_simplifie`** : Clé primaire, recherche exacte via clé primaire suffisante (pas d'index SAI nécessaire)
- **`methode_utilisee`** : Valeurs fixes, recherche exacte suffisante (index standard)
- **`modele`** : Valeurs fixes, recherche exacte suffisante (index standard)
- **`actif`** : Booléen, index standard pour filtrage rapide

**Note Importante** : Si recherche partielle sur `libelle_simplifie` nécessaire, ajouter colonne dérivée `libelle_simplifie_prefix TEXT` avec index N-Gram (comme `operations_by_account`)

**Amélioration Proposée** :
```cql
-- Index SAI standard sur methode_utilisee (filtrage rapide)
CREATE CUSTOM INDEX idx_decisions_methode
ON decisions_salaires(methode_utilisee)
USING 'StorageAttachedIndex';

-- Index SAI standard sur modele (filtrage rapide)
CREATE CUSTOM INDEX idx_decisions_modele
ON decisions_salaires(modele)
USING 'StorageAttachedIndex';

-- Index SAI standard sur actif (filtrage décisions actives)
CREATE CUSTOM INDEX idx_decisions_actif
ON decisions_salaires(actif)
USING 'StorageAttachedIndex';

-- OPTIONNEL : Si recherche partielle sur libelle_simplifie nécessaire
ALTER TABLE decisions_salaires ADD libelle_simplifie_prefix TEXT;

CREATE CUSTOM INDEX idx_decisions_libelle_prefix_ngram
ON decisions_salaires(libelle_simplifie_prefix)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "asciiFolding"}
    ]
  }'
};
```

**Conclusion** : ⚠️ **Amélioration recommandée** - Ajouter index SAI standards sur `methode_utilisee`, `modele`, et `actif`. Optionnel : ajouter recherche partielle sur `libelle_simplifie` si nécessaire

---

## 📊 PARTIE 2 : SYNTHÈSE PAR TABLE

| Table | Colonnes Texte | Recherche Avancée | Statut | Action |
|-------|---------------|-------------------|--------|--------|
| **1. operations_by_account** | `libelle`, `libelle_prefix`, `libelle_tokens`, `libelle_embedding` | ✅ Complète | ✅ **OK** | Aucune |
| **2. acceptation_client** | Aucune | ❌ Non applicable | ✅ **OK** | Aucune |
| **3. opposition_categorisation** | Aucune | ❌ Non applicable | ✅ **OK** | Aucune |
| **4. historique_opposition** | `status`, `raison` | ⚠️ Partielle | ⚠️ **À améliorer** | Ajouter index SAI |
| **5. feedback_par_libelle** | `libelle_simplifie`, `categorie` | ⚠️ Manquante | ⚠️ **À améliorer** | Ajouter index SAI |
| **6. feedback_par_ics** | `code_ics`, `categorie` | ⚠️ Partielle | ⚠️ **À améliorer** | Ajouter index SAI |
| **7. regles_personnalisees** | `libelle_simplifie`, `categorie_cible` | ⚠️ Manquante | ⚠️ **À améliorer** | Ajouter index SAI |
| **8. decisions_salaires** | `libelle_simplifie`, `methode_utilisee`, `modele` | ⚠️ Manquante | ⚠️ **À améliorer** | Ajouter index SAI |

---

## 📊 PARTIE 3 : RECOMMANDATIONS DÉTAILLÉES

### 3.1 Tables Ne Nécessitant Pas de Recherche Avancée

**Tables** : `acceptation_client`, `opposition_categorisation`

**Justification** :
- Tables de configuration avec clés primaires fixes
- Pas de colonnes texte significatives
- Accès direct par clé primaire uniquement

**Action** : ✅ **Aucune action nécessaire**

---

### 3.2 Tables Nécessitant des Index SAI Standards

**Tables** : `feedback_par_ics`, `decisions_salaires`

**Index Recommandés** :
- `feedback_par_ics` : `idx_categorie` (index standard)
- `decisions_salaires` : `idx_methode_utilisee`, `idx_modele`, `idx_actif` (index standards)

**Justification** :
- Colonnes avec valeurs fixes (catégories, méthodes, modèles)
- Recherche exacte suffisante (pas de recherche partielle nécessaire)
- Filtrage rapide pour requêtes analytiques

**Action** : ⚠️ **Ajouter index SAI standards** (priorité moyenne)

---

### 3.3 Tables Nécessitant des Index SAI Full-Text

**Tables** : `historique_opposition`, `feedback_par_libelle`, `regles_personnalisees`

**Index Recommandés** :
- `historique_opposition` : `idx_raison_fulltext` (full-text sur `raison`)
- `feedback_par_libelle` : `idx_libelle_simplifie_fulltext` (full-text sur `libelle_simplifie`)
- `regles_personnalisees` : `idx_libelle_simplifie_fulltext` (full-text sur `libelle_simplifie`)

**Justification** :
- Colonnes texte avec recherche partielle nécessaire
- Cas d'usage : audit, analyse statistique, gestion des règles
- Recherche full-text avec analyzers français (stemming, accents, casse)

**Action** : ⚠️ **Ajouter index SAI full-text** (priorité haute)

---

### 3.4 Tables Nécessitant des Index SAI Complémentaires

**Tables** : `historique_opposition`, `feedback_par_libelle`, `regles_personnalisees`

**Index Complémentaires** :
- `historique_opposition` : `idx_status` (index standard sur `status`)
- `feedback_par_libelle` : `idx_categorie` (index standard sur `categorie`)
- `regles_personnalisees` : `idx_categorie_cible`, `idx_actif` (index standards)

**Justification** :
- Filtrage rapide sur colonnes avec valeurs fixes
- Complément aux index full-text pour requêtes combinées

**Action** : ⚠️ **Ajouter index SAI standards complémentaires** (priorité moyenne)

---

## 📊 PARTIE 4 : PLAN D'ACTION

### 4.1 Priorité Haute (Recherche Full-Text)

**Tables** : `feedback_par_libelle`, `regles_personnalisees`

**Actions** :
1. Ajouter index SAI full-text sur `libelle_simplifie` avec analyzers français
2. Ajouter index SAI standards complémentaires (`categorie`, `categorie_cible`, `actif`)

**Impact** :
- ✅ Recherche partielle sur libellés pour analyse statistique
- ✅ Gestion des règles personnalisées par libellé
- ✅ Filtrage rapide par catégorie/statut

---

### 4.2 Priorité Moyenne (Index Standards)

**Tables** : `historique_opposition`, `feedback_par_ics`, `decisions_salaires`

**Actions** :
1. Ajouter index SAI full-text sur `raison` (historique_opposition) si recherche textuelle nécessaire
2. Ajouter index SAI standards sur `status`, `categorie`, `methode_utilisee`, `modele`, `actif`

**Impact** :
- ✅ Filtrage rapide pour requêtes analytiques
- ✅ Recherche dans raisons pour audit/compliance (si nécessaire)

---

### 4.3 Priorité Basse (Optionnel)

**Table** : `decisions_salaires`

**Action** :
- Ajouter colonne `libelle_simplifie_prefix TEXT` avec index N-Gram si recherche partielle nécessaire

**Impact** :
- ✅ Recherche partielle sur libellés (autocomplétion)

---

## 🎯 CONCLUSION

### Résumé

**Tables Complètes** : 1/8 (12.5%)
- ✅ `operations_by_account` : Toutes les fonctionnalités intégrées

**Tables Ne Nécessitant Pas de Recherche Avancée** : 2/8 (25%)
- ✅ `acceptation_client` : Pas de colonne texte
- ✅ `opposition_categorisation` : Pas de colonne texte

**Tables Nécessitant des Améliorations** : 5/8 (62.5%)
- ⚠️ `historique_opposition` : Ajouter index SAI sur `status` et `raison`
- ⚠️ `feedback_par_libelle` : Ajouter index SAI full-text sur `libelle_simplifie`
- ⚠️ `feedback_par_ics` : Ajouter index SAI standard sur `categorie`
- ⚠️ `regles_personnalisees` : Ajouter index SAI full-text sur `libelle_simplifie`
- ⚠️ `decisions_salaires` : Ajouter index SAI standards sur `methode_utilisee`, `modele`, `actif`

### Recommandations Finales

1. ✅ **Priorité Haute** : Ajouter index SAI full-text sur `libelle_simplifie` dans `feedback_par_libelle` et `regles_personnalisees`
2. ⚠️ **Priorité Moyenne** : Ajouter index SAI standards sur colonnes de filtrage (`categorie`, `status`, `actif`, etc.)
3. ⚠️ **Priorité Basse** : Ajouter recherche partielle sur `libelle_simplifie` dans `decisions_salaires` si nécessaire

**Bénéfices** :
- ✅ Recherche avancée cohérente sur toutes les tables avec colonnes texte
- ✅ Performance optimale pour requêtes analytiques
- ✅ Conformité avec les bonnes pratiques HCD/SAI

---

**Date** : 2025-01-XX
**Dernière mise à jour** : 2025-01-XX
**Version** : 2.0
