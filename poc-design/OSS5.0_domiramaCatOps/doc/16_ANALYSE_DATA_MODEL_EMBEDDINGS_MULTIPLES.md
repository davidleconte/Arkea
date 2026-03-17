# 🔍 Analyse : Data Model avec Embeddings Multiples

**Date** : 2025-11-30
**Dernière mise à jour** : 2025-01-XX
**Version** : 1.0
**Objectif** : Analyser la faisabilité d'ajouter une colonne vectorielle supplémentaire pour `multilingual-e5-large`
**Contexte** : Optimisation des embeddings pour améliorer la pertinence des résultats

> **Note** : Pour l'analyse des modèles et recommandations, voir [16_ANALYSE_MODELES_EMBEDDINGS_MULTIPLES.md](16_ANALYSE_MODELES_EMBEDDINGS_MULTIPLES.md). Pour le résumé de capacité, voir [16_RESUME_CAPACITE_MODELES_MULTIPLES.md](16_RESUME_CAPACITE_MODELES_MULTIPLES.md). Pour l'implémentation complète, voir [16_RESUME_IMPLEMENTATION_COMPLETE.md](16_RESUME_IMPLEMENTATION_COMPLETE.md).

---

## 📊 État Actuel du Schéma

### Table `operations_by_account`

**Colonnes vectorielles actuelles** :

- `libelle_embedding VECTOR<FLOAT, 1472>` - Embeddings ByteT5-small

**Index SAI actuels sur `operations_by_account`** :

| Index | Colonne | Type | Usage |
|-------|---------|-----|-------|
| `idx_libelle_fulltext_advanced` | `libelle` | Full-Text | Recherche full-text avec analyzers |
| `idx_libelle_prefix_ngram` | `libelle_prefix` | N-Gram | Recherche partielle |
| `idx_libelle_tokens` | `libelle_tokens` | Collection | Recherche avec CONTAINS |
| `idx_libelle_embedding_vector` | `libelle_embedding` | Vector | Recherche vectorielle ANN |
| `idx_cat_auto` | `cat_auto` | Equality | Filtrage par catégorie |
| `idx_cat_user` | `cat_user` | Equality | Filtrage par catégorie client |
| `idx_montant` | `montant` | Range | Filtrage par montant |
| `idx_type_operation` | `type_operation` | Equality | Filtrage par type |

**Total actuel** : **8 index SAI**

---

## 🔍 Limites SAI

### Limite par Défaut

**Limite SAI** : **10 index par table** (par défaut dans HCD/Cassandra)

**Configuration actuelle** :

- ✅ **8 index** utilisés sur `operations_by_account`
- ✅ **2 index** disponibles pour extensions

### Vérification de la Limite

```cql
-- Vérifier la limite SAI configurée
SELECT * FROM system_schema.indexes
WHERE keyspace_name = 'domiramacatops_poc'
  AND table_name = 'operations_by_account';
```

**Note** : La limite peut être augmentée via la configuration HCD si nécessaire.

---

## ✅ Faisabilité : Ajout d'une Colonne Vectorielle Supplémentaire

### Option 1 : Ajouter `libelle_embedding_e5` (RECOMMANDÉ)

**Nouvelle colonne** :

```cql
ALTER TABLE operations_by_account
ADD libelle_embedding_e5 VECTOR<FLOAT, 1024>;
```

**Nouvel index SAI** :

```cql
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_e5_vector
ON operations_by_account(libelle_embedding_e5)
USING 'StorageAttachedIndex';
```

**Impact** :

- ✅ **1 nouvelle colonne** : `libelle_embedding_e5`
- ✅ **1 nouvel index SAI** : Total = 9/10 index
- ✅ **1 index disponible** pour futures extensions
- ✅ **Pas de limite atteinte**

### Option 2 : Remplacer `libelle_embedding` (NON RECOMMANDÉ)

**Migration complète** :

- Supprimer `libelle_embedding` (ByteT5)
- Ajouter `libelle_embedding_e5` (multilingual-e5-large)
- Régénérer tous les embeddings

**Inconvénients** :

- ❌ Perte de compatibilité avec code existant
- ❌ Migration complète nécessaire
- ❌ Pas de comparaison possible entre modèles

