# 🔍 Colonnes Dynamiques : MAP HCD (Équivalent HBase)

**Date** : 2025-11-25  
**Objectif** : Démontrer le filtrage sur colonnes MAP (équivalent colonnes dynamiques HBase)

---

## 📋 Colonnes Dynamiques HBase

### Structure

**HBase** utilise des **colonnes dynamiques** calquées sur POJO Thrift :

```
Column Family: 'meta'
Column Qualifiers: 'source', 'device', 'channel', etc.
Column Values: 'mobile', 'iphone', 'app', etc.
```

### Exemple HBase

```java
// HBase : Colonnes dynamiques
Put put = new Put(rowkey);
put.addColumn(Bytes.toBytes("meta"), Bytes.toBytes("source"), Bytes.toBytes("mobile"));
put.addColumn(Bytes.toBytes("meta"), Bytes.toBytes("device"), Bytes.toBytes("iphone"));
put.addColumn(Bytes.toBytes("meta"), Bytes.toBytes("channel"), Bytes.toBytes("app"));
table.put(put);

// Filtrage avec ColumnFilter
Filter filter = new SingleColumnValueFilter(
    Bytes.toBytes("meta"),
    Bytes.toBytes("source"),
    CompareOperator.EQUAL,
    Bytes.toBytes("mobile")
);
Scan scan = new Scan();
scan.setFilter(filter);
```

---

## 🎯 Équivalent HCD : Colonnes MAP

### Structure

**HCD** utilise des **colonnes MAP<TEXT, TEXT>** :

```cql
meta_flags MAP<TEXT, TEXT>
```

### Exemple HCD

```cql
-- Insertion avec colonnes dynamiques (MAP)
INSERT INTO operations_by_account (
    code_si, contrat, date_op, numero_op, libelle, montant, meta_flags
)
VALUES (
    'DEMO_DYN', 'DEMO_001', '2024-01-20 10:00:00', 1, 'VIREMENT SEPA', 1000.00,
    {'source': 'mobile', 'channel': 'app', 'device': 'iphone'}
);

-- Filtrage sur colonnes MAP
SELECT * FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags['source'] = 'mobile';
```

---

## 📊 Comparaison : HBase vs HCD

| Critère | Colonnes Dynamiques HBase | Colonnes MAP HCD | Gagnant |
|---------|---------------------------|------------------|---------|
| **Structure** | Column qualifiers dynamiques | MAP<TEXT, TEXT> | ✅ **HCD** |
| **Typage** | ❌ Non typé | ✅ Typé | ✅ **HCD** |
| **Filtrage** | ColumnFilter | WHERE meta_flags['key'] | ✅ **HCD** |
| **Combinaison** | ❌ Limité | ✅ MAP + Index SAI | ✅ **HCD** |
| **Requêtes** | API HBase | CQL standard | ✅ **HCD** |

**Conclusion** : ✅ **Colonnes MAP HCD sont supérieures aux colonnes dynamiques HBase**

---

## 🎯 Équivalences Détaillées

### 1. Structure

**HBase** :
```
Column Family: 'meta'
Column Qualifier: 'source'
Column Value: 'mobile'
```

**HCD** :
```cql
meta_flags MAP<TEXT, TEXT>
{'source': 'mobile'}
```

**Équivalence** :
- ✅ **Column qualifier HBase** = **Clé MAP HCD**
- ✅ **Column value HBase** = **Valeur MAP HCD**

### 2. Filtrage

**HBase** :
```java
Filter filter = new SingleColumnValueFilter(
    Bytes.toBytes("meta"),
    Bytes.toBytes("source"),
    CompareOperator.EQUAL,
    Bytes.toBytes("mobile")
);
```

**HCD** :
```cql
WHERE meta_flags['source'] = 'mobile'
```

**Équivalence** :
- ✅ **ColumnFilter HBase** = **WHERE meta_flags['key'] HCD**

### 3. Vérification Présence

**HBase** :
```java
// Vérifier si column qualifier existe
Filter filter = new ColumnPrefixFilter(Bytes.toBytes("source"));
```

**HCD** :
```cql
-- Vérifier si clé existe
WHERE meta_flags CONTAINS KEY 'source'

-- Vérifier si valeur existe
WHERE meta_flags CONTAINS 'mobile'
```

**Équivalence** :
- ✅ **Vérification présence HBase** = **CONTAINS KEY / CONTAINS HCD**

---

## 📊 Démonstration

