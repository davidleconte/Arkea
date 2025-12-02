# 📚 Documentation du POC - Migration HBase → HCD

**Date de mise à jour** : 2025-12-02  
**Organisation** : Fichiers triés du plus récent au plus ancien  
**Statut** : ✅ Documentation à jour et portable cross-platform

---

## 🌍 Guides d'Installation Cross-Platform

### Installation par OS

- **GUIDE_INSTALLATION_HCD.md** ⭐ - Guide HCD (macOS, Linux, Windows WSL2)
- **GUIDE_INSTALLATION_LINUX.md** ⭐ - Guide Linux complet
- **GUIDE_INSTALLATION_WINDOWS.md** ⭐ - Guide Windows (WSL2)
- **GUIDE_INSTALLATION_SPARK_KAFKA.md** - Guide Spark/Kafka (cross-platform)
- **DEPLOYMENT.md** - Guide de déploiement complet

---

## 📋 Liste des Documents (du plus récent au plus ancien)

### 🔍 Audits et Analyses Récentes

1. **AUDIT_COMPLET_PROJET_ARKEA_2025_V2.md** ⭐ - Audit complet V2 du projet ARKEA (corrections et enrichissements)
2. **AUDIT_COMPLET_RACINE_ARKEA_2025.md** ⭐ - Audit complet de la racine ARKEA (corrections et enrichissements)
3. **EXPLICATION_NETTOYAGE_STRUCTURE.md** ⭐ - Explication détaillée du nettoyage de structure
4. **AUDIT_DOCUMENTATION_2025.md** ⭐ - Audit complet de la documentation
5. **AUDIT_PORTABILITE_CROSS_PLATFORM_2025.md** ⭐ - Audit de portabilité cross-platform
6. **REFERENCE_HCD_DOCUMENTATION.md** - Référence complète HCD 1.2
7. **ANALYSE_PROPOSITION_IBM_MECE.md** - Analyse proposition MECE IBM
8. **ANALYSE_INPUTS_CLIENTS_COMPLETE.md** - Analyse détaillée inputs clients

### 📚 Guides et Documentation

6. **GUIDE_CHOIX_POC.md** ⭐ - Guide pour choisir entre BIC, domirama2, domiramaCatOps **NOUVEAU**
7. **GUIDE_COMPARAISON_POCS.md** ⭐ - Comparaison technique détaillée des POCs **NOUVEAU**
8. **GUIDE_CONTRIBUTION_POCS.md** ⭐ - Standards pour contribuer aux POCs **NOUVEAU**
9. **GUIDE_MAINTENANCE.md** ⭐ - Processus de maintenance et archivage **NOUVEAU**
10. **INDEX.md** - Index complet de la documentation
11. **STRUCTURE_PROJET.md** - Structure complète du projet
12. **ORGANISATION_FINALE.md** - Organisation finale du projet
13. **ORDRE_EXECUTION_SCRIPTS.md** - Guide ordre d'exécution scripts
14. **SCRIPTS_A_JOUR.md** - Documentation complète des scripts
11. **RESULTATS_TEST_KAFKA_HCD.md** - Résultats tests Kafka → HCD
12. **KAFKA_HCD_STREAMING_READY.md** - Guide streaming Kafka → HCD
13. **ARCHITECTURE_POC_COMPLETE.md** - Architecture complète du POC
14. **ANALYSE_ETAT_ART_HBASE.md** - Analyse "État de l'art HBase chez Arkéa"

---

## 📖 Description des Documents

### Installation

- **GUIDE_INSTALLATION_HCD.md** ⭐ : Guide cross-platform pour installer HCD 1.2.3 (macOS, Linux, Windows WSL2)
- **GUIDE_INSTALLATION_LINUX.md** ⭐ : Guide complet d'installation Linux
- **GUIDE_INSTALLATION_WINDOWS.md** ⭐ : Guide d'installation Windows (WSL2)
- **GUIDE_INSTALLATION_SPARK_KAFKA.md** : Guide cross-platform pour installer Spark 3.5.1, Kafka 4.1.1 et spark-cassandra-connector
- **DEPLOYMENT.md** : Guide de déploiement complet cross-platform

