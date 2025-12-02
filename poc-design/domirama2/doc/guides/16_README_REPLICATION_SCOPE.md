# 🔄 REPLICATION_SCOPE : Réplication Multi-Cluster

**Date** : 2025-11-25  
**Objectif** : Documenter l'équivalent REPLICATION_SCOPE HBase dans HCD/Cassandra

---

## 📋 REPLICATION_SCOPE HBase

### Configuration

**HBase** utilise `REPLICATION_SCOPE` pour contrôler la réplication entre clusters :

```java
// HBase : Configuration de la réplication
HColumnDescriptor columnFamily = new HColumnDescriptor("data");
columnFamily.setScope(1);  // REPLICATION_SCOPE => '1' = Réplication activée
// REPLICATION_SCOPE => '0' = Pas de réplication
```

### Fonctionnement

**REPLICATION_SCOPE** :

- **0** : Pas de réplication (données locales uniquement)
- **1** : Réplication activée vers d'autres clusters HBase

**Architecture HBase** :

```
Cluster HBase Source
  └─> REPLICATION_SCOPE => '1'
      └─> Réplication vers Cluster HBase Destination
```

### Cas d'Usage

**REPLICATION_SCOPE => '1'** est utilisé pour :

- ✅ **Disaster Recovery** : Backup vers un cluster distant
- ✅ **Géolocalisation** : Réplication vers clusters régionaux
- ✅ **Analytics** : Réplication vers cluster d'analyse (séparé)
- ✅ **Conformité** : Réplication pour conformité réglementaire

---

## 🎯 Équivalent HCD/Cassandra

### Réplication au Niveau du Keyspace

**HCD/Cassandra** gère la réplication au niveau du **keyspace** :

```cql
-- Configuration de réplication dans le keyspace
CREATE KEYSPACE domirama2_poc
WITH REPLICATION = {
  'class': 'NetworkTopologyStrategy',
  'datacenter1': 3,  -- 3 réplicas dans datacenter1
  'datacenter2': 2   -- 2 réplicas dans datacenter2
};
```

### Stratégies de Réplication

#### 1. SimpleStrategy (Single Datacenter)

**Pour POC/Développement** :

```cql
CREATE KEYSPACE domirama2_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1  -- 1 réplica (POC single-node)
};
```

**Équivalent REPLICATION_SCOPE** :

- ✅ **SimpleStrategy** = Réplication locale uniquement
- ✅ **replication_factor: 1** = Pas de réplication (équivalent REPLICATION_SCOPE => '0')

#### 2. NetworkTopologyStrategy (Multi-Datacenter)

**Pour Production Multi-Cluster** :

```cql
CREATE KEYSPACE domirama2_poc
WITH REPLICATION = {
  'class': 'NetworkTopologyStrategy',
  'datacenter1': 3,  -- 3 réplicas dans datacenter1 (cluster principal)
  'datacenter2': 2   -- 2 réplicas dans datacenter2 (cluster secondaire)
};
```

**Équivalent REPLICATION_SCOPE** :

- ✅ **NetworkTopologyStrategy** = Réplication multi-cluster activée
- ✅ **datacenter2** = Cluster distant (équivalent REPLICATION_SCOPE => '1')

---

## 📊 Comparaison : HBase vs HCD/Cassandra

| Critère | REPLICATION_SCOPE HBase | Réplication HCD/Cassandra | Gagnant |
|---------|-------------------------|---------------------------|---------|
| **Niveau** | Column Family | Keyspace | ✅ **HCD** |
| **Granularité** | Par Column Family | Par Keyspace | ✅ **HCD** |
| **Configuration** | Par table | Centralisée (keyspace) | ✅ **HCD** |
| **Multi-Datacenter** | ⚠️ Configuration complexe | ✅ Native (NetworkTopologyStrategy) | ✅ **HCD** |
| **Consistance** | ⚠️ Asynchrone | ✅ Configurable (QUORUM, ALL, etc.) | ✅ **HCD** |

**Conclusion** : ✅ **Réplication HCD/Cassandra est plus flexible et native**

---

## 🎯 Équivalences Détaillées

### 1. Pas de Réplication (REPLICATION_SCOPE => '0')

**HBase** :

```java
HColumnDescriptor columnFamily = new HColumnDescriptor("data");
columnFamily.setScope(0);  // Pas de réplication
```

