# 🎯 POC Design - Migration HBase → HCD

**Date** : 2025-11-25  
**Objectif** : Répertoire centralisé pour tous les designs et implémentations de POC par table/projet

---

## 📁 Structure

Ce répertoire contient les designs et implémentations de POC organisés par table/projet HBase à migrer.

```
poc-design/
├── domirama/          # POC pour la table Domirama
│   ├── README.md
│   ├── create_domirama_schema.cql
│   ├── domirama_loader_csv.scala
│   ├── domirama_search_test.cql
│   ├── 07_setup_domirama_poc.sh
│   └── data/
│       └── operations_sample.csv
│
└── [autres projets]   # À venir : BIC, EDM, Catégorisation, etc.
```

---

## 🎯 Objectif

Centraliser tous les designs de POC pour faciliter :
- **Organisation** : Un répertoire par table/projet
- **Réutilisabilité** : Code et schémas réutilisables
- **Documentation** : README par projet
- **Tests** : Scripts de test isolés par projet

---

## 📊 Projets Disponibles

### ✅ Domirama

**Table HBase** : `B997X04:domirama`  
**Statut** : POC complet prêt

**Contenu** :
- Schéma CQL avec index SAI
- Code Spark pour ingestion
- Tests de recherche full-text
- Données de test

**Voir** : `domirama/README.md`

---

## 🚀 Utilisation

Chaque sous-répertoire contient son propre README avec les instructions d'utilisation.

**Exemple pour Domirama** :
```bash
cd poc-design/domirama
./07_setup_domirama_poc.sh
```

---

## 📝 Notes

- Chaque projet est **indépendant** et peut être exécuté séparément
- Les schémas sont **isolés** par keyspace (ex: `domirama_poc`, `bic_poc`, etc.)
- Les scripts utilisent des **chemins relatifs** quand possible

---

**Répertoire POC Design organisé !** ✅




