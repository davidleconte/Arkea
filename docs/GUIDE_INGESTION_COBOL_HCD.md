# 🔄 Guide : Ingestion Directe de Fichiers COBOL dans HCD

**Date** : 2026-03-13
**Objectif** : Ingérer directement des fichiers séquentiels COBOL dans HCD en respectant les bonnes pratiques et les exigences inputs-clients/inputs-ibm
**Contexte** : Migration HBase → HCD, format COBOL Base64 (Domirama)

---

## ✅ Réponse : OUI, c'est possible

HCD peut ingérer des données COBOL via plusieurs méthodes, en respectant les exigences des inputs-clients et inputs-ibm.

---

## 📋 Exigences Identifiées (inputs-clients & inputs-ibm)

### Format COBOL dans HBase (inputs-clients)

**D'après ANALYSE_INPUTS_CLIENTS_COMPLETE.md** :

- **Table** : `B997X04:domirama`
- **Format** : **Cobol Base64**
- **Key composite** : code SI + numéro de contrat + operation_date
- **TTL** : 10 ans
- **Fonctionnalités** :
  - SCAN + value filter
  - BulkLoad (batch)
  - Unload ORC (export)

### Recommandations IBM (inputs-ibm)

**D'après PROPOSITION_MECE_MIGRATION_HBASE_HCD.md** :

1. **Ingestion Batch** :
   - ✅ **Spark** (recommandé) : Remplacement de Pig/MapReduce
   - ✅ **DSBulk** : Pour chargement massif
   - ✅ **Spark-Cassandra-Connector** : Intégration native

2. **Format de Données** :
   - ✅ Colonnes normalisées (vs format COBOL brut)
   - ✅ `operation_data BLOB` : Stockage des données COBOL brutes (Base64)
   - ✅ Colonnes typées : date_op, montant, libelle, etc.

3. **Performance** :
   - ✅ Écriture parallèle (Spark)
   - ✅ Batch size optimisé
   - ✅ Gestion des erreurs

---

## 🔄 Méthodes d'Ingestion COBOL → HCD

### Méthode 1 : COBOL → Spark → HCD (Recommandé) ⭐

**Pipeline** :

```
Fichier Séquentiel COBOL → Spark (Parser) → HCD (via Spark-Cassandra-Connector)
```

**Avantages** :

- ✅ Performance optimale (parallélisation Spark)
- ✅ Conforme aux recommandations IBM
- ✅ Gestion des erreurs intégrée
- ✅ Transformation en vol (COBOL → colonnes typées)

**Code Spark Scala** :

```scala
import org.apache.spark.sql.{SparkSession, DataFrame}
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import com.datastax.spark.connector._

object CobolToHCDIngestion {

  def main(args: Array[String]): Unit = {
    val spark = SparkSession.builder()
      .appName("CobolToHCDIngestion")
      .config("spark.sql.adaptive.enabled", "true")
      .getOrCreate()

    // 1. Lire fichier séquentiel COBOL (format binaire)
    val cobolRDD = spark.sparkContext.binaryFiles("hdfs:///data/operations_cobol.dat")
      .flatMap { case (path, data) =>
        // Parser les records COBOL (500 bytes chacun)
        data.toArray.grouped(500).map { record =>
          parseCobolRecord(record)
        }
      }

    // 2. Convertir en DataFrame avec schéma typé
    val schema = StructType(Array(
      StructField("code_si", StringType, nullable = false),
      StructField("contrat", StringType, nullable = false),
      StructField("date_op", TimestampType, nullable = false),
      StructField("numero_op", IntegerType, nullable = false),
      StructField("libelle", StringType, nullable = true),
      StructField("montant", DecimalType(10, 2), nullable = true),
      StructField("devise", StringType, nullable = true),
      StructField("date_valeur", TimestampType, nullable = true),
      StructField("type_operation", StringType, nullable = true),
      StructField("sens_operation", StringType, nullable = true),
      StructField("operation_data", BinaryType, nullable = true) // COBOL brut Base64
    ))

    val df = spark.createDataFrame(cobolRDD, schema)

    // 3. Transformation des données
    val dfTransformed = df
      .withColumn("date_op", to_timestamp(col("date_op"), "yyyy-MM-dd'T'HH:mm:ssXXX"))
      .withColumn("date_valeur", to_timestamp(col("date_valeur"), "yyyy-MM-dd'T'HH:mm:ssXXX"))
      .withColumn("montant", col("montant").cast(DecimalType(10, 2)))
      .withColumn("operation_data", base64(col("operation_data"))) // Encoder en Base64

    // 4. Écriture dans HCD via Spark-Cassandra-Connector
    dfTransformed.write
      .format("org.apache.spark.sql.cassandra")
      .options(Map(
        "keyspace" -> "domirama_poc",
        "table" -> "operations_by_account",
        "spark.cassandra.output.batch.size.rows" -> "100",
        "spark.cassandra.output.concurrent.writes" -> "10"
      ))
      .mode("append")
      .save()

    spark.stop()
  }

  def parseCobolRecord(record: Array[Byte]): Row = {
    // Structure COBOL (exemple : 500 bytes)
    val codeSi = new String(record.slice(0, 10), "ISO-8859-1").trim
    val contrat = new String(record.slice(10, 30), "ISO-8859-1").trim
    val dateOpStr = new String(record.slice(30, 56), "ISO-8859-1").trim
    val numeroOp = new String(record.slice(56, 66), "ISO-8859-1").trim.toInt
    val libelle = new String(record.slice(66, 266), "ISO-8859-1").trim
    val montantStr = new String(record.slice(266, 278), "ISO-8859-1").trim
    val devise = new String(record.slice(278, 281), "ISO-8859-1").trim
    val dateValeurStr = new String(record.slice(281, 307), "ISO-8859-1").trim
    val typeOperation = new String(record.slice(307, 327), "ISO-8859-1").trim
    val sensOperation = new String(record.slice(327, 333), "ISO-8859-1").trim
    val operationData = record // Données brutes pour BLOB

    // Convertir montant (format COBOL S9(10)V99)
    val montant = BigDecimal(montantStr.replace(",", "."))

    // Convertir dates (format COBOL)
    val dateOp = java.sql.Timestamp.valueOf(parseCobolDate(dateOpStr))
    val dateValeur = java.sql.Timestamp.valueOf(parseCobolDate(dateValeurStr))

    Row(
      codeSi, contrat, dateOp, numeroOp, libelle,
      montant, devise, dateValeur, typeOperation, sensOperation,
      operationData
    )
  }

  def parseCobolDate(dateStr: String): String = {
    // Parser date COBOL (ex: YYYYMMDDHHMMSS)
    // Convertir en format ISO 8601
    // Implémentation selon format COBOL réel
    dateStr
  }
}
```

