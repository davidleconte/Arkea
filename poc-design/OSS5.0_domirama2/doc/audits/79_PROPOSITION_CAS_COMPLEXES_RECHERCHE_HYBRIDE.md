# 🎯 Proposition : Cas Complexes de Recherche Hybride

**Date** : 2025-11-26
**Script concerné** : `25_test_hybrid_search_v2_didactique.sh`
**Objectif** : Proposer des cas de test plus complexes pour démontrer les capacités avancées de la recherche hybride

---

## 📊 Analyse des Tests Actuels

### Tests Existants (6 tests)

| Test | Type | Complexité |
|------|------|------------|
| LOYER IMPAYE | Correct (2 termes) | ⭐ Simple |
| loyr impay | Typo (2 termes) | ⭐ Simple |
| VIREMENT IMPAYE | Correct (2 termes) | ⭐ Simple |
| viremnt impay | Typo (2 termes) | ⭐ Simple |
| CARREFOUR | Correct (1 terme) | ⭐ Simple |
| carrefur | Typo (1 terme) | ⭐ Simple |

### Limitations Identifiées

1. **Pas de typos partielles** : Tous les termes ont des typos ou aucun
2. **Pas de recherches multi-termes complexes** : Maximum 2 termes
3. **Pas de variations linguistiques** : Pluriel + typo, conjugaison + typo
4. **Pas de recherches contextuelles** : Plusieurs mots avec contexte
5. **Pas de recherches avec priorités** : Certains termes plus importants
6. **Pas de recherches avec synonymes sémantiques** : Mots différents mais sens proche

---

## 🎯 Cas Complexes Proposés

### Catégorie 1 : Typos Partielles (Mix Correct + Typo)

**Principe** : Certains termes sont corrects, d'autres ont des typos. La recherche hybride doit combiner Full-Text (pour les termes corrects) et Vector (pour les typos).

#### Test 1 : Un terme correct, un avec typo

```python
{
    "query": "LOYER impay",
    "description": "Recherche mixte: 'LOYER' correct + 'impay' typo",
    "expected": "Devrait trouver 'LOYER IMPAYE' grâce à Full-Text pour LOYER + Vector pour impay",
    "strategy": "Full-Text partiel + Vector (terme avec typo)",
    "explanation": "Démontre la recherche hybride avec mixte : Full-Text filtre avec 'LOYER' (terme correct), puis Vector Search gère 'impay' (typo) pour améliorer la pertinence."
}
```

#### Test 2 : Deux termes corrects, un avec typo

```python
{
    "query": "VIREMENT IMPAYE paris",
    "description": "Recherche mixte: 2 termes corrects + 'paris' typo (devrait être 'PARIS')",
    "expected": "Devrait trouver 'VIREMENT IMPAYE PARIS' grâce à Full-Text pour VIREMENT/IMPAYE + Vector pour paris",
    "strategy": "Full-Text partiel + Vector (terme avec typo)",
    "explanation": "Démontre la recherche hybride avec plusieurs termes corrects et un typo : Full-Text filtre avec les termes corrects, Vector gère le typo."
}
```

---

### Catégorie 2 : Recherches Multi-Termes Complexes (3+ termes)

**Principe** : Plusieurs termes (3, 4, 5) avec différentes combinaisons de typos.

#### Test 3 : Trois termes avec typos partiels

```python
{
    "query": "loyr impay paris",
    "description": "Recherche 3 termes avec typos: 'loyr' + 'impay' + 'paris'",
    "expected": "Devrait trouver 'LOYER IMPAYE PARIS' grâce au Vector Search (fallback)",
    "strategy": "Vector seul avec fallback (typos multiples)",
    "explanation": "Démontre le fallback automatique avec plusieurs typos : Full-Text ne trouve rien, donc fallback sur Vector Search qui gère tous les typos simultanément."
}
```

#### Test 4 : Quatre termes mixtes