### Architecture et Analyse

- **REFERENCE_HCD_DOCUMENTATION.md** : Référence complète de la documentation officielle HCD 1.2
  - Introduction à HCD
  - Storage-Attached Indexing (SAI)
  - CQL Analyzers (Full-Text)
  - Vector Search
  - Data API
  - CQL Reference
  - Data Modeling
  - Points clés pour le POC

- **ANALYSE_PROPOSITION_IBM_MECE.md** : Analyse de la proposition MECE IBM pour la migration
  - 4 axes : Technologique, Données, Applicatif, Organisationnel
  - 3 refontes détaillées : Domirama, meta-categories, bi-client
  - Guide POC complet : POC1 (CSV) et POC2 (SequenceFile)
  - Points clés, avantages, points d'attention

- **ANALYSE_INPUTS_CLIENTS_COMPLETE.md** : Analyse détaillée de tous les inputs clients
  - Document PDF analysé
  - Archive ZIP avec code source des projets
  - Inventaire complet des composants

- **ANALYSE_ETAT_ART_HBASE.md** : Analyse détaillée de l'existant HBase chez Arkéa
  - Projets utilisant HBase (Domirama, BIC, EDM)
  - Fonctionnalités HBase utilisées
  - Patterns d'usage
  - Points d'attention pour la migration

- **ARCHITECTURE_POC_COMPLETE.md** : Architecture complète du POC
  - Composants (HCD, Spark, Kafka)
  - Flux de données
  - Schémas de données
  - Outils et commandes

### Configuration et Utilisation

- **KAFKA_HCD_STREAMING_READY.md** : Guide pour utiliser le streaming Kafka → HCD
  - Configuration terminée
  - Comment utiliser le pipeline
  - Commandes de vérification

- **SCRIPTS_A_JOUR.md** : Documentation de tous les scripts
  - Liste complète des scripts
  - Description de chaque script
  - Modifications récentes

### Tests et Résultats

- **RESULTATS_TEST_KAFKA_HCD.md** : Résultats du test complet
  - Messages produits dans Kafka
  - Données dans HCD
  - Validations
  - Conclusion

---

## 🎯 Par où commencer ?

### Pour comprendre le contexte

1. Lire **ANALYSE_ETAT_ART_HBASE.md** pour comprendre l'existant
2. Lire **REFERENCE_HCD_DOCUMENTATION.md** pour comprendre HCD 1.2
3. Lire **ANALYSE_PROPOSITION_IBM_MECE.md** pour comprendre la proposition IBM
4. Lire **ARCHITECTURE_POC_COMPLETE.md** pour comprendre l'architecture

### Pour installer

**Choisir selon votre OS** :

1. **GUIDE_INSTALLATION_HCD.md** - Installer HCD (cross-platform)
2. **GUIDE_INSTALLATION_LINUX.md** - Guide Linux complet (si Linux)
3. **GUIDE_INSTALLATION_WINDOWS.md** - Guide Windows WSL2 (si Windows)
4. **GUIDE_INSTALLATION_SPARK_KAFKA.md** - Installer Spark/Kafka (cross-platform)
5. **DEPLOYMENT.md** - Guide de déploiement complet

### Pour utiliser

1. Consulter **KAFKA_HCD_STREAMING_READY.md** pour le streaming
2. Consulter **SCRIPTS_A_JOUR.md** pour tous les scripts disponibles

### Pour vérifier

1. Consulter **RESULTATS_TEST_KAFKA_HCD.md** pour les résultats des tests

---

**Note** : Les fichiers sont triés par date de modification (du plus récent au plus ancien).
