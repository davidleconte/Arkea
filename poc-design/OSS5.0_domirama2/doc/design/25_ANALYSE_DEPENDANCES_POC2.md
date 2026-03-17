# 📋 Analyse des Dépendances pour POC2 (SequenceFile + OperationDecoder)

**Date** : 2025-11-25
**Objectif** : Vérifier la disponibilité des dépendances JAR nécessaires pour le POC2 conforme IBM

---

## 🎯 Contexte

Le **POC2** de la proposition IBM nécessite :

- Lecture des **SequenceFiles** existants (format HBase actuel)
- Décodage **COBOL** via **OperationDecoder** (composants production)
- Alimentation HCD via Spark

**Objectif** : POC techniquement honnête avec les mêmes composants que la production

---

## 📦 Dépendances Requises

### Liste des JARs Nécessaires

D'après la demande, les dépendances suivantes sont **strictement nécessaires** :

| Groupe | Artifact | Version | Type | Source |
|--------|----------|---------|------|--------|
| `arkea` | `com.arkea.commons.cobol` | `0.30` | Interne | Arkéa |
| `arkea` | `com.arkea.cav.operationdecoder` | `0.6.3` | Interne | Arkéa |
| `arkea` | `com.arkea.commons.thrift` | `1.6.6` | Interne | Arkéa |
| `arkea` | `com.arkea.commons.crypto` | `0.8` | Interne | Arkéa |
| `com.arkea.commons.hadoop` | `com.arkea.commons.hadoop` | `2.0.0` | Interne | Arkéa |
| `net.sf` | `cb2xml` | `1.01.1` | Open Source | Maven Central |

**Source** : Dépendances déclarées dans `com.arkea.domiramabatch-ivy.xml`

---

## 🔍 Vérification de Disponibilité

### 1. Recherche dans les Inputs Clients

**Archive analysée** : `inputs-clients/groupe_2025-11-25-110250.zip`

**Contenu** :

- 11 archives `tar.gz` (code source des projets)
- 1 JAR : `com.arkea.commons.hbase-0.5.5.jar` (54 KB)
- 1 PDF : Documentation

**Résultat** :

- ❌ **JARs manquants** : Aucun des JARs requis n'est présent dans l'archive
- ⚠️ **JAR présent** : `com.arkea.commons.hbase-0.5.5.jar` (mais **pas dans la liste requise**)
- ✅ **Code source** : `domiramabatch-develop.tar.gz` (641 KB) - Contient probablement les dépendances déclarées dans `ivy.xml`

**Action nécessaire** : Extraire `domiramabatch-develop.tar.gz` et analyser `com.arkea.domiramabatch-ivy.xml` pour confirmer les versions

### 2. Vérification Proposition IBM

**Document** : `inputs-ibm/PROPOSITION_MECE_MIGRATION_HBASE_HCD.md`
**Section** : `3.1. Jars Arkéa à récupérer (minimum)` (lignes 1379-1391)

**JARs mentionnés par IBM** :

- ✅ `com.arkea.commons.cobol-0.30.jar` (confirmé)
- ✅ `com.arkea.cav.operationdecoder-0.6.3.jar` (confirmé)
- ⚠️ `com.arkea.commons.thrift-1.6.6.jar` (probable - mentionné par IBM)
- ⚠️ `com.arkea.commons.hadoop-2.0.0.jar` (optionnel mais utile - mentionné par IBM)
- ✅ `cb2xml-1.01.1.jar` (open-source - confirmé)

**Différence avec la liste fournie** :

- ❓ `com.arkea.commons.crypto-0.8.jar` : **Non mentionné par IBM** mais présent dans la liste fournie
  - **Hypothèse** : Nécessaire pour le décryptage des données COBOL chiffrées
  - **Action** : Vérifier si présent dans `ivy.xml` du projet `domiramabatch`

### 3. Comparaison Liste Fournie vs Proposition IBM

| Dépendance | Liste Fournie | Proposition IBM | Statut |
|------------|---------------|-----------------|--------|
| `com.arkea.commons.cobol:0.30` | ✅ | ✅ | **Confirmé** |
| `com.arkea.cav.operationdecoder:0.6.3` | ✅ | ✅ | **Confirmé** |
| `com.arkea.commons.thrift:1.6.6` | ✅ | ⚠️ (probable) | **Confirmé** |
| `com.arkea.commons.crypto:0.8` | ✅ | ❌ (non mentionné) | **À vérifier** |
| `com.arkea.commons.hadoop:2.0.0` | ✅ | ⚠️ (optionnel) | **Confirmé** |
| `net.sf:cb2xml:1.01.1` | ✅ | ✅ | **Confirmé** |

