# 🔍 Requêtes avec Fenêtre Glissante et STARTROW/STOPROW

**Date** : 2025-11-25  
**Objectif** : Démontrer les requêtes en base (hors exports) avec fenêtre glissante et STARTROW/STOPROW

---

## 🎯 Contexte

Les **fenêtres glissantes (TIMERANGE)** et **STARTROW/STOPROW** ne sont pas seulement pour les exports, mais aussi pour les **requêtes en base de données**.

### Besoins Arkéa

1. **Requêtes avec fenêtre glissante** : Accès aux données par période (mensuelle, hebdomadaire, etc.)
2. **Requêtes avec STARTROW/STOPROW** : Ciblage précis des données par plages de dates/numéros
3. **Performance** : Requêtes rapides sans scan complet

---

## 📋 Fenêtre Glissante (TIMERANGE) pour Requêtes

### Équivalent HBase

```java
// HBase : SCAN avec TIMERANGE
Scan scan = new Scan();
scan.setTimeRange(startTimestamp, endTimestamp);
scan.setStartRow(startRow);
scan.setStopRow(stopRow);
ResultScanner scanner = table.getScanner(scan);
```

### Solution HCD

```cql
-- HCD : WHERE date_op BETWEEN start AND end
SELECT * FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-01-01' AND date_op < '2024-02-01'
ORDER BY date_op DESC, numero_op ASC;
```

### Valeur Ajoutée SAI

**Sans SAI (HBase)** :

- ⚠️ SCAN complet de la partition
- ⚠️ Filtrage côté client
- ⚠️ Performance : O(n) où n = nombre d'opérations

**Avec SAI (HCD)** :

- ✅ Index sur `date_op` (clustering key)
- ✅ Recherche rapide sans scan complet
- ✅ Performance : O(log n) avec index
- ✅ **Valeur ajoutée** : Recherche combinée avec full-text

### Exemples de Requêtes

#### Exemple 1 : Requête Mensuelle

```cql
-- Requête pour janvier 2024
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-01-01' AND date_op < '2024-02-01'
ORDER BY date_op DESC, numero_op ASC
LIMIT 10;
```

**Valeur ajoutée SAI** :

- ✅ Index sur `date_op` optimise la recherche
- ✅ Pas de scan complet nécessaire
- ✅ Performance rapide même sur grandes plages

#### Exemple 2 : Requête avec Fenêtre Glissante (30 derniers jours)

```cql
-- Requête pour 30 derniers jours
SELECT code_si, contrat, date_op, numero_op, libelle, montant
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-11-01' AND date_op <= '2024-11-30'
ORDER BY date_op DESC
LIMIT 10;
```

**Valeur ajoutée SAI** :

- ✅ Index sur `date_op` optimise la recherche temporelle
- ✅ Requête rapide même sur grandes plages

#### Exemple 3 : Requête avec SAI (Date + Full-Text)

```cql
-- Requête avec filtre date + full-text search
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-01-01' AND date_op < '2024-02-01'
  AND libelle : 'LOYER'
ORDER BY date_op DESC
LIMIT 10;
```

**Valeur ajoutée SAI** :

- ✅ Combine index `date_op` (clustering) + `libelle` (full-text)
- ✅ Performance : Pas de scan complet, recherche indexée
- ✅ **Valeur ajoutée majeure** : Recherche combinée optimisée

---

## 📋 STARTROW/STOPROW pour Requêtes

### Équivalent HBase

```java
// HBase : SCAN avec STARTROW/STOPROW
Scan scan = new Scan();
scan.setStartRow(startRow);  // code_si + contrat + date_op + numero_op
scan.setStopRow(stopRow);
ResultScanner scanner = table.getScanner(scan);
```

### Solution HCD

```cql
-- HCD : WHERE sur clustering keys (date_op, numero_op)
SELECT * FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-01-15 10:00:00'
  AND date_op <= '2024-01-20 18:00:00'
  AND numero_op >= 1 AND numero_op <= 100
ORDER BY date_op DESC, numero_op ASC;
```

### Valeur Ajoutée SAI

**Sans SAI (HBase)** :

- ⚠️ SCAN avec STARTROW/STOPROW
- ⚠️ Filtrage côté client
- ⚠️ Performance : O(n) où n = nombre d'opérations dans la plage

**Avec SAI (HCD)** :

- ✅ Index sur clustering keys (`date_op`, `numero_op`)
- ✅ Recherche précise sans scan complet
- ✅ Performance : O(log n) avec index
- ✅ **Valeur ajoutée** : Recherche combinée avec full-text

### Exemples de Requêtes

#### Exemple 1 : Ciblage par Date Précise

```cql
-- Ciblage par plage de dates précise
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-01-15 10:00:00'
  AND date_op <= '2024-01-20 18:00:00'
ORDER BY date_op DESC, numero_op ASC
LIMIT 10;
```

**Valeur ajoutée SAI** :

- ✅ Index sur `date_op` (clustering key) optimise la recherche
- ✅ Pas de scan complet nécessaire

#### Exemple 2 : Ciblage par Date + Numéro Opération

