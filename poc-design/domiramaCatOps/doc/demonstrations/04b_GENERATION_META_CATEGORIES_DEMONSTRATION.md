# 📝 Démonstration : Génération des Données Meta-Categories (Parquet)

**Date** : 2025-11-27 21:21:03  
**Script** : `04_generate_meta_categories_parquet.sh`  
**Objectif** : Générer un jeu de données complet pour les 7 tables meta-categories du POC DomiramaCatOps

---

## 📋 Table des Matières

1. [Contexte et Stratégie](#contexte-et-stratégie)
2. [Code Python - Génération CSV](#code-python---génération-csv)
3. [Code Spark - Conversion CSV → Parquet](#code-spark---conversion-csv--parquet)
4. [Vérifications et Statistiques](#vérifications-et-statistiques)
5. [Conclusion](#conclusion)

---

## 📚 Contexte et Stratégie

### Objectif

Générer un jeu de données complet pour les **7 tables meta-categories** avec des données cohérentes avec les opérations générées.

### Les 7 Tables Meta-Categories

1. **acceptation_client** : Acceptation de l'affichage/catégorisation par le client
2. **opposition_categorisation** : Opposition à la catégorisation automatique
3. **historique_opposition** : Historique des changements d'opposition (remplace VERSIONS => '50' HBase)
4. **feedback_par_libelle** : Feedbacks moteur/clients par libellé (compteurs atomiques)
5. **feedback_par_ics** : Feedbacks moteur/clients par code ICS (compteurs atomiques)
6. **regles_personnalisees** : Règles de catégorisation personnalisées par établissement
7. **decisions_salaires** : Décisions de catégorisation spécifiques pour salaires

### Cohérence avec les Opérations

✅ **Mêmes codes SI** (1-10)  
✅ **Mêmes contrats** (cohérents avec operations_by_account)  
✅ **Mêmes libellés simplifiés** (CARREFOUR, LECLERC, etc.)  
✅ **Mêmes catégories** (ALIMENTATION, RESTAURANT, etc.)  
✅ **Mêmes types d'opérations** (VIREMENT, CB, CHEQUE, PRLV, AUTRE)

### Stratégie de Génération

1. **Génération CSV avec Python** : Données cohérentes pour 7 tables
2. **Conversion CSV → Parquet avec Spark** : Format optimisé pour performance
3. **Vérification de la cohérence** : Validation du nombre de lignes et des types

---

## 📝 Code Python - Génération CSV

### Code Exécuté

```python
#!/usr/bin/env python3
import csv, random, sys
from datetime import datetime, timedelta
from uuid import uuid4

# Codes SI et contrats (cohérents avec operations)
CODES_SI = [str(i) for i in range(1, 11)]
CONTRATS_PAR_SI = 50
PSE_PAR_CONTRAT = 2

# TABLE 1 : acceptation_client
for code_si in CODES_SI:
    for i in range(CONTRATS_PAR_SI):
        contrat = f"{code_si}{i:08d}"
        for j in range(PSE_PAR_CONTRAT):
            pse = f"PSE{j+1:03d}"
            accepted = random.random() < 0.8  # 80% acceptent
            # ...

# TABLE 2 : opposition_categorisation
# TABLE 3 : historique_opposition
# TABLE 4 : feedback_par_libelle
# TABLE 5 : feedback_par_ics
# TABLE 6 : regles_personnalisees
# TABLE 7 : decisions_salaires
```

### Résultats

✅ **acceptation_client** : 1000 acceptations générées  
✅ **opposition_categorisation** : 4 oppositions générées  
✅ **historique_opposition** : 40 entrées d'historique générées  
✅ **feedback_par_libelle** : 1000 feedbacks générés  
✅ **feedback_par_ics** : 600 feedbacks générés  
✅ **regles_personnalisees** : 300 règles générées  
✅ **decisions_salaires** : 5 décisions générées

---

## 💾 Code Spark - Conversion CSV → Parquet

### Code Exécuté

```scala
val spark = SparkSession.builder()
  .appName("GenerateMetaCategoriesParquet")
  .config("spark.sql.adaptive.enabled", "true")
  .getOrCreate()

// Conversion des types selon la table
val dfTyped = table_name match {
  case "acceptation_client" | "opposition_categorisation" =>
    df.withColumn("accepted", col("accepted").cast(BooleanType))
      .withColumn("opposed", col("opposed").cast(BooleanType))
      .withColumn("accepted_at", to_timestamp(...))
  case "historique_opposition" =>
    df.withColumn("timestamp", to_timestamp(...))
  case "feedback_par_libelle" | "feedback_par_ics" =>
    df.withColumn("count_engine", col("count_engine").cast(LongType))
      .withColumn("count_client", col("count_client").cast(LongType))
  case "regles_personnalisees" =>
    df.withColumn("actif", col("actif").cast(BooleanType))
      .withColumn("priorite", col("priorite").cast(IntegerType))
  case "decisions_salaires" =>
    df.withColumn("actif", col("actif").cast(BooleanType))
  case _ => df
}

dfTyped.write
  .mode("overwrite")
  .option("compression", "snappy")
  .parquet("output.parquet")
```

### Résultats

✅ **7 fichiers Parquet générés** dans `${ARKEA_HOME}/poc-design/domiramaCatOps/scripts/../data/meta-categories`  
✅ **Format** : Parquet (compression snappy)  
✅ **Types** : Boolean, Timestamp, Long (COUNTER), Integer

---

## 🔍 Vérifications et Statistiques

### Statistiques par Table

| Table | Lignes Générées |
|-------|-----------------|
| acceptation_client | 1000 |
| opposition_categorisation | 4 |
| historique_opposition | 40 |
| feedback_par_libelle | 1000 |
| feedback_par_ics | 600 |
| regles_personnalisees | 300 |
| decisions_salaires | 5 |

### Caractéristiques des Données

✅ **Cohérence** : Mêmes codes SI, contrats, libellés que les opérations  
✅ **Distribution réaliste** : 80% acceptent, 10% opposent, etc.  
✅ **Types corrects** : Boolean, Timestamp, Long (COUNTER), Integer  
✅ **Format optimisé** : Parquet (compression snappy)

---

## ✅ Conclusion

### Résumé de la Génération

✅ **7 fichiers Parquet générés** dans `${ARKEA_HOME}/poc-design/domiramaCatOps/scripts/../data/meta-categories`  
✅ **Cohérence** : Données cohérentes avec les opérations générées  
✅ **Distribution réaliste** : Respect des proportions métier  
✅ **Types corrects** : Conversion appropriée pour chaque table

### Points Clés Démontrés

- ✅ Génération de données cohérentes avec Python
- ✅ Conversion CSV → Parquet optimisée avec Spark
- ✅ Support de 7 tables distinctes avec types variés
- ✅ Distribution réaliste des données métier
- ✅ Format Parquet optimisé pour performance

### Prochaines Étapes

1. **Charger les opérations** : `./05_load_operations_data_parquet.sh`
2. **Charger les meta-categories** : `./06_load_meta_categories_data_parquet.sh`
3. **Exécuter les tests** : Tests de cohérence multi-tables

---

**✅ Génération terminée avec succès !**
