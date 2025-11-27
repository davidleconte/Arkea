# 🎯 Proposition : Amélioration de la Pertinence des Résultats

**Date** : 2025-11-26  
**Script concerné** : `25_test_hybrid_search_v2_didactique.sh`  
**Objectif** : Améliorer le calcul de pertinence pour obtenir de meilleurs résultats

---

## 📊 Analyse de la Logique Actuelle

### Fonction `fuzzy_match()` Actuelle

```python
def fuzzy_match(term, text):
    """Calcule un score de correspondance floue entre un terme et un texte."""
    # Correspondance exacte : score 10
    # Variations de typos : score 8
    # Préfixe : score 5
    # Distance Levenshtein simplifiée : score 3
    # Sinon : score 0
```

### Système de Scoring Actuel

1. **Score par terme** : Somme des scores `fuzzy_match()` pour chaque terme
2. **Bonus multi-termes** :
   - Tous les termes matchent : +100
   - Plusieurs termes matchent : +10
   - Un seul terme matche : -5
3. **Tri** : Par score décroissant, puis par index original (ordre Vector Search)

### Limitations Identifiées

1. **Distance de Levenshtein simplifiée** : Ne gère que 1 caractère différent
2. **Pas de pondération par position** : Un terme au début n'est pas plus important
3. **Pas de similarité cosinus** : N'utilise pas la similarité vectorielle réelle
4. **Pas de TF-IDF** : Tous les termes ont le même poids
5. **Pas de score de longueur** : Les libellés courts ne sont pas favorisés
6. **Pas de score sémantique** : N'utilise pas la similarité entre embeddings complets

---

## 🎯 Améliorations Proposées

### Amélioration 1 : Distance de Levenshtein Complète

**Problème** : La version simplifiée ne gère que 1 caractère différent.

**Solution** : Implémenter la distance de Levenshtein complète avec seuil adaptatif.

```python
def levenshtein_distance(s1, s2):
    """Calcule la distance de Levenshtein entre deux chaînes."""
    if len(s1) < len(s2):
        return levenshtein_distance(s2, s1)
    
    if len(s2) == 0:
        return len(s1)
    
    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row
    
    return previous_row[-1]

def fuzzy_match_levenshtein(term, text, max_distance=None):
    """Calcule un score basé sur la distance de Levenshtein."""
    if max_distance is None:
        max_distance = max(1, len(term) // 3)  # Seuil adaptatif
    
    # Chercher la meilleure correspondance dans le texte
    best_score = float('inf')
    term_lower = term.lower()
    text_lower = text.lower()
    
    # Essayer toutes les sous-chaînes de la longueur du terme
    for i in range(len(text_lower) - len(term_lower) + 1):
        substring = text_lower[i:i+len(term_lower)]
        distance = levenshtein_distance(term_lower, substring)
        if distance < best_score:
            best_score = distance
    
    if best_score <= max_distance:
        # Score inversement proportionnel à la distance
        # Distance 0 → score 10, distance 1 → score 8, distance 2 → score 6, etc.
        return max(0, 10 - (best_score * 2))
    
    return 0
```

**Avantages** :
- ✅ Gère les typos avec plusieurs caractères différents
- ✅ Seuil adaptatif selon la longueur du terme
- ✅ Score proportionnel à la distance

---

### Amélioration 2 : Score de Position

**Problème** : Un terme au début d'un libellé n'est pas plus important qu'un terme à la fin.

**Solution** : Ajouter un bonus pour les termes trouvés au début.

```python
def position_score(term, text, match_position):
    """Calcule un bonus basé sur la position du match dans le texte."""
    text_length = len(text)
    if text_length == 0:
        return 0
    
    # Position normalisée (0 = début, 1 = fin)
    normalized_position = match_position / text_length
    
    # Bonus décroissant : début = +3, milieu = +1, fin = +0
    if normalized_position < 0.2:  # Premier 20%
        return 3
    elif normalized_position < 0.5:  # Premier 50%
        return 1
    else:
        return 0
```

**Avantages** :
- ✅ Favorise les résultats où les termes importants sont au début
- ✅ Améliore la pertinence pour les recherches de noms propres