**Exécution** :

```bash
spark-submit \
  --class CobolToHCDIngestion \
  --packages com.datastax.spark:spark-cassandra-connector_2.12:3.5.0 \
  cobol-to-hcd-ingestion.jar \
  /data/operations_cobol.dat
```

---

### Méthode 2 : COBOL → CSV → DSBulk → HCD

**Pipeline** :

```
Fichier Séquentiel COBOL → Python (Parser) → CSV → DSBulk → HCD
```

**Avantages** :

- ✅ Utilise DSBulk (recommandé IBM pour bulk load)
- ✅ Gestion d'erreurs automatique
- ✅ Retry automatique
- ✅ Rapport détaillé

**Script Python de Conversion** :

```python
#!/usr/bin/env python3
"""
Conversion fichier séquentiel COBOL → CSV pour DSBulk
"""
import struct
import csv
import base64
from datetime import datetime

# Structure COBOL (500 bytes par record)
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
    'operation_data': (333, 167, 'binary'),  # Données brutes pour BLOB
}

def parse_cobol_date(date_str: str) -> str:
    """Convertit date COBOL en ISO 8601"""
    # Format COBOL : YYYYMMDDHHMMSS
    # Convertir en : YYYY-MM-DDTHH:MM:SS
    if len(date_str) >= 14:
        year = date_str[0:4]
        month = date_str[4:6]
        day = date_str[6:8]
        hour = date_str[8:10]
        minute = date_str[10:12]
        second = date_str[12:14]
        return f"{year}-{month}-{day}T{hour}:{minute}:{second}"
    return date_str

def parse_cobol_decimal(decimal_str: str) -> float:
    """Convertit décimal COBOL (S9(10)V99) en float"""
    # Format : signe + 10 chiffres + virgule + 2 décimales
    # Exemple : "+0000000123,45"
    decimal_str = decimal_str.strip()
    if ',' in decimal_str:
        decimal_str = decimal_str.replace(',', '.')
    return float(decimal_str)

def convert_cobol_to_csv(cobol_file: str, csv_file: str):
    """Convertit fichier séquentiel COBOL en CSV pour DSBulk"""

    with open(cobol_file, 'rb') as f_in, open(csv_file, 'w', encoding='utf-8', newline='') as f_out:
        # En-tête CSV (colonnes de la table HCD)
        fieldnames = [
            'code_si', 'contrat', 'date_op', 'numero_op', 'libelle',
            'montant', 'devise', 'date_valeur', 'type_operation', 'sens_operation',
            'operation_data'  # Base64
        ]
        writer = csv.DictWriter(f_out, fieldnames=fieldnames)
        writer.writeheader()

        # Lecture des records COBOL
        record_count = 0
        while True:
            record = f_in.read(500)
            if len(record) < 500:
                break

            # Extraction des champs
            row = {}
            for field_name, (offset, length, field_type) in COBOL_RECORD_FORMAT.items():
                value_bytes = record[offset:offset+length]

                if field_type == 'str':
                    value = value_bytes.decode('latin1', errors='ignore').strip()
                elif field_type == 'int':
                    value = int(value_bytes.decode('latin1', errors='ignore').strip() or 0)
                elif field_type == 'decimal':
                    value_str = value_bytes.decode('latin1', errors='ignore').strip()
                    value = parse_cobol_decimal(value_str)
                elif field_type == 'binary':
                    # Encoder en Base64 pour BLOB
                    value = base64.b64encode(value_bytes).decode('ascii')
                else:
                    value = value_bytes.decode('latin1', errors='ignore').strip()

                row[field_name] = value

            # Conversion des dates
            if 'date_op' in row and isinstance(row['date_op'], str):
                row['date_op'] = parse_cobol_date(row['date_op'])
            if 'date_valeur' in row and isinstance(row['date_valeur'], str):
                row['date_valeur'] = parse_cobol_date(row['date_valeur'])

            writer.writerow(row)
            record_count += 1

            if record_count % 10000 == 0:
                print(f"✅ {record_count} records convertis...")

        print(f"✅ Conversion terminée : {record_count} records")

# Utilisation
if __name__ == "__main__":
    convert_cobol_to_csv("operations_cobol.dat", "operations.csv")
```

