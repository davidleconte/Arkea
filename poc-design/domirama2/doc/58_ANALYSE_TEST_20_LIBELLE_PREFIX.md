# 🔍 Analyse : Test 20 et `libelle_prefix`

## Question

Pour le test 20, est-il possible d'utiliser `libelle_prefix` pour le N-Gram ou cela n'a pas de sens ? Faut-il faire un append sur la table pour ajouter un jeu de données valide ?

## Analyse du Test 20

### Requête du Test 20

```cql
SELECT code_si, contrat, libelle, montant, cat_auto, type_operation, date_op
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'virement'      -- Recherche full-text terme complet
  AND libelle : 'permanent'     -- Recherche full-text terme complet
  AND cat_auto = 'VIREMENT'
  AND type_operation = 'VIREMENT'
  AND montant < 0
  AND date_op >= '2023-01-01'
LIMIT 10;
```

### Résultats actuels

✅ **Le test 20 fonctionne déjà** : 2 résultats trouvés
- `VIREMENT PERMANENT VERS LIVRET A`
- `VIREMENT PERMANENT VERS ASSURANCE VIE`

---

## Réponse : Utiliser `libelle_prefix` pour le Test 20 ?

### ❌ **NON, cela n'a PAS de sens pour le Test 20**

**Raisons** :

1. **Le test cherche des termes complets** :
   - `libelle : 'virement'` → cherche le mot complet "virement"
   - `libelle : 'permanent'` → cherche le mot complet "permanent"
   - Ce ne sont **PAS** des recherches partielles

2. **`libelle_prefix` est conçu pour la recherche partielle** :
   - Exemple d'usage : `libelle_prefix : 'carref'` → trouve "CARREFOUR"
   - Utile pour : typos, autocomplétion, recherche partielle
   - **PAS utile** pour : recherche de termes complets

3. **Le test fonctionne déjà avec `libelle`** :
   - L'index `idx_libelle_fulltext_advanced` gère parfaitement les termes complets
   - Pas besoin de `libelle_prefix` pour ce cas d'usage

### ✅ **Quand utiliser `libelle_prefix` ?**

`libelle_prefix` est utile pour :
- ✅ Recherche partielle : `libelle_prefix : 'carref'` → trouve "CARREFOUR"
- ✅ Tolérance aux typos : `libelle_prefix : 'loyr'` → trouve "LOYER"
- ✅ Autocomplétion : `libelle_prefix : 'vire'` → trouve "VIREMENT"

**Exemple de test qui utiliserait `libelle_prefix`** :
```cql
-- Test 4 : Recherche partielle N-Gram
SELECT * FROM operations_by_account
WHERE code_si = '1' 
  AND contrat = '5913101072'
  AND libelle_prefix : 'carref'  -- Recherche partielle
LIMIT 5;
```

---

## État actuel des données

### Vérification de `libelle_prefix`

Sur 80 lignes pour le compte de test :
- ✅ **66 lignes** ont `libelle_prefix` rempli
- ⚠️ **14 lignes** n'ont **PAS** `libelle_prefix` (NULL)

### Impact

- ✅ **Test 20** : Fonctionne parfaitement (utilise `libelle`, pas `libelle_prefix`)
- ⚠️ **Test 4** : Pourrait échouer si les données testées n'ont pas `libelle_prefix`

---

## Faut-il faire un append pour ajouter des données ?

### Pour le Test 20 : ❌ **NON nécessaire**

Le test 20 fonctionne déjà avec les données existantes. Il utilise `libelle` (full-text), pas `libelle_prefix`.

### Pour d'autres tests utilisant `libelle_prefix` : ⚠️ **Peut-être**

Si d'autres tests (comme le test 4) échouent à cause de `libelle_prefix` NULL, il faut :

1. **Option 1 : Mettre à jour les données existantes** (recommandé)
   ```bash
   # Utiliser le script Spark existant
   ./examples/scala/update_libelle_prefix.scala
   ```

2. **Option 2 : Ajouter de nouvelles données avec `libelle_prefix`**
   - Les scripts de chargement récents (`11_load_domirama2_data_parquet.sh`) remplissent déjà `libelle_prefix`
   - Les anciennes données peuvent avoir `libelle_prefix = NULL`

---

## Recommandation

### Pour le Test 20

✅ **Ne rien changer** : Le test fonctionne déjà correctement avec `libelle` (full-text search).

### Pour améliorer la couverture globale

⚠️ **Mettre à jour les 14 lignes avec `libelle_prefix = NULL`** :

```bash
# Option 1 : Script Spark existant
cd poc-design/domirama2
spark-shell -i examples/scala/update_libelle_prefix.scala

# Option 2 : Script SQL direct (si possible)
# UPDATE operations_by_account SET libelle_prefix = libelle WHERE libelle_prefix IS NULL;
```

**Note** : En CQL, on ne peut pas faire `UPDATE ... SET libelle_prefix = libelle` directement car `libelle` n'est pas dans la clé primaire. Il faut utiliser Spark ou un script applicatif.

---

## Conclusion

1. ❌ **Test 20** : Ne pas utiliser `libelle_prefix` (pas de sens, le test fonctionne déjà)
2. ✅ **Test 4** : Utiliser `libelle_prefix` pour la recherche partielle
3. ⚠️ **Données** : Mettre à jour les 14 lignes avec `libelle_prefix = NULL` pour améliorer la couverture