---

## 📋 Schéma Proposé

### Modification du Schéma

```cql
-- ============================================
-- Ajout de la colonne vectorielle supplémentaire
-- ============================================
ALTER TABLE operations_by_account
ADD libelle_embedding_e5 VECTOR<FLOAT, 1024>;

-- ============================================
-- Création de l'index SAI vectoriel pour e5-large
-- ============================================
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_e5_vector
ON operations_by_account(libelle_embedding_e5)
USING 'StorageAttachedIndex';
```

### Schéma Complet Mis à Jour

```cql
CREATE TABLE domiramacatops_poc.operations_by_account (
    -- Partition Key
    code_si           TEXT,
    contrat           TEXT,

    -- Clustering Keys
    date_op           TIMESTAMP,
    numero_op         INT,

    -- Données de l'opération
    libelle           TEXT,
    montant           DECIMAL,
    devise            TEXT,
    date_valeur       TIMESTAMP,
    type_operation    TEXT,
    sens_operation    TEXT,
    operation_data    BLOB,
    cobol_data_base64 TEXT,
    meta_flags        MAP<TEXT, TEXT>,

    -- Colonnes de Recherche Avancée
    libelle_prefix    TEXT,
    libelle_tokens    SET<TEXT>,
    libelle_embedding VECTOR<FLOAT, 1472>,      -- ByteT5-small (existant)
    libelle_embedding_e5 VECTOR<FLOAT, 1024>,   -- multilingual-e5-large (NOUVEAU)

    -- Colonnes de Catégorisation
    cat_auto          TEXT,
    cat_confidence    DECIMAL,
    cat_user          TEXT,
    cat_date_user     TIMESTAMP,
    cat_validee       BOOLEAN,

    PRIMARY KEY ((code_si, contrat), date_op, numero_op)
) WITH CLUSTERING ORDER BY (date_op DESC, numero_op ASC)
  AND default_time_to_live = 315619200;
```

### Index SAI Mis à Jour

| # | Index | Colonne | Type | Statut |
|---|-------|---------|------|--------|
| 1 | `idx_libelle_fulltext_advanced` | `libelle` | Full-Text | ✅ Existant |
| 2 | `idx_libelle_prefix_ngram` | `libelle_prefix` | N-Gram | ✅ Existant |
| 3 | `idx_libelle_tokens` | `libelle_tokens` | Collection | ✅ Existant |
| 4 | `idx_libelle_embedding_vector` | `libelle_embedding` | Vector | ✅ Existant |
| 5 | `idx_libelle_embedding_e5_vector` | `libelle_embedding_e5` | Vector | 🆕 **NOUVEAU** |
| 6 | `idx_cat_auto` | `cat_auto` | Equality | ✅ Existant |
| 7 | `idx_cat_user` | `cat_user` | Equality | ✅ Existant |
| 8 | `idx_montant` | `montant` | Range | ✅ Existant |
| 9 | `idx_type_operation` | `type_operation` | Equality | ✅ Existant |
| 10 | *(disponible)* | - | - | 🔄 **RÉSERVÉ** |

**Total** : **9/10 index SAI utilisés** ✅

---

## 🔄 Impact sur les Tables

### Tables à Modifier

| Table | Modification | Impact |
|-------|-------------|--------|
| **operations_by_account** | Ajout colonne + index | ✅ Principal |
| *(autres tables)* | Aucune | ✅ Aucun impact |

### Scripts à Mettre à Jour

1. **Schéma** :
   - `schemas/01_create_domiramaCatOps_schema.cql` - Ajouter colonne
   - `schemas/02_create_operations_indexes.cql` - Ajouter index

2. **Scripts de génération d'embeddings** :
   - `examples/python/search/test_vector_search_base.py` - Support multi-modèles
   - Scripts de migration des embeddings

3. **Scripts de recherche** :
   - Support choix du modèle (ByteT5 vs e5-large)
   - Hybrid search avec les deux modèles

---

## 📊 Stratégie de Migration

### Phase 1 : Ajout de la Colonne (Sans Impact)