**HCD/Cassandra** :

```cql
CREATE KEYSPACE domirama2_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1  -- 1 réplica uniquement (pas de réplication)
};
```

**Équivalence** :

- ✅ **REPLICATION_SCOPE => '0'** = **SimpleStrategy avec replication_factor: 1**

### 2. Réplication Activée (REPLICATION_SCOPE => '1')

**HBase** :

```java
HColumnDescriptor columnFamily = new HColumnDescriptor("data");
columnFamily.setScope(1);  // Réplication activée
```

**HCD/Cassandra** :

```cql
CREATE KEYSPACE domirama2_poc
WITH REPLICATION = {
  'class': 'NetworkTopologyStrategy',
  'datacenter1': 3,  -- Cluster principal
  'datacenter2': 2   -- Cluster secondaire (réplication)
};
```

**Équivalence** :

- ✅ **REPLICATION_SCOPE => '1'** = **NetworkTopologyStrategy avec plusieurs datacenters**

---

## 🏗️ Architecture Multi-Cluster

### Architecture HBase (REPLICATION_SCOPE => '1')

```
Cluster HBase Principal (Paris)
  └─> Table: domirama
      └─> Column Family: data (REPLICATION_SCOPE => '1')
          └─> Réplication asynchrone
              └─> Cluster HBase Secondaire (Lyon)
                  └─> Table: domirama (répliquée)
```

### Architecture HCD/Cassandra (NetworkTopologyStrategy)

```
Keyspace: domirama2_poc
  └─> NetworkTopologyStrategy
      ├─> Datacenter1 (Paris) - replication_factor: 3
      │   └─> Node1, Node2, Node3
      └─> Datacenter2 (Lyon) - replication_factor: 2
          └─> Node4, Node5
```

**Avantages HCD** :

- ✅ **Réplication native** : Pas de configuration supplémentaire
- ✅ **Consistance configurable** : QUORUM, ALL, etc.
- ✅ **Géolocalisation** : Réplication automatique par datacenter

---

## 📋 Configuration pour Production Multi-Cluster

### Étape 1 : Configuration des Datacenters

**Dans cassandra.yaml de chaque node** :

```yaml
# Node dans Datacenter1 (Paris)
cluster_name: 'Arkea_HCD_Cluster'
datacenter: 'paris'
rack: 'rack1'

# Node dans Datacenter2 (Lyon)
cluster_name: 'Arkea_HCD_Cluster'
datacenter: 'lyon'
rack: 'rack1'
```

### Étape 2 : Création du Keyspace avec Réplication Multi-Cluster

```cql
-- Créer le keyspace avec réplication multi-datacenter
CREATE KEYSPACE domirama2_prod
WITH REPLICATION = {
  'class': 'NetworkTopologyStrategy',
  'paris': 3,   -- 3 réplicas dans datacenter Paris (cluster principal)
  'lyon': 2    -- 2 réplicas dans datacenter Lyon (cluster secondaire)
};
```

**Équivalent REPLICATION_SCOPE => '1'** :

- ✅ **NetworkTopologyStrategy** = Réplication activée
- ✅ **datacenter 'lyon'** = Cluster distant (équivalent destination HBase)

### Étape 3 : Vérification de la Réplication

```cql
-- Vérifier la configuration de réplication
DESCRIBE KEYSPACE domirama2_prod;

-- Vérifier les réplicas par datacenter
SELECT * FROM system_schema.keyspaces WHERE keyspace_name = 'domirama2_prod';
```

---

## 🎯 Cas d'Usage : Quand Utiliser la Réplication Multi-Cluster ?

### Cas 1 : Disaster Recovery

**Besoin** : Backup vers un cluster distant

**Configuration HCD** :

```cql
CREATE KEYSPACE domirama2_prod
WITH REPLICATION = {
  'class': 'NetworkTopologyStrategy',
  'paris': 3,   -- Cluster principal
  'lyon': 2     -- Cluster de backup (disaster recovery)
};
```

**Équivalent HBase** :

- REPLICATION_SCOPE => '1' sur Column Family 'data'

### Cas 2 : Géolocalisation

**Besoin** : Réplication vers clusters régionaux

**Configuration HCD** :