```python
{
    "query": "VIREMENT PERMANENT MENSUEL livret",
    "description": "Recherche 4 termes: 3 corrects + 1 typo possible",
    "expected": "Devrait trouver 'VIREMENT PERMANENT MENSUEL VERS LIVRET A'",
    "strategy": "Full-Text partiel + Vector (terme avec typo ou variation)",
    "explanation": "Démontre la recherche hybride avec plusieurs termes : Full-Text filtre avec les termes corrects, Vector gère les variations."
}
```

---

### Catégorie 3 : Variations Linguistiques + Typos

**Principe** : Combinaison de variations linguistiques (pluriel, conjugaison) avec typos.

#### Test 5 : Pluriel + typo

```python
{
    "query": "loyrs impay",
    "description": "Recherche avec pluriel typé: 'loyrs' (pluriel de 'loyer' avec typo) + 'impay'",
    "expected": "Devrait trouver 'LOYER IMPAYE' grâce au Vector Search (fallback)",
    "strategy": "Vector seul avec fallback (variation linguistique + typo)",
    "explanation": "Démontre la tolérance aux variations linguistiques avec typos : Full-Text ne gère pas bien 'loyrs', Vector Search capture la similarité sémantique."
}
```

#### Test 6 : Conjugaison + typo

```python
{
    "query": "virements impayes",
    "description": "Recherche avec pluriels typés: 'virements' + 'impayes'",
    "expected": "Devrait trouver 'VIREMENT IMPAYE' grâce au Vector Search (fallback)",
    "strategy": "Vector seul avec fallback (variations linguistiques + typos)",
    "explanation": "Démontre la tolérance aux variations linguistiques multiples avec typos : Vector Search capture la similarité sémantique globale."
}
```

---

### Catégorie 4 : Recherches Contextuelles

**Principe** : Plusieurs mots formant un contexte, avec typos sur certains mots.

#### Test 7 : Contexte complet avec typos

```python
{
    "query": "loyr impay regularisation paris",
    "description": "Recherche contextuelle 4 termes avec typos: contexte complet",
    "expected": "Devrait trouver 'LOYER IMPAYE REGULARISATION PARIS' grâce au Vector Search (fallback)",
    "strategy": "Vector seul avec fallback (contexte avec typos)",
    "explanation": "Démontre la recherche contextuelle avec typos : Vector Search capture le contexte global même avec plusieurs typos."
}
```

#### Test 8 : Contexte partiel (mots-clés importants)

```python
{
    "query": "loyr paris maison",
    "description": "Recherche contextuelle 3 termes: 'loyr' typo + contexte géographique",
    "expected": "Devrait trouver 'LOYER PARIS MAISON' grâce au Vector Search (fallback)",
    "strategy": "Vector seul avec fallback (contexte avec typo)",
    "explanation": "Démontre la recherche contextuelle : Vector Search comprend le contexte (loyer + Paris + maison) même avec typo."
}
```

---

### Catégorie 5 : Recherches avec Synonymes Sémantiques

**Principe** : Mots différents mais sémantiquement proches (synonymes).

#### Test 9 : Synonyme sémantique

```python
{
    "query": "paiement carte",
    "description": "Recherche avec synonyme: 'paiement' au lieu de 'CB' ou 'CARTE'",
    "expected": "Devrait trouver des opérations CB/CARTE grâce à la similarité sémantique",
    "strategy": "Full-Text + Vector (synonyme sémantique)",
    "explanation": "Démontre la recherche sémantique : Vector Search capture la similarité entre 'paiement' et 'CB'/'CARTE' même si les mots sont différents."
}
```

#### Test 10 : Synonyme avec typo

```python
{
    "query": "paiemnt carte",
    "description": "Recherche avec synonyme + typo: 'paiemnt' (typo) + 'carte'",
    "expected": "Devrait trouver des opérations CB/CARTE grâce au Vector Search (fallback)",
    "strategy": "Vector seul avec fallback (synonyme + typo)",
    "explanation": "Démontre la recherche sémantique avec typo : Vector Search capture à la fois le synonyme et tolère la typo."
}
```

---

### Catégorie 6 : Recherches avec Noms Propres et Codes