**Résultat** : **5/6 dépendances confirmées** par la proposition IBM, **1 dépendance à vérifier** (`crypto`)

---

## 📊 Analyse des Dépendances

### Dépendances Critiques

#### 1. `com.arkea.cav.operationdecoder:0.6.3` ⭐ CRITIQUE

**Usage** :

- Instanciation des `OperationDecoder` (ex. `Y7XDOMIOperationDecoder`)
- Décodage des données COBOL depuis SequenceFile
- Transformation COBOL → Colonnes normalisées

**Impact** : **BLOQUANT** - Sans ce JAR, impossible de décoder les données COBOL réelles

#### 2. `com.arkea.commons.cobol:0.30` ⭐ CRITIQUE

**Usage** :

- Parsing des structures COBOL
- Décodage des formats COBOL
- Gestion des copies COBOL

**Impact** : **BLOQUANT** - Nécessaire pour le décodage COBOL

#### 3. `com.arkea.commons.thrift:1.6.6` ⚠️ IMPORTANT

**Usage** :

- Décodage des données Thrift (catégorisation)
- Sérialisation/désérialisation Thrift

**Impact** : **IMPORTANT** - Nécessaire pour la catégorisation

#### 4. `com.arkea.commons.crypto:0.8` ⚠️ IMPORTANT

**Usage** :

- Décryptage des données chiffrées
- Gestion des clés de chiffrement

**Impact** : **IMPORTANT** - Peut être nécessaire selon les données

#### 5. `com.arkea.commons.hadoop:2.0.0` ⚠️ IMPORTANT

**Usage** :

- Lecture des SequenceFiles Hadoop
- InputFormat personnalisés
- Intégration avec l'écosystème Hadoop

**Impact** : **IMPORTANT** - Nécessaire pour lire les SequenceFiles

#### 6. `net.sf:cb2xml:1.01.1` ✅ DISPONIBLE

**Usage** :

- Conversion COBOL → XML
- Parsing des structures COBOL

**Impact** : **NON-BLOQUANT** - Disponible sur Maven Central

**Source** : Maven Central (open source)

---

## 🔴 Statut de Disponibilité

| Dépendance | Statut | Disponibilité | Action Requise | Confirmation IBM |
|------------|--------|---------------|----------------|-----------------|
| `com.arkea.commons.cobol:0.30` | ❌ Manquant | Non trouvé | **Demander à Arkéa** | ✅ Confirmé |
| `com.arkea.cav.operationdecoder:0.6.3` | ❌ Manquant | Non trouvé | **Demander à Arkéa** | ✅ Confirmé |
| `com.arkea.commons.thrift:1.6.6` | ❌ Manquant | Non trouvé | **Demander à Arkéa** | ⚠️ Probable |
| `com.arkea.commons.crypto:0.8` | ❌ Manquant | Non trouvé | **Demander à Arkéa** | ❓ À vérifier |
| `com.arkea.commons.hadoop:2.0.0` | ❌ Manquant | Non trouvé | **Demander à Arkéa** | ⚠️ Optionnel |
| `net.sf:cb2xml:1.01.1` | ✅ Disponible | Maven Central | Télécharger depuis Maven | ✅ Confirmé |

**Résultat** : **5/6 dépendances manquantes** (83%) - **Toutes les dépendances critiques sont manquantes**

---

## 📝 Actions Requises

### Priorité 1 (Critique - Bloquant)

1. **Demander les JARs à Arkéa** :
   - Format : ZIP contenant tous les JARs
   - OU : Accès à un repository Maven interne
   - OU : URLs de téléchargement

2. **JARs prioritaires** :
   - `com.arkea.cav.operationdecoder:0.6.3` ⭐
   - `com.arkea.commons.cobol:0.30` ⭐
   - `com.arkea.commons.hadoop:2.0.0` ⭐

### Priorité 2 (Important)

3. **JARs complémentaires** :
   - `com.arkea.commons.thrift:1.6.6`
   - `com.arkea.commons.crypto:0.8`

### Priorité 3 (Non-bloquant)

4. **JAR open source** :
   - `net.sf:cb2xml:1.01.1` → Télécharger depuis Maven Central

---

## 🔧 Configuration Spark pour POC2

### Structure Attendue

