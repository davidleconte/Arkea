# 📋 POC DomiramaCatOps - Vue d'Ensemble

**Date** : 2025-12-01  
**Projet** : Catégorisation des Opérations  
**Objectif** : Démontrer la migration de HBase vers DataStax HCD pour la catégorisation des opérations  
**Conformité** : **95%** avec les exigences clients et IBM  
**Statut** : ✅ **Tous les gaps critiques comblés**

---

## 🎯 Objectifs

Ce POC DomiramaCatOps démontre la migration de deux tables HBase vers DataStax HCD :

1. ✅ **Table `B997X04:domirama`** (Column Family `category`)
   - Catégorisation automatique des opérations
   - Stratégie multi-version (batch vs client)
   - Recherche avancée (Full-Text, Vector, Hybrid)

2. ✅ **Table `B997X04:domirama-meta-categories`**
   - 7 tables meta-categories (explosion du schéma HBase)
   - Règles personnalisées
   - Feedbacks et compteurs atomiques
   - Historique d'opposition

---

## 📊 Caractéristiques Principales

| Aspect | Description | Statut |
|--------|-------------|--------|
| **Keyspace** | `domiramacatops_poc` (nouveau keyspace dédié) | ✅ |
| **Table principale** | `operations_by_account` | ✅ |
| **Tables meta** | 7 tables meta-categories | ✅ |
| **Format source** | Parquet uniquement | ✅ |
| **Stratégie multi-version** | Batch écrit `cat_auto`, client écrit `cat_user` | ✅ |
| **Recherche avancée** | Full-Text, Vector, Hybrid, Fuzzy, N-Gram | ✅ |
| **Compteurs atomiques** | Feedbacks par libellé et ICS | ✅ |
| **TTL** | 10 ans (315619200 secondes) | ✅ |

---

## 📁 Structure du Projet

```
domiramaCatOps/
├── README.md                    # Vue d'ensemble du projet
├── doc/
│   ├── INDEX.md                 # Index de navigation
│   ├── guides/                  # Guides d'utilisation
│   │   ├── 01_README.md         # Ce fichier
│   │   ├── 02_GUIDE_SETUP.md    # Guide de configuration
│   │   ├── 03_GUIDE_INGESTION.md # Guide d'ingestion
│   │   ├── 04_GUIDE_RECHERCHE.md # Guide de recherche
│   │   └── ...
│   ├── design/                  # Documents de design
│   ├── implementation/          # Documents d'implémentation
│   ├── results/                 # Résultats de tests
│   ├── corrections/             # Corrections appliquées
│   ├── audits/                  # Audits et analyses
│   ├── demonstrations/          # Rapports auto-générés
│   └── templates/               # Templates réutilisables
├── schemas/
│   └── *.cql                   # Schémas CQL (numérotés)
├── scripts/
│   ├── 01_setup_domiramaCatOps_keyspace.sh
│   ├── 02_setup_operations_by_account.sh
│   ├── 05_load_operations_data_parquet.sh
│   ├── 08_test_category_search.sh
│   ├── 16_test_fuzzy_search.sh
│   ├── 17_demonstration_fuzzy_search.sh
│   ├── 18_test_hybrid_search.sh
│   └── ... (74 scripts au total)
└── data/                        # Données de test
```

**Note** : La plupart des scripts génèrent automatiquement une documentation structurée dans `doc/demonstrations/`.

---

## 🚀 Guide de Démarrage Rapide

### 1. Configuration du Schéma

```bash
# Créer le keyspace
./scripts/01_setup_domiramaCatOps_keyspace.sh

# Créer la table operations_by_account
./scripts/02_setup_operations_by_account.sh

# Créer les tables meta-categories
./scripts/03_setup_meta_categories_tables.sh

# Créer les index SAI
./scripts/04_create_indexes.sh
```

### 2. Chargement des Données