**Principe** : Recherches avec noms propres, codes, abréviations avec typos.

#### Test 11 : Nom propre avec typo

```python
{
    "query": "ratp navigo",
    "description": "Recherche nom propre: 'RATP NAVIGO' (abréviations)",
    "expected": "Devrait trouver 'CB RATP NAVIGO MOIS' grâce à Full-Text + Vector",
    "strategy": "Full-Text + Vector (noms propres)",
    "explanation": "Démontre la recherche hybride avec noms propres : Full-Text filtre avec les abréviations, Vector améliore la pertinence."
}
```

#### Test 12 : Code avec typo

```python
{
    "query": "sepa viremnt",
    "description": "Recherche code + typo: 'SEPA' (code) + 'viremnt' (typo)",
    "expected": "Devrait trouver 'VIREMENT SEPA' grâce à Full-Text pour SEPA + Vector pour viremnt",
    "strategy": "Full-Text partiel + Vector (code + typo)",
    "explanation": "Démontre la recherche hybride avec code : Full-Text filtre avec le code correct, Vector gère le typo."
}
```

---

### Catégorie 7 : Recherches avec Localisation

**Principe** : Recherches avec noms de lieux, adresses avec typos.

#### Test 13 : Localisation avec typo

```python
{
    "query": "carrefour paris",
    "description": "Recherche localisation: 'CARREFOUR' + 'PARIS'",
    "expected": "Devrait trouver 'CB CARREFOUR MARKET PARIS' grâce à Full-Text + Vector",
    "strategy": "Full-Text + Vector (localisation)",
    "explanation": "Démontre la recherche hybride avec localisation : Full-Text filtre avec les deux termes, Vector améliore la pertinence."
}
```

#### Test 14 : Localisation avec typos

```python
{
    "query": "carrefur parsi",
    "description": "Recherche localisation avec typos: 'carrefur' + 'parsi'",
    "expected": "Devrait trouver 'CB CARREFOUR MARKET PARIS' grâce au Vector Search (fallback)",
    "strategy": "Vector seul avec fallback (localisation avec typos)",
    "explanation": "Démontre la recherche contextuelle avec typos : Vector Search capture le contexte géographique même avec typos."
}
```

---

### Catégorie 8 : Recherches avec Catégories et Types

**Principe** : Recherches combinant libellé + catégorie/type avec typos.

#### Test 15 : Catégorie + libellé avec typo

```python
{
    "query": "loyr habitation",
    "description": "Recherche catégorie + libellé typé: 'loyr' + 'habitation'",
    "expected": "Devrait trouver 'LOYER' avec catégorie HABITATION grâce au Vector Search (fallback)",
    "strategy": "Vector seul avec fallback (catégorie + typo)",
    "explanation": "Démontre la recherche avec contexte catégoriel : Vector Search capture la relation entre 'loyr' et 'habitation'."
}
```

---

### Catégorie 9 : Recherches avec Montants et Dates (Contexte)

**Principe** : Recherches avec contexte temporel ou montant.

#### Test 16 : Contexte temporel

```python
{
    "query": "virement permanent mensuel",
    "description": "Recherche avec contexte temporel: 'VIREMENT PERMANENT MENSUEL'",
    "expected": "Devrait trouver 'VIREMENT PERMANENT MENSUEL VERS LIVRET A' grâce à Full-Text + Vector",
    "strategy": "Full-Text + Vector (contexte temporel)",
    "explanation": "Démontre la recherche hybride avec contexte temporel : Full-Text filtre avec les termes, Vector améliore la pertinence."
}
```

---

### Catégorie 10 : Recherches avec Inversions de Caractères

**Principe** : Typos avec inversions de caractères (plus complexes).

#### Test 17 : Inversion de caractères

```python
{
    "query": "paris loyre",
    "description": "Recherche avec inversion: 'paris' + 'loyre' (inversion de 'loyer')",
    "expected": "Devrait trouver 'LOYER PARIS' grâce au Vector Search (fallback)",
    "strategy": "Vector seul avec fallback (inversion de caractères)",
    "explanation": "Démontre la tolérance aux inversions : Vector Search capture la similarité même avec inversion de caractères."
}
```

