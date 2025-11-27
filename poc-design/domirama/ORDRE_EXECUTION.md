# 📋 Ordre d'Exécution des Scripts - POC Domirama

**Date** : 2025-11-25  
**Objectif** : Guide d'exécution séquentielle des scripts du POC Domirama

---

## 🔢 Scripts par Ordre d'Exécution

### 07_setup_domirama_poc.sh

**Objectif** : Configuration du schéma HCD pour Domirama

**Actions** :
- Crée le keyspace `domirama_poc`
- Crée la table `operations_by_account`
- Crée les index SAI (full-text, catégorie, montant)
- Vérifie la configuration

**Prérequis** :
- HCD installé (`./01_install_hcd.sh`)
- HCD démarré (`./03_start_hcd.sh`)

**Exécution** :
```bash
cd /Users/david.leconte/Documents/Arkea
./poc-design/domirama/07_setup_domirama_poc.sh
```

---

### 08_load_domirama_data.sh

**Objectif** : Chargement des données CSV dans HCD

**Actions** :
- Lit le fichier CSV `data/operations_sample.csv`
- Transforme les données via Spark
- Écrit dans la table `operations_by_account`
- Vérifie le nombre d'opérations chargées

**Prérequis** :
- Script 07 exécuté avec succès
- Spark installé (`./02_install_spark_kafka.sh`)
- HCD démarré

**Exécution** :
```bash
cd /Users/david.leconte/Documents/Arkea
./poc-design/domirama/08_load_domirama_data.sh
```

---

### 09_test_domirama_search.sh

**Objectif** : Tests de recherche full-text avec SAI

**Actions** :
- Exécute les tests de recherche CQL
- Teste la recherche par libellé (opérateur `:`)
- Teste les filtres combinés
- Valide le remplacement de Solr par SAI

**Prérequis** :
- Script 07 exécuté (schéma créé)
- Script 08 exécuté (données chargées)
- HCD démarré

**Exécution** :
```bash
cd /Users/david.leconte/Documents/Arkea
./poc-design/domirama/09_test_domirama_search.sh
```

---

## 📊 Workflow Complet

```
1. Installation (racine du projet)
   ├── ./01_install_hcd.sh
   ├── ./02_install_spark_kafka.sh
   └── ./03_start_hcd.sh

2. Configuration POC Domirama
   ├── ./poc-design/domirama/07_setup_domirama_poc.sh
   ├── ./poc-design/domirama/08_load_domirama_data.sh
   └── ./poc-design/domirama/09_test_domirama_search.sh
```

---

## ✅ Vérifications

### Après Script 07

```bash
cd /Users/david.leconte/Documents/Arkea/binaire/hcd-1.2.3
jenv local 11
eval "$(jenv init -)"
./bin/cqlsh localhost 9042 -e "DESCRIBE KEYSPACE domirama_poc;"
```

### Après Script 08

```bash
cd /Users/david.leconte/Documents/Arkea/binaire/hcd-1.2.3
jenv local 11
eval "$(jenv init -)"
./bin/cqlsh localhost 9042 -e "USE domirama_poc; SELECT COUNT(*) FROM operations_by_account;"
```

### Après Script 09

Les résultats des tests sont affichés dans la console.

---

## 🔗 Fichiers de Support

- **`create_domirama_schema.cql`** : Utilisé par script 07
- **`domirama_loader_csv.scala`** : Utilisé par script 08
- **`domirama_search_test.cql`** : Utilisé par script 09
- **`data/operations_sample.csv`** : Données de test

---

**Ordre d'exécution documenté !** ✅