```cql
-- Ciblage par date + numéro opération (STARTROW/STOPROW complet)
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op = '2024-01-15 10:00:00'
  AND numero_op >= 1 AND numero_op <= 100
ORDER BY date_op DESC, numero_op ASC
LIMIT 10;
```

**Valeur ajoutée SAI** :

- ✅ Index sur clustering keys (`date_op`, `numero_op`)
- ✅ Performance : Recherche précise sans scan complet

#### Exemple 3 : Ciblage avec SAI (Précis + Full-Text)

```cql
-- Ciblage précis + full-text search
SELECT code_si, contrat, date_op, numero_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-01-15' AND date_op <= '2024-01-20'
  AND numero_op >= 1 AND numero_op <= 100
  AND libelle : 'VIREMENT'
ORDER BY date_op DESC, numero_op ASC
LIMIT 10;
```

**Valeur ajoutée SAI** :

- ✅ Combine index clustering keys + `libelle` (full-text)
- ✅ Performance : Recherche précise et rapide
- ✅ **Valeur ajoutée majeure** : Recherche combinée optimisée

---

## 📊 Comparaison Performance

### Fenêtre Glissante (TIMERANGE)

| Critère | HBase (Sans SAI) | HCD (Avec SAI) | Amélioration |
|---------|------------------|----------------|--------------|
| **Méthode** | SCAN complet | Index sur date_op | ✅ Optimisé |
| **Performance** | O(n) | O(log n) | ✅ **Meilleure** |
| **Full-Text** | ❌ Non disponible | ✅ SAI full-text | ✅ **Valeur ajoutée** |
| **Recherche combinée** | ❌ Non disponible | ✅ Date + Full-Text | ✅ **Valeur ajoutée** |

### STARTROW/STOPROW

| Critère | HBase (Sans SAI) | HCD (Avec SAI) | Amélioration |
|---------|------------------|----------------|--------------|
| **Méthode** | SCAN avec STARTROW/STOPROW | Index clustering keys | ✅ Optimisé |
| **Performance** | O(n) | O(log n) | ✅ **Meilleure** |
| **Full-Text** | ❌ Non disponible | ✅ SAI full-text | ✅ **Valeur ajoutée** |
| **Recherche combinée** | ❌ Non disponible | ✅ Clustering + Full-Text | ✅ **Valeur ajoutée** |

---

## 🎯 Valeur Ajoutée SAI

### 1. Performance

**Sans SAI** :

- ⚠️ SCAN complet de la partition
- ⚠️ Filtrage côté client
- ⚠️ Performance : O(n)

**Avec SAI** :

- ✅ Index sur clustering keys (`date_op`, `numero_op`)
- ✅ Recherche indexée
- ✅ Performance : O(log n)
- ✅ **Amélioration significative**

### 2. Recherche Combinée

**Sans SAI** :

- ❌ Pas de recherche full-text
- ❌ Filtrage manuel côté client

**Avec SAI** :

- ✅ Index full-text sur `libelle`
- ✅ Recherche combinée (date + full-text)
- ✅ **Valeur ajoutée majeure**

### 3. Flexibilité

**Sans SAI** :

- ⚠️ Requêtes limitées aux filtres de base

**Avec SAI** :

- ✅ Requêtes complexes (date + full-text + autres filtres)
- ✅ Recherche sémantique possible (vector search)
- ✅ **Valeur ajoutée majeure**

---

## 📝 Scripts de Démonstration

### Script 29 : Requêtes Fenêtre Glissante

**Fichier** : `29_demo_requetes_fenetre_glissante.sh`

**Fonctionnalités** :

- ✅ Requêtes mensuelles (fenêtre glissante)
- ✅ Requêtes 30 derniers jours
- ✅ Requêtes avec SAI (date + full-text)
- ✅ Comparaison performance

**Usage** :

```bash
./29_demo_requetes_fenetre_glissante.sh
```

### Script 30 : Requêtes STARTROW/STOPROW

**Fichier** : `30_demo_requetes_startrow_stoprow.sh`

**Fonctionnalités** :

- ✅ Ciblage par date précise
- ✅ Ciblage par date + numéro opération
- ✅ Ciblage avec SAI (précis + full-text)
- ✅ Comparaison performance

**Usage** :

```bash
./30_demo_requetes_startrow_stoprow.sh
```

---

## ✅ Conclusion

### Valeur Ajoutée SAI

1. ✅ **Performance** : Index sur clustering keys (O(log n) vs O(n))
2. ✅ **Recherche combinée** : Date + Full-Text (non disponible en HBase)
3. ✅ **Flexibilité** : Requêtes complexes optimisées
4. ✅ **Valeur ajoutée majeure** : Recherche sémantique (vector search)

### Besoins Arkéa Satisfaits

1. ✅ **Requêtes avec fenêtre glissante** : Démontré avec WHERE date_op BETWEEN
2. ✅ **Requêtes avec STARTROW/STOPROW** : Démontré avec WHERE clustering keys
3. ✅ **Performance** : Optimisée avec SAI
4. ✅ **Valeur ajoutée** : Recherche combinée (date + full-text)

---

**✅ Les requêtes avec fenêtre glissante et STARTROW/STOPROW sont démontrées, avec la valeur ajoutée SAI !**
