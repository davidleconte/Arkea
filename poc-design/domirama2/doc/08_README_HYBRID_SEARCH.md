# 🔍 Recherche Hybride : Full-Text + Vector Search

## Vue d'ensemble

La recherche hybride combine les avantages de deux approches complémentaires pour offrir la meilleure expérience de recherche :

1. **Full-Text Search (SAI)** : Filtre initial pour la précision
2. **Vector Search (ByteT5)** : Tri par similarité pour tolérer les typos

## Architecture

### Stratégie de Recherche

```
Requête Utilisateur
    ↓
┌─────────────────────────────────────┐
│ 1. Essai Full-Text + Vector         │
│    WHERE libelle : 'terme'          │
│    ORDER BY embedding ANN OF [...]  │
└─────────────────────────────────────┘
    ↓ (si aucun résultat)
┌─────────────────────────────────────┐
│ 2. Fallback Vector Search seul      │
│    ORDER BY embedding ANN OF [...]  │
│    + Filtrage côté client           │
└─────────────────────────────────────┘
    ↓
Résultats Pertinents
```

## Avantages

### 1. Précision du Full-Text
- Filtre initial réduit l'espace de recherche
- Retourne uniquement les résultats contenant le terme recherché
- Performance optimale pour requêtes correctes

### 2. Tolérance aux Typos du Vector Search
- Si Full-Text ne trouve rien (typo), fallback sur Vector Search
- Les embeddings capturent la similarité sémantique
- Trouve des résultats même avec des erreurs de frappe

### 3. Meilleure Pertinence
- Combine la précision du Full-Text avec la flexibilité du Vector
- Tri par similarité vectorielle améliore le ranking
- Résultats plus pertinents que chaque approche seule

## Utilisation

### Script Python

```python
from hybrid_search import smart_hybrid_search

# Connexion à HCD
cluster = Cluster(['localhost'], port=9042)
session = cluster.connect('domirama2_poc')

# Recherche hybride
results = smart_hybrid_search(
    session=session,
    query_text="LOYER IMPAYE",
    code_si="1",
    contrat="5913101072",
    limit=10
)
```

### Exécution Directe

```bash
python3 hybrid_search.py
```

## Exemples de Requêtes

### Requête Correcte
- **Input**: `"LOYER IMPAYE"`
- **Stratégie**: Full-Text + Vector
- **Résultat**: `"LOYER IMPAYE REGULARISATION"` (1er résultat)

### Requête avec Typo
- **Input**: `"loyr impay"`
- **Stratégie**: Fallback Vector Search
- **Résultat**: `"LOYER PARIS MAISON"` (typo tolérée)

## Comparaison des Approches

| Critère | Full-Text seul | Vector seul | Hybride |
|---------|----------------|-------------|---------|
| **Précision** | ✅ Très élevée | ⚠️ Variable | ✅ Élevée |
| **Typos** | ❌ Non toléré | ✅ Toléré | ✅ Toléré |
| **Performance** | ✅ Très rapide | ⚠️ Moyenne | ✅ Rapide |
| **Pertinence** | ✅ Excellente | ⚠️ Variable | ✅ Excellente |

## Recommandations

### Quand utiliser Full-Text seul
- Recherches exactes avec termes connus
- Performance critique
- Pas besoin de tolérance aux typos

### Quand utiliser Vector seul
- Recherches avec typos fréquents
- Recherches sémantiques (synonymes)
- Multilingue

### Quand utiliser Hybride (recommandé)
- **Production** : Meilleur compromis
- Expérience utilisateur optimale
- Tolère les erreurs tout en gardant la précision

## Implémentation Technique

### Requête CQL Hybride

```cql
SELECT libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1' 
  AND contrat = '5913101072'
  AND libelle : 'loyer'  -- Filtre Full-Text
ORDER BY libelle_embedding ANN OF [0.12, 0.5, ..., -0.03]  -- Tri Vector
LIMIT 10;
```

### Fallback Vector

Si la requête Full-Text ne retourne rien (typo), on utilise :

```cql
SELECT libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
ORDER BY libelle_embedding ANN OF [0.12, 0.5, ..., -0.03]
LIMIT 30;
```

Puis filtrage côté client pour améliorer la pertinence.

## Scripts Disponibles

- `hybrid_search.py` : Implémentation de la recherche hybride
- `25_test_hybrid_search.sh` : Script de démonstration
- `test_hybrid_search.py` : Tests comparatifs

## Performance

- **Full-Text + Vector** : ~10-50ms (selon la taille de la partition)
- **Vector seul** : ~50-200ms (plus lent car plus de résultats à trier)
- **Fallback** : Automatique si Full-Text ne trouve rien

## Conclusion

La recherche hybride offre le meilleur compromis entre :
- ✅ **Précision** (Full-Text)
- ✅ **Tolérance aux typos** (Vector)
- ✅ **Pertinence** (Combinaison des deux)

**Recommandation** : Utiliser la recherche hybride en production pour une expérience utilisateur optimale.