```bash
# Générer les données Parquet
./scripts/04_generate_operations_parquet.sh

# Charger les opérations (batch)
./scripts/05_load_operations_data_parquet.sh

# Générer les embeddings
./scripts/05_generate_libelle_embedding.sh

# Charger les meta-categories
./scripts/06_load_meta_categories_data_parquet.sh
```

### 3. Tests de Recherche

```bash
# Recherche par catégorie
./scripts/08_test_category_search.sh

# Recherche floue (fuzzy search)
./scripts/16_test_fuzzy_search.sh

# Recherche hybride
./scripts/18_test_hybrid_search.sh
```

---

## 📚 Documentation

### Guides Disponibles

- **[02_GUIDE_SETUP.md](02_GUIDE_SETUP.md)** : Configuration complète du schéma
- **[03_GUIDE_INGESTION.md](03_GUIDE_INGESTION.md)** : Chargement des données (batch et temps réel)
- **[04_GUIDE_RECHERCHE.md](04_GUIDE_RECHERCHE.md)** : Recherche avancée (Full-Text, Vector, Hybrid)

### Autres Ressources

- **[INDEX.md](../INDEX.md)** : Index complet de la documentation
- **[demonstrations/](../demonstrations/)** : Rapports auto-générés par les scripts didactiques
- **[design/](../design/)** : Documents de design et architecture
- **[audits/](../audits/)** : Audits et analyses complètes

---

## 🎯 Fonctionnalités Démonstrées

### 1. Catégorisation Automatique

- ✅ Batch écrit `cat_auto` et `cat_confidence`
- ✅ Client peut corriger via `cat_user`
- ✅ Stratégie multi-version garantit qu'aucune correction n'est perdue

### 2. Recherche Avancée

- ✅ **Full-Text Search** : Recherche par libellé avec index SAI
- ✅ **Vector Search** : Recherche floue avec embeddings ByteT5
- ✅ **Hybrid Search** : Combinaison Full-Text + Vector
- ✅ **N-Gram Search** : Recherche partielle avec `libelle_tokens`

### 3. Meta-Categories

- ✅ **Règles personnalisées** : Table `regles_personnalisees`
- ✅ **Feedbacks** : Compteurs atomiques par libellé et ICS
- ✅ **Historique opposition** : Traçabilité des corrections
- ✅ **Acceptation/Opposition** : Gestion des validations client

---

## 🔍 Équivalences HBase → HCD

| Concept HBase | Équivalent HCD | Statut |
|---------------|----------------|--------|
| Namespace `B997X04` | Keyspace `domiramacatops_poc` | ✅ |
| Table `domirama` | Table `operations_by_account` | ✅ |
| Column Family `category` | Colonnes `cat_auto`, `cat_user`, etc. | ✅ |
| Table `domirama-meta-categories` | 7 tables séparées | ✅ |
| RowKey | Partition Key + Clustering Keys | ✅ |
| TTL 315619200s | `default_time_to_live = 315619200` | ✅ |
| INCREMENT | Type COUNTER | ✅ |
| BLOOMFILTER | Index SAI | ✅ |

---

## 📊 Statistiques

- **Scripts** : 74 scripts shell
- **Scripts didactiques** : 10 scripts avec génération automatique de documentation
- **Schémas CQL** : 10+ fichiers
- **Démonstrations** : 33+ rapports auto-générés
- **Documentation** : 100+ fichiers markdown

---

## ✅ Prochaines Étapes

1. **Lire les guides** :
   - [Guide de Configuration](02_GUIDE_SETUP.md)
   - [Guide d'Ingestion](03_GUIDE_INGESTION.md)
   - [Guide de Recherche](04_GUIDE_RECHERCHE.md)

2. **Exécuter les scripts** :
   - Suivre l'ordre d'exécution recommandé
   - Consulter les rapports générés dans `doc/demonstrations/`

3. **Consulter les démonstrations** :
   - Tous les scripts didactiques génèrent des rapports markdown
   - Rapports disponibles dans `doc/demonstrations/`

---

**Date de création** : 2025-12-01  
**Dernière mise à jour** : 2025-12-01
