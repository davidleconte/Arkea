# 🔄 Analyse : Génération COBOL vs Python pour Conversion Parquet

**Date** : 2026-03-13
**Question** : Est-ce qu'il aurait été possible de générer des séquences de fichiers COBOL puis de les transformer en Parquet ?
**Contexte** : Migration HBase → HCD, génération de données de test pour POCs

---

## ✅ Réponse : OUI, c'est techniquement possible

### Approche Actuelle (Python → CSV → Parquet)

**Pipeline actuel** :

```
Python Script → CSV → Spark → Parquet
```

**Exemple** (domiramaCatOps) :

- `04_generate_operations_parquet.sh` : Génère CSV avec Python, convertit en Parquet avec Spark
- Avantages : Simple, rapide, portable, facile à maintenir

---

## 🔄 Approche Alternative : COBOL → Fichier Séquentiel → Parquet

### Architecture Possible

```
COBOL Program → Fichier Séquentiel (EBCDIC/ASCII) → Conversion → Parquet
```

### Étapes Détaillées

#### 1. **Génération COBOL**

**Exemple de programme COBOL** :

```cobol
IDENTIFICATION DIVISION.
PROGRAM-ID. GENERATE-OPERATIONS.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT OPERATIONS-FILE ASSIGN TO 'operations.dat'
           ORGANIZATION IS SEQUENTIAL
           ACCESS MODE IS SEQUENTIAL
           FILE STATUS IS WS-FILE-STATUS.
DATA DIVISION.
FILE SECTION.
FD  OPERATIONS-FILE
    RECORDING MODE IS F
    RECORD CONTAINS 500 CHARACTERS.
01  OPERATION-RECORD.
    05  CODE-SI              PIC X(10).
    05  CONTRAT              PIC X(20).
    05  DATE-OP              PIC X(26).
    05  NUMERO-OP             PIC 9(10).
    05  LIBELLE               PIC X(200).
    05  MONTANT               PIC S9(10)V99.
    05  DEVISE                PIC X(3).
    05  DATE-VALEUR           PIC X(26).
    05  TYPE-OPERATION        PIC X(20).
    05  SENS-OPERATION        PIC X(6).
    05  FILLER                PIC X(383).
WORKING-STORAGE SECTION.
01  WS-FILE-STATUS           PIC XX.
01  WS-COUNTER               PIC 9(10) VALUE ZERO.
01  WS-MAX-RECORDS            PIC 9(10) VALUE 20000.
PROCEDURE DIVISION.
MAIN-PARA.
    OPEN OUTPUT OPERATIONS-FILE
    PERFORM GENERATE-RECORDS UNTIL WS-COUNTER >= WS-MAX-RECORDS
    CLOSE OPERATIONS-FILE
    STOP RUN.
GENERATE-RECORDS.
    MOVE FUNCTION RANDOM(WS-COUNTER) TO CODE-SI
    MOVE FUNCTION CURRENT-DATE TO DATE-OP
    MOVE WS-COUNTER TO NUMERO-OP
    MOVE 'CB CARREFOUR CITY PARIS 15' TO LIBELLE
    MOVE 123.45 TO MONTANT
    WRITE OPERATION-RECORD
    ADD 1 TO WS-COUNTER.
```

**Caractéristiques** :

- Format fixe (Fixed-Length Records)
- Encodage : EBCDIC (mainframe) ou ASCII (Linux/Windows)
- Structure : Records de 500 caractères
- Types : PIC X (string), PIC 9 (numeric), PIC S9V99 (decimal)

---

#### 2. **Conversion Fichier Séquentiel → Format Intermédiaire**

**Options de conversion** :

**A. Conversion Directe COBOL → CSV** :