**Import avec DSBulk** :

```bash
# Charger le CSV dans HCD
dsbulk load \
  -h localhost \
  -p 9042 \
  -k domirama_poc \
  -t operations_by_account \
  -url operations.csv \
  -header true \
  -batchSize 100 \
  -maxConcurrentQueries 10 \
  -maxErrors 1000 \
  -logDir logs/dsbulk \
  -delim "," \
  -quote "\""
```

**Options DSBulk importantes** :

- `-batchSize` : Nombre de lignes par batch (100 recommandé)
- `-maxConcurrentQueries` : Parallélisation (10 recommandé)
- `-maxErrors` : Tolérance aux erreurs
- `-logDir` : Logs détaillés

---

### Méthode 3 : COBOL → JSON → DSBulk → HCD

**Pipeline** :

```
Fichier Séquentiel COBOL → Python (Parser) → JSON → DSBulk → HCD
```

**Avantages** :

- ✅ Format JSON plus flexible
- ✅ Support des types complexes
- ✅ Meilleur pour données structurées

**Code Python (JSON)** :

```python
import json
import base64

def convert_cobol_to_json(cobol_file: str, json_file: str):
    """Convertit fichier séquentiel COBOL en JSON pour DSBulk"""

    records = []
    with open(cobol_file, 'rb') as f_in:
        while True:
            record = f_in.read(500)
            if len(record) < 500:
                break

            # Parser record COBOL (même logique que CSV)
            parsed_record = parse_cobol_record(record)

            # Convertir en JSON
            json_record = {
                'code_si': parsed_record['code_si'],
                'contrat': parsed_record['contrat'],
                'date_op': parsed_record['date_op'],
                'numero_op': parsed_record['numero_op'],
                'libelle': parsed_record['libelle'],
                'montant': float(parsed_record['montant']),
                'devise': parsed_record['devise'],
                'date_valeur': parsed_record['date_valeur'],
                'type_operation': parsed_record['type_operation'],
                'sens_operation': parsed_record['sens_operation'],
                'operation_data': base64.b64encode(parsed_record['operation_data']).decode('ascii')
            }

            records.append(json_record)

    # Écrire JSON (un objet par ligne pour DSBulk)
    with open(json_file, 'w', encoding='utf-8') as f_out:
        for record in records:
            f_out.write(json.dumps(record, ensure_ascii=False) + '\n')

# Import avec DSBulk
# dsbulk load -url operations.json -k domirama_poc -t operations_by_account
```

---

## 🎯 Respect des Exigences

### Exigences inputs-clients

| Exigence | Solution | Statut |
|----------|----------|--------|
| **Format COBOL Base64** | Colonne `operation_data BLOB` avec Base64 | ✅ Conforme |
| **BulkLoad (batch)** | Spark ou DSBulk | ✅ Conforme |
| **TTL 10 ans** | `WITH default_time_to_live = 315360000` | ✅ Conforme |
| **Key composite** | Partition key `(code_si, contrat)` + Clustering `(date_op, numero_op)` | ✅ Conforme |
| **Performance** | Parallélisation Spark/DSBulk | ✅ Conforme |

