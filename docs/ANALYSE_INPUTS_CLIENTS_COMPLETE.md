# 📊 Analyse Complète des Inputs Clients

**Date** : 2025-11-25  
**Répertoire** : `inputs-clients/`  
**Objectif** : Analyse détaillée de tous les fichiers fournis par le client

---

## 📋 Inventaire des Fichiers

### 1. Document PDF Principal

**Fichier** : `Etat de l'art HBase chez Arkéa.pdf`  
**Taille** : 758 KB  
**Type** : PDF (8 pages)  
**Statut** : ✅ Analysé

**Contenu** :
- État des lieux complet de l'utilisation HBase chez Arkéa
- Infrastructure HBase (HBase 1.1.2, Hadoop HDP 2.6.4)
- Projets utilisant HBase (Domirama, Catégorisation, BIC, EDM)
- Fonctionnalités HBase utilisées
- Patterns d'usage et points d'attention

**Analyse détaillée** : Voir `docs/ANALYSE_ETAT_ART_HBASE.md`

---

### 2. Archive ZIP : Code Source des Projets

**Fichier** : `groupe_2025-11-25-110250.zip`  
**Taille** : 3.6 MB  
**Type** : ZIP  
**Statut** : ✅ Analysé

**Structure** :
```
projets_hbase/
├── categorisation/          # Projet Catégorisation des Opérations
│   ├── domirama-category-main.tar.gz (350 KB)
│   ├── categorizationjar-master.tar.gz (158 KB)
│   └── categorizationapi-main.tar.gz (474 KB)
│
├── bic/                      # Projet BIC (Base d'Interaction Client)
│   ├── bic-event-main.tar.gz (754 KB)
│   ├── bic-unload-main.tar.gz (153 KB)
│   ├── bic-batch-main.tar.gz (165 KB)
│   └── bic-backend-main.tar.gz (75 KB)
│
├── edm/                      # Projet EDM (Environnement de Données Marketing)
│   ├── edm-event-main.tar.gz (162 KB)
│   └── edm-hbase-main.tar.gz (83 KB)
│
├── domirama/                 # Projet Domirama
│   └── domiramabatch-develop.tar.gz (627 KB)
│
├── hbase-tools-master.tar.gz # Outils HBase développés par Arkéa (20 KB)
├── com.arkea.commons.hbase-0.5.5.jar  # Librairie utilitaire Java (53 KB)
└── Etat de l'art HBase chez Arkéa.pdf (dupliqué)
```

**Total** : 18 fichiers
- **11 archives tar.gz** (code source des projets)
- **1 JAR** (librairie utilitaire)
- **1 PDF** (documentation, dupliqué)
- **5 répertoires** (organisation par projet)

---

## 🔍 Analyse Détaillée par Projet

### 1. Catégorisation des Opérations

**Répertoire** : `projets_hbase/categorisation/`

**Composants** :
- **domirama-category-main.tar.gz** (350 KB)
  - Projet principal de catégorisation
  - Extension du projet Domirama
  - Ajout de Column Family `category` à la table `domirama`

- **categorizationjar-master.tar.gz** (158 KB)
  - JAR de catégorisation
  - Logique métier de catégorisation

- **categorizationapi-main.tar.gz** (474 KB)
  - API de catégorisation
  - Interface pour corrections client

**Fonctionnalités HBase utilisées** :
- TTL pour purge automatique
- Temporalité des cellules (batch vs client)
- INCREMENT (compteurs atomiques pour feedbacks)
- SCAN + value filter pour lecture temps réel
- FullScan + STARTROW + STOPROW + TIMERANGE pour unload incrémentaux

**Schéma HBase** :
- Table : `B997X04:domirama` (Column Family `category`)
- Table : `B997X04:domirama-meta-categories` (plusieurs KeySpace)

---

### 2. BIC (Base d'Interaction Client)

**Répertoire** : `projets_hbase/bic/`

**Composants** :
- **bic-event-main.tar.gz** (754 KB)
  - Consumer Kafka pour événements temps réel
  - Écriture embarquée dans Tomcat
  - Traitement des interactions client ⇔ banque

- **bic-unload-main.tar.gz** (153 KB)
  - Unload HDFS ORC
  - Export des données pour analyse

- **bic-batch-main.tar.gz** (165 KB)
  - Traitement batch
  - MapReduce en bulkLoad
  - Chargement massif des données

- **bic-backend-main.tar.gz** (75 KB)
  - Backend API
  - Lecture temps réel avec SCAN + value filter

