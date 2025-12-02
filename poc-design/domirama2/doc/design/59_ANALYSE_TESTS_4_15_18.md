# 🔍 Analyse des Tests 4, 15 et 18 - Causes d'Échec

## Problème Identifié

Les tests 4, 15 et 18 ne renvoient aucune ligne. Après analyse, **la cause principale est identifiée** :

### ❌ **Cause Racine : Index SAI sur `libelle` manquant**

L'index SAI `idx_libelle_fulltext_advanced` **n'existe pas** dans la base de données, ce qui empêche toutes les recherches full-text sur `libelle`.

**Preuve** :
```sql
-- Liste des index existants
SELECT * FROM system_schema.indexes 
WHERE keyspace_name = 'domirama2_poc' 
  AND table_name = 'operations_by_account';

-- Résultat : PAS d'index sur libelle
-- Seuls index présents :
-- - idx_cat_auto
-- - idx_cat_user
-- - idx_libelle_embedding_vector
-- - idx_libelle_prefix_ngram
-- - idx_montant
-- - idx_type_operation
```

**Erreur obtenue** :
```
InvalidRequest: Error from server: code=2200 [Invalid query] 
message=": restriction is only supported on properly indexed columns. 
libelle : 'carref' is not valid."
```

---

## Analyse Détaillée par Test

### 🔴 TEST 4 : Recherche partielle N-Gram

**Requête** :
```cql
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'carref'  -- Partiel → trouve "CARREFOUR"
LIMIT 5;
```

**Causes d'échec** :

1. ❌ **Index SAI sur `libelle` manquant** (cause principale)
   - L'index `idx_libelle_fulltext_advanced` n'existe pas
   - Impossible d'utiliser l'opérateur `:` sur `libelle`

2. ⚠️ **Index N-Gram inexistant sur `libelle`** (cause secondaire)
   - Même si l'index full-text existait, il ne supporte pas la recherche partielle
   - L'index `idx_libelle_ngram` n'existe pas (limitation SAI : un seul index par colonne)

**Solutions** :

1. ✅ **Créer l'index full-text** (obligatoire) :
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

2. ⚠️ **Pour la recherche partielle** : Utiliser `libelle_prefix` :
   ```cql
   -- Alternative : utiliser libelle_prefix pour recherche partielle
   SELECT * FROM operations_by_account
   WHERE code_si = '1' 
     AND contrat = '5913101072'
     AND libelle_prefix : 'carref'  -- Recherche partielle
   LIMIT 5;
   ```

---

### 🔴 TEST 15 : Recherche avec noms propres (EDF ORANGE)

**Requête** :
```cql
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'EDF'
  AND libelle : 'ORANGE'
LIMIT 5;
```

**Causes d'échec** :

1. ❌ **Index SAI sur `libelle` manquant** (cause principale)
   - L'index `idx_libelle_fulltext_advanced` n'existe pas
   - Impossible d'utiliser l'opérateur `:` sur `libelle`

2. ⚠️ **Données manquantes** (cause secondaire possible)
   - Même avec l'index, il faut qu'il existe des libellés contenant **ET** "EDF" **ET** "ORANGE"
   - Les données ajoutées via `add_missing_test_data.cql` contiennent :
     - `PRELEVEMENT EDF FACTURE ELECTRICITE` (contient "EDF")
     - `PRELEVEMENT ORANGE FACTURE TELEPHONE` (contient "ORANGE")
   - Mais **AUCUN libellé ne contient les deux termes simultanément**

**Solutions** :

1. ✅ **Créer l'index full-text** (obligatoire)

2. ⚠️ **Ajouter des données avec EDF ET ORANGE** (si besoin) :
   ```cql
   INSERT INTO operations_by_account (
       code_si, contrat, date_op, numero_op, op_id,
       libelle, montant, devise, date_valeur, type_operation, sens_operation,
       cat_auto, cat_confidence
   ) VALUES (
       '1', '5913101072', '2024-11-25 00:00:00', 1015, 'op_test_15_003',
       'PRELEVEMENT EDF ET ORANGE FACTURES COMBINEES', -131.40, 'EUR', 
       '2024-11-25 00:00:00', 'PRELEVEMENT', 'DEBIT',
       'DIVERS', 0.95
   );
   ```

3. 💡 **Alternative** : Modifier le test pour chercher EDF **OU** ORANGE :
   ```cql
   -- Chercher EDF OU ORANGE (pas ET)
   SELECT * FROM operations_by_account
   WHERE code_si = '1'
     AND contrat = '5913101072'
     AND (libelle : 'EDF' OR libelle : 'ORANGE')
   LIMIT 5;
   ```

---

### 🔴 TEST 18 : Recherche avec localisation précise (paris 15eme 16eme)