```cql
-- Ajouter la colonne (NULL par défaut, pas d'impact sur données existantes)
ALTER TABLE operations_by_account
ADD libelle_embedding_e5 VECTOR<FLOAT, 1024>;

-- Créer l'index (vide au début, pas d'impact)
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_e5_vector
ON operations_by_account(libelle_embedding_e5)
USING 'StorageAttachedIndex';
```

**Impact** : ✅ Aucun impact sur les données existantes

### Phase 2 : Génération Progressive des Embeddings

**Stratégie** :

1. Générer les embeddings e5-large progressivement
2. Commencer par les données récentes
3. Étendre progressivement aux données historiques

**Script de migration** :

```python
# Migration progressive des embeddings
for batch in batches:
    # Générer embeddings e5-large
    embeddings_e5 = model_e5.encode(libelles_batch)
    # Mettre à jour dans HCD
    update_embeddings(embeddings_e5)
```

### Phase 3 : Comparaison et Validation

**Tests** :

1. Comparer les résultats ByteT5 vs e5-large
2. Mesurer la pertinence
3. Décider de la stratégie (hybrid, e5 seul, ou les deux)

---

## 📝 Génération de Données de Test Pertinentes

### Analyse : "Générer plus de données de test pertinentes"

#### Problème Actuel

**Données de test limitées** :

- Seulement 49 libellés dans le compte de test
- Peu de variété dans les libellés
- Libellés non pertinents pour certaines requêtes

**Exemples de problèmes** :

- Requête "LOYER IMPAYE" → Résultats non pertinents
- Requête "VIREMENT SALAIRE" → Peu de résultats pertinents
- Requête "CARREFOUR" → 1 seul résultat pertinent

#### Solution : Génération de Données de Test Pertinentes

### 1. Analyse des Requêtes de Test

**Requêtes identifiées dans les tests** :

- "LOYER IMPAYE"
- "VIREMENT SALAIRE"
- "PAIEMENT CARTE BANCAIRE"
- "CARREFOUR PARIS"
- "RESTAURANT PARIS"
- "SUPERMARCHE"
- "ASSURANCE HABITATION"
- "TAXE FONCIERE"

### 2. Libellés Pertinents à Générer

**Pour chaque requête, générer 5-10 libellés pertinents** :

| Requête | Libellés Pertinents à Générer |
|---------|------------------------------|
| **LOYER IMPAYE** | - REGULARISATION LOYER IMPAYE PARIS<br>- LOYER IMPAYE MENSUEL<br>- LOYER IMPAYE REGULARISATION<br>- LOYER IMPAYE APPARTEMENT<br>- LOYER IMPAYE MAISON |
| **VIREMENT SALAIRE** | - VIREMENT SALAIRE MARS 2024<br>- VIREMENT SALAIRE FEVRIER 2024<br>- VIREMENT SALAIRE JANVIER 2024<br>- VIREMENT SALAIRE MENSUEL<br>- VIREMENT SALAIRE ENTREPRISE |
| **PAIEMENT CARTE BANCAIRE** | - CB RESTAURANT PARIS<br>- CB SUPERMARCHE PARIS<br>- CB CARREFOUR MARKET<br>- CB PHARMACIE PARIS<br>- CB STATION SERVICE |
| **CARREFOUR PARIS** | - CB CARREFOUR MARKET PARIS<br>- CB CARREFOUR CITY PARIS 15<br>- CB CARREFOUR EXPRESS PARIS<br>- CB CARREFOUR DRIVE PARIS<br>- RETRAIT DAB CARREFOUR PARIS |
| **RESTAURANT PARIS** | - CB RESTAURANT PARIS 15<br>- CB RESTAURANT BRASSERIE PARIS<br>- CB RESTAURANT ITALIEN PARIS<br>- CB RESTAURANT JAPONAIS PARIS<br>- CB RESTAURANT FRANCAIS PARIS |
| **SUPERMARCHE** | - CB SUPERMARCHE MONOPRIX PARIS<br>- CB SUPERMARCHE INTERMARCHE<br>- CB SUPERMARCHE LECLERC<br>- CB SUPERMARCHE CASINO<br>- CB SUPERMARCHE FRANPRIX |
| **ASSURANCE HABITATION** | - ASSURANCE HABITATION ANNUELLE<br>- PRIME ASSURANCE HABITATION<br>- ASSURANCE HABITATION MENSUELLE<br>- ASSURANCE HABITATION RENOUVELLEMENT<br>- ASSURANCE HABITATION COMPLEMENTAIRE |
| **TAXE FONCIERE** | - TAXE FONCIERE ANNEE 2024<br>- TAXE FONCIERE TRIMESTRIELLE<br>- TAXE FONCIERE REGULARISATION<br>- TAXE FONCIERE APPARTEMENT<br>- TAXE FONCIERE MAISON |