---

## 📊 Tableau Récapitulatif des Cas Complexes Proposés

| Catégorie | Nombre de Tests | Complexité | Valeur Ajoutée |
|-----------|----------------|-------------|----------------|
| **Typos Partielles** | 2 | ⭐⭐ Moyenne | Mixte Full-Text + Vector |
| **Multi-Termes (3+)** | 2 | ⭐⭐⭐ Élevée | Plusieurs termes avec typos |
| **Variations Linguistiques** | 2 | ⭐⭐⭐ Élevée | Pluriel/conjugaison + typo |
| **Recherches Contextuelles** | 2 | ⭐⭐⭐ Élevée | Contexte complet |
| **Synonymes Sémantiques** | 2 | ⭐⭐⭐⭐ Très Élevée | Similarité sémantique |
| **Noms Propres/Codes** | 2 | ⭐⭐ Moyenne | Codes + typos |
| **Localisation** | 2 | ⭐⭐ Moyenne | Géographie + typos |
| **Catégories/Types** | 1 | ⭐⭐⭐ Élevée | Contexte métier |
| **Contexte Temporel** | 1 | ⭐⭐ Moyenne | Temporalité |
| **Inversions** | 1 | ⭐⭐⭐ Élevée | Typos complexes |
| **TOTAL** | **17 tests** | | |

---

## 🎯 Recommandation : Tests à Ajouter

### Option 1 : Ajouter 5-7 Tests Complexes (Recommandé)

**Tests prioritaires à ajouter** :

1. **Test 7** : Typos partielles (LOYER impay) - ⭐⭐
2. **Test 8** : Trois termes avec typos (loyr impay paris) - ⭐⭐⭐
3. **Test 9** : Pluriel + typo (loyrs impay) - ⭐⭐⭐
4. **Test 10** : Contexte complet (loyr impay regularisation paris) - ⭐⭐⭐
5. **Test 11** : Synonyme sémantique (paiement carte) - ⭐⭐⭐⭐
6. **Test 12** : Nom propre + typo (ratp navigo) - ⭐⭐
7. **Test 13** : Localisation avec typos (carrefur parsi) - ⭐⭐

**Total** : 6 tests actuels + 7 nouveaux = **13 tests**

### Option 2 : Ajouter Tous les Tests (17 nouveaux)

**Avantages** :

- ✅ Couverture complète de tous les cas complexes
- ✅ Démonstration exhaustive des capacités
- ✅ Documentation très complète

**Inconvénients** :

- ⚠️ Temps d'exécution plus long
- ⚠️ Rapport très volumineux

---

## 💡 Implémentation Proposée

### Structure des Tests Complexes