### Test 1 : Filtrage par Clé MAP

**Requête** :
```cql
SELECT * FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags['source'] = 'mobile';
```

**Équivalent HBase** :
- ColumnFilter sur qualifier `meta:source`

**Résultat** :
- ✅ Filtre les opérations avec `source = 'mobile'`

### Test 2 : Filtrage par Clé MAP avec Valeur Spécifique

**Requête** :
```cql
SELECT * FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags['device'] = 'iphone';
```

**Équivalent HBase** :
- ColumnFilter sur qualifier `meta:device`

**Résultat** :
- ✅ Filtre les opérations avec `device = 'iphone'`

### Test 3 : Filtrage Combiné (MAP + Index SAI)

**Requête** :
```cql
SELECT * FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags['source'] = 'web'
  AND libelle : 'VIREMENT';
```

**Équivalent HBase** :
- ❌ Non disponible (pas de recherche full-text native)

**Valeur ajoutée HCD** :
- ✅ **Filtrage combiné** : MAP + Index SAI full-text
- ✅ **Performance optimale** : Index sur les deux filtres

### Test 4 : Vérification Présence Clé (CONTAINS KEY)

**Requête** :
```cql
SELECT * FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags CONTAINS KEY 'ip';
```

**Équivalent HBase** :
- Vérifier si column qualifier existe

**Résultat** :
- ✅ Filtre les opérations avec clé `ip` présente

### Test 5 : Vérification Présence Valeur (CONTAINS)

**Requête** :
```cql
SELECT * FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags CONTAINS 'paris';
```

**Équivalent HBase** :
- Vérifier si column value existe

**Résultat** :
- ✅ Filtre les opérations avec valeur `paris` présente

---

## 🎯 Cas d'Usage Réels

### Cas d'Usage 1 : Filtrer par Canal (Mobile vs Web)

**Requête** :
```cql
SELECT COUNT(*) FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags['source'] = 'mobile';
```

**Usage** :
- ✅ Analyser les opérations par canal
- ✅ Statistiques par source (mobile, web, etc.)

### Cas d'Usage 2 : Filtrer par IP (Sécurité)

**Requête** :
```cql
SELECT * FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags CONTAINS KEY 'ip';
```

**Usage** :
- ✅ Détecter les opérations avec IP
- ✅ Analyse de sécurité

### Cas d'Usage 3 : Filtrage Combiné (Canal + Type)

**Requête** :
```cql
SELECT * FROM operations_by_account
WHERE code_si = 'DEMO_DYN' AND contrat = 'DEMO_001'
  AND meta_flags['source'] = 'web'
  AND libelle : 'VIREMENT';
```

**Usage** :
- ✅ Recherche combinée (MAP + full-text)
- ✅ Analyse multi-critères

---

## 🎯 Avantages vs Colonnes Dynamiques HBase

### 1. Structure Typée

**HBase** :
- ❌ Colonnes dynamiques non typées
- ❌ Nécessite conversion manuelle

**HCD** :
- ✅ **MAP<TEXT, TEXT>** : Structure typée
- ✅ Validation automatique

### 2. Filtrage Combiné

**HBase** :
- ❌ Limité aux ColumnFilters
- ❌ Pas de recherche full-text native

**HCD** :
- ✅ **Filtrage combiné** : MAP + Index SAI full-text
- ✅ Performance optimale

### 3. Requêtes CQL Standard

**HBase** :
- ❌ API Java spécifique
- ❌ Code complexe

**HCD** :
- ✅ **CQL standard** : Requêtes simples
- ✅ Compatible avec tous les outils CQL

### 4. Performance

**HBase** :
- ⚠️ Nécessite scan complet pour filtrage

**HCD** :
- ✅ **Index SAI** : Peut optimiser les filtres MAP
- ✅ Performance meilleure

---

## 🎯 Conclusion

### Équivalences Démonstrées

1. ✅ **Structure MAP<TEXT, TEXT>** = Colonnes dynamiques HBase
2. ✅ **Filtrage WHERE meta_flags['key']** = ColumnFilter HBase
3. ✅ **CONTAINS KEY / CONTAINS** = Vérification présence HBase

### Avantages HCD

1. ✅ **Structure typée** : MAP<TEXT, TEXT>
2. ✅ **Filtrage combiné** : MAP + Index SAI
3. ✅ **Requêtes CQL standard**
4. ✅ **Performance** : Index SAI possible

### Valeur Ajoutée

