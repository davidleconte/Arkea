# 🔍 Solutions pour CONTAINS KEY / CONTAINS côté Base de Données

**Date** : 2025-11-30  
**Problème** : Filtrage par CONTAINS KEY / CONTAINS nécessite actuellement un filtrage côté application  
**Objectif** : Résoudre ce problème côté base de données avec SAI

---

## 📋 Problème Actuel

### Situation

- **Test 4** : `WHERE meta_flags CONTAINS KEY 'ip'` → Filtrage côté application
- **Test 5** : `WHERE meta_flags CONTAINS 'paris'` → Filtrage côté application

### Limitations

- ⚠️ Performance dégradée (récupération de toutes les données puis filtrage)
- ⚠️ Consommation réseau accrue
- ⚠️ Charge CPU côté application

---

## ✅ SOLUTION 1 : Index SAI sur KEYS(meta_flags) pour CONTAINS KEY

### Principe

Créer un index SAI sur les **clés** du MAP pour permettre `CONTAINS KEY` côté base de données.

### Implémentation

```cql
-- Créer un index SAI sur les clés du MAP
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_flags_keys
ON operations_by_account(KEYS(meta_flags))
USING 'StorageAttachedIndex';
```

### Utilisation

```cql
-- Requête optimisée (plus besoin de filtrage côté application)
SELECT code_si, contrat, date_op, numero_op, libelle, meta_flags
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_flags CONTAINS KEY 'ip';
```

### Avantages

- ✅ **Performance** : Index SAI distribué, recherche rapide
- ✅ **Côté base de données** : Pas de filtrage côté application
- ✅ **Scalabilité** : Fonctionne sur grand volume
- ✅ **Pas d'ALLOW FILTERING** : Utilise l'index SAI

### Inconvénients

- ⚠️ **Stockage supplémentaire** : Index sur toutes les clés MAP
- ⚠️ **Limite 10 index SAI** : Compte dans la limite de 10 index par table

### Statut Support HCD

✅ **Supporté** : SAI supporte les index sur `KEYS(collection)` pour les MAP

---

## ✅ SOLUTION 2 : Index SAI sur VALUES(meta_flags) pour CONTAINS

### Principe

Créer un index SAI sur les **valeurs** du MAP pour permettre `CONTAINS` côté base de données.

### Implémentation

```cql
-- Créer un index SAI sur les valeurs du MAP
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_flags_values
ON operations_by_account(VALUES(meta_flags))
USING 'StorageAttachedIndex';
```

### Utilisation

```cql
-- Requête optimisée (plus besoin de filtrage côté application)
SELECT code_si, contrat, date_op, numero_op, libelle, meta_flags
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_flags CONTAINS 'paris';
```

### Avantages

- ✅ **Performance** : Index SAI distribué, recherche rapide
- ✅ **Côté base de données** : Pas de filtrage côté application
- ✅ **Scalabilité** : Fonctionne sur grand volume
- ✅ **Pas d'ALLOW FILTERING** : Utilise l'index SAI

### Inconvénients

- ⚠️ **Stockage supplémentaire** : Index sur toutes les valeurs MAP
- ⚠️ **Limite 10 index SAI** : Compte dans la limite de 10 index par table
- ⚠️ **Valeurs dupliquées** : Si plusieurs clés ont la même valeur, index plus volumineux

### Statut Support HCD

✅ **Supporté** : SAI supporte les index sur `VALUES(collection)` pour les MAP

---

## ✅ SOLUTION 3 : Index SAI sur MAP complet (ENTRIES)

### Principe

Créer un index SAI sur les **entrées complètes** (clé + valeur) du MAP.

### Implémentation

```cql
-- Créer un index SAI sur les entrées du MAP
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_flags_entries
ON operations_by_account(ENTRIES(meta_flags))
USING 'StorageAttachedIndex';
```

### Utilisation

```cql
-- Permet de rechercher sur clé ET valeur
SELECT code_si, contrat, date_op, numero_op, libelle, meta_flags
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_flags['source'] = 'mobile';  -- Utilise l'index
```

### Avantages

- ✅ **Flexibilité** : Supporte recherche sur clé, valeur, ou les deux
- ✅ **Performance** : Index SAI distribué

### Inconvénients

- ⚠️ **Stockage maximal** : Index sur toutes les entrées (clé + valeur)
- ⚠️ **Limite 10 index SAI** : Compte dans la limite

### Statut Support HCD

✅ **Supporté** : SAI supporte les index sur `ENTRIES(collection)` pour les MAP

---

## ✅ SOLUTION 4 : Colonnes Dérivées + Index SAI (Déjà Implémentée)

### Principe

Créer des colonnes dérivées pour les clés MAP fréquemment utilisées, avec index SAI.

### Implémentation Actuelle

