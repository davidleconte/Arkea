# 🔍 Démonstration : Configuration Fuzzy Search avec ByteT5 - POC Domirama2

**Date** : 2025-11-26 17:51:00  
**Script** : `21_setup_fuzzy_search_v2_didactique.sh`  
**Objectif** : Configurer la recherche floue avec colonne vectorielle et index SAI vectoriel

---

## 📋 Table des Matières

1. [Contexte - Pourquoi la Recherche Floue ?](#contexte)
2. [DDL - Ajout de la Colonne Vectorielle](#ddl-colonne)
3. [DDL - Création de l'Index Vectoriel](#ddl-index)
4. [Vérifications](#vérifications)
5. [Résumé et Prochaines Étapes](#résumé)

---

## 📚 Contexte - Pourquoi la Recherche Floue ?

### Problème

Les recherches avec typos complexes ne fonctionnent pas avec les index standard :

**Scénario 1** : Un utilisateur cherche 'LOYER' mais tape 'LOYR' (caractère 'e' manquant)
- Résultat avec index standard : ❌ Aucun résultat trouvé

**Scénario 2** : Un utilisateur cherche 'CARREFOUR' mais tape 'KARREFOUR' (faute)
- Résultat avec index N-Gram : ⚠️  Peut trouver, mais pas toujours

**Problème** : Les index full-text (standard, N-Gram) ont des limitations :
- Index standard : Recherche exacte (après stemming/accents)
- Index N-Gram : Recherche partielle mais limitée aux préfixes
- Aucun index ne gère bien les typos complexes (faute, inversion, etc.)

### Solution

Utiliser des embeddings sémantiques pour capturer la similarité :

- **Embeddings** : Représentation vectorielle du sens des mots
- **ByteT5** : Modèle multilingue robuste aux typos (1472 dimensions)
- **Similarité cosinus** : Mesure la proximité sémantique entre vecteurs
- **ANN (Approximate Nearest Neighbor)** : Recherche rapide des vecteurs proches

**Exemple de recherche qui fonctionne :**

```cql
SELECT libelle, montant
FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
ORDER BY libelle_embedding ANN OF [0.12, 0.5, ..., -0.03]  -- Vecteur de la requête
LIMIT 5;
```

**Avantages :**
- ✅ Tolère les typos complexes (faute, inversion, caractères manquants)
- ✅ Capture la similarité sémantique (synonymes, variations)
- ✅ Multilingue (ByteT5 supporte plusieurs langues)
- ✅ Robuste aux variations linguistiques

### Équivalences HBase → HCD

| Concept HBase | Équivalent HCD | Statut |
|---------------|----------------|--------|
| Recherche vectorielle | Type VECTOR natif | ✅ |
| Système ML externe | Aucun système externe | ✅ |
| Elasticsearch + ML | Index SAI vectoriel intégré | ✅ |
| Synchronisation HBase ↔ Elasticsearch ↔ ML | Pas de synchronisation nécessaire | ✅ |

### Améliorations HCD

✅ **Type VECTOR natif** (vs système ML externe)  
✅ **Index SAI vectoriel intégré** (vs Elasticsearch externe)  
✅ **Pas de synchronisation** (vs HBase + Elasticsearch + ML)  
✅ **Performance optimale** (index co-localisé avec données)  
✅ **Support ANN natif** (Approximate Nearest Neighbor)

---

## 📋 DDL - Ajout de la Colonne Vectorielle

### Résultat Attendu

Colonne 'libelle_embedding' (VECTOR<FLOAT, 1472>) ajoutée à la table 'operations_by_account' :
- Type : VECTOR<FLOAT, 1472> (vecteur de 1472 dimensions)
- Dimensions : 1472 (taille des embeddings ByteT5-small)
- Valeur par défaut : NULL (pour données existantes)
- Remplissage : Automatique pour nouvelles données (via script 22)

### DDL

```cql
ALTER TABLE operations_by_account ADD libelle_embedding VECTOR<FLOAT, 1472>;
```

### Explication

- **ALTER TABLE** : Modifie la structure d'une table existante
- **ADD** : Ajoute une nouvelle colonne
- **libelle_embedding** : Nom de la colonne vectorielle
- **VECTOR<FLOAT, 1472>** : Type de données vectoriel
  - VECTOR : Type natif HCD pour stocker des vecteurs
  - FLOAT : Type de chaque dimension (nombre décimal)
  - 1472 : Nombre de dimensions (taille des embeddings ByteT5-small)

### À propos des Embeddings ByteT5

- **ByteT5-small** : Modèle de langage multilingue
- **Dimensions** : 1472 (taille fixe des embeddings générés)
- **Robustesse** : Tolère les typos et variations linguistiques
- **Multilingue** : Supporte plusieurs langues (français, anglais, etc.)
- **Génération** : Via script Python (transformers + torch)

### Note Importante

- Les données EXISTANTES auront libelle_embedding = NULL
- Les NOUVELLES données auront libelle_embedding rempli automatiquement
- Pour mettre à jour les données existantes :
  - Utiliser le script 22: `./22_generate_embeddings.sh`
  - Ou utiliser le script Python: `examples/python/generate_embeddings_bytet5.py`

---

## 📋 DDL - Création de l'Index Vectoriel

### Résultat Attendu

Index 'idx_libelle_embedding_vector' créé sur la colonne 'libelle_embedding' :
- Type : Index SAI vectoriel (Storage-Attached Index)
- Usage : Recherche par similarité (ANN - Approximate Nearest Neighbor)
- Performance : Recherche rapide même sur millions de vecteurs

### DDL

```cql
DROP INDEX IF EXISTS idx_libelle_embedding_vector;
CREATE CUSTOM INDEX IF NOT EXISTS idx_libelle_embedding_vector
ON operations_by_account(libelle_embedding)
USING 'StorageAttachedIndex';
```

### Explication

- **DROP INDEX IF EXISTS** : Supprime l'index s'il existe (idempotent)
- **CREATE CUSTOM INDEX** : Crée un index personnalisé
- **idx_libelle_embedding_vector** : Nom de l'index
- **ON operations_by_account(libelle_embedding)** : Colonne indexée
- **USING 'StorageAttachedIndex'** : Type d'index (SAI)

### À propos de l'Index SAI Vectoriel

- **SAI (Storage-Attached Indexing)** : Index intégré à HCD
- **Type vectoriel** : Optimisé pour recherche par similarité
- **ANN (Approximate Nearest Neighbor)** : Trouve les vecteurs les plus proches
- **Similarité cosinus** : Mesure la proximité entre vecteurs
- **Performance** : Recherche rapide même sur millions de vecteurs

### Comment fonctionne la recherche vectorielle

1. La requête est encodée en vecteur (via ByteT5)
2. L'index SAI trouve les vecteurs les plus proches (ANN)
3. Les résultats sont triés par similarité cosinus
4. Les top-K résultats sont retournés

### Note Importante

- L'indexation se fait en arrière-plan (peut prendre quelques minutes)
- Attendre 30-60 secondes avant de tester les recherches
- Vérifier l'état de l'index : `SELECT * FROM system_views.indexes WHERE index_name = 'idx_libelle_embedding_vector';`

---

## 🔍 Vérifications

### Colonne

✅ Colonne libelle_embedding présente dans le schéma

### Index

✅ Index idx_libelle_embedding_vector créé

### Indexation

⏳ Indexation en cours (peut prendre quelques minutes)
- Les index SAI sont construits en arrière-plan
- Attendre 30-60 secondes avant de tester les recherches
- Vérifier l'état : `SELECT * FROM system_views.indexes WHERE index_name = 'idx_libelle_embedding_vector';`

---

## 📊 Résumé et Prochaines Étapes

### Résumé de la Configuration

✅ Colonne 'libelle_embedding' (VECTOR<FLOAT, 1472>) ajoutée  
✅ Index 'idx_libelle_embedding_vector' créé  
✅ Support de la recherche par similarité (ANN)  
✅ Tolérance aux typos complexes et variations linguistiques

### Avantages de la Recherche Vectorielle

✅ Tolère les typos complexes (faute, inversion, caractères manquants)  
✅ Capture la similarité sémantique (synonymes, variations)  
✅ Multilingue (ByteT5 supporte plusieurs langues)  
✅ Robuste aux variations linguistiques  
✅ Performance optimale (index co-localisé avec données)

### Prochaines Étapes

1. **Installer les dépendances Python** :
   ```bash
   pip install transformers torch
   ```

2. **Générer les embeddings pour les données existantes** :
   ```bash
   ./22_generate_embeddings.sh
   ```

3. **Tester la recherche floue** :
   ```bash
   ./23_test_fuzzy_search.sh
   ```

### Important

- Les données existantes ont libelle_embedding = NULL
- Il faut générer les embeddings avec le script 22
- Attendre que l'index soit construit (30-60 secondes)

---

**✅ Configuration de la recherche floue terminée !**