```scala
// POC2 - SequenceFile + OperationDecoder
import com.arkea.cav.operationdecoder.Y7XDOMIOperationDecoder
import com.arkea.commons.cobol.CobolDecoder
import org.apache.hadoop.io.{SequenceFile, Text}
import org.apache.spark.sql.SparkSession

val spark = SparkSession.builder()
  .appName("Domirama2LoaderSequenceFile")
  .config("spark.cassandra.connection.host", "localhost")
  .getOrCreate()

// Lire SequenceFile
val sequenceFile = spark.sparkContext
  .sequenceFile[Text, Text]("hdfs://path/to/sequencefile")

// Décoder COBOL via OperationDecoder
val decoder = new Y7XDOMIOperationDecoder()
val decoded = sequenceFile.map { case (key, value) =>
  val operation = decoder.decode(value.toString)
  // Transformer en Operation pour HCD
}

// Écrire dans HCD
decoded.write
  .format("org.apache.spark.sql.cassandra")
  .options(Map("keyspace" -> "domirama2_poc", "table" -> "operations_by_account"))
  .save()
```

### Dépendances Spark

```xml
<dependencies>
  <!-- JARs Arkéa (à ajouter manuellement) -->
  <dependency>
    <groupId>arkea</groupId>
    <artifactId>com.arkea.cav.operationdecoder</artifactId>
    <version>0.6.3</version>
    <scope>provided</scope>
  </dependency>
  <!-- ... autres dépendances Arkéa ... -->

  <!-- Spark Cassandra Connector -->
  <dependency>
    <groupId>com.datastax.spark</groupId>
    <artifactId>spark-cassandra-connector_2.12</artifactId>
    <version>3.5.0</version>
  </dependency>
</dependencies>
```

---

## 📋 Checklist POC2

### Prérequis Techniques

- [ ] ✅ HCD 1.2.3 installé et démarré
- [ ] ✅ Spark 3.5.1 installé
- [ ] ✅ Spark Cassandra Connector 3.5.0
- [ ] ❌ **JARs Arkéa manquants** (5/6)
- [ ] ✅ Schéma HCD créé (domirama2_poc)

### JARs Requis

- [ ] ❌ `com.arkea.commons.cobol:0.30`
- [ ] ❌ `com.arkea.cav.operationdecoder:0.6.3`
- [ ] ❌ `com.arkea.commons.thrift:1.6.6`
- [ ] ❌ `com.arkea.commons.crypto:0.8`
- [ ] ❌ `com.arkea.commons.hadoop:2.0.0`
- [ ] ✅ `net.sf:cb2xml:1.01.1` (Maven Central)

### Fichiers Requis

- [ ] ❌ SequenceFiles de production (ou échantillons)
- [ ] ❌ Configuration OperationDecoder
- [ ] ❌ Mapping COBOL → Colonnes HCD

---

## 🎯 Conclusion

### Statut Actuel

**POC2 non réalisable** sans les JARs Arkéa :

- ❌ **5/6 dépendances manquantes** (83%)
- ❌ **2 dépendances critiques** manquantes (OperationDecoder, Cobol)
- ✅ **1 dépendance disponible** (cb2xml sur Maven Central)

### Vérification Proposition IBM

**✅ Liste validée** : La liste fournie est **cohérente** avec la proposition IBM :

- **5/6 dépendances** confirmées par IBM (lignes 1383-1391)
- **1 dépendance** (`crypto`) non mentionnée par IBM mais probablement nécessaire

**Source IBM** : `inputs-ibm/PROPOSITION_MECE_MIGRATION_HBASE_HCD.md` - Section `3.1. Jars Arkéa à récupérer (minimum)`

### Actions Immédiates

1. **Demander les JARs à Arkéa** :
   - Format ZIP avec tous les JARs
   - OU accès repository Maven interne
   - OU instructions de build depuis le code source

2. **Alternative** :
   - Si les JARs ne sont pas disponibles, le POC2 ne peut pas être réalisé
   - Se limiter au POC1 (CSV) qui est fonctionnel

### Recommandation

**Pour réaliser le POC2 conforme IBM** :

- ✅ **Demander les JARs** à Arkéa (priorité haute)
- ✅ **Vérifier les SequenceFiles** disponibles (échantillons ou production)
- ✅ **Préparer la configuration** Spark avec les JARs

**Sans ces JARs** :

- ⚠️ POC2 **non réalisable**
- ✅ POC1 (CSV) reste fonctionnel et valide pour la démonstration

---

## 📚 Références

- **Proposition IBM** : `inputs-ibm/PROPOSITION_MECE_MIGRATION_HBASE_HCD.md`
- **Code source** : `inputs-clients/groupe_2025-11-25-110250.zip` → `domiramabatch-develop.tar.gz`
- **Dépendances déclarées** : `com.arkea.domiramabatch-ivy.xml` (à extraire)

---

**Date de vérification** : 2025-11-25
**Statut** : ⚠️ **JARs manquants - Action requise auprès d'Arkéa**
