# Analyse : État de l'art HBase chez Arkéa

**Date du document** : 24/11/2025  
**Document analysé** : Etat de l'art HBase chez Arkéa.pdf

---

## 📋 Résumé Exécutif

Ce document présente un état des lieux complet de l'utilisation d'HBase au sein d'Arkéa. L'objectif principal est d'identifier précisément toutes les utilisations spécifiques de ce moteur afin de qualifier un potentiel remplaçant dans le cadre des futures évolutions de la plateforme Big Data interne.

**Contexte** : HBase est un point critique pour la plateforme Big Data d'Arkéa, servant des usages opérationnels importants du groupe.

---

## 🏗️ Infrastructure HBase

### Configuration Actuelle

**Software** :
- HBase 1.1.2
- Hadoop HDP 2.6.4
- Stockage : HDFS (Hadoop Distributed File System)

**Hardware** :
- **Hors production** : 1 instance HBase mutualisée
- **Production** : 2 instances HBase sur un même cluster Hadoop

### Architecture des Nœuds

Les nœuds HBase sont des machines physiques du cluster Hadoop avec les rôles suivants :
- **DataNode HDFS** :
  - Localité des hfiles
  - Facteur de réplication x3
  - Rebalancing des hfiles en cas de panne
- **RegionServer** :
  - Service temps réel distribué
  - Lecture/écriture

### Add-ons Développés par Arkéa

1. **hbase-tools** :
   - Merge de régions (réduire le nombre de fichiers de région et compacter les données)
   - Utilisé notamment sur la BIC pour optimiser les tailles de fichiers de région

2. **com.arkea.commons.hbase-0.5.5.jar** :
   - Librairie utilitaire Java pour simplifier :
     - La gestion des connexions et DAO
     - Les FullScan Batch (redéfinition de l'input format : 2 mappers par region-server au lieu d'1 mapper par region-file)
     - Unload HDFS ORC
     - Les BulkLoad

---

## 📊 Projets Utilisant HBase

### 1. Domirama

**Objectif** : Restitution des opérations sur les comptes chèques des clients avec une capacité de recherche sur 10 ans d'historique.

**Tables** :
- `B997X04:domirama`
- `B997X04:domirama-budget` (obsolète)