```python
#!/usr/bin/env python3
"""
Conversion fichier séquentiel COBOL → CSV
"""
import struct

# Structure du record COBOL (500 bytes)
COBOL_RECORD_FORMAT = {
    'code_si': (0, 10, 'str'),
    'contrat': (10, 20, 'str'),
    'date_op': (30, 26, 'str'),
    'numero_op': (56, 10, 'int'),
    'libelle': (66, 200, 'str'),
    'montant': (266, 12, 'decimal'),  # S9(10)V99
    'devise': (278, 3, 'str'),
    'date_valeur': (281, 26, 'str'),
    'type_operation': (307, 20, 'str'),
    'sens_operation': (327, 6, 'str'),
}

def convert_cobol_to_csv(cobol_file, csv_file):
    """Convertit fichier séquentiel COBOL en CSV"""
    with open(cobol_file, 'rb') as f_in, open(csv_file, 'w', encoding='utf-8') as f_out:
        # En-tête CSV
        f_out.write(','.join(COBOL_RECORD_FORMAT.keys()) + '\n')

        # Lecture des records
        while True:
            record = f_in.read(500)
            if len(record) < 500:
                break

            # Extraction des champs
            fields = []
            for field_name, (offset, length, field_type) in COBOL_RECORD_FORMAT.items():
                value = record[offset:offset+length].decode('latin1').strip()

                # Conversion selon type
                if field_type == 'int':
                    value = int(value) if value else 0
                elif field_type == 'decimal':
                    # Format COBOL : S9(10)V99 (signe + 10 chiffres + virgule + 2 décimales)
                    value = float(value.replace(',', '.')) if value else 0.0
                elif field_type == 'str':
                    value = value.strip()

                fields.append(str(value))

            f_out.write(','.join(fields) + '\n')

# Utilisation
convert_cobol_to_csv('operations.dat', 'operations.csv')
```

**B. Conversion Directe COBOL → Parquet (avec PyArrow)** :

```python
#!/usr/bin/env python3
"""
Conversion directe fichier séquentiel COBOL → Parquet
"""
import pyarrow as pa
import pyarrow.parquet as pq
import struct

def convert_cobol_to_parquet(cobol_file, parquet_file):
    """Convertit fichier séquentiel COBOL directement en Parquet"""

    # Définir le schéma Parquet
    schema = pa.schema([
        pa.field('code_si', pa.string()),
        pa.field('contrat', pa.string()),
        pa.field('date_op', pa.timestamp('ns')),
        pa.field('numero_op', pa.int32()),
        pa.field('libelle', pa.string()),
        pa.field('montant', pa.decimal128(10, 2)),
        pa.field('devise', pa.string()),
        pa.field('date_valeur', pa.timestamp('ns')),
        pa.field('type_operation', pa.string()),
        pa.field('sens_operation', pa.string()),
    ])

    # Lire et convertir les records
    records = []
    with open(cobol_file, 'rb') as f:
        while True:
            record = f.read(500)
            if len(record) < 500:
                break

            # Extraire les champs (même logique que ci-dessus)
            code_si = record[0:10].decode('latin1').strip()
            contrat = record[10:30].decode('latin1').strip()
            # ... extraction des autres champs ...

            records.append({
                'code_si': code_si,
                'contrat': contrat,
                # ... autres champs ...
            })

    # Créer la table PyArrow
    table = pa.Table.from_pylist(records, schema=schema)

    # Écrire en Parquet
    pq.write_table(table, parquet_file, compression='snappy')

# Utilisation
convert_cobol_to_parquet('operations.dat', 'operations.parquet')
```

**C. Conversion avec Spark** :

```scala
// Spark Scala - Conversion COBOL → Parquet
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("COBOLToParquet")
  .getOrCreate()

// Lire fichier séquentiel COBOL (format binaire)
val cobolRDD = spark.sparkContext.binaryFiles("operations.dat")
  .flatMap { case (path, data) =>
    // Parser les records COBOL (500 bytes chacun)
    data.toArray.grouped(500).map { record =>
      // Extraire les champs selon la structure COBOL
      val codeSi = new String(record.slice(0, 10), "ISO-8859-1").trim
      val contrat = new String(record.slice(10, 30), "ISO-8859-1").trim
      // ... autres champs ...

      (codeSi, contrat, /* ... autres champs ... */)
    }
  }

// Convertir en DataFrame
val df = spark.createDataFrame(cobolRDD).toDF(
  "code_si", "contrat", /* ... autres colonnes ... */
)

// Convertir les types
val dfTyped = df
  .withColumn("numero_op", col("numero_op").cast("int"))
  .withColumn("montant", col("montant").cast("decimal(10,2)"))
  .withColumn("date_op", to_timestamp(col("date_op"), "yyyy-MM-dd'T'HH:mm:ssXXX"))

// Écrire en Parquet
dfTyped.write
  .mode("overwrite")
  .option("compression", "snappy")
  .parquet("operations.parquet")
```

---

## 📊 Comparaison : COBOL vs Python

### Avantages de l'Approche COBOL