```cql
-- Colonnes dérivées déjà créées
ALTER TABLE operations_by_account ADD meta_source TEXT;
ALTER TABLE operations_by_account ADD meta_device TEXT;
ALTER TABLE operations_by_account ADD meta_channel TEXT;
ALTER TABLE operations_by_account ADD meta_fraud_score TEXT;
ALTER TABLE operations_by_account ADD meta_ip TEXT;
ALTER TABLE operations_by_account ADD meta_location TEXT;

-- Index SAI sur colonnes dérivées (2 créés, 4 sans index - limite 10)
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_source
ON operations_by_account(meta_source)
USING 'StorageAttachedIndex';

CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_device
ON operations_by_account(meta_device)
USING 'StorageAttachedIndex';
```

### Utilisation

```cql
-- Pour les clés fréquentes (source, device) : Utiliser colonnes dérivées
SELECT * FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_source = 'mobile';  -- Utilise idx_meta_source

-- Pour les clés moins fréquentes : Utiliser CONTAINS KEY avec index SAI
SELECT * FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_flags CONTAINS KEY 'ip';  -- Utilise idx_meta_flags_keys
```

### Avantages

- ✅ **Performance optimale** : Index SAI sur colonnes dérivées
- ✅ **Flexibilité** : Colonnes dérivées pour clés fréquentes, index KEYS pour autres
- ✅ **Déjà partiellement implémenté** : 6 colonnes dérivées créées

### Inconvénients

- ⚠️ **Maintenance** : Synchronisation MAP / colonnes dérivées
- ⚠️ **Limite 10 index SAI** : Seulement 2 index créés sur colonnes dérivées

---

## 📊 Comparaison des Solutions

| Solution | Performance | Stockage | Flexibilité | Complexité | Recommandation |
|----------|-------------|----------|-------------|------------|----------------|
| **1. Index KEYS(meta_flags)** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ **Recommandé pour CONTAINS KEY** |
| **2. Index VALUES(meta_flags)** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ **Recommandé pour CONTAINS** |
| **3. Index ENTRIES(meta_flags)** | ⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⚠️  Si besoin clé+valeur |
| **4. Colonnes dérivées** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ✅ **Déjà implémenté (clés fréquentes)** |

---

## 🎯 Recommandation : Solution Hybride (Adaptée à la Limite 10 Index)

### ⚠️  Contrainte : Limite 10 Index SAI Atteinte

La table `operations_by_account` a déjà **9 index SAI** (sur 10 maximum). Il n'est **pas possible** de créer les index `idx_meta_flags_keys` et `idx_meta_flags_values` sans supprimer des index existants.

### Stratégie Optimale (Adaptée)

1. **Clés MAP fréquemment utilisées** (source, device, channel, etc.)
   - ✅ **Colonnes dérivées + Index SAI** (déjà implémenté pour source, device)
   - ✅ Performance maximale
   - ✅ **Recommandation** : Créer des colonnes dérivées pour toutes les clés fréquentes

2. **Clés MAP moins fréquentes** (ip, location, fraud_score, etc.)
   - ⚠️  **Option A** : Colonnes dérivées sans index SAI (filtrage avec ALLOW FILTERING si nécessaire)
   - ⚠️  **Option B** : Filtrage côté application (solution actuelle)
   - ⚠️  **Option C** : Supprimer un index moins utilisé pour créer idx_meta_flags_keys/values

3. **Clés MAP rares ou dynamiques**
   - ✅ Utiliser CONTAINS KEY / CONTAINS avec filtrage côté application
   - ✅ Ou créer colonnes dérivées si la clé devient fréquente

### Implémentation Recommandée

```cql
-- ============================================
-- SOLUTION HYBRIDE : Colonnes dérivées + Index SAI sur MAP
-- ============================================

-- 1. Colonnes dérivées pour clés fréquentes (DÉJÀ CRÉÉES)
-- meta_source, meta_device, meta_channel, meta_fraud_score, meta_ip, meta_location

-- 2. Index SAI sur colonnes dérivées (2 CRÉÉS, 4 SANS INDEX - limite 10)
-- idx_meta_source, idx_meta_device

-- 3. Index SAI sur KEYS(meta_flags) pour CONTAINS KEY
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_flags_keys
ON operations_by_account(KEYS(meta_flags))
USING 'StorageAttachedIndex';

-- 4. Index SAI sur VALUES(meta_flags) pour CONTAINS
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_flags_values
ON operations_by_account(VALUES(meta_flags))
USING 'StorageAttachedIndex';
```

### Compte Total Index SAI

