# 📁 Structure Complète du Projet POC

**Date** : 2025-11-25  
**Organisation** : Projet structuré avec répertoires dédiés

---

## 📂 Structure

```
Arkea/
├── inputs-clients/        # Documents et fichiers fournis par le client
│   ├── Etat de l'art HBase chez Arkéa.pdf
│   ├── groupe_*.zip
│   └── README.md
│
├── inputs-ibm/            # Documents et fichiers fournis par IBM
│   └── README.md
│
├── software/              # Archives des logiciels (.tar.gz, .tgz)
│   ├── hcd-1.2.3-bin.tar.gz
│   ├── spark-3.5.1-bin-hadoop3.tgz
│   └── README.md
│
├── binaire/               # Logiciels extraits et installés
│   ├── hcd-1.2.3/         # HCD extrait
│   ├── spark-3.5.1/       # Spark extrait
│   ├── spark-jars/        # JARs (spark-cassandra-connector)
│   ├── kafka/             # Lien symbolique vers /opt/homebrew/opt/kafka
│   └── README.md
│
├── docs/                  # Documentation (.md)
│   ├── README.md
│   ├── ORDRE_EXECUTION_SCRIPTS.md
│   └── ... (10 fichiers)
│
├── [0-9]*.sh             # Scripts numérotés
│   ├── 01_install_hcd.sh
│   ├── 02_install_spark_kafka.sh
│   └── ... (9 scripts)
│
└── autres fichiers...     # Configuration, schémas, etc.
```

---

## 📦 Répertoires

### `inputs-clients/` - Inputs Clients
- **Contenu** : Documents et fichiers fournis par le client
- **Usage** : Référence et analyse
- **Fichiers** :
  - Documents PDF d'analyse
  - Archives ZIP de données/exemples

### `inputs-ibm/` - Inputs IBM
- **Contenu** : Documents et fichiers fournis par IBM
- **Usage** : Référence et analyse
- **Fichiers** : À compléter

### `software/` - Archives
- **Contenu** : Fichiers d'archive téléchargés (.tar.gz, .tgz)
- **Usage** : Conservation des archives originales pour réinstallation
- **Taille totale** : ~469 MB

### `binaire/` - Logiciels Installés
- **Contenu** : Logiciels extraits et prêts à l'emploi
- **Usage** : Exécution des logiciels
- **Composants** :
  - HCD 1.2.3
  - Spark 3.5.1
  - spark-cassandra-connector 3.5.0
  - Kafka (lien symbolique)

### `docs/` - Documentation
- **Contenu** : Tous les fichiers .md
- **Organisation** : Triés du plus récent au plus ancien
- **Total** : 10 fichiers

---

## 🔄 Flux d'Installation

```
software/*.tar.gz
    ↓ (extraction)
binaire/*/
    ↓ (utilisation)
Scripts numérotés
```

---

**Structure organisée et claire !** ✅