```python
# Tests complexes à ajouter
complex_test_cases = [
    # Catégorie 1 : Typos Partielles
    {
        "query": "LOYER impay",
        "description": "Recherche mixte: 'LOYER' correct + 'impay' typo",
        "expected": "Devrait trouver 'LOYER IMPAYE' grâce à Full-Text pour LOYER + Vector pour impay",
        "strategy": "Full-Text partiel + Vector (terme avec typo)",
        "explanation": "Démontre la recherche hybride avec mixte : Full-Text filtre avec 'LOYER' (terme correct), puis Vector Search gère 'impay' (typo) pour améliorer la pertinence.",
        "complexity": "Moyenne",
        "category": "Typos Partielles"
    },
    {
        "query": "VIREMENT IMPAYE paris",
        "description": "Recherche mixte: 2 termes corrects + 'paris' typo",
        "expected": "Devrait trouver 'VIREMENT IMPAYE PARIS' grâce à Full-Text pour VIREMENT/IMPAYE + Vector pour paris",
        "strategy": "Full-Text partiel + Vector (terme avec typo)",
        "explanation": "Démontre la recherche hybride avec plusieurs termes corrects et un typo : Full-Text filtre avec les termes corrects, Vector gère le typo.",
        "complexity": "Moyenne",
        "category": "Typos Partielles"
    },

    # Catégorie 2 : Multi-Termes (3+)
    {
        "query": "loyr impay paris",
        "description": "Recherche 3 termes avec typos: 'loyr' + 'impay' + 'paris'",
        "expected": "Devrait trouver 'LOYER IMPAYE PARIS' grâce au Vector Search (fallback)",
        "strategy": "Vector seul avec fallback (typos multiples)",
        "explanation": "Démontre le fallback automatique avec plusieurs typos : Full-Text ne trouve rien, donc fallback sur Vector Search qui gère tous les typos simultanément.",
        "complexity": "Élevée",
        "category": "Multi-Termes"
    },
    {
        "query": "VIREMENT PERMANENT MENSUEL livret",
        "description": "Recherche 4 termes: 3 corrects + 1 typo possible",
        "expected": "Devrait trouver 'VIREMENT PERMANENT MENSUEL VERS LIVRET A'",
        "strategy": "Full-Text partiel + Vector (terme avec typo ou variation)",
        "explanation": "Démontre la recherche hybride avec plusieurs termes : Full-Text filtre avec les termes corrects, Vector gère les variations.",
        "complexity": "Élevée",
        "category": "Multi-Termes"
    },

    # Catégorie 3 : Variations Linguistiques
    {
        "query": "loyrs impay",
        "description": "Recherche avec pluriel typé: 'loyrs' (pluriel de 'loyer' avec typo) + 'impay'",
        "expected": "Devrait trouver 'LOYER IMPAYE' grâce au Vector Search (fallback)",
        "strategy": "Vector seul avec fallback (variation linguistique + typo)",
        "explanation": "Démontre la tolérance aux variations linguistiques avec typos : Full-Text ne gère pas bien 'loyrs', Vector Search capture la similarité sémantique.",
        "complexity": "Élevée",
        "category": "Variations Linguistiques"
    },

    # Catégorie 4 : Recherches Contextuelles
    {
        "query": "loyr impay regularisation paris",
        "description": "Recherche contextuelle 4 termes avec typos: contexte complet",
        "expected": "Devrait trouver 'LOYER IMPAYE REGULARISATION PARIS' grâce au Vector Search (fallback)",
        "strategy": "Vector seul avec fallback (contexte avec typos)",
        "explanation": "Démontre la recherche contextuelle avec typos : Vector Search capture le contexte global même avec plusieurs typos.",
        "complexity": "Élevée",
        "category": "Recherches Contextuelles"
    },

    # Catégorie 5 : Synonymes Sémantiques
    {
        "query": "paiement carte",
        "description": "Recherche avec synonyme: 'paiement' au lieu de 'CB' ou 'CARTE'",
        "expected": "Devrait trouver des opérations CB/CARTE grâce à la similarité sémantique",
        "strategy": "Full-Text + Vector (synonyme sémantique)",
        "explanation": "Démontre la recherche sémantique : Vector Search capture la similarité entre 'paiement' et 'CB'/'CARTE' même si les mots sont différents.",
        "complexity": "Très Élevée",
        "category": "Synonymes Sémantiques"
    },

    # Catégorie 6 : Noms Propres
    {
        "query": "ratp navigo",
        "description": "Recherche nom propre: 'RATP NAVIGO' (abréviations)",
        "expected": "Devrait trouver 'CB RATP NAVIGO MOIS' grâce à Full-Text + Vector",
        "strategy": "Full-Text + Vector (noms propres)",
        "explanation": "Démontre la recherche hybride avec noms propres : Full-Text filtre avec les abréviations, Vector améliore la pertinence.",
        "complexity": "Moyenne",
        "category": "Noms Propres"
    },

    # Catégorie 7 : Localisation
    {
        "query": "carrefur parsi",
        "description": "Recherche localisation avec typos: 'carrefur' + 'parsi'",
        "expected": "Devrait trouver 'CB CARREFOUR MARKET PARIS' grâce au Vector Search (fallback)",
        "strategy": "Vector seul avec fallback (localisation avec typos)",
        "explanation": "Démontre la recherche contextuelle avec typos : Vector Search capture le contexte géographique même avec typos.",
        "complexity": "Moyenne",
        "category": "Localisation"
    },
]
```

