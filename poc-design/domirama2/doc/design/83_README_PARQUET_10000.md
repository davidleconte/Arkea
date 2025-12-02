# 📊 Fichiers Parquet 10 000 Lignes - Full-Text Search

**Date** : 2025-11-25  
**Objectif** : Démonstration complète du full-text search avec des données réalistes et complexes

---

## 🎯 Génération des Données

### Script de Génération

**Fichier** : `generate_realistic_data.py`

**Caractéristiques** :

- ✅ **10 000 lignes** de données réalistes
- ✅ **Libellés complexes** : Opérations bancaires françaises avec accents, variations
- ✅ **50 comptes différents** pour varier les données
- ✅ **Période 2 ans** (2023-2024) pour historique complet
- ✅ **Catégorisation automatique** avec scores de confiance

### Libellés Inclus

**Catégories variées** :

- 🏠 **Habitation** : Loyers, charges, taxes foncières
- 🛒 **Alimentation** : Supermarchés, marchés, boulangeries
- 🍽️ **Restaurants** : Restaurants, fast-food, livraison
- 🚇 **Transport** : RATP, Uber, SNCF, essence, parking
- ⚡ **Utilitaires** : EDF, Orange, Netflix, Spotify
- 💰 **Revenus** : Salaires, primes, allocations
- 🎬 **Loisirs** : Cinéma, théâtre, sport, shopping
- 🏥 **Santé** : Pharmacie, médecin, mutuelle
- 🏦 **Banque** : Frais bancaires, agios

**Complexité des libellés** :

- ✅ Accents français (é, è, à, ç, etc.)
- ✅ Variations (LOYER JANVIER, LOYER FEVRIER, etc.)
- ✅ Noms propres (CARREFOUR, MONOPRIX, EDF, etc.)
- ✅ Abréviations (CB, RATP, SNCF, etc.)
- ✅ Combinaisons complexes (CB CARREFOUR CITY PARIS 15)

---

## 📁 Fichiers Générés

### CSV Source

**Fichier** : `data/operations_10000.csv`

- **Lignes** : 10 001 (en-tête + 10 000 données)
- **Taille** : ~1.5 MB
- **Format** : CSV avec en-tête

### Parquet Optimisé

**Fichier** : `data/operations_10000.parquet/`

- **Format** : Parquet (binaire optimisé)
- **Taille** : ~300-500 KB (compression)
- **Schéma** : Typé (String, Int, Decimal, Timestamp)

---

## 🚀 Utilisation

### 1. Générer les Données CSV

```bash
cd poc-design/domirama2
python3 generate_realistic_data.py
```

**Résultat** : `data/operations_10000.csv` (10 000 lignes)

### 2. Convertir en Parquet

```bash
./14_generate_parquet_from_csv.sh data/operations_10000.csv data/operations_10000.parquet
```

**Résultat** : `data/operations_10000.parquet/` (format optimisé)

### 3. Charger dans HCD

```bash
./11_load_domirama11_load_domirama2_data_parquet.sh data/operations_10000.parquet
```

**Résultat** : 10 000 opérations dans `domirama2_poc.operations_by_account`

---

## 🔍 Tests Full-Text Search

### Exemples de Requêtes

#### 1. Recherche Simple

```cql
SELECT libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND libelle : 'loyer'
LIMIT 20;
```

**Résultat attendu** : Tous les loyers (LOYER JANVIER, LOYER FEVRIER, etc.)

#### 2. Recherche avec Stemming

```cql
SELECT libelle, montant
FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND libelle : 'loyers'  -- Pluriel
LIMIT 20;
```

**Résultat attendu** : Trouve aussi "LOYER" (singulier) grâce au stemming français

#### 3. Recherche Insensible à la Casse

```cql
SELECT libelle, montant
FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND libelle : 'Carrefour'  -- Majuscule
LIMIT 20;
```

**Résultat attendu** : Trouve "CB CARREFOUR CITY PARIS 15" (majuscules)

#### 4. Recherche Multi-Termes (AND)

```cql
SELECT libelle, montant
FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND libelle : 'carrefour'
  AND libelle : 'paris'
LIMIT 20;
```

**Résultat attendu** : Opérations Carrefour à Paris uniquement

#### 5. Recherche par Catégorie

```cql
SELECT libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND cat_auto = 'ALIMENTATION'
LIMIT 50;
```

**Résultat attendu** : Toutes les opérations d'alimentation

#### 6. Recherche Complexe (Full-Text + Filtre)

```cql
SELECT libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '01'
  AND contrat = '1234567890'
  AND libelle : 'restaurant'
  AND montant < -50
LIMIT 20;
```

**Résultat attendu** : Restaurants avec montant > 50€

---

## 📊 Statistiques des Données

### Répartition par Catégorie

- **HABITATION** : ~15% (loyers, charges)
- **ALIMENTATION** : ~20% (supermarchés, marchés)
- **RESTAURANT** : ~10% (restaurants, fast-food)
- **TRANSPORT** : ~15% (RATP, Uber, essence)
- **UTILITAIRES** : ~15% (EDF, Orange, abonnements)
- **REVENUS** : ~5% (salaires, primes)
- **LOISIRS** : ~10% (cinéma, shopping, sport)
- **SANTE** : ~5% (pharmacie, médecin)
- **DIVERS** : ~5% (autres)

### Répartition par Type

- **CARTE** : ~40% (paiements CB)
- **VIREMENT** : ~30% (virements SEPA)
- **PRELEVEMENT** : ~25% (prélèvements automatiques)
- **CREDIT** : ~5% (salaires, revenus)

---

## ✅ Avantages pour le POC

### 1. Démonstration Full-Text

- ✅ **10 000 lignes** : Volume suffisant pour démontrer les performances
- ✅ **Libellés variés** : Teste le stemming, l'asciifolding, la casse
- ✅ **Accents français** : Démonstration du traitement des caractères spéciaux
- ✅ **Variations** : Teste la recherche avec variations (LOYER vs LOYERS)

### 2. Performance

- ✅ **Parquet** : Lecture 3-10x plus rapide que CSV
- ✅ **Index SAI** : Recherche full-text optimisée
- ✅ **Compression** : Fichier 3x plus petit que CSV

### 3. Réalisme

- ✅ **Données réalistes** : Opérations bancaires françaises authentiques
- ✅ **Historique 2 ans** : Démontre la gestion du temps
- ✅ **50 comptes** : Variété des données

---

## 🔧 Scripts Disponibles

1. **`generate_realistic_data.py`** : Génère 10 000 lignes CSV
2. **`14_generate_parquet_from_csv.sh`** : Convertit CSV → Parquet
3. **`11_load_domirama11_load_domirama2_data_parquet.sh`** : Charge Parquet → HCD
4. **`12_test_domirama12_test_domirama2_search.sh`** : Tests de recherche

---

## 📝 Notes

- Les libellés sont en **MAJUSCULES** (convention bancaire française)
- Les accents sont présents pour tester l'**asciifolding**
- Les variations (singulier/pluriel) testent le **stemming français**
- Les noms propres testent la recherche **insensible à la casse**

---

**Date de création** : 2025-11-25  
**Statut** : ✅ **Prêt pour démonstration full-text search**