---

### Amélioration 3 : Similarité Cosinus entre Embeddings

**Problème** : Le score actuel n'utilise pas la similarité vectorielle réelle.

**Solution** : Calculer la similarité cosinus entre l'embedding de la requête et celui du libellé.

```python
import numpy as np

def cosine_similarity(vec1, vec2):
    """Calcule la similarité cosinus entre deux vecteurs."""
    dot_product = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    
    if norm1 == 0 or norm2 == 0:
        return 0
    
    return dot_product / (norm1 * norm2)

def vector_similarity_score(query_embedding, libelle_embedding):
    """Calcule un score basé sur la similarité vectorielle."""
    if libelle_embedding is None:
        return 0
    
    similarity = cosine_similarity(query_embedding, libelle_embedding)
    
    # Convertir la similarité (-1 à 1) en score (0 à 10)
    # Similarité 1.0 → score 10, similarité 0.8 → score 8, etc.
    return max(0, similarity * 10)
```

**Avantages** :
- ✅ Utilise la similarité sémantique réelle
- ✅ Capture les synonymes et variations
- ✅ Complète le scoring lexical

---

### Amélioration 4 : TF-IDF pour Pondération des Termes

**Problème** : Tous les termes ont le même poids, même les mots courants.

**Solution** : Utiliser TF-IDF pour pondérer les termes selon leur rareté.

```python
def calculate_tfidf_score(term, text, all_texts):
    """Calcule un score TF-IDF pour un terme dans un texte."""
    # TF (Term Frequency) : Fréquence du terme dans le texte
    term_lower = term.lower()
    text_lower = text.lower()
    tf = text_lower.count(term_lower) / max(1, len(text_lower.split()))
    
    # IDF (Inverse Document Frequency) : Rareté du terme
    # Compter dans combien de textes le terme apparaît
    docs_with_term = sum(1 for t in all_texts if term_lower in t.lower())
    idf = np.log(len(all_texts) / max(1, docs_with_term))
    
    # Score TF-IDF
    tfidf = tf * idf
    
    # Normaliser en score 0-5
    return min(5, tfidf * 10)
```

**Avantages** :
- ✅ Favorise les termes rares (plus informatifs)
- ✅ Réduit l'importance des mots courants
- ✅ Améliore la pertinence pour les recherches spécialisées

---

### Amélioration 5 : Score de Longueur

**Problème** : Les libellés courts ne sont pas favorisés.

**Solution** : Ajouter un bonus pour les libellés de longueur appropriée.

```python
def length_score(libelle, query_terms):
    """Calcule un bonus basé sur la longueur du libellé."""
    libelle_length = len(libelle.split())
    query_length = len(query_terms)
    
    # Longueur idéale : 1.5x à 3x la longueur de la requête
    ideal_min = query_length * 1.5
    ideal_max = query_length * 3
    
    if ideal_min <= libelle_length <= ideal_max:
        return 2  # Bonus pour longueur idéale
    elif libelle_length < ideal_min:
        return 1  # Légèrement trop court
    else:
        return 0  # Trop long
```

**Avantages** :
- ✅ Favorise les résultats concis et pertinents
- ✅ Évite les libellés trop longs (moins pertinents)

---

### Amélioration 6 : Score Combiné Multi-Facteurs

**Solution** : Combiner tous les scores avec des poids adaptatifs.