| Aspect | COBOL | Python (Actuel) |
|--------|-------|-----------------|
| **Fidélité Mainframe** | ✅ Format identique aux systèmes mainframe | ⚠️ Format différent |
| **Performance Génération** | ✅ Très rapide (compilé) | ⚠️ Plus lent (interprété) |
| **Compatibilité Legacy** | ✅ Compatible avec systèmes existants | ❌ Nécessite réécriture |
| **Validation Format** | ✅ Respect strict des formats COBOL | ⚠️ Validation manuelle |
| **Réutilisation Code** | ✅ Réutilise code COBOL existant | ❌ Code nouveau |

### Inconvénients de l'Approche COBOL

| Aspect | COBOL | Python (Actuel) |
|--------|-------|-----------------|
| **Complexité** | ❌ Plus complexe (compilation, environnement) | ✅ Simple (script direct) |
| **Portabilité** | ❌ Nécessite compilateur COBOL | ✅ Portable (Python universel) |
| **Maintenance** | ❌ Moins de développeurs COBOL | ✅ Large communauté Python |
| **Flexibilité** | ❌ Moins flexible (format fixe) | ✅ Très flexible (dynamique) |
| **Développement** | ❌ Plus long (compilation, tests) | ✅ Rapide (développement itératif) |
| **Dépendances** | ❌ Compilateur COBOL requis | ✅ Python standard |

---

## 🎯 Cas d'Usage Recommandés

### ✅ Utiliser COBOL si

1. **Migration depuis Mainframe** :
   - Système source en COBOL
   - Besoin de fidélité 100% au format
   - Réutilisation de code existant

2. **Validation Format** :
   - Tests de compatibilité avec systèmes legacy
   - Validation de conversion EBCDIC → ASCII
   - Tests de limites (tailles de champs, formats)

3. **Performance Critique** :
   - Génération de très gros volumes (millions de records)
   - Contraintes de temps strictes

### ✅ Utiliser Python (Approche Actuelle) si

1. **POC et Développement** :
   - Rapidité de développement
   - Flexibilité des données
   - Itérations fréquentes

2. **Portabilité** :
   - Déploiement cross-platform
   - Pas de dépendances lourdes
   - Facilité de maintenance

3. **Équipe** :
   - Équipe plus familière avec Python
   - Pas d'expertise COBOL disponible
   - Besoin de documentation claire

---

## 🔧 Implémentation Hybride Possible

### Architecture Hybride

```
COBOL (Production) → Fichier Séquentiel → Python (Conversion) → Parquet
```

**Avantages** :

- ✅ Génération COBOL pour fidélité
- ✅ Conversion Python pour flexibilité
- ✅ Meilleur des deux mondes

**Exemple** :

```bash
#!/bin/bash
# Pipeline hybride : COBOL → Python → Parquet

# 1. Génération COBOL (sur mainframe ou simulateur)
cobc -x generate_operations.cbl
./generate_operations

# 2. Conversion Python (portable)
python3 convert_cobol_to_csv.py operations.dat operations.csv

# 3. Conversion Spark → Parquet
spark-submit --class COBOLToParquet convert_cobol_to_parquet.scala
```

---

## 📝 Recommandation pour ARKEA

### Pour le POC ARKEA

**Approche actuelle (Python) est recommandée** car :

1. ✅ **Rapidité de développement** : POC nécessite itérations rapides
2. ✅ **Flexibilité** : Données de test variées et complexes
3. ✅ **Portabilité** : Déploiement cross-platform (macOS, Linux, WSL2)
4. ✅ **Maintenance** : Équipe plus familière avec Python
5. ✅ **Documentation** : Scripts didactiques plus faciles à comprendre

### Pour la Production

**Envisager COBOL si** :

1. ⚠️ **Système source en COBOL** : Migration depuis mainframe
2. ⚠️ **Besoins de performance** : Volumes très importants
3. ⚠️ **Validation format** : Tests de compatibilité strictes

**Sinon, continuer avec Python** :

- Performance Python suffisante pour la plupart des cas
- Flexibilité plus importante
- Maintenance plus simple

---

## 🚀 Conclusion

**OUI, c'est techniquement possible** de générer des fichiers séquentiels COBOL et de les transformer en Parquet.

**Cependant**, pour le POC ARKEA, l'approche actuelle (Python → CSV → Parquet) est **plus adaptée** car :

- ✅ Plus rapide à développer
- ✅ Plus flexible
- ✅ Plus portable
- ✅ Plus facile à maintenir

**L'approche COBOL serait pertinente** si :

- Migration depuis un système mainframe COBOL
- Besoin de validation de format strict
- Performance critique pour très gros volumes

---

**Dernière mise à jour** : 2026-03-13