---

## 🔧 Modifications Nécessaires au Script

### 1. Améliorer la Logique de Fallback

**Problème actuel** : Le fallback est binaire (tout ou rien).

**Amélioration proposée** : Fallback partiel pour typos partielles.

```python
# Stratégie améliorée
def execute_hybrid_search(query_text, terms, query_embedding):
    # Essayer Full-Text avec tous les termes
    results = try_fulltext_vector(terms, query_embedding)

    if not results:
        # Fallback : Essayer Full-Text avec seulement les termes corrects
        correct_terms = [t for t in terms if is_correct_term(t)]
        if correct_terms:
            results = try_fulltext_vector(correct_terms, query_embedding)
            # Ensuite, filtrer avec Vector pour les typos
            results = filter_with_vector(results, query_embedding, typo_terms)

    if not results:
        # Fallback complet : Vector seul
        results = try_vector_only(query_embedding)

    return results
```

### 2. Améliorer le Mapping des Typos

**Problème actuel** : Mapping manuel limité.

**Amélioration proposée** : Détection automatique des typos + correction intelligente.

```python
# Détection automatique des typos
def detect_typos(term):
    """Détecte si un terme est une typo et propose des corrections."""
    # Utiliser la distance de Levenshtein
    # Comparer avec un dictionnaire de mots connus
    # Proposer les corrections les plus probables
    pass
```

### 3. Améliorer le Filtrage Côté Client

**Problème actuel** : Filtrage simple par correspondance exacte.

**Amélioration proposée** : Filtrage intelligent avec scoring.

```python
# Filtrage intelligent
def intelligent_filter(results, terms, query_embedding):
    """Filtre les résultats avec scoring intelligent."""
    scored_results = []
    for result in results:
        score = calculate_relevance_score(result, terms, query_embedding)
        scored_results.append((score, result))

    # Trier par score décroissant
    scored_results.sort(key=lambda x: x[0], reverse=True)
    return [r[1] for r in scored_results[:5]]
```

---

## 📊 Comparaison : Tests Actuels vs Tests Complexes

| Aspect | Tests Actuels | Tests Complexes Proposés |
|--------|---------------|---------------------------|
| **Nombre de tests** | 6 | 13-23 |
| **Complexité moyenne** | ⭐ Simple | ⭐⭐⭐ Élevée |
| **Types de cas** | 2 (correct, typo) | 10 catégories |
| **Valeur démonstrative** | ⭐⭐ Moyenne | ⭐⭐⭐⭐ Très Élevée |
| **Temps d'exécution** | ~30s | ~60-90s |
| **Couverture** | Basique | Exhaustive |

---

## ✅ Recommandation Finale

### **Ajouter 7 Tests Complexes Prioritaires**

**Raisons** :

1. ✅ Couvre les cas les plus importants
2. ✅ Temps d'exécution raisonnable (~60s)
3. ✅ Rapport de taille acceptable
4. ✅ Valeur démonstrative élevée

**Tests à ajouter** :

1. `LOYER impay` - Typos partielles
2. `loyr impay paris` - Multi-termes (3)
3. `loyrs impay` - Variations linguistiques
4. `loyr impay regularisation paris` - Contexte complet
5. `paiement carte` - Synonymes sémantiques
6. `ratp navigo` - Noms propres
7. `carrefur parsi` - Localisation avec typos

**Total** : 6 tests actuels + 7 nouveaux = **13 tests**

---

## 🎯 Prochaines Étapes

1. ✅ Valider la proposition avec l'utilisateur
2. ✅ Implémenter les 7 tests complexes
3. ✅ Améliorer la logique de fallback partiel
4. ✅ Tester et valider
5. ✅ Mettre à jour la documentation

---

**✅ Proposition terminée**