```cql
CREATE KEYSPACE domirama2_prod
WITH REPLICATION = {
  'class': 'NetworkTopologyStrategy',
  'paris': 3,   -- Cluster France
  'lyon': 2,    -- Cluster France (backup)
  'bruxelles': 2 -- Cluster Belgique (géolocalisation)
};
```

**Équivalent HBase** :

- REPLICATION_SCOPE => '1' avec configuration multi-cluster

### Cas 3 : Analytics Séparé

**Besoin** : Réplication vers cluster d'analyse (lecture seule)

**Configuration HCD** :

```cql
CREATE KEYSPACE domirama2_prod
WITH REPLICATION = {
  'class': 'NetworkTopologyStrategy',
  'paris': 3,      -- Cluster production (écriture)
  'analytics': 2   -- Cluster analytics (lecture seule)
};
```

**Équivalent HBase** :

- REPLICATION_SCOPE => '1' vers cluster analytics

---

## 🔍 POC Actuel : Single-Node

### Configuration Actuelle

**POC Domirama2** :

```cql
CREATE KEYSPACE domirama2_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1  -- Single-node (POC)
};
```

**Équivalent REPLICATION_SCOPE** :

- ✅ **SimpleStrategy** = Pas de réplication multi-cluster
- ✅ **replication_factor: 1** = Équivalent REPLICATION_SCOPE => '0'

### Pourquoi Pas de Réplication dans le POC ?

**Raisons** :

- ✅ **POC local** : Single-node sur MacBook Pro
- ✅ **Démonstration** : Focus sur fonctionnalités métier
- ✅ **Complexité** : Multi-cluster nécessite plusieurs nodes

**Note** : La réplication multi-cluster peut être démontrée si nécessaire avec :

- Configuration multi-datacenter simulée
- Documentation de la configuration production

---

## 📋 Migration : HBase → HCD (Réplication)

### Étape 1 : Analyser Configuration HBase

**HBase** :

```java
// Analyser les Column Families avec REPLICATION_SCOPE => '1'
HTableDescriptor tableDesc = admin.getTableDescriptor(tableName);
for (HColumnDescriptor cf : tableDesc.getColumnFamilies()) {
    if (cf.getScope() == 1) {
        // Cette Column Family doit être répliquée
        System.out.println("CF: " + cf.getName() + " - Réplication activée");
    }
}
```

### Étape 2 : Créer Keyspace avec Réplication

**HCD** :

```cql
-- Créer le keyspace avec réplication multi-cluster
CREATE KEYSPACE domirama2_prod
WITH REPLICATION = {
  'class': 'NetworkTopologyStrategy',
  'datacenter1': 3,  -- Cluster principal
  'datacenter2': 2   -- Cluster secondaire (réplication)
};
```

### Étape 3 : Migration des Données

**Stratégie** :

1. ✅ **Double-write** : Écrire dans HBase et HCD simultanément
2. ✅ **Validation** : Vérifier la cohérence des données
3. ✅ **Basculer** : Passer la lecture vers HCD
4. ✅ **Arrêter** : Arrêter l'écriture HBase

---

## 🎯 Avantages vs REPLICATION_SCOPE HBase

### 1. Configuration Centralisée

**HBase** :

- ⚠️ Configuration par Column Family
- ⚠️ Nécessite configuration sur chaque table

**HCD** :

- ✅ **Configuration au niveau keyspace** : Une seule configuration
- ✅ **Plus simple** : Pas de configuration par table

### 2. Réplication Native

**HBase** :

- ⚠️ Réplication asynchrone configurée séparément
- ⚠️ Nécessite configuration supplémentaire

**HCD** :

- ✅ **Réplication native** : Intégrée dans Cassandra
- ✅ **Pas de configuration supplémentaire** : Fonctionne automatiquement

### 3. Consistance Configurable

**HBase** :

- ⚠️ Consistance limitée par la réplication asynchrone

**HCD** :

- ✅ **Consistance configurable** : QUORUM, ALL, ONE, etc.
- ✅ **Lecture locale** : LOCAL_QUORUM pour performance

### 4. Multi-Datacenter

**HBase** :

- ⚠️ Configuration complexe pour multi-cluster

**HCD** :

- ✅ **NetworkTopologyStrategy** : Support natif multi-datacenter
- ✅ **Géolocalisation** : Réplication automatique par région

---

## 🎯 Conclusion

### Équivalences Démonstrées

