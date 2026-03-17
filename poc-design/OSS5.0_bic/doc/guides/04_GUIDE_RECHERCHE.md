# 📖 Guide : Recherche et Requêtes dans le POC BIC

**Date** : 2025-12-01
**Version** : 1.0.0
**Objectif** : Guide complet pour effectuer des recherches et requêtes dans HCD

---

## 📋 Table des Matières

- [Vue d'Ensemble](#vue-densemble)
- [Timeline Conseiller](#timeline-conseiller)
- [Filtrage](#filtrage)
- [Recherche Full-Text](#recherche-full-text)
- [Pagination](#pagination)
- [Performance](#performance)

---

## 🎯 Vue d'Ensemble

Le POC BIC supporte plusieurs types de recherches :

1. **Timeline** : Historique des interactions d'un client
2. **Filtrage** : Par canal, type, résultat, période
3. **Recherche Full-Text** : Recherche dans le contenu JSON
4. **Filtres Combinés** : Combinaison de plusieurs filtres

---

## 📅 Timeline Conseiller

### Requête de Base

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001' AND numero_client = 'CLIENT123'
LIMIT 100;
```

### Avec Pagination

```cql
-- Première page
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001' AND numero_client = 'CLIENT123'
LIMIT 20;

-- Page suivante (avec curseur)
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND date_interaction < '2024-06-15 10:30:00+0000'
LIMIT 20;
```

### Test Automatique

```bash
./scripts/11_test_timeline_conseiller.sh EFS001 CLIENT123
```

---

## 🔍 Filtrage

### Par Canal

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND canal = 'email'
LIMIT 100;
```

**Canaux disponibles** : `email`, `SMS`, `agence`, `telephone`, `web`, `RDV`, `agenda`, `mail`

### Par Type d'Interaction

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND type_interaction = 'consultation'
LIMIT 100;
```

**Types disponibles** : `consultation`, `conseil`, `transaction`, `reclamation`, `achat`, `demande`, `suivi`

### Par Résultat

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND resultat = 'succes'
LIMIT 100;
```

**Résultats disponibles** : `succes`, `echec`, `en_cours`, `annule`

### Par Période

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND date_interaction >= '2024-01-01 00:00:00+0000'
  AND date_interaction < '2024-12-31 23:59:59+0000'
LIMIT 100;
```

### Tests Automatiques

```bash
# Filtrage par canal et résultat
./scripts/12_test_filtrage_canal.sh

# Filtrage par type
./scripts/13_test_filtrage_type.sh

# Filtres combinés exhaustifs
./scripts/18_test_filtering.sh
```

---

## 🔎 Recherche Full-Text

### Recherche Simple

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND json_data : 'reclamation'
LIMIT 100;
```

### Recherche Multi-Termes

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND json_data : 'reclamation'
  AND json_data : 'urgent'
LIMIT 100;
```

### Recherche avec Analyseurs Lucene

L'index SAI full-text utilise des analyseurs Lucene pour :

- **Lowercase** : Recherche insensible à la casse
- **Asciifolding** : Normalisation des accents
- **French Light Stemming** : Dérivation française

**Exemple** : La recherche `'reclamation'` trouvera aussi `'réclamation'`, `'réclamations'`, etc.

### Test Automatique

```bash
./scripts/16_test_fulltext_search.sh
```

---

## 📄 Pagination

### Pagination Simple (LIMIT)

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001' AND numero_client = 'CLIENT123'
LIMIT 20;
```

### Pagination avec Curseur

```cql
-- Page 1
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001' AND numero_client = 'CLIENT123'
LIMIT 20;

-- Page 2 (utiliser le dernier date_interaction de la page 1)
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND date_interaction < '2024-06-15 10:30:00+0000'
LIMIT 20;
```

### Pagination Exhaustive

Le script 11 teste la pagination exhaustive (toutes les pages jusqu'à la fin).

---

## ⚡ Performance

### Objectifs de Performance

- **Timeline simple** : < 100ms
- **Filtrage** : < 100ms
- **Recherche full-text** : < 200ms
- **Filtres combinés** : < 100ms

### Tests de Performance

```bash
# Tests de performance globaux
./scripts/19_test_performance_global.sh 50

# Tests de charge et scalabilité
./scripts/20_test_load_global.sh 10K 10
```

### Optimisations

1. **Utiliser les index SAI** : Les filtres sur `canal`, `type_interaction`, `resultat` utilisent automatiquement les index SAI
2. **Partition key** : Toujours inclure `code_efs` et `numero_client` dans les requêtes
3. **LIMIT** : Utiliser LIMIT pour limiter le nombre de résultats
4. **Pagination** : Utiliser la pagination pour les grandes listes

---

## 📚 Exemples Complets

### Exemple 1 : Timeline avec Filtres

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND canal = 'email'
  AND type_interaction = 'consultation'
  AND date_interaction >= '2024-01-01 00:00:00+0000'
LIMIT 50;
```

### Exemple 2 : Recherche Full-Text avec Filtres

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND json_data : 'reclamation'
  AND canal = 'email'
LIMIT 50;
```

### Exemple 3 : Export Batch (Période)

```cql
SELECT * FROM bic_poc.interactions_by_client
WHERE code_efs = 'EFS001'
  AND numero_client = 'CLIENT123'
  AND date_interaction >= '2024-01-01 00:00:00+0000'
  AND date_interaction < '2024-12-31 23:59:59+0000';
```

---

## 🔍 Dépannage

### Problème : Requête lente

**Symptôme** : Requête prend > 1 seconde

**Solution** :

1. Vérifier que les index SAI sont créés
2. Vérifier que la partition key est utilisée
3. Utiliser LIMIT pour limiter les résultats
4. Vérifier avec `TRACING ON` :

```cql
TRACING ON;
SELECT * FROM bic_poc.interactions_by_client WHERE ...;
```

### Problème : Aucun résultat

**Symptôme** : `0 rows`

**Solution** :

1. Vérifier que les données existent : `SELECT COUNT(*) FROM ...`
2. Vérifier les filtres (canal, type, etc.)
3. Vérifier la période (date_interaction)

---

**Date** : 2025-12-01
**Version** : 1.0.0