```python
def calculate_combined_relevance_score(
    query_text, query_embedding, libelle, libelle_embedding,
    all_libelles, query_terms
):
    """Calcule un score de pertinence combiné multi-facteurs."""
    
    total_score = 0
    libelle_lower = libelle.lower()
    
    # 1. Score lexical (fuzzy_match amélioré) : 40%
    lexical_score = 0
    for term in query_terms:
        term_score = fuzzy_match_levenshtein(term, libelle_lower)
        position = libelle_lower.find(term.lower())
        if position >= 0:
            term_score += position_score(term, libelle_lower, position)
        lexical_score += term_score
    lexical_score = min(10, lexical_score / len(query_terms))  # Normaliser
    total_score += lexical_score * 0.4
    
    # 2. Score vectoriel (similarité cosinus) : 40%
    vector_score = vector_similarity_score(query_embedding, libelle_embedding)
    total_score += vector_score * 0.4
    
    # 3. Score TF-IDF : 10%
    tfidf_score = 0
    for term in query_terms:
        tfidf_score += calculate_tfidf_score(term, libelle, all_libelles)
    tfidf_score = min(10, tfidf_score / len(query_terms))  # Normaliser
    total_score += tfidf_score * 0.1
    
    # 4. Score de longueur : 10%
    length_bonus = length_score(libelle, query_terms)
    total_score += length_bonus * 0.1
    
    # 5. Bonus multi-termes (conservé)
    matched_terms = sum(1 for term in query_terms 
                       if fuzzy_match_levenshtein(term, libelle_lower) > 0)
    if len(query_terms) > 1:
        if matched_terms == len(query_terms):
            total_score += 20  # Tous les termes matchent
        elif matched_terms > 1:
            total_score += 5   # Plusieurs termes matchent
    
    return total_score
```

**Avantages** :
- ✅ Combine plusieurs facteurs de pertinence
- ✅ Poids adaptatifs selon l'importance
- ✅ Meilleure pertinence globale

---

### Amélioration 7 : Filtrage Adaptatif par Seuil

**Problème** : Le filtrage actuel garde tous les résultats, même peu pertinents.

**Solution** : Filtrer les résultats en dessous d'un seuil de pertinence.

```python
def filter_by_relevance_threshold(results, scores, min_score=3.0):
    """Filtre les résultats en dessous d'un seuil de pertinence."""
    filtered = []
    for result, score in zip(results, scores):
        if score >= min_score:
            filtered.append((result, score))
    
    # Trier par score décroissant
    filtered.sort(key=lambda x: x[1], reverse=True)
    
    return [r for r, s in filtered]
```

**Avantages** :
- ✅ Élimine les résultats peu pertinents
- ✅ Améliore la qualité des résultats retournés

---

## 📊 Comparaison : Avant vs Après

| Aspect | Avant | Après |
|--------|-------|-------|
| **Distance de Levenshtein** | Simplifiée (1 caractère) | Complète (adaptative) |
| **Score de position** | ❌ Non | ✅ Oui |
| **Similarité vectorielle** | ❌ Non | ✅ Oui (cosinus) |
| **TF-IDF** | ❌ Non | ✅ Oui |
| **Score de longueur** | ❌ Non | ✅ Oui |
| **Score combiné** | Lexical seul | Multi-facteurs |
| **Filtrage par seuil** | ❌ Non | ✅ Oui |

---

## 🎯 Implémentation Proposée

### Étape 1 : Ajouter les Fonctions d'Amélioration

Créer un module Python séparé `relevance_scoring.py` avec toutes les fonctions améliorées.

### Étape 2 : Intégrer dans le Script 25

Modifier la section de filtrage côté client pour utiliser le nouveau système de scoring.

### Étape 3 : Tests et Validation

Tester avec les 23 tests existants et comparer les résultats avant/après.

### Étape 4 : Ajustement des Poids

Ajuster les poids des différents facteurs selon les résultats des tests.

---

## 💡 Recommandations

### Priorité Haute

1. **Distance de Levenshtein complète** : Impact immédiat sur les typos
2. **Similarité cosinus** : Utilise déjà les embeddings générés
3. **Score combiné multi-facteurs** : Améliore significativement la pertinence

### Priorité Moyenne

4. **Score de position** : Améliore la pertinence pour les noms propres
5. **Filtrage par seuil** : Améliore la qualité des résultats

### Priorité Basse

6. **TF-IDF** : Nécessite de calculer sur tous les libellés (coût computationnel)
7. **Score de longueur** : Impact limité mais facile à implémenter

---

## 📝 Prochaines Étapes

1. ✅ Valider la proposition avec l'utilisateur
2. ✅ Implémenter les améliorations prioritaires
3. ✅ Tester et comparer les résultats
4. ✅ Ajuster les poids selon les résultats
5. ✅ Documenter les améliorations

---

**✅ Proposition terminée**