| Index | Type | Statut |
|-------|------|--------|
| idx_cat_auto | Égalité | ✅ Existe |
| idx_cat_user | Égalité | ✅ Existe |
| idx_libelle_embedding_vector | Vector | ✅ Existe |
| idx_libelle_fulltext_advanced | Full-Text | ✅ Existe |
| idx_libelle_prefix_ngram | N-Gram | ✅ Existe |
| idx_libelle_tokens | Collection | ✅ Existe |
| idx_meta_device | Égalité | ✅ Existe |
| idx_montant | Range | ✅ Existe |
| idx_type_operation | Égalité | ✅ Existe |
| **Total** | | **9/10** (1 place disponible) |

⚠️  **Note** : La limite de 10 index SAI est presque atteinte. Il n'est **pas possible** de créer les index `idx_meta_flags_keys` et `idx_meta_flags_values` sans supprimer des index existants.

---

## 🚀 Plan d'Action (Adapté à la Limite 10 Index)

### ⚠️  Situation Actuelle

- **9 index SAI** déjà créés sur `operations_by_account`
- **1 place disponible** (sur 10 maximum)
- **Impossible** de créer les 2 index nécessaires (KEYS + VALUES)

### Option 1 : Supprimer un Index Moins Utilisé (Si Justifié)

Si un index existant est peu utilisé, on peut le supprimer pour créer les index MAP :

```cql
-- Supprimer un index moins utilisé (exemple : idx_montant si peu utilisé)
DROP INDEX IF EXISTS domiramacatops_poc.idx_montant;

-- Créer les index MAP
CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_flags_keys
ON operations_by_account(KEYS(meta_flags))
USING 'StorageAttachedIndex';

CREATE CUSTOM INDEX IF NOT EXISTS idx_meta_flags_values
ON operations_by_account(VALUES(meta_flags))
USING 'StorageAttachedIndex';
```

### Option 2 : Utiliser Colonnes Dérivées pour Toutes les Clés Fréquentes (Recommandé)

Créer des colonnes dérivées pour toutes les clés MAP fréquemment utilisées :

```cql
-- Colonnes dérivées déjà créées : meta_source, meta_device, meta_channel, meta_fraud_score, meta_ip, meta_location
-- Créer des index SAI sur les colonnes dérivées les plus utilisées
-- (Déjà fait pour meta_source et meta_device)

-- Pour les autres clés fréquentes, utiliser les colonnes dérivées sans index SAI
-- (filtrage avec ALLOW FILTERING si nécessaire, ou filtrage côté application)
```

### Étape 2 : Créer le Script d'Exécution

```bash
# Fichier : scripts/13_create_meta_flags_map_indexes.sh
#!/bin/bash
# Création des index SAI sur KEYS et VALUES de meta_flags

set -e

# Charger l'environnement
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
fi

HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
if [ -n "${HCD_HOME}" ]; then
    CQLSH_BIN="${HCD_HOME}/bin/cqlsh"
else
    CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
fi
CQLSH="$CQLSH_BIN localhost 9042"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CQL_FILE="${SCRIPT_DIR}/../schemas/13_create_meta_flags_map_indexes.cql"

echo ""
info "🔧 Création des index SAI sur KEYS et VALUES de meta_flags..."
echo ""

# Vérifier que le fichier CQL existe
if [ ! -f "$CQL_FILE" ]; then
    error "Fichier CQL non trouvé : $CQL_FILE"
    exit 1
fi

# Vérifier que HCD est démarré
if ! nc -z localhost 9042 2>/dev/null; then
    error "HCD n'est pas démarré sur localhost:9042"
    exit 1
fi

# Exécuter le fichier CQL
info "📝 Exécution du fichier CQL : $CQL_FILE"
$CQLSH -f "$CQL_FILE"

if [ $? -eq 0 ]; then
    success "✅ Index SAI créés avec succès"
else
    error "❌ Erreur lors de la création des index SAI"
    exit 1
fi

echo ""
info "📊 Vérification des index créés..."
$CQLSH -e "USE domiramacatops_poc; SELECT index_name FROM system_schema.indexes WHERE keyspace_name = 'domiramacatops_poc' AND table_name = 'operations_by_account' AND index_name IN ('idx_meta_flags_keys', 'idx_meta_flags_values');"

echo ""
success "✅ Script terminé"
```

### Étape 3 : Modifier les Tests 4 et 5

```bash
# Modifier scripts/13_test_dynamic_columns.sh

# Test 4 : Utiliser CONTAINS KEY avec index SAI
execute_query \
    "4" \
    "Filtrage par Présence de Clé MAP (CONTAINS KEY)" \
    "Recherche des opérations où meta_flags contient la clé 'ip' en utilisant l'index SAI sur KEYS(meta_flags)." \
    "HBase: Vérification présence qualifier 'meta:ip'" \
    "SELECT code_si, contrat, date_op, numero_op, libelle, meta_flags
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_flags CONTAINS KEY 'ip'
LIMIT 50;" \
    "Opérations avec meta_flags contenant la clé 'ip' (utilise index SAI idx_meta_flags_keys)"

# Test 5 : Utiliser CONTAINS avec index SAI
execute_query \
    "5" \
    "Filtrage par Valeur MAP (CONTAINS)" \
    "Recherche des opérations où meta_flags contient la valeur 'paris' en utilisant l'index SAI sur VALUES(meta_flags)." \
    "HBase: ColumnFilter avec valeur 'paris'" \
    "SELECT code_si, contrat, date_op, numero_op, libelle, meta_flags
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '100000000'
  AND meta_flags CONTAINS 'paris'
LIMIT 50;" \
    "Opérations avec meta_flags contenant la valeur 'paris' (utilise index SAI idx_meta_flags_values)"
```