1. ✅ **REPLICATION_SCOPE => '0'** = **SimpleStrategy avec replication_factor: 1**
2. ✅ **REPLICATION_SCOPE => '1'** = **NetworkTopologyStrategy avec plusieurs datacenters**

### Avantages HCD

1. ✅ **Configuration centralisée** : Au niveau keyspace (vs Column Family)
2. ✅ **Réplication native** : Intégrée dans Cassandra
3. ✅ **Consistance configurable** : QUORUM, ALL, etc.
4. ✅ **Multi-datacenter** : Support natif (NetworkTopologyStrategy)

### POC Actuel

**Configuration** :

- ✅ **SimpleStrategy** : Single-node (POC)
- ✅ **Équivalent REPLICATION_SCOPE => '0'** : Pas de réplication

**Pour Production** :

- ✅ **NetworkTopologyStrategy** : Multi-cluster si nécessaire
- ✅ **Équivalent REPLICATION_SCOPE => '1'** : Réplication activée

---

## 📋 Recommandations

### Pour le POC

**Configuration actuelle** :

```cql
CREATE KEYSPACE domirama2_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};
```

**Justification** :

- ✅ POC local (single-node)
- ✅ Focus sur fonctionnalités métier
- ✅ Équivalent REPLICATION_SCOPE => '0' (pas de réplication)

### Pour Production

**Configuration recommandée** :

```cql
CREATE KEYSPACE domirama2_prod
WITH REPLICATION = {
  'class': 'NetworkTopologyStrategy',
  'datacenter1': 3,  -- Cluster principal (3 réplicas)
  'datacenter2': 2   -- Cluster secondaire (2 réplicas pour disaster recovery)
};
```

**Justification** :

- ✅ Équivalent REPLICATION_SCOPE => '1' (réplication activée)
- ✅ Disaster recovery : Cluster secondaire
- ✅ Haute disponibilité : 3 réplicas dans cluster principal

---

## 🚀 Démonstrations Disponibles

### Script 34 : Démonstration Standard

**Fichier** : `34_demo_replication_scope_v2.sh`

**Contenu** :

- Explication REPLICATION_SCOPE HBase vs Réplication HCD
- Vérification configuration POC
- Comparaison HBase vs HCD
- Configuration production

### Script 34 v2 : Démonstration Améliorée ⭐

**Fichier** : `34_demo_replication_scope_v2.sh`

**Améliorations** :

- ✅ Consistency levels expliqués (QUORUM, LOCAL_QUORUM, etc.)
- ✅ Driver Java : Configuration et exemples
- ✅ Load Balancing Policy : DatacenterAwareRoundRobinPolicy
- ✅ Retry Policy : DefaultRetryPolicy
- ✅ Exemple Java complet : Code fonctionnel
- ✅ Comparaison avec HBase : Avantages consistance

**Usage** :

```bash
./34_demo_replication_scope_v2.sh
```

### Exemple Java Complet

**Fichier** : `ExempleJavaReplication.java`

**Contenu** :

- Configuration du driver avec consistency level
- Exemples avec QUORUM, LOCAL_QUORUM, ONE
- Load Balancing Policy
- Retry Policy

**Compilation** :

```bash
javac -cp "cassandra-driver-core-4.x.x.jar" ExempleJavaReplication.java
```

---

## 📋 Consistency Levels et Drivers

### Consistency Levels Disponibles

| Level | Description | Cas d'Usage |
|-------|-------------|-------------|
| **ONE** | 1 réplica répond | Performance maximale, risque consistance |
| **TWO** | 2 réplicas répondent | Performance élevée |
| **THREE** | 3 réplicas répondent | Consistance forte (si RF >= 3) |
| **QUORUM** | (RF/2 + 1) réplicas | Équilibre performance/consistance (recommandé) |
| **LOCAL_QUORUM** | QUORUM dans datacenter local | Performance locale (multi-datacenter) |
| **EACH_QUORUM** | QUORUM dans chaque datacenter | Consistance forte multi-datacenter |
| **ALL** | Tous les réplicas | Consistance maximale, performance réduite |
| **ANY** | N'importe quel réplica | Écriture uniquement (performance maximale) |

### Driver Java (DataStax Driver 4.x)

#### Configuration Globale