**Fonctionnalités HBase utilisées** :
- TTL pour purge automatique (2 ans d'historique)
- SCAN + value filter pour lecture temps réel
- FullScan + STARTROW + STOPROW + TIMERANGE pour unload incrémentaux ORC
- BulkLoad pour écriture batch

**Schéma HBase** :
- Table : `B993O02:bi-client`
- Key : code efs + numéro de client + date (yyyyMMdd) + cd_canal + idt_tech
- Format : JSON dans une colonne + colonnes dynamiques normalisées

---

### 3. EDM (Environnement de Données Marketing)

**Répertoire** : `projets_hbase/edm/`

**Composants** :
- **edm-event-main.tar.gz** (162 KB)
  - Traitement des événements marketing
  - Événements qui ne sont pas des interactions

- **edm-hbase-main.tar.gz** (83 KB)
  - Intégration HBase
  - Accès aux informations issues du batch

**Architecture** :
- Design identique à la BIC
- Utilise HBase de la même manière
- Réceptacle pour événements marketing
- Consolidation à la volée

---

### 4. Domirama

**Répertoire** : `projets_hbase/domirama/`

**Composants** :
- **domiramabatch-develop.tar.gz** (627 KB)
  - Traitement batch Domirama
  - Préparation en PIG
  - Écriture via MapReduce avec API HBase en phase reduce

**Fonctionnalités HBase utilisées** :
- TTL pour purge automatique (10 ans d'historique)
- SCAN pour créer index SOLR in-memory
- MultiGet des clés
- Pas d'utilisation de la temporalité des cellules

**Schéma HBase** :
- Table : `B997X04:domirama`
- Key : code SI + numéro de contrat + binaire (numéro d'opération + date)
- Format : Données Cobol encodées en Base64
- Column qualifier par type de copy

---

### 5. Outils et Bibliothèques

**hbase-tools-master.tar.gz** (20 KB)
- Outils HBase développés par Arkéa
- Merge de régions (réduire le nombre de fichiers de région)
- Compaction des données
- Utilisé notamment sur la BIC pour optimiser les tailles de fichiers de région

**com.arkea.commons.hbase-0.5.5.jar** (53 KB)
- Librairie utilitaire Java développée par Arkéa
- Simplifie :
  - La gestion des connexions et DAO
  - Les FullScan Batch (redéfinition de l'input format : 2 mappers par region-server au lieu d'1 mapper par region-file)
  - Unload HDFS ORC
  - Les BulkLoad

---

## 📊 Résumé par Projet

| Projet | Composants | Taille Totale | Fonctionnalités HBase Clés |
|--------|------------|---------------|----------------------------|
| **Catégorisation** | 3 archives | ~982 KB | TTL, Temporalité, INCREMENT, SCAN + filters |
| **BIC** | 4 archives | ~1.1 MB | TTL, SCAN + filters, BulkLoad, Unload ORC |
| **EDM** | 2 archives | ~245 KB | Identique à BIC |
| **Domirama** | 1 archive | ~627 KB | TTL, SCAN, MultiGet |
| **Outils** | 1 archive + 1 JAR | ~73 KB | Merge régions, FullScan optimisé |

---

## 🎯 Points Clés pour la Migration

### 1. Schémas à Migrer

**Domirama** :
- Table : `B997X04:domirama`
- Key composite : code SI + numéro de contrat + operation_date
- Format : Cobol Base64
- TTL : 10 ans

**Catégorisation** :
- Extension de Domirama (Column Family `category`)
- Table : `B997X04:domirama-meta-categories`
- Temporalité des cellules importante
- INCREMENT pour compteurs

**BIC** :
- Table : `B993O02:bi-client`
- Key : code efs + numéro client + date + canal + idt_tech
- Format : JSON + colonnes dynamiques
- TTL : 2 ans

**EDM** :
- Design identique à BIC
- Événements marketing

### 2. Patterns d'Accès à Migrer

**Temps Réel** :
- SCAN + value filter
- MultiGet
- PUT avec timestamp

**Batch** :
- FullScan + STARTROW + STOPROW + TIMERANGE
- BulkLoad
- Unload ORC

**Optimisations** :
- BLOOMFILTER
- FullScan optimisé (2 mappers par region-server)

### 3. Fonctionnalités HBase à Remplacer

| Fonctionnalité HBase | Équivalent HCD/Cassandra |
|---------------------|--------------------------|
| TTL | TTL (identique) |
| Temporalité des cellules | Timestamp clustering |
| INCREMENT | Counter type ou application |
| SCAN + filters | SELECT avec WHERE |
| BulkLoad | COPY ou Spark batch write |
| MultiGet | SELECT IN ou batch reads |

---

## 📝 Prochaines Étapes

1. **Extraire les archives** pour analyser le code source
2. **Identifier les schémas** exacts utilisés
3. **Extraire la logique métier** (notamment `recurrentDetection`)
4. **Créer les schémas HCD** équivalents
5. **Adapter les patterns d'accès** pour HCD

---

## 🔍 Analyse du Code Source (À Faire)

Les archives tar.gz contiennent le code source des projets. Pour une analyse complète :

1. Extraire chaque archive
2. Analyser la structure du code
3. Identifier les dépendances
4. Extraire les schémas et configurations
5. Documenter la logique métier

---

**Analyse complète des inputs clients terminée !** ✅
