# 📝 Démonstration : Génération des Données Operations (Parquet)

**Date** : 2025-11-27 21:19:19  
**Script** : `04_generate_operations_parquet.sh`  
**Objectif** : Générer un jeu de données complet pour valider tous les use cases du POC DomiramaCatOps

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

Générer un jeu de données complet contenant **20000 opérations** avec une diversité maximale pour valider tous les use cases du POC DomiramaCatOps.

### Caractéristiques des Données

**Volume et Diversité** :
- Volume : 20000 opérations
- 10 codes SI différents
- 50 contrats par code SI (500 contrats total)
- 200+ libellés différents
- 30+ catégories différentes
- 5 types d'opérations (VIREMENT, CB, CHEQUE, PRLV, AUTRE)
- 2 sens (DEBIT, CREDIT)
- Période : 6 mois (janvier 2024 - juin 2024)

**Recherches Avancées Supportées** :
- ✅ **Full-text search** : Libellés variés avec accents français
- ✅ **Fuzzy search** : Variations de libellés et typos potentielles
- ✅ **N-Gram search** : Préfixes variés (CARREFOUR, CARREF, CARRE, CAR)
- ✅ **Vector search** : Libellés sémantiquement similaires
- ✅ **Hybrid search** : Combinaison full-text + vector

**Catégorisation** :
- Catégories automatiques avec scores de confiance variés
- Distribution réaliste (15% ALIMENTATION, 10% RESTAURANT, etc.)
- 5% sans catégorie (pour tester les cas null)

### Stratégie de Génération

1. **Génération CSV avec Python** : Données réalistes avec diversité maximale
2. **Conversion CSV → Parquet avec Spark** : Format optimisé pour performance
3. **Vérification de la cohérence** : Validation du nombre de lignes et des types

---

## 📝 Code Python - Génération CSV

### Code Exécuté

```python
#!/usr/bin/env python3
import csv, random, sys
from datetime import datetime, timedelta
from decimal import Decimal

# Libellés variés pour recherches avancées
LIBELLES = [
    "CB CARREFOUR CITY PARIS 15",
    "CB CARREFOUR MARKET RUE DE VAUGIRARD",
    # ... 200+ libellés différents
]

# Catégories avec distribution réaliste
CATEGORIES = [
    ("ALIMENTATION", 0.15),
    ("RESTAURANT", 0.10),
    # ... 30+ catégories
]

# Génération des opérations
for i in range(20000):
    code_si = random.choice(CODES_SI)
    contrat = f"{code_si}{random.randint(0, 49):08d}"
    date_op = START_DATE + timedelta(days=random_days)
    libelle = random.choice(LIBELLES)
    montant = random.uniform(-5000, 10000)
    categorie_auto = random.choice(CATEGORIES)
    # ...

# Écriture CSV
with open('/Users/david.leconte/Documents/Arkea/poc-design/domiramaCatOps/scripts/../data/operations_20000_temp.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=operations[0].keys())
    writer.writeheader()
    writer.writerows(operations)
```

### Explication

**Génération Réaliste** :
- Utilisation de libellés réels (CARREFOUR, LECLERC, etc.)
- Distribution réaliste des catégories (15% ALIMENTATION, etc.)
- Dates aléatoires sur 6 mois
- Montants réalistes (débits : -5000 à -5€, crédits : 100 à 10000€)

**Recherches Avancées** :
- Libellés avec accents (é, è, à, ç) pour full-text
- Variations (CARREFOUR, CARREFUR, CARREFOR) pour fuzzy
- Préfixes (CARREFOUR, CARREF, CARRE, CAR) pour N-Gram
- Sémantiquement similaires (SUPERMARCHE, HYPERMARCHE) pour vector

**Catégorisation** :
- Scores de confiance variés (0.0 à 1.0)
- 70% haute confiance (0.8-1.0)
- 20% confiance moyenne (0.5-0.8)
- 5% faible confiance (0.0-0.5)
- 5% sans catégorie (null)

### Résultats

✅ **CSV généré** : 20000 opérations

---

## 💾 Code Spark - Conversion CSV → Parquet

### Code Exécuté

