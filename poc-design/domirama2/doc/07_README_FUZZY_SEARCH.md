# 🔍 Fuzzy Search avec Vector Search (ByteT5)

## Vue d'ensemble

Ce document décrit l'implémentation de la recherche floue (fuzzy search) dans le POC Domirama2 en utilisant **ByteT5** pour générer des embeddings vectoriels et **HCD Vector Search** pour effectuer des recherches par similarité.

## Architecture

### Composants

1. **ByteT5 Model** (`google/byt5-small`)
   - Modèle de transformation de texte en vecteurs
   - Dimension: **1472**
   - Traitement au niveau des bytes (multilingue)
   - Résilient aux typos et variations

2. **Colonne Vectorielle** (`libelle_embedding`)
   - Type: `VECTOR<FLOAT, 1472>`
   - Stocke l'embedding de chaque libellé
   - Indexée avec SAI pour recherche ANN

3. **Index SAI Vectoriel** (`idx_libelle_embedding_vector`)
   - Index Storage-Attached pour recherche par similarité
   - Utilise l'algorithme ANN (Approximate Nearest Neighbor)
   - Basé sur JVector (DiskANN)

## Avantages de ByteT5 pour Fuzzy Search

### 1. Traitement au Niveau des Bytes
- Fonctionne avec n'importe quel alphabet (Latin, Cyrillic, Chinois, etc.)
- Pas de dépendance à un vocabulaire fixe
- Idéal pour les environnements multilingues

### 2. Robustesse aux Typos
- Les embeddings capturent la similarité sémantique
- Résilient aux erreurs de frappe mineures
- Gère les variations de formulation

### 3. Similarité Sémantique
- Comprend le sens au-delà de la correspondance exacte
- Trouve des résultats même avec des synonymes
- Gère les variations grammaticales

## Workflow

### 1. Génération des Embeddings

```python
from transformers import AutoTokenizer, AutoModel
import torch

tokenizer = AutoTokenizer.from_pretrained("google/byt5-small")
model = AutoModel.from_pretrained("google/byt5-small")

def encode_text(text):
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True)
    with torch.no_grad():
        encoder_outputs = model.encoder(**inputs)
        embeddings = encoder_outputs.last_hidden_state.mean(dim=1)
    return embeddings[0].tolist()
```

### 2. Stockage dans HCD

```cql
-- Ajouter la colonne vectorielle
ALTER TABLE operations_by_account 
ADD libelle_embedding VECTOR<FLOAT, 1472>;

-- Créer l'index vectoriel
CREATE CUSTOM INDEX idx_libelle_embedding_vector
ON operations_by_account(libelle_embedding)
USING 'StorageAttachedIndex';
```

### 3. Recherche Vectorielle

```cql
-- Recherche par similarité (ANN)
SELECT libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
ORDER BY libelle_embedding ANN OF [0.12, 0.5, ..., -0.03]  -- Vecteur de la requête
LIMIT 5;
```

### 4. Recherche Hybride (Vector + Full-Text)

```cql
-- Combinaison de recherche vectorielle et filtrage textuel
SELECT libelle, montant
FROM operations_by_account
WHERE code_si = '1'
  AND contrat = '5913101072'
  AND libelle : 'loy'  -- Filtre full-text
ORDER BY libelle_embedding ANN OF [0.12, 0.5, ..., -0.03]  -- Tri par similarité
LIMIT 5;
```

## Scripts Disponibles

### 1. `21_setup_fuzzy_search.sh`
- Configure le schéma HCD pour la recherche vectorielle
- Ajoute la colonne `libelle_embedding`
- Crée l'index SAI vectoriel

### 2. `22_generate_embeddings.sh`
- Génère les embeddings ByteT5 pour tous les libellés existants
- Met à jour la colonne `libelle_embedding` dans HCD
- Utilise Spark pour le traitement distribué

### 3. `23_test_fuzzy_search.sh`
- Teste la recherche floue avec différentes requêtes contenant des typos
- Démonstration de la tolérance aux erreurs
- Affiche les résultats avec scores de similarité

### 4. `generate_embeddings_bytet5.py`
- Script Python standalone pour générer des embeddings
- Utile pour tester ou générer des embeddings ponctuels

## Exemples de Requêtes

### Typo: Caractère Manquant
- Requête: `"loyr"` → Trouve: `"LOYER"`

### Typo: Inversion de Caractères
- Requête: `"parsi"` → Trouve: `"PARIS"`

### Typo: Accent Manquant
- Requête: `"impay"` → Trouve: `"IMPAYE"`

### Typo: Caractère Manquant
- Requête: `"viremnt"` → Trouve: `"VIREMENT"`

## Comparaison avec Full-Text Search

| Critère | Full-Text Search (SAI) | Vector Search (ByteT5) |
|---------|------------------------|------------------------|
| **Typos** | ❌ Nécessite tokens complets | ✅ Tolère les typos |
| **Similarité Sémantique** | ❌ Basé sur tokens | ✅ Basé sur sens |
| **Multilingue** | ⚠️ Dépend des analyzers | ✅ Natif (bytes) |
| **Performance** | ✅ Très rapide | ⚠️ Nécessite génération embedding |
| **Précision** | ✅ Exacte | ⚠️ Approximative (ANN) |

## Recommandations d'Utilisation

### Utiliser Full-Text Search pour:
- Recherches exactes avec tokens complets
- Filtrage rapide par mots-clés
- Recherches avec stemming/accents

### Utiliser Vector Search pour:
- Recherches avec typos
- Recherches sémantiques (synonymes)
- Recherches multilingues
- Recherches avec variations de formulation

### Utiliser Recherche Hybride pour:
- Combiner précision (full-text) et tolérance (vector)
- Filtrer d'abord par full-text, puis trier par similarité
- Meilleur compromis performance/précision

## Dépendances

```bash
pip install transformers torch
```

## Configuration de la Clé API Hugging Face

Pour améliorer les performances et éviter les limitations de taux lors du téléchargement des modèles, configurez la clé API Hugging Face :

### Option 1: Variable d'environnement (recommandé)

La clé API est déjà configurée dans `.poc-profile` :

```bash
export HF_API_KEY="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"
```

Ou chargez le profil complet :

```bash
source .poc-profile
```

### Option 2: Dans le script Python

La clé API est automatiquement utilisée depuis la variable d'environnement `HF_API_KEY`, avec une valeur par défaut si non définie.

### Avantages de l'utilisation de la clé API

- ✅ **Téléchargement plus rapide** : Accès prioritaire aux modèles
- ✅ **Pas de limitations de taux** : Évite les erreurs 429 (Too Many Requests)
- ✅ **Accès aux modèles privés** : Si vous avez des modèles privés
- ✅ **Meilleure fiabilité** : Connexions plus stables

## Références

- [ByteT5 Paper](https://arxiv.org/abs/2105.13626)
- [HCD Vector Search Documentation](https://docs.datastax.com/en/hyper-converged-database/1.2/tutorials/vector-search-with-cql.html)
- [Transformers Library](https://huggingface.co/docs/transformers)

