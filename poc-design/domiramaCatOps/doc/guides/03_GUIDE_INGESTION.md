# 📥 Guide d'Ingestion - DomiramaCatOps

**Date** : 2025-12-01  
**Objectif** : Guide complet pour charger les données dans HCD (batch et temps réel)  
**Prérequis** : Schéma configuré (voir [Guide de Configuration](02_GUIDE_SETUP.md))

---

## 📋 Table des Matières

1. [Stratégie Multi-Version](#stratégie-multi-version)
2. [Ingestion Batch (Parquet)](#ingestion-batch-parquet)
3. [Génération d'Embeddings](#génération-dembeddings)
4. [Ingestion Temps Réel](#ingestion-temps-réel)
5. [Chargement Meta-Categories](#chargement-meta-categories)
6. [Vérifications](#vérifications)
7. [Prochaines Étapes](#prochaines-étapes)

---

## 🔄 Stratégie Multi-Version

### Principe

**Batch écrit UNIQUEMENT** :

- ✅ `cat_auto` : Catégorie automatique
- ✅ `cat_confidence` : Score de confiance
- ❌ `cat_user` : NULL (batch ne touche jamais)
- ❌ `cat_date_user` : NULL (batch ne touche jamais)
- ❌ `cat_validee` : false (batch ne touche jamais)

**Client écrit UNIQUEMENT** :

- ✅ `cat_user` : Catégorie modifiée par client
- ✅ `cat_date_user` : Date de modification
- ✅ `cat_validee` : Acceptation par client

**Avantage** : Aucune correction client n'est perdue lors des ré-exécutions du batch.

---

## 📦 Ingestion Batch (Parquet)

### Étape 1 : Génération des Données Parquet

**Script** : `04_generate_operations_parquet.sh`

**Exécution** :

```bash
cd scripts
./04_generate_operations_parquet.sh
```

**Résultat** :

- Fichier Parquet généré : `data/operations_20000.parquet/`
- Format : Parquet (columnar binaire)
- Nombre de lignes : 20 000 opérations

**Avantages Parquet** :

- ✅ Performance : Lecture 3-10x plus rapide que CSV
- ✅ Schéma typé : Types préservés, pas de parsing
- ✅ Compression : Jusqu'à 10x plus petit
- ✅ Optimisations : Projection pushdown, predicate pushdown

---

### Étape 2 : Chargement des Opérations

**Script** : `05_load_operations_data_parquet.sh`

**Exécution** :

```bash
./05_load_operations_data_parquet.sh [chemin_parquet]
```

**Processus** :

1. **Lecture Parquet** :

   ```scala
   val ops = spark.read.parquet(parquetFile)
   ```

2. **Transformation** :

   ```scala
   val opsTransformed = ops.select(
     col("code_si").as("code_si"),
     col("contrat").as("contrat"),
     col("date_op").as("date_op"),
     col("numero_op").as("numero_op"),
     col("libelle").as("libelle"),
     col("montant").as("montant"),
     // Colonnes de catégorisation
     col("categorie_auto").as("cat_auto"),
     col("cat_confidence").as("cat_confidence"),
     lit(null).cast("string").as("cat_user"),  // Batch NE TOUCHE JAMAIS
     lit(null).cast("timestamp").as("cat_date_user"),  // Batch NE TOUCHE JAMAIS
     lit(false).cast("boolean").as("cat_validee")  // Batch NE TOUCHE JAMAIS
   )
   ```

3. **Écriture HCD** :

   ```scala
   opsTransformed.write
     .format("org.apache.spark.sql.cassandra")
     .options(Map("keyspace" -> "domiramacatops_poc", "table" -> "operations_by_account"))
     .mode("append")
     .save()
   ```

**Rapport généré** : `doc/demonstrations/05_LOAD_OPERATIONS_DEMONSTRATION.md`

---

## 🤖 Génération d'Embeddings

### Script : `05_generate_libelle_embedding.sh`

**Objectif** : Générer les embeddings ByteT5 pour tous les libellés

**Exécution** :

```bash
./05_generate_libelle_embedding.sh
```

**Processus** :

1. **Lecture des libellés** depuis HCD
2. **Encodage ByteT5** : Génération des embeddings 1472 dimensions
3. **Mise à jour HCD** : UPDATE avec les embeddings
4. **Index automatique** : L'index SAI se construit automatiquement

**Modèle** : `google/byt5-small` (optimisé pour le français)

**Dimensions** : 1472

**Rapport généré** : `doc/demonstrations/05_GENERATE_EMBEDDINGS_DEMONSTRATION.md`

---

## ⚡ Ingestion Temps Réel

### Script : `07_load_category_data_realtime.sh`

**Objectif** : Charger des corrections client en temps réel

**Exécution** :

```bash
./07_load_category_data_realtime.sh
```

**Processus** :

1. **Correction client** : UPDATE avec `cat_user`, `cat_date_user`, `cat_validee`

   ```cql
   UPDATE operations_by_account
   SET cat_user = 'NOUVEAU_CATEGORIE',
       cat_date_user = toTimestamp(now()),
       cat_validee = true
   WHERE code_si = '1' AND contrat = '100000000'
     AND date_op = '2024-01-01 10:00:00'
     AND numero_op = 1;
   ```

2. **Stratégie** : Le batch ne touche jamais ces colonnes

**Rapport généré** : `doc/demonstrations/07_LOAD_CATEGORY_REALTIME_DEMONSTRATION.md`

---

## 🏷️ Chargement Meta-Categories

### Étape 1 : Génération des Données Parquet

**Script** : `04_generate_meta_categories_parquet.sh`

**Exécution** :

```bash
./04_generate_meta_categories_parquet.sh
```

**Résultat** :

- 7 fichiers Parquet générés (un par table meta-category)
- Données cohérentes avec les opérations chargées

---

### Étape 2 : Chargement des Meta-Categories

**Script** : `06_load_meta_categories_data_parquet.sh`

**Exécution** :

```bash
./06_load_meta_categories_data_parquet.sh
```

**Tables Chargées** :

1. `acceptation_client`
2. `opposition_categorisation`
3. `historique_opposition`
4. `feedback_par_libelle` (COUNTER)
5. `feedback_par_ics` (COUNTER)
6. `regles_personnalisees`
7. `decisions_salaires`

**Rapport généré** : `doc/demonstrations/06_LOAD_META_CATEGORIES_DEMONSTRATION.md`

---

## ✅ Vérifications

### Vérification 1 : Opérations Chargées

```bash
cd binaire/hcd-1.2.3
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT COUNT(*) FROM domiramacatops_poc.operations_by_account;"
```

**Attendu** : Nombre d'opérations chargées (> 0)

### Vérification 2 : Stratégie Batch

```bash
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT cat_auto, cat_user FROM domiramacatops_poc.operations_by_account LIMIT 10;"
```

**Attendu** : `cat_auto` non null, `cat_user` null (batch ne touche jamais)

### Vérification 3 : Embeddings Générés

```bash
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT COUNT(*) FROM domiramacatops_poc.operations_by_account WHERE libelle_embedding IS NOT NULL ALLOW FILTERING;"
```

**Attendu** : Nombre d'opérations avec embeddings (> 0)

### Vérification 4 : Meta-Categories

```bash
./bin/cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT COUNT(*) FROM domiramacatops_poc.regles_personnalisees;"
```

**Attendu** : Nombre de règles personnalisées (> 0)

---

## 🚀 Prochaines Étapes

Une fois l'ingestion terminée :

1. **Tester la recherche** :

   ```bash
   ./08_test_category_search.sh
   ```

2. **Tester la recherche floue** :

   ```bash
   ./16_test_fuzzy_search.sh
   ```

3. **Tester la recherche hybride** :

   ```bash
   ./18_test_hybrid_search.sh
   ```

4. **Consulter le guide de recherche** :
   - [Guide de Recherche](04_GUIDE_RECHERCHE.md)

---

## 📚 Ressources

- **Scripts** : Tous les scripts sont dans `scripts/`
- **Démonstrations** : Rapports auto-générés dans `doc/demonstrations/`
- **Documentation** : [INDEX.md](../INDEX.md)

---

**Date de création** : 2025-12-01  
**Dernière mise à jour** : 2025-12-01