### Exigences inputs-ibm

| Exigence | Solution | Statut |
|----------|----------|--------|
| **Spark (recommandé)** | Méthode 1 : Spark direct | ✅ Conforme |
| **DSBulk (bulk load)** | Méthode 2 ou 3 : DSBulk | ✅ Conforme |
| **Colonnes normalisées** | Schéma CQL typé | ✅ Conforme |
| **operation_data BLOB** | Stockage Base64 | ✅ Conforme |
| **Performance optimale** | Batch size, parallélisation | ✅ Conforme |

---

## 📊 Schéma CQL Recommandé

**Conforme aux exigences inputs-clients et inputs-ibm** :

```sql
CREATE TABLE domirama_poc.operations_by_account (
    code_si TEXT,
    contrat TEXT,
    date_op TIMESTAMP,
    numero_op INT,
    libelle TEXT,
    montant DECIMAL,
    devise TEXT,
    date_valeur TIMESTAMP,
    type_operation TEXT,
    sens_operation TEXT,
    operation_data BLOB,  -- COBOL Base64 (exigence inputs-clients)
    meta_flags MAP<TEXT, TEXT>,
    PRIMARY KEY ((code_si, contrat), date_op, numero_op)
) WITH CLUSTERING ORDER BY (date_op DESC, numero_op ASC)
  AND default_time_to_live = 315360000;  -- 10 ans (exigence inputs-clients)
```

---

## 🔧 Bonnes Pratiques

### 1. Performance

- ✅ **Batch Size** : 100-1000 lignes par batch
- ✅ **Parallélisation** : 10-20 threads concurrents
- ✅ **Compression** : Activer si gros volumes
- ✅ **Monitoring** : Suivre les métriques Spark/DSBulk

### 2. Gestion des Erreurs

- ✅ **Retry automatique** : Configurer dans Spark/DSBulk
- ✅ **Logs détaillés** : Enregistrer les erreurs
- ✅ **Validation** : Vérifier les données avant insertion
- ✅ **Rollback** : Plan de rollback en cas d'échec

### 3. Qualité des Données

- ✅ **Validation format COBOL** : Vérifier structure des records
- ✅ **Types de données** : Conversion correcte (dates, décimales)
- ✅ **Encodage** : Gérer EBCDIC/ASCII correctement
- ✅ **Base64** : Encoder correctement les données brutes

### 4. Sécurité

- ✅ **Authentification** : Utiliser credentials sécurisés
- ✅ **Chiffrement** : Activer SSL/TLS pour connexions
- ✅ **Audit** : Logger les opérations d'ingestion

---

## 📝 Exemple Complet : Script d'Ingestion

**Script bash complet** :

```bash
#!/bin/bash
set -euo pipefail

# Configuration
COBOL_FILE="${1:-/data/operations_cobol.dat}"
KEYSPACE="domirama_poc"
TABLE="operations_by_account"
HCD_HOST="${HCD_HOST:-localhost}"
HCD_PORT="${HCD_PORT:-9042}"

# 1. Conversion COBOL → CSV
echo "🔄 Conversion COBOL → CSV..."
python3 convert_cobol_to_csv.py "$COBOL_FILE" "operations.csv"

# 2. Validation CSV
echo "✅ Validation CSV..."
python3 validate_csv.py "operations.csv"

# 3. Import DSBulk
echo "📥 Import DSBulk dans HCD..."
dsbulk load \
  -h "$HCD_HOST" \
  -p "$HCD_PORT" \
  -k "$KEYSPACE" \
  -t "$TABLE" \
  -url "operations.csv" \
  -header true \
  -batchSize 100 \
  -maxConcurrentQueries 10 \
  -maxErrors 1000 \
  -logDir "logs/dsbulk" \
  -delim "," \
  -quote "\""

# 4. Vérification
echo "🔍 Vérification..."
cqlsh "$HCD_HOST" "$HCD_PORT" -e "SELECT COUNT(*) FROM $KEYSPACE.$TABLE;"

echo "✅ Ingestion terminée !"
```

---

## 🚀 Conclusion

**OUI, il est possible d'insérer directement des fichiers COBOL dans HCD** en respectant :

✅ **Exigences inputs-clients** : Format COBOL Base64, BulkLoad, TTL
✅ **Exigences inputs-ibm** : Spark/DSBulk, colonnes normalisées, performance
✅ **Bonnes pratiques** : Performance, gestion d'erreurs, qualité, sécurité

**Méthode recommandée** : **Spark direct** (Méthode 1) pour performance optimale, ou **DSBulk** (Méthode 2) pour simplicité et gestion d'erreurs.

---

**Dernière mise à jour** : 2026-03-13
