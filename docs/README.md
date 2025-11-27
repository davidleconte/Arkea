# 📚 Documentation du POC - Migration HBase → HCD

**Date de création** : 2025-11-25  
**Organisation** : Fichiers triés du plus récent au plus ancien

---

## 📋 Liste des Documents (du plus récent au plus ancien)

1. **REFERENCE_HCD_DOCUMENTATION.md** - Référence complète de la documentation officielle IBM/DataStax HCD 1.2 (nouveau)
2. **ANALYSE_PROPOSITION_IBM_MECE.md** - Analyse de la proposition MECE IBM pour la migration HBase → HCD
2. **ANALYSE_INPUTS_CLIENTS_COMPLETE.md** - Analyse détaillée de tous les inputs clients
3. **INDEX.md** - Index complet de la documentation
4. **STRUCTURE_PROJET.md** - Structure complète du projet (la plus récente et complète)
5. **ORGANISATION_FINALE.md** - Organisation finale du projet
6. **ORGANISATION.md** - Organisation du projet
7. **ORDRE_EXECUTION_SCRIPTS.md** - Guide d'ordre d'exécution des scripts
8. **SCRIPTS_A_JOUR.md** - Documentation complète de tous les scripts disponibles
9. **RESULTATS_TEST_KAFKA_HCD.md** - Résultats détaillés du test complet du pipeline Kafka → HCD
10. **KAFKA_HCD_STREAMING_READY.md** - Guide complet pour utiliser le streaming Kafka → HCD
11. **GUIDE_INSTALLATION_SPARK_KAFKA.md** - Guide détaillé d'installation de Spark, Kafka et spark-cassandra-connector
12. **ARCHITECTURE_POC_COMPLETE.md** - Architecture complète du POC (composants, flux de données, schémas)
13. **GUIDE_INSTALLATION_HCD_MAC.md** - Guide détaillé d'installation de HCD sur MacBook Pro M3
14. **ANALYSE_ETAT_ART_HBASE.md** - Analyse complète du document "État de l'art HBase chez Arkéa"
15. **DOCUMENTATION_FINALE.md** - Index de la documentation (ancien)

---

## 📖 Description des Documents

### Installation

- **GUIDE_INSTALLATION_HCD_MAC.md** : Guide pas à pas pour installer HCD 1.2.3 sur MacBook Pro M3 Pro
- **GUIDE_INSTALLATION_SPARK_KAFKA.md** : Guide pour installer Spark 3.5.1, Kafka 4.1.1 et spark-cassandra-connector

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
1. Suivre **GUIDE_INSTALLATION_HCD_MAC.md** pour HCD
2. Suivre **GUIDE_INSTALLATION_SPARK_KAFKA.md** pour Spark/Kafka

### Pour utiliser
1. Consulter **KAFKA_HCD_STREAMING_READY.md** pour le streaming
2. Consulter **SCRIPTS_A_JOUR.md** pour tous les scripts disponibles

### Pour vérifier
1. Consulter **RESULTATS_TEST_KAFKA_HCD.md** pour les résultats des tests

---

**Note** : Les fichiers sont triés par date de modification (du plus récent au plus ancien).

