# 🔍 Guide de Recherche - DomiramaCatOps

**Date** : 2025-12-01
**Objectif** : Guide complet pour la recherche avancée dans DomiramaCatOps
**Prérequis** : Données chargées (voir [Guide d'Ingestion](03_GUIDE_INGESTION.md))

---

## 📋 Table des Matières

1. [Types de Recherche](#types-de-recherche)
2. [Recherche par Catégorie](#recherche-par-catégorie)
3. [Recherche Full-Text](#recherche-full-text)
4. [Recherche Vectorielle (Fuzzy)](#recherche-vectorielle-fuzzy)
5. [Recherche Hybride](#recherche-hybride)
6. [Recherche N-Gram](#recherche-n-gram)
7. [Exemples Complets](#exemples-complets)
8. [Prochaines Étapes](#prochaines-étapes)

---

## 🎯 Types de Recherche

DomiramaCatOps supporte 5 types de recherche :

| Type | Description | Index | Script |
|------|-------------|-------|--------|
| **Par Catégorie** | Filtrage par `cat_auto` ou `cat_user` | SAI | `08_test_category_search.sh` |
| **Full-Text** | Recherche par libellé avec index SAI | SAI Full-Text | `08_test_category_search.sh` |
| **Vectorielle** | Recherche floue avec embeddings | SAI Vector | `16_test_fuzzy_search.sh` |
| **Hybride** | Combinaison Full-Text + Vector | SAI Full-Text + Vector | `18_test_hybrid_search.sh` |
| **N-Gram** | Recherche partielle avec tokens | SAI + SET | `08_test_category_search.sh` |

---

## 🏷️ Recherche par Catégorie

### Script : `08_test_category_search.sh`

**Objectif** : Rechercher les opérations par catégorie

**Exécution** :

```bash
cd scripts
./08_test_category_search.sh
```

### Exemple 1 : Recherche par Catégorie Batch

```cql
SELECT libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1' AND contrat = '100000000'
  AND cat_auto = 'LOYER'
LIMIT 10;
```

**Explication** :

- **WHERE** : Filtre sur la partition (code_si, contrat)
- **cat_auto** : Utilise l'index SAI `idx_cat_auto`
- **Performance** : O(log n) avec index vs O(n) sans index

### Exemple 2 : Recherche par Catégorie Client

```cql
SELECT libelle, montant, cat_user
FROM operations_by_account
WHERE code_si = '1' AND contrat = '100000000'
  AND cat_user = 'LOYER'
LIMIT 10;
```

**Explication** :

- **cat_user** : Utilise l'index SAI `idx_cat_user`
- **Stratégie multi-version** : Priorise `cat_user` si non null

**Rapport généré** : `doc/demonstrations/08_CATEGORY_SEARCH_DEMONSTRATION.md`

---

## 📝 Recherche Full-Text

### Script : `08_test_category_search.sh`

**Objectif** : Rechercher par libellé avec index SAI Full-Text

### Exemple : Recherche Full-Text

```cql
SELECT libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1' AND contrat = '100000000'
  AND libelle : 'loyer'
LIMIT 10;
```

**Explication** :

- **libelle : 'loyer'** : Utilise l'index SAI Full-Text `idx_libelle_fulltext`
- **Analyzer français** : lowercase, frenchLightStem, asciiFolding
- **Performance** : Recherche rapide même sur grandes collections

### Avantages

✅ **Analyzer français** : Stemming et normalisation
✅ **Tolérance aux accents** : asciiFolding
✅ **Performance** : Index intégré (pas d'Elasticsearch externe)

---

## 🔀 Recherche Vectorielle (Fuzzy)

### Script : `16_test_fuzzy_search.sh`

**Objectif** : Recherche floue avec embeddings ByteT5

**Exécution** :

```bash
./16_test_fuzzy_search.sh
```

### Exemple : Recherche Floue

```cql
SELECT libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1' AND contrat = '100000000'
ORDER BY libelle_embedding ANN OF [0.123, 0.456, ...]
LIMIT 5;
```

**Explication** :

- **ORDER BY ... ANN OF** : Tri par similarité vectorielle (Approximate Nearest Neighbor)
- **libelle_embedding** : Embeddings ByteT5 1472 dimensions
- **Tolérance aux typos** : 'LOYR' trouve 'LOYER'

### Cas d'Usage

| Requête | Typo | Résultat |
|---------|------|----------|
| 'LOYER' | 'LOYR' | ✅ Trouve 'LOYER' |
| 'VIREMENT' | 'VIREMNT' | ✅ Trouve 'VIREMENT' |
| 'PAIEMENT CARTE' | 'PAIMENT CART' | ✅ Trouve 'PAIEMENT CARTE' |

**Rapport généré** : `doc/demonstrations/16_FUZZY_SEARCH_DEMONSTRATION.md`

---

## 🔀 Recherche Hybride

### Script : `18_test_hybrid_search.sh`

**Objectif** : Combinaison Full-Text + Vector Search

**Exécution** :

```bash
./18_test_hybrid_search.sh
```

### Exemple : Recherche Hybride

```cql
SELECT libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1' AND contrat = '100000000'
  AND libelle : 'loyer'  -- Full-Text filtre
ORDER BY libelle_embedding_invoice ANN OF [...]  -- Vector trie
LIMIT 10;
```

**Explication** :

- **WHERE libelle : 'terme'** : Full-Text Search filtre les résultats pertinents
- **ORDER BY ... ANN OF** : Vector Search trie selon similarité
- **Résultat** : Précision (Full-Text) + Tolérance aux typos (Vector)

### Modèles Disponibles

| Modèle | Colonne | Cas d'Usage | Performance |
|--------|---------|------------|-------------|
| **ByteT5-small** | `libelle_embedding` | 'PAIEMENT CARTE' / 'CB' | Moyenne |
| **multilingual-e5-large** | `libelle_embedding_e5` | Généraliste | Lente |
| **Modèle Facturation** | `libelle_embedding_invoice` | Spécialisé bancaire | 4x plus rapide |

**Rapport généré** : `doc/demonstrations/18_HYBRID_SEARCH_DEMONSTRATION.md`

---

## 🔤 Recherche N-Gram

### Exemple : Recherche Partielle avec Tokens

```cql
SELECT libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1' AND contrat = '100000000'
  AND libelle_tokens CONTAINS 'loy'
LIMIT 10;
```

**Explication** :

- **libelle_tokens** : SET<TEXT> avec N-grams 3-8 caractères
- **CONTAINS** : Recherche partielle dans le SET
- **Performance** : Index SAI sur SET

### Avantages

✅ **Recherche partielle** : 'loy' trouve 'LOYER'
✅ **Performance** : Index SAI sur SET
✅ **Flexibilité** : Combinaison avec Full-Text

---

## 📚 Exemples Complets

### Exemple 1 : Recherche Multi-Critères

```cql
SELECT libelle, montant, cat_auto, cat_user
FROM operations_by_account
WHERE code_si = '1' AND contrat = '100000000'
  AND libelle : 'loyer'
  AND cat_auto = 'LOYER'
  AND montant > 1000
ORDER BY date_op DESC
LIMIT 10;
```

**Explication** :

- **Full-Text** : `libelle : 'loyer'`
- **Filtre catégorie** : `cat_auto = 'LOYER'`
- **Range query** : `montant > 1000`
- **Tri temporel** : `ORDER BY date_op DESC`

### Exemple 2 : Recherche avec Priorité Client

```cql
SELECT libelle, montant,
       COALESCE(cat_user, cat_auto) AS categorie_finale,
       cat_confidence
FROM operations_by_account
WHERE code_si = '1' AND contrat = '100000000'
  AND libelle : 'virement'
ORDER BY date_op DESC
LIMIT 10;
```

**Explication** :

- **COALESCE** : Priorise `cat_user` si non null, sinon `cat_auto`
- **Stratégie multi-version** : Aucune correction client perdue

---

## 🚀 Prochaines Étapes

1. **Tester les autres fonctionnalités** :
   - Règles personnalisées : `10_test_regles_personnalisees.sh`
   - Feedbacks : `11_test_feedbacks_counters.sh`
   - Data API : `24_demo_data_api.sh`

2. **Consulter les démonstrations** :
   - Tous les scripts génèrent des rapports dans `doc/demonstrations/`

3. **Consulter la documentation** :
   - [INDEX.md](../INDEX.md)
   - [Guide de Configuration](02_GUIDE_SETUP.md)
   - [Guide d'Ingestion](03_GUIDE_INGESTION.md)

---

## 📚 Ressources

- **Scripts** : Tous les scripts sont dans `scripts/`
- **Démonstrations** : Rapports auto-générés dans `doc/demonstrations/`
- **Documentation** : [INDEX.md](../INDEX.md)

---

**Date de création** : 2025-12-01
**Dernière mise à jour** : 2025-12-01