**Key Design** :
- Une ligne par opération
- Clé composite : code SI + numéro de contrat + binaire (numéro d'opération + date pour ordre antichronologique)

**Format de stockage** :
- Données Cobol encodées en Base64
- Column qualifier par type de copy

**Opérations** :
- **Écriture** : Préparation en PIG, écriture via MapReduce avec API HBase en phase reduce
- **Lecture** : API avec SCAN pour créer index SOLR in-memory, puis MultiGet des clés

**Fonctionnalités HBase utilisées** :
- TTL pour purge automatique
- Pas d'utilisation de la temporalité des cellules

**Remarques importantes** :
- Réplica complet disponible sur Elasticsearch (13 mois pour transactionAPI)
- Projet de refonte TAILS à l'étude
- Les capacités de search full-text de DataStax pourraient être un plus

---

### 2. Catégorisation des Opérations

**Objectif** : Extension du projet Domirama pour enrichir les opérations d'un système de catégorisation automatique et personnalisable par les clients.

**Architecture** :
- Ajout d'une Column Family à la table `domirama` existante
- Partage du même design de clé

**Tables** :
- `B997X04:domirama` (Column Family `category`)
- `B997X04:domirama-meta-categories`

**Key Design** :
- Même structure que Domirama
- Plusieurs KeySpace dans la table `domirama-meta-categories` pour différents usages :
  - Acceptation d'affichage par le client
  - Opposition categ
  - Historique opposition
  - Feedbacks moteur/clients par libellé
  - Feedbacks moteur/clients par ICS
  - Règles catégorisation spécifiques client
  - Méthode de catégorisation sur libellé taggé salaires

**Format de stockage** :
- Données Thrift encodées en binaire
- Colonnes dynamiques calquées sur propriétés du POJO Thrift
- Permet filtres sur valeurs dans les Scan + optimisation avec BLOOMFILTER

**Opérations** :
- **Écriture** :
  - MapReduce en bulkLoad
  - API pour corrections client (PUT avec current_Timestamp)
- **Lecture** :
  - Temps réel : API avec SCAN + value filter
  - Batch : FullScan + STARTROW + STOPROW + TIMERANGE pour unload incrémentaux ORC

**Fonctionnalités HBase utilisées** :
- TTL pour purge automatique
- Temporalité des cellules (batch écrit sur même timestamp, client sur timestamp réel)
- INCREMENT (compteurs atomiques pour feedbacks)

---

### 3. Base d'Interaction Client (BIC)

**Objectif** : Collecter l'intégralité des interactions entre la banque et les clients sur tous les canaux (site web, agence, RDV, agenda, mail, SMS...) pour restituer au conseiller une timeline de 2 ans d'historique.

**Tables** :
- `B993O02:bi-client` (identique à `bi-prospect`)

**Key Design** :
- Une ligne par interaction client ⇔ banque
- Clé : code efs + numéro de client + date (yyyyMMdd) + cd_canal + idt_tech (garant unicité pour MAJ)

**Format de stockage** :
- Données JSON dans une colonne
- Colonnes dynamiques normalisées extraites du JSON
- Permet filtres sur valeurs dans les Scan + optimisation avec BLOOMFILTER

**Opérations** :
- **Écriture** :
  - Temps réel : embarquée dans consumer Kafka exécutés par Tomcat (bic-event)
  - Batch : MapReduce en bulkLoad
- **Lecture** :
  - Temps réel : API avec SCAN + value filter
  - Batch : FullScan + STARTROW + STOPROW + TIMERANGE pour unload incrémentaux ORC

**Fonctionnalités HBase utilisées** :
- TTL pour purge automatique

---

### 4. Environnement de Données Marketing (EDM)

**Objectif** : Environnement de données marketing améliorant la connaissance client par calcul massif quotidien d'indicateurs pour l'animation de la relation commerciale.

**Architecture** :
- Design identique à la BIC
- Utilise HBase de la même manière

**Rôle d'HBase** :
- Réceptacle pour tous les événements qui ne sont pas des interactions
- Accès aux informations issues du batch pour consolidation à la volée
- Repousser des événements métiers en réaction

**Opérations** :
- Complément batch par calcul événementiel temps réel

---

## 🔍 Fonctionnalités HBase Critiques Utilisées

### Fonctionnalités Principales

1. **TTL (Time To Live)** :
   - Utilisé dans tous les projets pour purge automatique
   - Valeurs variables selon les projets (1 jour à 10 ans)

2. **Temporalité des cellules (Versions)** :
   - Utilisé dans la catégorisation (batch vs client avec timestamps différents)
   - Versions multiples (2 à 50 selon les colonnes)

3. **BLOOMFILTER** :
   - Optimisation des lectures (ROWCOL, NONE selon les cas)
   - Réduction des I/O inutiles

4. **INCREMENT atomique** :
   - Utilisé dans domirama-meta-categories pour compteurs de feedbacks
   - Opérations atomiques d'incrément/décrément

5. **Colonnes dynamiques** :
   - Utilisées dans catégorisation et BIC
   - Permettent filtres sur valeurs dans les Scan

6. **BulkLoad** :
   - Utilisé pour chargements batch performants
   - Évite la surcharge de l'API temps réel

7. **SCAN avec filtres** :
   - STARTROW + STOPROW pour fenêtrage
   - TIMERANGE pour fenêtre glissante
   - Value filters pour filtrage côté serveur

8. **MultiGet** :
   - Utilisé dans Domirama après indexation SOLR

9. **Réplication** :
   - REPLICATION_SCOPE = '1' sur toutes les colonnes
   - Réplication vers autres clusters

---

## 📈 Patterns d'Utilisation Identifiés

### Patterns d'Écriture

1. **Batch** :
   - MapReduce avec bulkLoad (Domirama, Catégorisation, BIC, EDM)
   - Préparation des données en PIG (Domirama)

2. **Temps réel** :
   - API directe (PUT) depuis applications
   - Consumer Kafka → HBase (BIC, EDM)

### Patterns de Lecture

1. **Temps réel** :
   - SCAN avec filtres (value filter, STARTROW, STOPROW)
   - GET/MultiGet après indexation (Domirama)

2. **Batch** :
   - FullScan pour unload incrémentaux ORC
   - Fenêtre glissante avec TIMERANGE

### Patterns de Design

1. **Clé composite** :
   - Tous les projets utilisent des clés composites
   - Ordre antichronologique pour historique

2. **Colonnes dynamiques** :
   - Utilisées pour flexibilité et filtrage
   - Extraction de champs JSON/Thrift en colonnes séparées

3. **Multi-usage dans une table** :
   - KeySpace différents dans domirama-meta-categories
   - Évite création de multiples petites tables

---

## ⚠️ Points d'Attention pour Migration

### Dépendances Techniques

1. **HDFS** : Dépendance forte au stockage HDFS
2. **Hadoop MapReduce** : Utilisé pour tous les chargements batch
3. **SOLR** : Indexation in-memory pour Domirama
4. **Elasticsearch** : Réplica pour transactionAPI (13 mois)
5. **Kafka** : Intégration pour BIC et EDM

### Fonctionnalités Critiques à Reproduire

1. **TTL automatique** : Purge automatique des données
2. **Versions multiples** : Historique des modifications
3. **BulkLoad** : Chargements batch performants
4. **SCAN avec filtres avancés** : Filtrage côté serveur
5. **INCREMENT atomique** : Compteurs atomiques
6. **Colonnes dynamiques** : Flexibilité du schéma
7. **Réplication** : Synchronisation multi-cluster

### Projets en Évolution

1. **Domirama** : Projet de refonte TAILS à l'étude
2. **domirama-budget** : Table obsolète
3. **DataStax** : Capacités de search full-text mentionnées comme potentiel plus

---

## 🎯 Recommandations pour Évaluation d'un Remplaçant

### Critères d'Évaluation

1. **Compatibilité fonctionnelle** :
   - Support TTL
   - Versions multiples
   - Opérations atomiques (INCREMENT)
   - Filtres avancés dans les scans

2. **Performance** :
   - BulkLoad pour chargements batch
   - SCAN performants avec filtres
   - Support de grandes quantités de données (10 ans d'historique)

3. **Intégration** :
   - Compatibilité avec écosystème Hadoop
   - Support Kafka
   - Intégration avec outils d'indexation (SOLR, Elasticsearch)

4. **Évolutivité** :
   - Support de la réplication
   - Scalabilité horizontale
   - Gestion des régions/partitions

5. **Opérationnel** :
   - Outils de monitoring
   - Backup/restore
   - Gestion des compactions

### Points à Vérifier Spécifiquement

- Support des colonnes dynamiques ou équivalent
- Performance des SCAN avec value filters
- Capacités de recherche full-text (mention DataStax)
- Compatibilité avec format ORC pour unload
- Support des timestamps personnalisés pour temporalité

---

## 📝 Conclusion

HBase est utilisé de manière intensive dans 4 projets critiques d'Arkéa avec des patterns d'utilisation variés :
- Stockage d'historique long terme (10 ans pour Domirama)
- Interactions temps réel (BIC, EDM)
- Catégorisation avec versions multiples
- Calculs batch quotidiens (EDM)

La migration vers un remplaçant nécessitera une attention particulière sur :
- Les fonctionnalités avancées (TTL, versions, INCREMENT)
- Les performances de scan avec filtres
- L'intégration avec l'écosystème existant
- La compatibilité avec les patterns batch/temps réel

Le document mentionne DataStax comme potentiel candidat, notamment pour ses capacités de search full-text.