**Requête** :
```cql
SELECT code_si, contrat, libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'paris'
  AND libelle : '15eme'
  AND libelle : '16eme'
LIMIT 5;
```

**Causes d'échec** :

1. ❌ **Index SAI sur `libelle` manquant** (cause principale)
   - L'index `idx_libelle_fulltext_advanced` n'existe pas
   - Impossible d'utiliser l'opérateur `:` sur `libelle`

2. ⚠️ **Données manquantes** (cause secondaire)
   - Même avec l'index, il faut qu'il existe des libellés contenant **ET** "paris" **ET** "15eme" **ET** "16eme"
   - Les données ajoutées contiennent :
     - `CB RESTAURANT PARIS 15EME RUE VAUGIRARD` (contient "paris" et "15eme")
     - `CB CINEMA PARIS 16EME AVENUE FOCH` (contient "paris" et "16eme")
   - Mais **AUCUN libellé ne contient les trois termes simultanément**

**Solutions** :

1. ✅ **Créer l'index full-text** (obligatoire)

2. ⚠️ **Ajouter des données avec les trois termes** (si besoin) :
   ```cql
   INSERT INTO operations_by_account (
       code_si, contrat, date_op, numero_op, op_id,
       libelle, montant, devise, date_valeur, type_operation, sens_operation,
       cat_auto, cat_confidence
   ) VALUES (
       '1', '5913101072', '2024-11-23 12:00:00', 1016, 'op_test_18_003',
       'CB RESTAURANT PARIS 15EME PUIS CINEMA PARIS 16EME', -45.00, 'EUR',
       '2024-11-23 12:00:00', 'CARTE', 'DEBIT',
       'LOISIRS', 0.90
   );
   ```

3. 💡 **Alternative** : Modifier le test pour chercher paris ET (15eme OU 16eme) :
   ```cql
   -- Chercher paris ET (15eme OU 16eme)
   SELECT * FROM operations_by_account
   WHERE code_si = '1'
     AND contrat = '5913101072'
     AND libelle : 'paris'
     AND (libelle : '15eme' OR libelle : '16eme')
   LIMIT 5;
   ```

---

## Solution Globale

### Étape 1 : Créer l'index SAI sur `libelle` (OBLIGATOIRE)

```cql
USE domirama2_poc;

CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_fulltext_advanced
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

**Note** : L'index peut prendre quelques secondes à être construit. Attendre avant de tester.

### Étape 2 : Vérifier que l'index est créé

```cql
SELECT * FROM system_schema.indexes 
WHERE keyspace_name = 'domirama2_poc' 
  AND table_name = 'operations_by_account'
  AND index_name = 'idx_libelle_fulltext_advanced';
```

### Étape 3 : Tester les requêtes

```cql
-- Test 4 : Recherche partielle (ne fonctionnera pas, utiliser libelle_prefix)
SELECT * FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND libelle : 'carref'  -- ❌ Ne trouvera pas (recherche partielle non supportée)
LIMIT 5;

-- Test 15 : EDF ET ORANGE (ne trouvera rien, aucun libellé ne contient les deux)
SELECT * FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND libelle : 'EDF' AND libelle : 'ORANGE'  -- ❌ Aucun résultat
LIMIT 5;

-- Test 18 : paris ET 15eme ET 16eme (ne trouvera rien, aucun libellé ne contient les trois)
SELECT * FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND libelle : 'paris' AND libelle : '15eme' AND libelle : '16eme'  -- ❌ Aucun résultat
LIMIT 5;
```

---

## Résumé des Causes

| Test | Cause Principale | Cause Secondaire | Solution |
|------|------------------|-----------------|----------|
| **Test 4** | ❌ Index SAI sur `libelle` manquant | ⚠️ Recherche partielle non supportée | Créer index + utiliser `libelle_prefix` |
| **Test 15** | ❌ Index SAI sur `libelle` manquant | ⚠️ Aucun libellé ne contient EDF ET ORANGE | Créer index + ajouter données ou modifier test |
| **Test 18** | ❌ Index SAI sur `libelle` manquant | ⚠️ Aucun libellé ne contient paris ET 15eme ET 16eme | Créer index + ajouter données ou modifier test |

---

## Conclusion

**Cause principale commune** : ❌ **Index SAI sur `libelle` manquant**

**Action immédiate** : Créer l'index `idx_libelle_fulltext_advanced`

**Causes secondaires** :
- Test 4 : Recherche partielle non supportée (utiliser `libelle_prefix`)
- Test 15 : Aucun libellé ne contient EDF ET ORANGE simultanément
- Test 18 : Aucun libellé ne contient paris ET 15eme ET 16eme simultanément