---

## ✅ Solutions Alternatives (Limite 10 Index Atteinte)

### Solution A : Colonnes Dérivées pour Clés Fréquentes (Recommandé)

**Avantages** :

1. ✅ **Performance maximale** : Index SAI sur colonnes dérivées (déjà 2 créés)
2. ✅ **Pas de limite** : Pas de limite sur le nombre de colonnes dérivées
3. ✅ **Flexibilité** : Peut créer des colonnes dérivées pour toutes les clés fréquentes
4. ✅ **Pas d'ALLOW FILTERING** : Utilise les index SAI sur colonnes dérivées

**Inconvénients** :

- ⚠️  **Maintenance** : Synchronisation MAP / colonnes dérivées
- ⚠️  **Stockage** : Colonnes supplémentaires

### Solution B : Filtrage Côté Application (Solution Actuelle)

**Avantages** :

1. ✅ **Pas de limite** : Pas de contrainte d'index
2. ✅ **Flexibilité maximale** : Supporte toutes les clés MAP dynamiques
3. ✅ **Pas de maintenance** : Pas de synchronisation nécessaire

**Inconvénients** :

- ⚠️  **Performance** : Récupération de toutes les données puis filtrage
- ⚠️  **Réseau** : Consommation réseau accrue
- ⚠️  **CPU** : Charge CPU côté application

### Solution C : Supprimer un Index Moins Utilisé

**Avantages** :

1. ✅ **Performance maximale** : Index SAI sur KEYS/VALUES
2. ✅ **Pas de filtrage côté application** : Tout se fait dans HCD
3. ✅ **Flexibilité** : Supporte toutes les clés MAP dynamiques

**Inconvénients** :

- ⚠️  **Perte de fonctionnalité** : Perte de l'index supprimé
- ⚠️  **Analyse nécessaire** : Identifier l'index le moins utilisé

---

## 📝 Notes Importantes

### Limite 10 Index SAI

- ⚠️  **Contrainte** : Maximum 10 index SAI par table
- ✅ **État actuel** : 7 index (3 places disponibles)
- ✅ **Solution** : Créer 2 index supplémentaires (KEYS, VALUES) = 9/10

### Maintenance

- ✅ **Synchronisation** : Les colonnes dérivées doivent être mises à jour lors INSERT/UPDATE
- ✅ **Index automatique** : Les index SAI sur KEYS/VALUES se mettent à jour automatiquement

### Performance

- ✅ **Index KEYS** : Recherche rapide sur présence de clé
- ✅ **Index VALUES** : Recherche rapide sur valeur
- ✅ **Combinaison** : Peut combiner avec colonnes dérivées pour performance maximale

---

## 🎯 Conclusion

### ⚠️  Contrainte : Limite 10 Index SAI Atteinte

La table `operations_by_account` a déjà **9 index SAI** (sur 10 maximum). Il n'est **pas possible** de créer les index `idx_meta_flags_keys` et `idx_meta_flags_values` sans supprimer des index existants.

### Solution Recommandée : Solution Hybride Adaptée

**Pour les clés MAP fréquemment utilisées** :

- ✅ **Colonnes dérivées + Index SAI** (déjà implémenté pour source, device)
- ✅ Performance maximale avec index SAI
- ✅ **Recommandation** : Créer des colonnes dérivées pour toutes les clés fréquentes (channel, ip, location, fraud_score)

**Pour les clés MAP moins fréquentes ou dynamiques** :

- ✅ **Filtrage côté application** (solution actuelle)
- ✅ Flexibilité maximale sans contrainte d'index
- ⚠️  Performance acceptable si volume modéré

**Alternative si besoin de performance** :

- ⚠️  **Supprimer un index moins utilisé** pour créer idx_meta_flags_keys/values
- ⚠️  Nécessite une analyse préalable des index existants

### Résultat Final

- ✅ **Clés fréquentes** : 100% côté base de données (colonnes dérivées + index SAI)
- ⚠️  **Clés moins fréquentes** : Filtrage côté application (acceptable pour volume modéré)
- ✅ **Flexibilité** : Supporte toutes les clés MAP dynamiques
- ✅ **Respecte la limite** : 9/10 index utilisés (1 place disponible)