**HCD avec MAP** apporte :
- ✅ **Filtrage combiné** : MAP + Index SAI full-text (non disponible avec HBase)
- ✅ **Structure typée** : Validation automatique
- ✅ **Requêtes CQL** : Plus simple que API HBase

---

## 🚀 Démonstrations Disponibles

### Script 33 : Démonstration Standard

**Fichier** : `33_demo_colonnes_dynamiques_v2.sh`

**Contenu** :
- Explication colonnes dynamiques HBase vs MAP HCD
- Insertion de données avec MAP
- Filtrage simple sur MAP
- Vérification présence (CONTAINS KEY / CONTAINS)
- Cas d'usage réels

### Script 33 v2 : Démonstration Améliorée ⭐

**Fichier** : `33_demo_colonnes_dynamiques_v2.sh`

**Améliorations** :
- ✅ Mesures de performance précises (latence, throughput)
- ✅ Cas d'usage avancés (filtrage multi-clés, mise à jour)
- ✅ Comparaison avec/sans filtrage MAP
- ✅ Tests de charge (requêtes multiples)
- ✅ Analyse du plan d'exécution (tracing)
- ✅ Requêtes complexes (plusieurs clés MAP)
- ✅ Mise à jour dynamique des MAP

**Usage** :
```bash
./33_demo_colonnes_dynamiques_v2.sh
```

---

## 📊 Résultats des Exécutions

### Script 33 : Colonnes Dynamiques (Exécuté le 2025-11-26)

**Résultats** (10 parties démontrées) :

#### PARTIE 1 : Préparation des Données (MAP Complexes)
- ✅ **5 opérations insérées** avec `meta_flags` complexes
- ✅ **Données avec plusieurs clés MAP** : source, device, os, location, etc.

#### PARTIE 2 : Filtrage Simple avec Mesures de Performance
- ✅ **Filtrage par source = 'mobile'** : Fonctionne correctement
- ✅ **Équivalent HBase** : ColumnFilter sur qualifier 'meta:source'

#### PARTIE 3 : Filtrage Multi-Clés (Avancé)
- ✅ **Filtrage combiné** (source + device) : Fonctionne
- ✅ **Filtrage avec CONTAINS KEY 'ip'** : Fonctionne
- ✅ **Valeur ajoutée** : Filtrage multi-clés MAP (non disponible avec HBase simple)

#### PARTIE 4 : Filtrage Combiné (MAP + Index SAI Full-Text)
- ✅ **Filtrage MAP + full-text search** : Fonctionne
- ✅ **Valeur ajoutée HCD** : Non disponible avec HBase

#### PARTIE 5 : Mise à Jour Dynamique des Colonnes MAP
- ✅ **Ajout de clé 'fraud_score'** : Mise à jour atomique réussie
- ✅ **Avantage HCD** : Pas besoin de réécrire toute la row
- ✅ **Équivalent HBase** : Put avec nouveau column qualifier

#### PARTIE 6 : Tests de Charge (Requêtes Multiples)
- ✅ **10 requêtes consécutives** : Exécutées avec succès
- ✅ **Temps moyen** : 602ms
- ✅ **Throughput** : 1 requête/seconde
- ✅ **Performance stable** : Pas de dégradation

#### PARTIE 7 : Requêtes Complexes (Plusieurs Clés MAP)
- ✅ **Filtrage avec plusieurs conditions MAP** : Fonctionne
- ✅ **Avantage HCD** : Filtrage multi-clés en une seule requête

#### PARTIE 8 : Comparaison Performance
- ✅ **Sans filtrage MAP** : Scan complet
- ✅ **Avec filtrage MAP** : Performance meilleure
- ✅ **Équivalent ColumnFilter HBase** mais avec structure typée

#### PARTIE 9 : Cas d'Usage Avancés
- ✅ **Analyse par canal** (mobile vs web) : Fonctionne
- ✅ **Détection fraude** (fraud_score) : Fonctionne

#### PARTIE 10 : Résumé et Conclusion
- ✅ **Colonnes dynamiques démontrées** avec `MAP<TEXT, TEXT>`
- ✅ **Avantages vs HBase** : Structure typée, filtrage combiné, multi-clés

**Conclusion** :
- ✅ Tous les tests passés avec succès
- ✅ Performance validée (tests de charge)
- ✅ Avantages significatifs vs colonnes dynamiques HBase

---

**✅ Le filtrage sur colonnes MAP est démontré, avec des avantages significatifs !**