```scala
val spark = SparkSession.builder()
  .appName("GenerateOperationsParquet")
  .config("spark.sql.adaptive.enabled", "true")
  .getOrCreate()

println("📥 Lecture du CSV...")
val df = spark.read
  .option("header", "true")
  .option("inferSchema", "true")
  .csv("temp.csv")

println(s"✅ ${df.count()} lignes lues")

// Convertir les types
val dfTyped = df.withColumn(
  "date_op",
  to_timestamp(col("date_op"), "yyyy-MM-dd'T'HH:mm:ssXXX")
).withColumn(
  "numero_op",
  col("numero_op").cast(IntegerType)
).withColumn(
  "montant",
  col("montant").cast(DecimalType(10, 2))
).withColumn(
  "cat_confidence",
  col("cat_confidence").cast(DecimalType(3, 2))
)

println("💾 Écriture en Parquet...")
dfTyped.write
  .mode("overwrite")
  .option("compression", "snappy")
  .parquet("/Users/david.leconte/Documents/Arkea/poc-design/domiramaCatOps/scripts/../data/operations_20000.parquet")

println(s"✅ Parquet généré : /Users/david.leconte/Documents/Arkea/poc-design/domiramaCatOps/scripts/../data/operations_20000.parquet")

// Vérification
val count = spark.read.parquet("/Users/david.leconte/Documents/Arkea/poc-design/domiramaCatOps/scripts/../data/operations_20000.parquet").count()
println(s"📊 Vérification : $count lignes dans le Parquet")
```

### Explication

**Lecture CSV** :
- `option("header", "true")` : Première ligne = en-têtes
- `option("inferSchema", "true")` : Inférence automatique des types
- Lecture optimisée avec Spark

**Conversion des Types** :
- `date_op` : Conversion en Timestamp (format ISO 8601)
- `numero_op` : Conversion en Integer
- `montant` : Conversion en Decimal(10, 2)
- `cat_confidence` : Conversion en Decimal(3, 2)

**Écriture Parquet** :
- `mode("overwrite")` : Permet les rejeux (idempotence)
- `compression("snappy")` : Compression rapide et efficace
- Format Parquet : Optimisé pour Spark (3-10x plus rapide que CSV)

### Résultats

✅ **Parquet généré** : 20000 opérations  
✅ **Taille** : 392K  
✅ **Fichiers** : 4 fichiers Parquet  
✅ **Compression** : snappy

---

## 🔍 Vérifications et Statistiques

### Vérification du Fichier Parquet

| Métrique | Valeur |
|----------|--------|
| Fichier Parquet | `/Users/david.leconte/Documents/Arkea/poc-design/domiramaCatOps/scripts/../data/operations_20000.parquet` |
| Lignes générées | 20000 |
| Taille | 392K |
| Fichiers Parquet | 4 |
| Compression | snappy |

### Caractéristiques des Données

✅ **10 codes SI** différents  
✅ **500 contrats** (50 par code SI)  
✅ **200+ libellés** différents  
✅ **30+ catégories** différentes  
✅ **5 types d'opérations** (VIREMENT, CB, CHEQUE, PRLV, AUTRE)  
✅ **2 sens** (DEBIT, CREDIT)  
✅ **Période** : 6 mois (janvier 2024 - juin 2024)

### Recherches Avancées Supportées

✅ **Full-text search** : Libellés variés avec accents français  
✅ **Fuzzy search** : Variations de libellés et typos potentielles  
✅ **N-Gram search** : Préfixes variés (CARREFOUR, CARREF, CARRE, CAR)  
✅ **Vector search** : Libellés sémantiquement similaires  
✅ **Hybrid search** : Combinaison full-text + vector

---

## ✅ Conclusion

### Résumé de la Génération

✅ **Opérations générées** : 20000  
✅ **Fichier Parquet** : `/Users/david.leconte/Documents/Arkea/poc-design/domiramaCatOps/scripts/../data/operations_20000.parquet`  
✅ **Format** : Parquet (compression snappy)  
✅ **Taille** : 392K  
✅ **Diversité** : Maximale (200+ libellés, 30+ catégories)

### Points Clés Démontrés

- ✅ Génération de données réalistes avec Python
- ✅ Conversion CSV → Parquet optimisée avec Spark
- ✅ Support complet des recherches avancées (full-text, fuzzy, N-Gram, vector, hybrid)
- ✅ Distribution réaliste des catégories et scores de confiance
- ✅ Format Parquet optimisé pour performance (3-10x plus rapide que CSV)

### Prochaines Étapes

1. **Charger les données** : `./05_load_operations_data_parquet.sh /Users/david.leconte/Documents/Arkea/poc-design/domiramaCatOps/scripts/../data/operations_20000.parquet`
2. **Générer les embeddings** : `./05_generate_libelle_embedding.sh`
3. **Générer les meta-categories** : `./04_generate_meta_categories_parquet.sh`
4. **Exécuter les tests** : Tests de recherche avancée

---

**✅ Génération terminée avec succès !**
