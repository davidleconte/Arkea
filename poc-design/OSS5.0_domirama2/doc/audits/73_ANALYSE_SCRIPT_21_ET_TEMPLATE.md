# 📋 Analyse du Script 21 : `21_setup_fuzzy_search.sh`

**Date** : 2025-11-26
**Script** : `21_setup_fuzzy_search.sh`
**Objectif** : Configuration de la recherche floue (fuzzy search) avec colonne vectorielle et index SAI vectoriel

---

## 📊 Vue d'Ensemble

### Objectif Principal

Le script 21 configure la recherche floue (fuzzy search) en ajoutant :

1. La colonne `libelle_embedding` (VECTOR<FLOAT, 1472>) à la table `operations_by_account`
2. L'index SAI vectoriel `idx_libelle_embedding_vector` sur cette colonne
3. Support des recherches par similarité sémantique (ANN - Approximate Nearest Neighbor)

### Fonctionnalités

- ✅ Ajout de la colonne `libelle_embedding` (VECTOR<FLOAT, 1472>) (si elle n'existe pas)
- ✅ Création de l'index `idx_libelle_embedding_vector` (index SAI vectoriel)
- ✅ Vérification de l'existence de la colonne avant ajout
- ✅ Messages informatifs sur l'indexation en arrière-plan
- ✅ Instructions pour les prochaines étapes (génération embeddings, tests)

---

## 🔍 Analyse Détaillée

### Structure du Script

#### 1. **Vérifications Préalables**

```bash
# Vérification que HCD est démarré
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
```

✅ **Bon** : Vérification de l'état de HCD avant exécution

#### 2. **Ajout de la Colonne Vectorielle**

```bash
COLUMN_EXISTS=$(./bin/cqlsh localhost 9042 -e "USE domirama2_poc; DESCRIBE TABLE operations_by_account;" 2>&1 | grep -c "libelle_embedding" || echo "0")

if [ "$COLUMN_EXISTS" -eq 0 ]; then
    ./bin/cqlsh localhost 9042 -e "USE domirama2_poc; ALTER TABLE operations_by_account ADD libelle_embedding VECTOR<FLOAT, 1472>;" 2>&1 | grep -v "Warnings" || true
    success "✅ Colonne libelle_embedding ajoutée"
else
    info "✅ Colonne libelle_embedding existe déjà"
fi
```

✅ **Bon** : Vérification de l'existence avant ajout (évite les erreurs)
✅ **Bon** : Type VECTOR<FLOAT, 1472> (1472 dimensions pour ByteT5-small)

#### 3. **Création de l'Index Vectoriel**

```cql
DROP INDEX IF EXISTS idx_libelle_embedding_vector;
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_vector
ON operations_by_account(libelle_embedding)
USING 'StorageAttachedIndex';
```

✅ **Bon** : Index SAI vectoriel (pas d'options spécifiques, utilise les paramètres par défaut)
✅ **Bon** : DROP IF EXISTS avant création (idempotent)

#### 4. **Messages Informatifs**

```bash
info "⏳ Indexation en cours (peut prendre quelques minutes)..."
info "   Les index SAI sont construits en arrière-plan"
info "   Attendre 30-60 secondes avant de tester les recherches"
```

✅ **Bon** : Informe l'utilisateur sur le temps d'indexation

---

## 📊 Comparaison avec les Scripts Existants

### Script 19 : `19_setup_typo_tolerance.sh`

| Aspect | Script 19 | Script 21 |
|--------|-----------|-----------|
| **Type** | Setup partiel (colonne TEXT) | Setup partiel (colonne VECTOR) |
| **Colonne** | `libelle_prefix` (TEXT) | `libelle_embedding` (VECTOR<FLOAT, 1472>) |
| **Index** | `idx_libelle_prefix_ngram` (SAI N-Gram) | `idx_libelle_embedding_vector` (SAI Vectoriel) |
| **Usage** | Recherche partielle avec N-Gram | Recherche par similarité sémantique (ANN) |
| **Équivalent HBase** | Elasticsearch N-Gram | Pas d'équivalent direct (nécessite Elasticsearch + ML externe) |
| **Complexité** | Moyenne (index N-Gram) | Haute (index vectoriel + embeddings) |

**Conclusion** : Les deux scripts sont similaires en structure (setup partiel), mais diffèrent par le type de colonne et d'index.

### Script 10 : `10_setup_domirama2_poc.sh`

| Aspect | Script 10 | Script 21 |
|--------|-----------|-----------|
| **Type** | Setup complet (keyspace + table) | Setup partiel (colonne + index) |
| **Portée** | Création complète du schéma | Ajout d'une colonne et d'un index |
| **Complexité** | Haute (schéma complet) | Moyenne (ajout partiel) |

**Conclusion** : Le script 21 est un setup partiel, comme le script 19.

---

## 🎯 Analyse du Type de Script

### Type de Script : **Setup Partiel**

**Caractéristiques** :

- ✅ Ajoute une colonne à une table existante
- ✅ Crée un index sur cette colonne
- ✅ Vérifie l'existence avant d'agir (idempotent)
- ✅ Pas de tests, pas d'orchestration
- ✅ Focus sur la configuration du schéma

**Comparaison avec les types existants** :

- ❌ **Pas un script de test** : Ne teste pas les fonctionnalités
- ❌ **Pas un script d'orchestration** : N'orchestre pas plusieurs étapes
- ✅ **Script de setup partiel** : Configure une partie du schéma

---

## 📋 Analyse des Templates Existants

### Template 43 : Script Didactique Général

**Type** : Scripts de test/démonstration
**Caractéristiques** :

- Tests avec résultats attendus/réels
- Requêtes CQL (DML)
- Comparaisons et validations

**Adapté au script 21 ?** : ❌ **NON**

- Le script 21 ne fait pas de tests
- Le script 21 ne fait pas de requêtes DML
- Le script 21 est un script de setup (DDL)

### Template 47 : Script Setup Didactique

**Type** : Scripts de setup/schéma (DDL)
**Caractéristiques** :

- DDL complet avec explications
- Équivalences HBase → HCD
- Vérifications détaillées
- Cinématique complète

**Adapté au script 21 ?** : ✅ **OUI (avec adaptations)**

- Le script 21 est un script de setup (DDL)
- Le script 21 ajoute une colonne et un index
- Le script 21 nécessite des explications sur le type VECTOR
- Le script 21 nécessite des équivalences HBase → HCD

**Adaptations nécessaires** :

1. ✅ Focus sur le type VECTOR (nouveau type de données)
2. ✅ Explications sur les embeddings ByteT5 (1472 dimensions)
3. ✅ Explications sur l'index SAI vectoriel (ANN)
4. ✅ Équivalences HBase → HCD (pas d'équivalent direct)
5. ✅ Explications sur la recherche par similarité cosinus

### Template 63 : Script Orchestration Didactique

**Type** : Scripts d'orchestration complète
**Caractéristiques** :

- Orchestre plusieurs étapes
- Appelle d'autres scripts
- Gère plusieurs démonstrations

**Adapté au script 21 ?** : ❌ **NON**

- Le script 21 n'orchestre pas plusieurs étapes
- Le script 21 ne appelle pas d'autres scripts
- Le script 21 est un script de setup simple

---

## 💡 Recommandation : Template 47 (Adapté)

### Pourquoi le Template 47 ?

1. ✅ **Type de script** : Le script 21 est un script de setup (DDL), comme le Template 47
2. ✅ **Structure similaire** : Ajoute une colonne et un index, comme le script 19 (qui utilise Template 47)
3. ✅ **Besoins didactiques** : Nécessite des explications sur le type VECTOR et les embeddings
4. ✅ **Équivalences HBase → HCD** : Nécessite des explications (pas d'équivalent direct)

### Adaptations Nécessaires

#### 1. **PARTIE 0: CONTEXTE - Pourquoi la Recherche Floue ?**

**Contenu** :

- Problème : Les recherches avec typos complexes ne fonctionnent pas avec les index standard
- Solution : Recherche vectorielle avec embeddings ByteT5
- Équivalences HBase → HCD :
  - HBase : Pas d'équivalent direct (nécessite Elasticsearch + ML externe)
  - HCD : Type VECTOR natif + index SAI vectoriel + recherche par similarité (ANN)

#### 2. **PARTIE 1: DDL - Ajout de la Colonne Vectorielle**

**Contenu** :

- DDL : `ALTER TABLE operations_by_account ADD libelle_embedding VECTOR<FLOAT, 1472>;`
- Explications :
  - Type VECTOR<FLOAT, 1472> : Vecteur de 1472 dimensions (ByteT5-small)
  - Chaque dimension est un FLOAT (nombre décimal)
  - Stocke l'embedding sémantique du libellé
  - Permet recherche par similarité cosinus

#### 3. **PARTIE 2: DDL - Création de l'Index Vectoriel**

**Contenu** :

- DDL : `CREATE CUSTOM INDEX idx_libelle_embedding_vector ON operations_by_account(libelle_embedding) USING 'StorageAttachedIndex';`
- Explications :
  - Index SAI vectoriel : Optimisé pour recherche par similarité (ANN)
  - ANN (Approximate Nearest Neighbor) : Trouve les vecteurs les plus proches
  - Performance : Recherche rapide même sur millions de vecteurs
  - Pas d'options spécifiques : Utilise les paramètres par défaut

#### 4. **PARTIE 3: VÉRIFICATIONS**

**Contenu** :

- Vérification de l'existence de la colonne
- Vérification de l'existence de l'index
- Affichage du schéma mis à jour

#### 5. **PARTIE 4: RÉSUMÉ ET PROCHAINES ÉTAPES**

**Contenu** :

- Résumé de ce qui a été configuré
- Instructions pour les prochaines étapes :
  - Script 22 : Génération embeddings
  - Script 23 : Tests fuzzy search
- Notes sur l'indexation en arrière-plan

---

## 📝 Structure Proposée du Script 21 Amélioré

```bash
#!/bin/bash
# ============================================
# Script 21 : Configuration Fuzzy Search avec ByteT5 (Version Didactique)
# Ajout de la colonne vectorielle et de l'index pour recherche floue
# ============================================

# PARTIE 0: CONTEXTE - Pourquoi la Recherche Floue ?
#   - Problème : Recherches avec typos complexes qui échouent
#   - Solution : Recherche vectorielle avec embeddings ByteT5
#   - Équivalences HBase → HCD (pas d'équivalent direct)

# PARTIE 1: DDL - Ajout de la Colonne Vectorielle
#   - DDL : ALTER TABLE ADD libelle_embedding VECTOR<FLOAT, 1472>
#   - Explications : Type VECTOR, dimensions, ByteT5
#   - Vérification : Colonne ajoutée

# PARTIE 2: DDL - Création de l'Index Vectoriel
#   - DDL : CREATE INDEX idx_libelle_embedding_vector
#   - Explications : Index SAI vectoriel, ANN, performance
#   - Vérification : Index créé

# PARTIE 3: VÉRIFICATIONS
#   - Vérification de l'existence de la colonne
#   - Vérification de l'existence de l'index
#   - Affichage du schéma mis à jour

# PARTIE 4: RÉSUMÉ ET PROCHAINES ÉTAPES
#   - Résumé de ce qui a été configuré
#   - Instructions pour les prochaines étapes
#   - Notes sur l'indexation en arrière-plan

# PARTIE 5: GÉNÉRATION RAPPORT MARKDOWN
#   - Documentation structurée
#   - DDL complet avec explications
#   - Équivalences HBase → HCD
```

---

## ✅ Conclusion

**Template recommandé** : **Template 47 (Script Setup Didactique) - ADAPTÉ**

**Raisons** :

1. ✅ Le script 21 est un script de setup (DDL), comme le Template 47
2. ✅ Structure similaire au script 19 (qui utilise Template 47)
3. ✅ Nécessite des explications sur le type VECTOR et les embeddings
4. ✅ Nécessite des équivalences HBase → HCD (pas d'équivalent direct)

**Adaptations nécessaires** :

- ✅ Ajouter contexte (PARTIE 0) sur la recherche floue
- ✅ Enrichir les explications sur le type VECTOR (dimensions, ByteT5)
- ✅ Enrichir les explications sur l'index SAI vectoriel (ANN, performance)
- ✅ Ajouter équivalences HBase → HCD (pas d'équivalent direct)
- ✅ Ajouter section prochaines étapes (génération embeddings, tests)
- ✅ Générer rapport markdown structuré

**Points clés à documenter** :

- ✅ Type VECTOR<FLOAT, 1472> : 1472 dimensions pour ByteT5-small
- ✅ Index SAI vectoriel : Recherche par similarité (ANN)
- ✅ Équivalent HBase : Pas d'équivalent direct (nécessite Elasticsearch + ML externe)
- ✅ Améliorations HCD : Recherche vectorielle native, pas de système ML externe

---

*Analyse créée le 2025-11-26 pour déterminer le template approprié pour le script 21*
