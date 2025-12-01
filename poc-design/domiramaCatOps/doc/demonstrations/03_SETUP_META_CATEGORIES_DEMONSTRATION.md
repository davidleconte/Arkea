# 🏗️ Démonstration : Configuration des Tables Meta-Categories

**Date** : 2025-11-28 09:38:54  
**Script** : 03_setup_meta_categories_tables.sh  
**Objectif** : Démontrer la création complète des 7 tables HCD pour domirama-meta-categories

---

## 📋 Table des Matières

1. [Contexte HBase → HCD](#contexte-hbase--hcd)
2. [DDL - 7 Tables](#ddl---7-tables)
3. [DDL - Index SAI](#ddl---index-sai)
4. [Vérifications](#vérifications)
5. [Conclusion](#conclusion)

---

## 📚 Contexte HBase → HCD

### Équivalences

| Concept HBase | Équivalent HCD | Statut |
|---------------|----------------|--------|
| Table `B997X04:domirama-meta-categories` | 7 tables distinctes | ✅ |
| 7 "KeySpaces" logiques | 7 tables HCD | ✅ |
| VERSIONS => '50' | Table `historique_opposition` | ✅ |
| INCREMENT atomique | Type `COUNTER` | ✅ |
| Colonnes dynamiques | Clustering key `categorie` | ✅ |
| REPLICATION_SCOPE => '1' | NetworkTopologyStrategy | ✅ |

### Améliorations HCD

✅ **Schéma fixe et typé** (vs schéma flexible HBase)  
✅ **7 tables distinctes** (vs 1 table avec KeySpaces logiques)  
✅ **Historique illimité** (vs VERSIONS => '50')  
✅ **Type COUNTER natif** (vs INCREMENT sur colonnes dynamiques)  
✅ **Recherche par catégorie** (vs colonnes dynamiques)

---

## 📋 DDL - 7 Tables

### Table 1 : acceptation_client

**Source HBase** : `ACCEPT:{code_efs}:{no_contrat}:{no_pse}`

```cql
CREATE TABLE IF NOT EXISTS acceptation_client (
    code_efs      TEXT,
    no_contrat    TEXT,
    no_pse        TEXT,
    accepted_at   TIMESTAMP,
    accepted      BOOLEAN,
    PRIMARY KEY ((code_efs, no_contrat, no_pse))
);
```

**Usage** : Acceptation de l'affichage/catégorisation par le client

---

### Table 2 : opposition_categorisation

**Source HBase** : `OPPOSITION:{code_efs}:{no_pse}`

```cql
CREATE TABLE IF NOT EXISTS opposition_categorisation (
    code_efs      TEXT,
    no_pse        TEXT,
    opposed       BOOLEAN,
    opposed_at    TIMESTAMP,
    PRIMARY KEY ((code_efs, no_pse))
);
```

**Usage** : Opposition à la catégorisation automatique

---

### Table 3 : historique_opposition

**Source HBase** : `HISTO_OPPOSITION:{code_efs}:{no_pse}:{timestamp}` (VERSIONS => '50')

```cql
CREATE TABLE IF NOT EXISTS historique_opposition (
    code_efs      TEXT,
    no_pse        TEXT,
    horodate      TIMEUUID,  -- Clustering key
    status         TEXT,
    timestamp      TIMESTAMP,
    raison         TEXT,
    PRIMARY KEY ((code_efs, no_pse), horodate)
) WITH CLUSTERING ORDER BY (horodate DESC);
```

**Usage** : Historique des changements d'opposition (remplace VERSIONS => '50')

---

### Table 4 : feedback_par_libelle

**Source HBase** : `ANALYZE_LABEL:{type_op}:{sens_op}:{libellé}` (compteurs dynamiques)

```cql
CREATE TABLE IF NOT EXISTS feedback_par_libelle (
    type_operation     TEXT,
    sens_operation     TEXT,
    libelle_simplifie  TEXT,
    categorie          TEXT,      -- Clustering key
    count_engine       COUNTER,   -- Compteur moteur
    count_client       COUNTER,   -- Compteur client
    PRIMARY KEY ((type_operation, sens_operation, libelle_simplifie), categorie)
);
```

**Usage** : Feedbacks moteur/clients par libellé (compteurs atomiques)

---

### Table 5 : feedback_par_ics

**Source HBase** : `ICS_DECISION:{type_op}:{sens_op}:{no_ICS}` (compteurs dynamiques)

```cql
CREATE TABLE IF NOT EXISTS feedback_par_ics (
    type_operation     TEXT,
    sens_operation     TEXT,
    code_ics           TEXT,
    categorie          TEXT,      -- Clustering key
    count_engine       COUNTER,
    count_client       COUNTER,
    PRIMARY KEY ((type_operation, sens_operation, code_ics), categorie)
);
```

**Usage** : Feedbacks moteur/clients par code ICS

---

### Table 6 : regles_personnalisees

**Source HBase** : `CUSTOM_RULE:{code_efs}:{type_op}:{sens_op}:{libellé}`

```cql
CREATE TABLE IF NOT EXISTS regles_personnalisees (
    code_efs          TEXT,
    type_operation    TEXT,
    sens_operation    TEXT,
    libelle_simplifie TEXT,
    categorie_cible    TEXT,
    actif             BOOLEAN,
    priorite          INT,
    created_at        TIMESTAMP,
    updated_at        TIMESTAMP,
    PRIMARY KEY ((code_efs), type_operation, sens_operation, libelle_simplifie)
);
```

**Usage** : Règles de catégorisation personnalisées par client

---

### Table 7 : decisions_salaires

**Source HBase** : `SALARY_DECISION:{libellé}`

```cql
CREATE TABLE IF NOT EXISTS decisions_salaires (
    libelle_simplifie  TEXT,
    methode_utilisee    TEXT,
    modele             TEXT,
    actif              BOOLEAN,
    created_at         TIMESTAMP,
    updated_at         TIMESTAMP,
    PRIMARY KEY (libelle_simplifie)
);
```

**Usage** : Méthode de catégorisation sur libellés taggés salaires

---

## 📋 DDL - Index SAI

### Index Créés

**historique_opposition** :
- `idx_historique_status` : Index standard sur `status`
- `idx_historique_raison_fulltext` : Index full-text sur `raison`

**feedback_par_libelle** :
- `idx_feedback_libelle_fulltext` : Index full-text sur `libelle_simplifie`
- `idx_feedback_categorie` : Index standard sur `categorie`

**feedback_par_ics** :
- `idx_feedback_ics_categorie` : Index standard sur `categorie`

**regles_personnalisees** :
- `idx_regles_libelle_fulltext` : Index full-text sur `libelle_simplifie`
- `idx_regles_categorie_cible` : Index standard sur `categorie_cible`
- `idx_regles_actif` : Index standard sur `actif`

**decisions_salaires** :
- `idx_decisions_methode` : Index standard sur `methode_utilisee`
- `idx_decisions_modele` : Index standard sur `modele`
- `idx_decisions_actif` : Index standard sur `actif`

### Vérification

✅ 17 index(es) SAI créé(s)

---

## 🔍 Vérifications

### Résumé des Vérifications

| Vérification | Attendu | Obtenu | Statut |
|--------------|---------|--------|--------|
| Keyspace existe | domiramacatops_poc | domiramacatops_poc | ✅ |
| Tables créées | 7 | 7 | ✅ |
| Index SAI | 10+ | 17 | ✅ |

---

## ✅ Conclusion

Les 7 tables meta-categories ont été créées avec succès :

✅ **Keyspace** : domiramacatops_poc  
✅ **Tables** : 7 tables créées  
✅ **Index** : 17 index SAI créés  
✅ **Conformité** : 100% conforme à la proposition IBM

### Prochaines Étapes

- Script 05: Chargement des données operations (batch)
- Script 06: Chargement des données meta-categories (batch)
- Script 07: Chargement temps réel (corrections client)

---

**✅ Configuration terminée avec succès !**
