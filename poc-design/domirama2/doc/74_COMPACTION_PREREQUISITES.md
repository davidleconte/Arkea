# 🔧 Prérequis pour Compaction : Éviter les Tombstones à l'Export

**Date** : 2025-11-26  
**Objectif** : Documenter les prérequis nécessaires avant une compaction pour éviter les tombstones lors de l'export  
**Script** : `scripts/compact_table_prepare.sh`

---

## 📋 Table des Matières

1. [Pourquoi des Prérequis ?](#pourquoi-des-prérequis)
2. [Prérequis Obligatoires](#prérequis-obligatoires)
3. [Prérequis Recommandés](#prérequis-recommandés)
4. [Drain : Nécessaire ou Non ?](#drain--nécessaire-ou-non)
5. [Script Automatisé](#script-automatisé)
6. [Procédure Complète](#procédure-complète)

---

## ❓ Pourquoi des Prérequis ?

### Problème

Lors d'une compaction, Cassandra purge les tombstones expirés (après `gc_grace_seconds`). Cependant, si les tombstones ne sont pas correctement propagés sur tous les nœuds, il y a un risque de :

1. **Zombie Data** : Réapparition de données supprimées après compaction
2. **Tombstones non purgés** : Tombstones non propagés ne seront pas purgés
3. **Incohérences** : Données différentes entre nœuds

### Solution

Les prérequis garantissent :
- ✅ Propagation correcte des tombstones (repair)
- ✅ Cohérence du cluster (vérification état)
- ✅ Configuration appropriée (gc_grace_seconds)
- ✅ Espace disque suffisant (vérification)

---

## ✅ Prérequis Obligatoires

### 1. Vérification État du Cluster

**Objectif** : S'assurer que tous les nœuds sont opérationnels et synchronisés.

**Commande** :
```bash
nodetool status
```

**Vérifications** :
- ✅ Tous les nœuds en état `UN` (Up Normal)
- ❌ Aucun nœud en état `DN` (Down)
- ❌ Aucun nœud en état `UJ` (Up Joining)

**Impact** :
- Si un nœud est down, les tombstones peuvent ne pas être propagés
- Risque de zombie data après compaction

### 2. Vérification gc_grace_seconds

**Objectif** : Vérifier que `gc_grace_seconds` est approprié.

**Commande** :
```cql
DESCRIBE TABLE domirama2_poc.operations_by_account;
```

**Valeur par défaut** : 864000 secondes (10 jours)

**Vérifications** :
- ✅ `gc_grace_seconds >= 864000` (recommandé)
- ⚠️ Si `gc_grace_seconds < 864000`, s'assurer que les repairs sont réguliers

**Impact** :
- Si `gc_grace_seconds` est trop court, risque de purge prématurée
- Si trop long, accumulation de tombstones

---

## ⭐ Prérequis Recommandés

### 3. Repair Complet (⭐ CRITIQUE)

**Objectif** : Propager les tombstones sur tous les nœuds avant compaction.

**Commande** :
```bash
nodetool repair -pr domirama2_poc operations_by_account
```

**Options** :
- `-pr` : Primary range only (plus rapide, recommandé pour standalone)
- Sans `-pr` : Full repair (tous les ranges, plus long)

**Pourquoi c'est critique** :
- ✅ Propage les tombstones sur tous les nœuds
- ✅ Évite la réapparition de données supprimées (zombie data)
- ✅ Garantit la cohérence avant compaction

**Quand l'effectuer** :
- ⭐ **AVANT chaque compaction importante** (export mensuel/annuel)
- ⭐ **Si des suppressions ont eu lieu récemment**
- ⭐ **Si un nœud a été hors ligne**

**Durée** : Variable selon la taille des données (peut prendre plusieurs heures)

### 4. Vérification Espace Disque

**Objectif** : S'assurer qu'il y a suffisamment d'espace pour la compaction.

**Commande** :
```bash
df -h /chemin/vers/hcd
```

**Vérifications** :
- ✅ Espace disponible > 20% (recommandé)
- ⚠️ Si < 20%, risque de problème pendant compaction

**Impact** :
- La compaction nécessite de l'espace temporaire
- Manque d'espace = compaction échouée

---

## 🚫 Drain : Nécessaire ou Non ?

### Réponse : **NON, le drain n'est PAS nécessaire pour la compaction**

### Qu'est-ce que le drain ?

```bash
nodetool drain
```

**Effets** :
- Vide les memtables sur le disque
- Empêche de nouvelles écritures
- Prépare un nœud à l'arrêt

### Quand utiliser le drain ?

- ✅ **Avant d'arrêter un nœud** (maintenance, mise à jour)
- ✅ **Avant un redémarrage** du nœud
- ❌ **PAS pour la compaction** (compaction peut s'exécuter en ligne)

### Pourquoi pas nécessaire pour compaction ?

- ✅ La compaction s'exécute en arrière-plan
- ✅ Les écritures continuent normalement
- ✅ Pas besoin d'arrêter le nœud

---

## 🤖 Script Automatisé

### Script : `scripts/compact_table_prepare.sh`

**Fonctionnalités** :
1. ✅ Vérification état du cluster
2. ✅ Vérification gc_grace_seconds
3. ✅ Repair complet (optionnel mais recommandé)
4. ✅ Vérification espace disque
5. ✅ Compaction de la table
6. ✅ Vérification post-compaction

**Utilisation** :
```bash
# Avec paramètres par défaut (domirama2_poc.operations_by_account)
./scripts/compact_table_prepare.sh

# Avec paramètres personnalisés
./scripts/compact_table_prepare.sh domirama2_poc operations_by_account
```

**Interactions** :
- Demande confirmation pour repair (recommandé : Oui)
- Demande confirmation pour compaction (après vérifications)

---

## 📋 Procédure Complète

### Étape 1 : Vérification Préalable

```bash
# 1. Vérifier que HCD est démarré
nc -z localhost 9042

# 2. Vérifier l'état du cluster
nodetool status

# 3. Vérifier gc_grace_seconds
cqlsh localhost 9042 -e "DESCRIBE TABLE domirama2_poc.operations_by_account;"
```

### Étape 2 : Repair (Recommandé)

```bash
# Repair complet (propagation tombstones)
nodetool repair -pr domirama2_poc operations_by_account

# Attendre la fin du repair
# Surveiller avec : nodetool netstats
```

**Durée** : Variable (peut prendre plusieurs heures)

### Étape 3 : Vérification Espace Disque

```bash
# Vérifier l'espace disponible
df -h /chemin/vers/hcd

# S'assurer qu'il y a > 20% d'espace disponible
```

### Étape 4 : Compaction

```bash
# Compaction de la table
nodetool compact domirama2_poc operations_by_account

# La compaction s'exécute en arrière-plan
# Surveiller avec : nodetool compactionstats
```

**Durée** : Variable selon la taille des données

### Étape 5 : Vérification Post-Compaction

```bash
# Vérifier le statut de la compaction
nodetool compactionstats

# Vérifier les statistiques de la table
nodetool tablestats domirama2_poc operations_by_account

# Vérifier les tombstones restants (via cqlsh)
cqlsh localhost 9042 -e "SELECT COUNT(*) FROM domirama2_poc.operations_by_account;"
```

### Étape 6 : Export

```bash
# Une fois la compaction terminée, lancer l'export
./27_export_incremental_parquet_v2_didactique.sh
```

---

## 🎯 Résumé des Prérequis

| Prérequis | Obligatoire | Recommandé | Commande |
|-----------|-------------|------------|----------|
| **État cluster** | ✅ | - | `nodetool status` |
| **gc_grace_seconds** | ✅ | - | `DESCRIBE TABLE` |
| **Repair** | - | ⭐ **CRITIQUE** | `nodetool repair -pr` |
| **Espace disque** | ✅ | - | `df -h` |
| **Compaction** | ✅ | - | `nodetool compact` |
| **Drain** | ❌ | ❌ | **NON nécessaire** |

---

## ⚠️ Points d'Attention

### 1. Repair en Mode Standalone

En mode standalone (1 nœud), le repair peut échouer ou être ignoré. C'est normal, mais :
- ⚠️ Les tombstones ne sont pas propagés (pas d'autres nœuds)
- ✅ La compaction fonctionne quand même
- ✅ Les tombstones expirés seront purgés

### 2. Durée des Opérations

- **Repair** : Peut prendre plusieurs heures selon la taille des données
- **Compaction** : Peut prendre plusieurs heures selon la taille des données
- **Planifier** : Effectuer ces opérations en heures creuses si possible

### 3. Impact sur les Performances

- **Repair** : Consomme des ressources (CPU, I/O, réseau)
- **Compaction** : Consomme des ressources (CPU, I/O)
- **Recommandation** : Effectuer en heures creuses

### 4. Monitoring

Surveiller les opérations avec :
```bash
# Statut du repair
nodetool netstats

# Statut de la compaction
nodetool compactionstats

# Statistiques de la table
nodetool tablestats domirama2_poc operations_by_account
```

---

## 📚 Références

- [Apache Cassandra : Compaction Overview](https://cassandra.apache.org/doc/stable/cassandra/managing/operating/compaction/overview.html)
- [DataStax : When to Repair Nodes](https://docs.datastax.com/en/cassandra-oss/3.x/cassandra/operations/opsRepairNodesWhen.html)
- [Apache Cassandra : nodetool drain](https://cassandra.apache.org/doc/stable/cassandra/tools/nodetool/drain.html)

---

## ✅ Checklist Avant Compaction

- [ ] HCD démarré et accessible
- [ ] État du cluster vérifié (tous nœuds UN)
- [ ] `gc_grace_seconds` vérifié (>= 864000 recommandé)
- [ ] Repair effectué (⭐ recommandé)
- [ ] Espace disque vérifié (> 20% disponible)
- [ ] Compaction lancée
- [ ] Compaction surveillée (compactionstats)
- [ ] Résultats vérifiés (tablestats)

---

**✅ Documentation créée le 2025-11-26**


