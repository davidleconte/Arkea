# 📊 Analyse : Script 11 Parquet et Applicabilité du Template Didactique

**Date** : 2025-11-26  
**Script analysé** : `11_load_domirama2_data_parquet.sh`  
**Objectif** : Analyser le script Parquet et déterminer si le template d'ingestion existant est applicable, doit être enrichi, ou si un template spécifique est nécessaire

---

## 📋 Table des Matières

1. [Analyse du Script 11 Parquet](#analyse-du-script-11-parquet)
2. [Comparaison avec Script 11 CSV Didactique](#comparaison-avec-script-11-csv-didactique)
3. [Comparaison avec Template Ingestion](#comparaison-avec-template-ingestion)
4. [Recommandations](#recommandations)
5. [Conclusion](#conclusion)

---

## 🔍 Analyse du Script 11 Parquet

### Objectif du Script

Le script `11_load_domirama2_data_parquet.sh` est un **script d'ingestion/ETL** qui :

1. **Lit des données** depuis un fichier Parquet (répertoire)
2. **Transforme les données** via Spark (Scala) - **moins de casts nécessaires**
3. **Écrit les données** dans HCD via Spark Cassandra Connector
4. **Vérifie le chargement** (nombre d'opérations, stratégie batch)

### Structure Actuelle du Script

```bash
# Structure actuelle (250 lignes)
1. En-tête et commentaires (lignes 1-47)
2. Configuration des couleurs (lignes 51-60)
3. Configuration des variables (lignes 62-65)
4. Gestion du fichier Parquet (lignes 67-82)
5. Chargement .poc-profile (lignes 84-87)
6. Vérifications (lignes 89-109)
7. Configuration Spark (lignes 111-119)
8. Affichage info avec avantages Parquet (lignes 121-134)
9. Script Spark Scala (lignes 137-205)
10. Exécution Spark (lignes 207-213)
11. Vérifications post-chargement (lignes 217-239)
12. Messages finaux avec avantages Parquet (lignes 241-249)
```

### Fonctionnalités Actuelles

✅ **Vérifications** :

- HCD démarré
- Keyspace existe
- Fichier Parquet présent (vérification répertoire `[ ! -d ]`)

✅ **Exécution Spark** :

- Création d'un script Scala temporaire
- Exécution via `spark-shell`
- **Lecture Parquet** : `.parquet()` (pas d'options header/inferSchema)
- **Transformation** : Moins de casts (types déjà présents)
- Écriture dans HCD

✅ **Vérifications Post-Chargement** :

- Nombre d'opérations chargées
- Vérification que `cat_user` est null (stratégie batch)

✅ **Avantages Parquet mentionnés** :

- Lecture 3-10x plus rapide
- Schéma typé (pas de parsing)
- Compression automatique
- Format standard production

### Limitations Actuelles

❌ **Pas d'affichage du code Spark** :

- Le code Scala n'est pas affiché avant exécution
- Pas d'explication des différences Parquet vs CSV

❌ **Vérifications basiques** :

- Vérifications limitées (comptage, null check)
- Pas d'affichage détaillé des résultats

❌ **Pas d'explications** :

- Pas d'explications des avantages Parquet
- Pas d'explications des différences dans les transformations

❌ **Pas de documentation générée** :

- Pas de rapport markdown généré automatiquement

---

## 📋 Comparaison avec Script 11 CSV Didactique

### Similarités

| Aspect | Script CSV Didactique | Script Parquet | Identique ? |
|--------|----------------------|----------------|-------------|
| **Type** | ETL (Ingestion) | ETL (Ingestion) | ✅ Oui |
| **Structure** | 7 parties didactiques | Structure basique | ⚠️ Non |
| **Stratégie multi-version** | Documentée | Mentionnée | ⚠️ Partiel |
| **Code Spark affiché** | Oui (complet) | Non | ❌ Non |
| **Explications** | Détaillées | Basiques | ❌ Non |
| **Documentation générée** | Oui (markdown) | Non | ❌ Non |

### Différences Clés

| Aspect | Script CSV | Script Parquet |
|--------|-----------|----------------|
| **Format source** | CSV (fichier) | Parquet (répertoire) |
| **Lecture** | `.csv(inputPath)` avec options | `.parquet(inputPath)` sans options |
| **Vérification fichier** | `[ ! -f ]` | `[ ! -d ]` |
| **Transformation** | Beaucoup de `.cast()` | Moins de `.cast()` (types déjà présents) |
| **Schéma** | Pas d'affichage | `raw.printSchema()` |
| **Avantages** | Non mentionnés | Mentionnés (performance, typage) |

### Différences dans le Code Spark

**CSV** :

```scala
val raw = spark.read
  .option("header", "true")
  .option("inferSchema", "false")
  .csv(inputPath)

val ops = raw.select(
  col("code_si").cast("string").as("code_si"),  // Cast nécessaire
  to_timestamp(col("date_iso"), "yyyy-MM-dd'T'HH:mm:ss'Z'").as("date_op"),  // Conversion nécessaire
  ...
)
```

**Parquet** :

```scala
val raw = spark.read.parquet(inputPath)
raw.printSchema()  // Affichage du schéma

val ops = raw.select(
  col("code_si").as("code_si"),  // Pas de cast (déjà String)
  col("date_op").as("date_op"),  // Pas de conversion (déjà Timestamp)
  ...
)
```

---

## 📋 Comparaison avec Template Ingestion

### Template Ingestion (`50_TEMPLATE_SCRIPT_INGESTION_DIDACTIQUE.md`)

**Focus** : Ingestion de données (CSV ou Parquet)  
**Type** : ETL (Spark → HCD)  
**Structure** : 7 parties didactiques

| Aspect | Template Ingestion | Besoin Script Parquet | Applicable ? |
|--------|-------------------|----------------------|--------------|
| **Type** | ETL (Ingestion) | ETL (Ingestion) | ✅ Oui |
| **Structure** | 7 parties didactiques | 7 parties didactiques | ✅ Oui |
| **Format** | Générique (CSV/Parquet) | Parquet spécifique | ⚠️ Partiel |
| **Code Spark** | Affichage complet | Affichage complet nécessaire | ✅ Oui |
| **Explications** | Détaillées | Détaillées nécessaires | ✅ Oui |
| **Avantages format** | Non spécifique | Parquet spécifique | ⚠️ À enrichir |
| **Documentation** | Génération markdown | Génération markdown | ✅ Oui |

**Conclusion** : Le template est **applicable** mais doit être **enrichi** pour supporter Parquet.

---

## 💡 Recommandations

### Option 1 : Utiliser le Template Existant avec Adaptations

**Avantages** :

- Réutilise le template existant
- Cohérence avec le script CSV didactique
- Adaptations mineures nécessaires

**Adaptations nécessaires** :

- Remplacer `.csv()` par `.parquet()`
- Supprimer les options `header` et `inferSchema`
- Ajouter `raw.printSchema()` pour afficher le schéma
- Réduire les `.cast()` dans les transformations
- Ajouter section "Avantages Parquet vs CSV"
- Adapter la vérification fichier (`[ ! -d ]` au lieu de `[ ! -f ]`)

**Verdict** : ✅ **Recommandé**

### Option 2 : Créer un Template Spécifique pour Parquet

**Avantages** :

- Template dédié à Parquet
- Sections spécifiques Parquet

**Inconvénients** :

- Duplication de code avec template CSV
- Maintenance de deux templates similaires
- Pas de valeur ajoutée significative

**Verdict** : ❌ **Non recommandé**

### Option 3 : Enrichir le Template Existant pour Support Multi-Format

**Avantages** :

- Un seul template pour CSV et Parquet
- Sections conditionnelles selon le format

**Inconvénients** :

- Template plus complexe
- Sections conditionnelles à gérer
- Risque de confusion

**Verdict** : ⚠️ **Possible mais non recommandé**

---

## ✅ Conclusion

### Recommandation Finale

**Utiliser le template d'ingestion existant avec des adaptations spécifiques pour Parquet**.

### Justification

1. **Structure identique** :
   - Les deux scripts ont la même structure (lecture, transformation, écriture)
   - Les différences sont mineures (format de lecture, nombre de casts)

2. **Adaptations simples** :
   - Remplacer `.csv()` par `.parquet()`
   - Adapter les explications pour Parquet
   - Ajouter section "Avantages Parquet"

3. **Cohérence** :
   - Même structure didactique que le script CSV
   - Même niveau de détail
   - Même génération de documentation

### Adaptations à Apporter

1. **PARTIE 1** : Ajouter section "Avantages Parquet vs CSV"
2. **PARTIE 2** : Adapter code Spark pour `.parquet()` et `printSchema()`
3. **PARTIE 3** : Adapter explications (moins de casts nécessaires)
4. **PARTIE 6** : Adapter vérification fichier (`[ ! -d ]`)
5. **PARTIE 7** : Ajouter comparaison Parquet vs CSV

### Prochaines Étapes

1. ✅ **Créer version didactique** : `11_load_domirama2_data_parquet_v2_didactique.sh` - **TERMINÉ**
2. ✅ **Adapter le template** : Utiliser le template d'ingestion avec adaptations Parquet - **TERMINÉ**
3. ⏳ **Tester** : Exécuter le script amélioré et vérifier la documentation générée
4. ⏳ **Valider** : S'assurer que la documentation est complète et pertinente

---

## 📊 Tableau Récapitulatif

| Aspect | Template Ingestion | Script CSV Didactique | Script Parquet | Template à Utiliser |
|--------|-------------------|----------------------|----------------|---------------------|
| **Type** | ETL (Ingestion) | ETL (Ingestion) | ETL (Ingestion) | Template Ingestion (adapté) |
| **Format** | Générique | CSV | Parquet | Adaptations Parquet |
| **Structure** | 7 parties | 7 parties | Basique | 7 parties (adaptées) |
| **Code Spark** | Affichage complet | Affichage complet | Non affiché | Affichage complet (adapté) |
| **Explications** | Détaillées | Détaillées | Basiques | Détaillées (adaptées) |
| **Documentation** | Génération markdown | Génération markdown | Non générée | Génération markdown |

---

## 🔄 Différences Clés à Adapter

### 1. Format de Lecture

**CSV** :

```scala
val raw = spark.read
  .option("header", "true")
  .option("inferSchema", "false")
  .csv(inputPath)
```

**Parquet** :

```scala
val raw = spark.read.parquet(inputPath)
raw.printSchema()  // Affichage du schéma typé
```

### 2. Transformations

**CSV** : Beaucoup de `.cast()` nécessaires

```scala
col("code_si").cast("string").as("code_si")
to_timestamp(col("date_iso"), "yyyy-MM-dd'T'HH:mm:ss'Z'").as("date_op")
```

**Parquet** : Moins de `.cast()` (types déjà présents)

```scala
col("code_si").as("code_si")  // Déjà String
col("date_op").as("date_op")  // Déjà Timestamp
```

### 3. Vérification Fichier

**CSV** : `[ ! -f "$CSV_FILE" ]` (fichier)
**Parquet** : `[ ! -d "$PARQUET_FILE" ]` (répertoire)

### 4. Avantages à Documenter

**Parquet** :

- Lecture 3-10x plus rapide
- Schéma typé (pas de parsing)
- Compression automatique
- Format standard production

---

**✅ Conclusion : Le template d'ingestion existant est applicable avec des adaptations spécifiques pour Parquet !**
