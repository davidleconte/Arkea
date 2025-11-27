# 🔍 Index SAI Avancés - Full-Text Search Complexe

## Vue d'ensemble

Ce document décrit la configuration des index SAI (Storage-Attached Indexing) avancés pour le POC Domirama2, permettant des recherches full-text complexes en français.

## ⚠️ Limitation SAI

**Important** : SAI ne permet qu'**un seul index par colonne**. Il n'est pas possible de créer plusieurs index avec des analyzers différents sur la même colonne.

**Solution** : Créer un index unique avec un analyzer combinant toutes les fonctionnalités nécessaires.

## 📋 Index Créé

### `idx_libelle_fulltext_advanced`

**Analyzer** : Multi-capacités pour le français

```cql
CREATE CUSTOM INDEX idx_libelle_fulltext_advanced
ON operations_by_account(libelle)
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

### Capacités

1. **Tokenizer Standard**
   - Découpe le texte en tokens selon les espaces et ponctuation
   - Gère les mots composés et les nombres

2. **Filtre Lowercase**
   - Convertit tout en minuscules
   - Recherche insensible à la casse

3. **Filtre AsciiFolding**
   - Supprime les accents (é → e, è → e, à → a, etc.)
   - Permet de rechercher "impayé" et trouver "IMPAYE"

4. **Filtre FrenchLightStem**
   - Stemming français léger
   - Gère pluriel/singulier (loyers → loyer)
   - Gère variations grammaticales

## 🔍 Exemples de Recherches

### 1. Recherche Simple

```cql
SELECT libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'loyer';
```

**Résultat** : Trouve "LOYER", "LOYERS", "loyer", etc.

### 2. Recherche avec Accent (Asciifolding)

```cql
SELECT libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'impayé';
```

**Résultat** : Trouve "IMPAYE", "impayé", "IMPAYÉ", etc.

### 3. Recherche avec Stemming (Pluriel)

```cql
SELECT libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'loyers';
```

**Résultat** : Trouve "LOYER", "LOYERS", "loyers", etc.

### 4. Recherche Multi-Termes

```cql
SELECT libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'loyer'
  AND libelle : 'paris';
```

**Résultat** : Trouve les opérations contenant "loyer" ET "paris"

### 5. Recherche avec Filtres

```cql
SELECT libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'virement'
  AND libelle : 'impaye'
  AND cat_auto = 'VIREMENT'
  AND montant < 0;
```

**Résultat** : Virements impayés avec filtre catégorie et montant

## 📊 Tests Validés

✅ **Stemming français** : `'loyers'` → trouve `'LOYER'`
✅ **Asciifolding** : `'impayé'` → trouve `'IMPAYE'`
✅ **Case-insensitive** : `'LOYER'` = `'loyer'` = `'Loyer'`
✅ **Multi-termes** : `'loyer' AND 'paris'` fonctionne
✅ **Combinaisons** : Full-text + filtres (montant, catégorie, date)

## 🚀 Utilisation

### Scripts

1. **Configuration** : `./16_setup_advanced_indexes.sh`
   - Crée l'index avancé
   - Supprime les anciens index si nécessaire

2. **Tests** : `./17_test_advanced_search.sh`
   - Exécute 20 tests de recherche complexes
   - Valide toutes les fonctionnalités

### Attente d'Indexation

Après création de l'index, attendre **30-60 secondes** pour que l'indexation soit complète avant de tester les recherches.

## 💡 Notes Techniques

### Pourquoi un seul index ?

SAI stocke les index directement dans les SSTables. Un seul index par colonne permet :
- **Performance optimale** : Pas de duplication d'index
- **Cohérence** : Un seul analyzer pour toutes les recherches
- **Simplicité** : Pas de choix d'index à faire dans les requêtes

### Alternatives pour recherches spécialisées

Si des recherches très spécialisées sont nécessaires (ex: recherche exacte sans stemming), on peut :
1. Créer une **colonne dérivée** (ex: `libelle_exact`) avec un index dédié
2. Utiliser des **filtres dans les requêtes** pour affiner les résultats
3. Combiner plusieurs **colonnes** avec des index différents

## 📝 Références

- [SAI Quickstart](https://docs.datastax.com/en/hyper-converged-database/1.2/tutorials/sai-quickstart.html)
- [Use Analyzers with CQL](https://docs.datastax.com/en/hyper-converged-database/1.2/tutorials/use-analyzers-with-cql.html)
- [CQL SAI Documentation](https://docs.datastax.com/en/cql/hcd/develop/indexing/sai/sai-faq.html)

