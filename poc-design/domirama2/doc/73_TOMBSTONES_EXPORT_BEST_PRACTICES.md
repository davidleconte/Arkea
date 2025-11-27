# ⚠️ Gestion des Tombstones pour l'Export HCD → Parquet

**Date** : 2025-11-26  
**Objectif** : Documenter la gestion des tombstones avant l'export et les bonnes pratiques  
**Contexte** : Export incrémental depuis HCD vers Parquet via Spark

---

## 📋 Table des Matières

1. [Qu'est-ce qu'un Tombstone ?](#quest-ce-quun-tombstone)
2. [Impact sur l'Export](#impact-sur-lexport)
3. [Détection des Tombstones](#détection-des-tombstones)
4. [Stratégies de Traitement](#stratégies-de-traitement)
5. [Bonnes Pratiques](#bonnes-pratiques)
6. [Intégration dans le Script d'Export](#intégration-dans-le-script-dexport)

---

## 🪦 Qu'est-ce qu'un Tombstone ?

### Définition

Un **tombstone** est un marqueur de suppression dans Cassandra/HCD qui indique qu'une donnée a été supprimée ou expirée. Il permet à Cassandra de savoir qu'une donnée n'existe plus, même si elle n'a pas encore été physiquement supprimée du disque.

### Causes de Création

Les tombstones sont créés dans les cas suivants :

1. **Suppression explicite** : `DELETE FROM table WHERE ...`
2. **Valeurs NULL** : Insertion de `NULL` dans une colonne
3. **Expiration TTL** : Données expirées via `default_time_to_live` ou `USING TTL`
4. **Mise à jour de collections** : Modification de collections non figées (SET, LIST, MAP)
5. **Compaction** : Lors de la fusion des SSTables

### Cycle de Vie

```
INSERT → UPDATE → DELETE → Tombstone → Compaction → Purge Physique
                                    ↑
                            (après gc_grace_seconds)
```

- **Création** : Lors d'une suppression ou expiration
- **Conservation** : Pendant `gc_grace_seconds` (défaut : 10 jours = 864000 secondes)
- **Purge** : Lors de la compaction, après `gc_grace_seconds`

---

## ⚠️ Impact sur l'Export

### Problèmes Rencontrés

Lors d'un export Spark depuis HCD, les tombstones peuvent causer :

1. **Performance dégradée** :
   - Cassandra doit scanner les tombstones en mémoire
   - Avertissements : `Scanned over X tombstone rows`
   - Ralentissement des requêtes de lecture

2. **Résultats incorrects** :
   - Les tombstones ne sont **pas** exportés (données supprimées)
   - Mais ils sont comptés dans les scans, ce qui peut fausser les statistiques

3. **Erreurs potentielles** :
   - Si le nombre de tombstones dépasse `tombstone_failure_threshold` (défaut : 100000)
   - La requête peut échouer avec une erreur

### Exemple d'Avertissement

```
Scanned over 1248 tombstone rows for query SELECT * FROM domirama2_poc.operations_by_account 
BYTES LIMIT 2097152 - more than the warning threshold 1000
```

**Signification** :
- Plus de 1000 tombstones scannés (seuil d'avertissement)
- Performance potentiellement dégradée
- Nécessite une action (compaction ou filtrage)

---

## 🔍 Détection des Tombstones

### 1. Via cqlsh

```cql
-- Vérifier le nombre de tombstones dans une table
SELECT COUNT(*) FROM domirama2_poc.operations_by_account 
WHERE date_op >= '2024-01-01' AND date_op < '2024-02-01';
-- Avertissement affiché si > 1000 tombstones
```

### 2. Via nodetool

```bash
# Statistiques de table (nécessite accès au nœud)
nodetool tablestats domirama2_poc.operations_by_account

# Informations sur les tombstones
nodetool cfstats domirama2_poc.operations_by_account
```

### 3. Via Spark (dans le script d'export)

```scala
// Les tombstones sont automatiquement filtrés par Spark Cassandra Connector
// Mais les avertissements apparaissent dans les logs
val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map(
    "table" -> "operations_by_account",
    "keyspace" -> "domirama2_poc"
  ))
  .load()
  .filter(col("date_op") >= startDate && col("date_op") < endDate)
```

**Note** : Spark Cassandra Connector filtre automatiquement les tombstones, mais les avertissements peuvent apparaître dans les logs.

---

## 🛠️ Stratégies de Traitement

### Stratégie 1 : Compaction Avant Export (⭐ Recommandé)

**Principe** : Effectuer une compaction manuelle avant l'export pour purger les tombstones expirés.

**Avantages** :
- ✅ Purge physique des tombstones expirés
- ✅ Amélioration des performances de lecture
- ✅ Réduction des avertissements

**Inconvénients** :
- ⚠️ Consommation de ressources (CPU, I/O)
- ⚠️ Nécessite un accès nodetool (production)

**Commande** :

```bash
# Compaction manuelle d'une table
nodetool compact domirama2_poc operations_by_account

# Compaction de toutes les tables d'un keyspace
nodetool compact domirama2_poc
```

**Quand l'utiliser** :
- Avant un export important (mensuel, annuel)
- Si le nombre de tombstones est élevé (> 1000)
- Si les performances sont dégradées

### Stratégie 2 : Filtrage dans Spark (Automatique)

**Principe** : Spark Cassandra Connector filtre automatiquement les tombstones.

**Avantages** :
- ✅ Automatique, aucune action requise
- ✅ Les tombstones ne sont pas exportés
- ✅ Pas d'impact sur les données exportées

**Inconvénients** :
- ⚠️ Les avertissements peuvent apparaître dans les logs
- ⚠️ Performance potentiellement dégradée si beaucoup de tombstones

**Code** :

```scala
// Le filtrage est automatique, pas besoin de code supplémentaire
val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map(
    "table" -> "operations_by_account",
    "keyspace" -> "domirama2_poc"
  ))
  .load()
  .filter(col("date_op") >= startDate && col("date_op") < endDate)
// Les tombstones sont automatiquement exclus
```

### Stratégie 3 : Configuration gc_grace_seconds

**Principe** : Ajuster `gc_grace_seconds` pour purger les tombstones plus rapidement.

**Avantages** :
- ✅ Purge plus rapide des tombstones
- ✅ Réduction de l'accumulation

**Inconvénients** :
- ⚠️ Risque si les réparations ne sont pas régulières
- ⚠️ Nécessite une configuration au niveau table

**Configuration** :

```cql
-- Réduire gc_grace_seconds (défaut : 864000 = 10 jours)
ALTER TABLE domirama2_poc.operations_by_account 
WITH gc_grace_seconds = 432000;  -- 5 jours

-- Vérifier la configuration
DESCRIBE TABLE domirama2_poc.operations_by_account;
```

**Quand l'utiliser** :
- Si les réparations sont effectuées régulièrement
- Si le cluster est stable
- Si l'accumulation de tombstones est un problème récurrent

### Stratégie 4 : TimeWindowCompactionStrategy (TWCS)

**Principe** : Utiliser TWCS pour les tables avec TTL, facilitant la purge des tombstones.

**Avantages** :
- ✅ Optimisé pour les données temporelles avec TTL
- ✅ Purge efficace des tombstones expirés
- ✅ Performance améliorée pour les exports par fenêtre temporelle

**Configuration** :

```cql
-- Changer la stratégie de compaction
ALTER TABLE domirama2_poc.operations_by_account 
WITH compaction = {
  'class': 'TimeWindowCompactionStrategy',
  'compaction_window_unit': 'DAYS',
  'compaction_window_size': 1
};
```

**Quand l'utiliser** :
- Tables avec TTL (comme `operations_by_account`)
- Exports par fenêtre temporelle
- Données de type séries temporelles

---

## ✅ Bonnes Pratiques

### 1. Avant l'Export

- ✅ **Vérifier les tombstones** : Surveiller les avertissements dans les logs
- ✅ **Compacter si nécessaire** : Si > 1000 tombstones, effectuer une compaction
- ✅ **Vérifier gc_grace_seconds** : S'assurer que la valeur est appropriée
- ✅ **Surveiller les performances** : Vérifier les temps de réponse des requêtes

### 2. Pendant l'Export

- ✅ **Filtrage automatique** : Spark filtre automatiquement les tombstones
- ✅ **Surveiller les logs** : Vérifier les avertissements tombstone
- ✅ **Vérifier les statistiques** : Comparer le nombre d'opérations exportées vs attendues

### 3. Après l'Export

- ✅ **Vérifier la cohérence** : Comparer les données exportées avec les données source
- ✅ **Documenter les tombstones** : Noter le nombre de tombstones scannés
- ✅ **Planifier la compaction** : Si nécessaire, planifier une compaction régulière

### 4. Configuration Recommandée

```cql
-- Table avec TTL et TWCS
CREATE TABLE domirama2_poc.operations_by_account (
    -- colonnes...
) WITH
    default_time_to_live = 315360000  -- 10 ans
    AND gc_grace_seconds = 864000     -- 10 jours (défaut)
    AND compaction = {
        'class': 'TimeWindowCompactionStrategy',
        'compaction_window_unit': 'DAYS',
        'compaction_window_size': 1
    };
```

### 5. Monitoring

```bash
# Surveiller les tombstones via nodetool
nodetool tablestats domirama2_poc.operations_by_account | grep -i tombstone

# Vérifier les métriques de compaction
nodetool compactionstats
```

---

## 🔧 Intégration dans le Script d'Export

### Vérification des Tombstones

Le script `27_export_incremental_parquet_v2_didactique.sh` doit :

1. **Détecter les avertissements tombstone** dans les logs Spark
2. **Afficher un avertissement** si > 1000 tombstones
3. **Suggérer une compaction** si nécessaire
4. **Documenter dans le rapport** le nombre de tombstones scannés

### Code à Ajouter

```scala
// Dans le script Spark
// Les tombstones sont automatiquement filtrés, mais on peut détecter les avertissements
// via les logs et afficher un message d'avertissement

println("\n⚠️  Vérification des tombstones...")
println("   Les tombstones sont automatiquement filtrés par Spark Cassandra Connector")
println("   Si des avertissements apparaissent, considérer une compaction avant l'export")
```

### Documentation dans le Rapport

Le rapport markdown généré doit inclure :

- **Section "Gestion des Tombstones"** :
  - Nombre de tombstones détectés (si disponible)
  - Avertissements émis
  - Recommandations (compaction si nécessaire)

---

## 📊 Exemple de Rapport

```markdown
## 🔍 Gestion des Tombstones

### Détection

- **Avertissements tombstone** : 1248 tombstones scannés
- **Seuil d'avertissement** : 1000 (dépassé)
- **Impact** : Performance potentiellement dégradée

### Actions Recommandées

1. **Compaction manuelle** (si accès nodetool) :
   ```bash
   nodetool compact domirama2_poc operations_by_account
   ```

2. **Vérification gc_grace_seconds** :
   ```cql
   DESCRIBE TABLE domirama2_poc.operations_by_account;
   ```

3. **Surveillance** : Surveiller les métriques de compaction

### Résultat

- ✅ **Export réussi** : Les tombstones ont été automatiquement filtrés
- ⚠️  **Performance** : Légère dégradation due aux tombstones
- ✅ **Données** : Aucun tombstone exporté (comportement attendu)
```

---

## 🎯 Recommandations Finales

### Pour les Exports Réguliers

1. **Compaction planifiée** : Effectuer une compaction avant les exports mensuels/annuels
2. **Monitoring** : Surveiller les métriques de tombstones
3. **Configuration** : Utiliser TWCS pour les tables avec TTL
4. **Documentation** : Documenter les actions et résultats

### Pour les Exports Ponctuels

1. **Vérification** : Vérifier les avertissements dans les logs
2. **Compaction si nécessaire** : Si > 1000 tombstones, compacter avant l'export
3. **Filtrage automatique** : S'appuyer sur le filtrage automatique de Spark
4. **Rapport** : Documenter les tombstones dans le rapport d'export

---

## 📚 Références

- [DataStax : Tombstones](https://docs.datastax.com/en/cql/cassandra-5.0/data-modeling/best-practices.html)
- [Apache Cassandra : Compaction](https://cassandra.apache.org/doc/stable/cassandra/managing/operating/compaction/overview.html)
- [TimeWindowCompactionStrategy](https://cassandra.apache.org/doc/stable/cassandra/managing/operating/compaction/twcs.html)

---

**✅ Documentation créée le 2025-11-26**



