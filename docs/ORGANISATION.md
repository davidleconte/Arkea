# 📁 Organisation du Projet POC

**Date** : 2025-11-25  
**Structure** : Documentation et scripts organisés

---

## 📚 Documentation

Tous les fichiers `.md` sont stockés dans le répertoire `docs/` et triés du **plus récent au plus ancien**.

### Accès à la documentation
```bash
cd docs/
ls -lt *.md  # Liste triée par date (plus récent en premier)
```

### Fichiers dans `docs/`
- **README.md** - Index de la documentation
- **ORDRE_EXECUTION_SCRIPTS.md** - Guide d'ordre d'exécution des scripts
- **SCRIPTS_A_JOUR.md** - Documentation complète des scripts
- **RESULTATS_TEST_KAFKA_HCD.md** - Résultats des tests
- **KAFKA_HCD_STREAMING_READY.md** - Guide streaming
- **GUIDE_INSTALLATION_SPARK_KAFKA.md** - Guide installation Spark/Kafka
- **ARCHITECTURE_POC_COMPLETE.md** - Architecture du POC
- **GUIDE_INSTALLATION_HCD_MAC.md** - Guide installation HCD
- **ANALYSE_ETAT_ART_HBASE.md** - Analyse de l'existant
- **DOCUMENTATION_FINALE.md** - Index de la documentation (ancien)

---

## 🔢 Scripts Numérotés

Tous les scripts `.sh` sont numérotés selon l'ordre d'exécution logique.

### Scripts d'Installation et Configuration (01-06)

| Numéro | Script | Description |
|--------|--------|-------------|
| **01** | `01_install_hcd.sh` | Installe HCD 1.2.3 |
| **02** | `02_install_spark_kafka.sh` | Installe Spark 3.5.1, Kafka et connector |
| **03** | `03_start_hcd.sh` | Démarre HCD |
| **04** | `04_start_kafka.sh` | Démarre Kafka |
| **05** | `05_setup_kafka_hcd_streaming.sh` | Configure le streaming |
| **06** | `06_test_kafka_hcd_streaming.sh` | Test du pipeline |

### Scripts Utilitaires (70-90)

| Numéro | Script | Description |
|--------|--------|-------------|
| **70** | `70_kafka-helper.sh` | Helper pour Kafka |
| **80** | `80_verify_all.sh` | Vérifie tous les composants |
| **90** | `90_list_scripts.sh` | Liste tous les scripts |

---

## 🚀 Workflow Rapide

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
cat README.md
```

---

**Structure organisée et facile à utiliser !** ✅