```java
CqlSession session = CqlSession.builder()
    .withConfigLoader(DriverConfigLoader.programmaticBuilder()
        .withString(DefaultDriverOption.REQUEST_CONSISTENCY, "QUORUM")
        .withString(DefaultDriverOption.LOAD_BALANCING_LOCAL_DATACENTER, "paris")
        .build())
    .build();
```

#### Configuration par Requête

```java
SimpleStatement select = SimpleStatement.builder("SELECT * FROM ...")
    .setConsistencyLevel(ConsistencyLevel.LOCAL_QUORUM)
    .build();
```

#### Load Balancing Policy

**DatacenterAwareRoundRobinPolicy** (recommandé pour multi-datacenter) :

- Envoie les requêtes vers le datacenter local en priorité
- Compatible avec LOCAL_QUORUM pour performance
- Fallback automatique si datacenter local indisponible

#### Retry Policy

**DefaultRetryPolicy** (recommandé) :

- Gestion automatique des erreurs de consistance
- Retry intelligent si consistency level non atteint
- Fallback automatique vers autre datacenter si nécessaire

---

## 📊 Résultats des Exécutions

### Script 34 : REPLICATION_SCOPE (Exécuté le 2025-11-26)

**Résultats** (10 parties démontrées) :

#### PARTIE 1 : REPLICATION_SCOPE HBase vs Réplication HCD

- ✅ **HBase** : Réplication asynchrone (pas de contrôle consistance)
- ✅ **HCD** : Réplication avec consistency levels configurables
- ✅ **Différence clé** : Contrôle de la consistance avec HCD

#### PARTIE 2 : Consistency Levels HCD/Cassandra

- ✅ **Niveaux documentés** : ONE, TWO, THREE, QUORUM, LOCAL_QUORUM, EACH_QUORUM, ALL, ANY
- ✅ **Exemples calculés** : QUORUM = (RF/2 + 1) réplicas
- ✅ **Avantage vs HBase** : Contrôle de la consistance

#### PARTIE 3 : Driver Java - Configuration de Base

- ✅ **Configuration avec DriverConfigLoader** : Documentée
- ✅ **Consistency level par défaut** : QUORUM (recommandé)

#### PARTIE 4 : Driver Java - Consistency Level par Requête

- ✅ **setConsistencyLevel() par requête** : Fonctionne
- ✅ **Exemples** : QUORUM, LOCAL_QUORUM documentés
- ✅ **Avantage** : Performance vs Consistance (trade-off configurable)

#### PARTIE 5 : Driver Java - Load Balancing Policy

- ✅ **DatacenterAwareRoundRobinPolicy** : Documentée
- ✅ **Compatible avec LOCAL_QUORUM** : Pour performance
- ✅ **Fallback automatique** : Si datacenter local indisponible

#### PARTIE 6 : Driver Java - Retry Policy

- ✅ **DefaultRetryPolicy** : Gestion automatique des erreurs
- ✅ **Compatible avec QUORUM/LOCAL_QUORUM** : Retry intelligent

#### PARTIE 7 : Cas d'Usage - Multi-Datacenter

- ✅ **NetworkTopologyStrategy** : Configuration documentée
- ✅ **LOCAL_QUORUM** : Performance locale
- ✅ **Équivalent REPLICATION_SCOPE => '1'** : Réplication activée

#### PARTIE 8 : Comparaison HBase vs HCD

- ✅ **HBase** : Réplication asynchrone, pas de contrôle consistance
- ✅ **HCD** : Réplication synchrone, consistance configurable
- ✅ **Avantage HCD** : Contrôle de la consistance

#### PARTIE 9 : Exemple Complet Java

- ✅ **Exemple Java créé** : `/tmp/ExempleJavaReplication.java`
- ✅ **Configuration globale et par requête** : Documentée
- ✅ **Load Balancing et Retry Policy** : Inclus

#### PARTIE 10 : Résumé et Conclusion

- ✅ **Équivalences REPLICATION_SCOPE** : Documentées
- ✅ **Consistency Levels et Drivers** : Expliqués
- ✅ **Avantages vs HBase** : Consistance configurable

**Conclusion** :

- ✅ Toutes les équivalences documentées
- ✅ Exemples Java fonctionnels fournis
- ✅ Avantages significatifs vs REPLICATION_SCOPE HBase

---

**✅ L'équivalent REPLICATION_SCOPE est documenté, avec des avantages significatifs !**
