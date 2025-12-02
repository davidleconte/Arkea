# 🎯 POC Design - Migration HBase → HCD

**Date** : 2025-11-25  
**Objectif** : Répertoire centralisé pour tous les designs et implémentations de POC par table/projet

---

## 📁 Structure

Ce répertoire contient les designs et implémentations de POC organisés par table/projet HBase à migrer.

```
poc-design/
├── domirama2/         # POC Domirama v2 (remplace domirama/)
│   ├── scripts/       # 64 scripts
│   ├── doc/           # 138 fichiers de documentation
│   └── schemas/       # 9 schémas CQL
│
├── domiramaCatOps/    # POC Catégorisation
│   ├── scripts/       # 80 scripts
│   ├── doc/           # 168 fichiers de documentation
│   └── schemas/       # 10 schémas CQL
│
├── bic/               # POC BIC (Base d'Interaction Client)
│   ├── scripts/       # 20 scripts
│   ├── doc/           # 45 fichiers de documentation
│   └── schemas/       # 3 schémas CQL
│
└── archive/            # Archives (domirama_archive_2025-12-01.tar.gz)
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

### ✅ Domirama2

**Table HBase** : `B997X04:domirama`  
**Statut** : POC complet et amélioré

**Contenu** :
- 64 scripts (setup, load, test, export, demo)
- 138 fichiers de documentation
- 9 schémas CQL avec index SAI avancés
- Tests exhaustifs (recherche, export, API, vector)

**Voir** : `domirama2/README.md`

**Note** : `domirama/` (POC initial) a été archivé le 2025-12-01 et remplacé par `domirama2/`

### ✅ DomiramaCatOps

**Table HBase** : `B997X04:domirama-meta-categories`  
**Statut** : POC complet avec catégorisation

**Contenu** :
- 80 scripts (catégorisation, feedbacks, règles)
- 168 fichiers de documentation
- 10 schémas CQL avec séparation MECE
- Tests exhaustifs

**Voir** : `domiramaCatOps/README.md`

### ✅ BIC

**Table HBase** : `B993O02:bi-client`  
**Statut** : POC complet

**Contenu** :
- 20 scripts (setup, génération, ingestion, tests)
- 45 fichiers de documentation
- 3 schémas CQL avec index SAI
- Tests exhaustifs (timeline, filtres, full-text)

**Voir** : `bic/README.md`

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