### 3. Script de Génération de Données

**Script à créer** : `scripts/16_generate_relevant_test_data.sh`

**Fonctionnalités** :

1. Générer des libellés pertinents pour chaque requête de test
2. Créer des opérations avec ces libellés
3. Générer les embeddings (ByteT5 + e5-large)
4. Insérer dans HCD

**Volume recommandé** :

- **100-200 opérations** avec libellés pertinents
- **Répartition** : 10-20 libellés par requête de test
- **Dates variées** : Sur 3-6 mois

### 4. Structure des Données de Test

**Format** :

```python
test_data = [
    {
        "code_si": "6",
        "contrat": "600000041",
        "libelle": "REGULARISATION LOYER IMPAYE PARIS",
        "montant": 850.00,
        "date_op": "2024-11-15",
        "cat_auto": "HABITATION",
        # ... autres champs
    },
    # ... plus de données
]
```

**Catégories à couvrir** :

- HABITATION (loyers, charges, assurances)
- ALIMENTATION (supermarchés, restaurants)
- TRANSPORT (parking, essence)
- VIREMENT (salaires, pensions)
- DIVERS (taxes, services)

---

## 📋 Plan d'Implémentation

### Étape 1 : Modification du Schéma (1 jour)

1. **Créer le script de migration** :

   ```bash
   scripts/17_add_e5_embedding_column.sh
   ```

2. **Contenu** :
   - Ajouter colonne `libelle_embedding_e5`
   - Créer index SAI
   - Vérifier la création

### Étape 2 : Génération de Données de Test (1-2 jours)

1. **Créer le script de génération** :

   ```bash
   scripts/16_generate_relevant_test_data.sh
   ```

2. **Fonctionnalités** :
   - Générer 100-200 opérations pertinentes
   - Générer embeddings ByteT5 (existant)
   - Générer embeddings e5-large (nouveau)
   - Insérer dans HCD

### Étape 3 : Migration des Embeddings Existants (Optionnel, 2-3 jours)

1. **Script de migration progressive** :

   ```bash
   scripts/18_migrate_embeddings_to_e5.sh
   ```

2. **Stratégie** :
   - Migration par batch
   - Commencer par données récentes
   - Étendre progressivement

### Étape 4 : Tests et Validation (1 jour)

1. **Comparer les modèles** :
   - ByteT5 vs e5-large
   - Mesurer la pertinence
   - Évaluer les performances

2. **Décider de la stratégie** :
   - Utiliser e5-large seul
   - Utiliser les deux (hybrid)
   - Garder ByteT5 comme fallback

---

## ✅ Conclusion

### Faisabilité

✅ **FAISABLE** : Ajout d'une colonne vectorielle supplémentaire

**Raisons** :

1. ✅ Limite SAI : 9/10 index utilisés (1 disponible)
2. ✅ Pas de limite atteinte
3. ✅ Impact minimal sur données existantes
4. ✅ Migration progressive possible

### Recommandations

1. **Ajouter `libelle_embedding_e5`** :
   - Colonne : `VECTOR<FLOAT, 1024>`
   - Index : `idx_libelle_embedding_e5_vector`
   - Total : 9/10 index SAI

2. **Générer des données de test pertinentes** :
   - 100-200 opérations avec libellés pertinents
   - Couvrir toutes les requêtes de test
   - Générer embeddings pour les deux modèles

3. **Stratégie hybride** :
   - Garder ByteT5 pour compatibilité
   - Utiliser e5-large pour meilleure pertinence
   - Comparer et optimiser

---

**Date de génération** : 2025-11-30
**Version** : 1.0
