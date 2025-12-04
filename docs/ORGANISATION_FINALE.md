# 📁 Organisation Finale du Projet POC

**Date** : 2025-11-25  
**Structure** : Projet organisé avec répertoires dédiés

---

## 📂 Structure du Projet

```
Arkea/
├── binaire/              # Tous les logiciels installés
│   ├── hcd-1.2.3/        # HCD (Hyper-Converged Database)
│   ├── spark-3.5.1/      # Apache Spark
│   ├── spark-jars/       # JARs (spark-cassandra-connector)
│   ├── kafka/            # Lien symbolique vers /opt/homebrew/opt/kafka
│   └── README.md         # Documentation des logiciels
│
├── docs/                 # Tous les fichiers de documentation (.md)
│   ├── README.md         # Index de la documentation
│   ├── ORDRE_EXECUTION_SCRIPTS.md
│   ├── SCRIPTS_A_JOUR.md
│   ├── RESULTATS_TEST_KAFKA_HCD.md
│   ├── KAFKA_HCD_STREAMING_READY.md
│   ├── GUIDE_INSTALLATION_SPARK_KAFKA.md
│   ├── ARCHITECTURE_POC_COMPLETE.md
│   ├── GUIDE_INSTALLATION_HCD_MAC.md
│   ├── ANALYSE_ETAT_ART_HBASE.md
│   └── DOCUMENTATION_FINALE.md
│
├── [0-9]*.sh            # Scripts numérotés (01-06, 70-90)
│   ├── 01_install_hcd.sh
│   ├── 02_install_spark_kafka.sh
│   ├── 03_start_hcd.sh
│   ├── 04_start_kafka.sh
│   ├── 05_setup_kafka_hcd_streaming.sh
│   ├── 06_test_kafka_hcd_streaming.sh
│   ├── 70_kafka-helper.sh
│   ├── 80_verify_all.sh
│   └── 90_list_scripts.sh
│
└── autres fichiers...   # Fichiers de configuration, schémas, etc.
```

---

## 📦 Répertoire `binaire/`

Contient tous les logiciels installés pour le POC :

| Logiciel | Chemin | Type |
|----------|--------|------|
| **HCD** | `binaire/hcd-1.2.3/` | Installation locale (tarball) |
| **Spark** | `binaire/spark-3.5.1/` | Installation locale (tarball) |
| **Kafka** | `binaire/kafka/` → `/opt/homebrew/opt/kafka` | Lien symbolique (Homebrew) |
| **spark-jars** | `binaire/spark-jars/` | JARs téléchargés |

### Chemins Absolus

```bash
HCD_HOME="${ARKEA_HOME}/binaire/hcd-1.2.3"
SPARK_HOME="${ARKEA_HOME}/binaire/spark-3.5.1"
KAFKA_HOME="/opt/homebrew/opt/kafka"
```

---

## 📚 Répertoire `docs/`

Tous les fichiers `.md` sont organisés dans `docs/`, triés du **plus récent au plus ancien**.

### Liste (du plus récent au plus ancien)

1. **README.md** - Index de la documentation
2. **ORDRE_EXECUTION_SCRIPTS.md** - Guide d'ordre d'exécution
3. **DOCUMENTATION_FINALE.md** - Index de la documentation
4. **SCRIPTS_A_JOUR.md** - Documentation des scripts
5. **RESULTATS_TEST_KAFKA_HCD.md** - Résultats des tests
6. **KAFKA_HCD_STREAMING_READY.md** - Guide streaming
7. **GUIDE_INSTALLATION_SPARK_KAFKA.md** - Guide installation Spark/Kafka
8. **ARCHITECTURE_POC_COMPLETE.md** - Architecture du POC
9. **GUIDE_INSTALLATION_HCD_MAC.md** - Guide installation HCD
10. **ANALYSE_ETAT_ART_HBASE.md** - Analyse de l'existant

---

## 🔢 Scripts Numérotés

Tous les scripts `.sh` sont numérotés selon l'ordre d'exécution :

### Installation et Configuration (01-06)

- `01_install_hcd.sh` - Installe HCD
- `02_install_spark_kafka.sh` - Installe Spark et Kafka
- `03_start_hcd.sh` - Démarre HCD
- `04_start_kafka.sh` - Démarre Kafka
- `05_setup_kafka_hcd_streaming.sh` - Configure le streaming
- `06_test_kafka_hcd_streaming.sh` - Test du pipeline

### Utilitaires (70-90)

- `70_kafka-helper.sh` - Helper pour Kafka
- `80_verify_all.sh` - Vérifie tous les composants
- `90_list_scripts.sh` - Liste tous les scripts

---

## ✅ Mises à Jour Effectuées

### Scripts Mis à Jour

Tous les scripts ont été mis à jour pour pointer vers `binaire/` :

- ✅ `01_install_hcd.sh` - Installe dans `binaire/hcd-1.2.3/`
- ✅ `02_install_spark_kafka.sh` - Installe dans `binaire/spark-3.5.1/` et `binaire/spark-jars/`
- ✅ `03_start_hcd.sh` - Utilise `binaire/hcd-1.2.3/`
- ✅ `05_setup_kafka_hcd_streaming.sh` - Utilise `binaire/hcd-1.2.3/`
- ✅ `06_test_kafka_hcd_streaming.sh` - Utilise `binaire/`
- ✅ `80_verify_all.sh` - Vérifie `binaire/`

---

## 🚀 Utilisation

### Installation Complète

```bash
./scripts/setup/01_install_hcd.sh
./scripts/setup/02_install_spark_kafka.sh
./scripts/setup/03_start_hcd.sh background
./scripts/setup/04_start_kafka.sh background
./scripts/setup/05_setup_kafka_hcd_streaming.sh
./scripts/setup/06_test_kafka_hcd_streaming.sh
```

### Vérification

```bash
./scripts/utils/80_verify_all.sh
```

### Documentation

```bash
cd docs/
ls -lt *.md  # Trié du plus récent au plus ancien
cat README.md
```

---

## 📝 Notes

- **Tous les logiciels** sont maintenant centralisés dans `binaire/`
- **Tous les scripts** pointent vers les nouveaux chemins
- **Tous les fichiers .md** sont organisés dans `docs/`
- **Tous les scripts** sont numérotés pour faciliter l'utilisation

---

**Projet parfaitement organisé !** ✅
