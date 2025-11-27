# 📥 Inputs IBM

**Date** : 2025-11-25  
**Répertoire** : `inputs-ibm/` - Documents et fichiers fournis par IBM

---

## 📋 Description

Ce répertoire contient les documents, fichiers et ressources fournis par IBM pour le POC de migration HBase → HCD.

---

## 📁 Contenu

| Fichier | Description | Taille | Statut |
|---------|-------------|--------|--------|
| `PROPOSITION_MECE_MIGRATION_HBASE_HCD.md` | Proposition MECE complète pour la migration | ~1560 lignes | ✅ Analysé |

---

## 📄 Document Principal

### Proposition MECE - Migration HBase → HCD

**Fichier** : `PROPOSITION_MECE_MIGRATION_HBASE_HCD.md`  
**Source** : IBM / DataStax  
**Date** : 2025-11-25  
**Taille** : ~1560 lignes

**Contenu** :
- **Axe Technologique** : Constats, enjeux, propositions (HCD, SAI, IA)
- **Axe Données** : Schémas actuels, enjeux, propositions (tables Cassandra)
- **Axe Applicatif** : Applications actuelles, enjeux, propositions (refonte code)
- **Axe Organisationnel** : Organisation actuelle, enjeux, propositions (phases)
- **Refonte Domirama** : Modélisation CQL, recherche full-text/vectorielle, Data API
- **Refonte domirama-meta-categories** : Séparation MECE, compteurs, indexation
- **Refonte bi-client** : Schéma BIC, ingestion Kafka, export batch
- **Guide POC** : POC1 (CSV) et POC2 (SequenceFile) avec code complet

**Analyse détaillée** : Voir `docs/ANALYSE_PROPOSITION_IBM_MECE.md`

---

## 🔍 Points Clés de la Proposition

### Avantages

✅ **Simplification** : Suppression HDFS/Yarn/ZooKeeper, cluster unique  
✅ **Performance** : Indexation SAI native, recherche full-text intégrée  
✅ **Modernisation** : Spark au lieu de PIG/MapReduce, API REST/GraphQL  
✅ **IA** : Support embeddings, recherche vectorielle native

### Points d'Attention

⚠️ **Refonte complète** du modèle de données nécessaire  
⚠️ **Migration complexe** avec validation qualité essentielle  
⚠️ **Formation** des équipes requise  
⚠️ **Investissement** significatif en temps et ressources

---

## 📝 Notes

- Ce répertoire est organisé de la même manière que `inputs-clients/`
- Les fichiers IBM sont stockés ici pour référence et analyse
- L'analyse détaillée est dans `docs/ANALYSE_PROPOSITION_IBM_MECE.md`

---

**Inputs IBM organisés dans ce répertoire !** ✅

