# 🧪 Proposition de Tests Complexes et Très Complexes pour Script 40

**Date** : 2025-01-XX  
**Script** : `40_test_like_patterns.sh`  
**Objectif** : Étendre le script avec des tests complexes et très complexes basés sur les exigences inputs-clients et inputs-ibm

---

## 📋 Table des Matières

1. [Tests Complexes](#tests-complexes)
2. [Tests Très Complexes](#tests-très-complexes)
3. [Priorisation](#priorisation)
4. [Implémentation](#implémentation)

---

## 🎯 Tests Complexes

### Catégorie 1 : Recherche Hybride avec Filtres Multiples

#### TEST 6 : LIKE + Filtre Temporel (Range Query)

**Source** : inputs-ibm (Range Queries pattern)  
**Complexité** : ⭐⭐⭐

**Description** :

- Recherche LIKE sur libellé avec filtrage par plage de dates
- Combine recherche vectorielle + LIKE + filtres CQL (date >= X AND date <= Y)

**Exemple** :

```python
hybrid_like_search(
    query_text="loyer",
    like_query="libelle LIKE '%LOYER%'",
    filter_dict={"date_op": {"$gte": "2024-01-01", "$lte": "2024-12-31"}},
    limit=10
)
```

**Métriques attendues** :

- Temps d'exécution CQL (impact du filtre temporel)
- Nombre de résultats avant/après filtrage temporel
- Efficacité du filtrage combiné

---

#### TEST 7 : LIKE + Filtre Montant (Range Query)

**Source** : inputs-clients (RC-06)  
**Complexité** : ⭐⭐⭐

**Description** :

- Recherche LIKE avec filtrage par montant (ex: montant < -100 pour débits)
- Combine recherche vectorielle + LIKE + filtres numériques

**Exemple** :

```python
hybrid_like_search(
    query_text="restaurant",
    like_query="libelle LIKE '%RESTAURANT%'",
    filter_dict={"montant": {"$lte": -50}},  # Débits >= 50€
    limit=10
)
```

**Cas d'usage métier** :

- Trouver toutes les dépenses restaurant importantes (> 50€)
- Filtrer les opérations par montant pour analyse budgétaire

---

#### TEST 8 : LIKE + Filtre Catégorie (IN Clause)

**Source** : inputs-ibm (Field-Specific Queries)  
**Complexité** : ⭐⭐⭐

**Description** :

- Recherche LIKE avec filtrage par catégories multiples
- Combine recherche vectorielle + LIKE + filtre IN

**Exemple** :

```python
hybrid_like_search(
    query_text="alimentation",
    like_query="libelle LIKE '%CARREFOUR%'",
    filter_dict={"cat_auto": {"$in": ["ALIMENTATION", "RESTAURANT"]}},
    limit=10
)
```

**Cas d'usage métier** :

- Trouver les opérations Carrefour dans certaines catégories
- Analyse des dépenses par catégorie avec recherche textuelle

---

### Catégorie 2 : Recherche Multi-Champs avec Logique Booléenne

#### TEST 9 : Multi-Field LIKE avec AND (Tous les patterns doivent matcher)

**Source** : inputs-ibm (Boolean Search, Compound Queries)  
**Complexité** : ⭐⭐⭐⭐

**Description** :

- Recherche avec plusieurs patterns LIKE sur différents champs
- Tous les patterns doivent être satisfaits (logique AND)
- Utilise `multi_field_like_search` avec `match_all=True`

**Exemple** :

```python
multi_field_like_search(
    query_text="loyer impaye",
    like_queries=[
        "libelle LIKE '%LOYER%'",
        "libelle LIKE '%IMP%'"
    ],
    match_all=True,  # Les deux patterns doivent matcher
    limit=10
)
```

**Cas d'usage métier** :

- Trouver les opérations contenant "LOYER" ET "IMPAYE"
- Recherche précise avec plusieurs critères obligatoires

---

#### TEST 10 : Multi-Field LIKE avec OR (Au moins un pattern doit matcher)

**Source** : inputs-ibm (Boolean Search)  
**Complexité** : ⭐⭐⭐⭐

**Description** :

- Recherche avec plusieurs patterns LIKE sur différents champs
- Au moins un pattern doit être satisfait (logique OR)
- Utilise `multi_field_like_search` avec `match_all=False`

**Exemple** :

```python
multi_field_like_search(
    query_text="virement",
    like_queries=[
        "libelle LIKE '%VIREMENT%'",
        "cat_auto LIKE '%IR%'"
    ],
    match_all=False,  # Au moins un pattern doit matcher
    limit=10
)
```

**Cas d'usage métier** :

- Trouver les opérations contenant "VIREMENT" OU dans une catégorie contenant "IR"
- Recherche élargie avec alternatives

---

### Catégorie 3 : Recherche avec Typos et Variations

#### TEST 11 : LIKE avec Typos Simulés

**Source** : inputs-ibm (Fuzzy Logic Patterns, Typo Tolerance)  
**Complexité** : ⭐⭐⭐

**Description** :

- Recherche LIKE avec patterns contenant des erreurs de frappe
- Teste la robustesse de la recherche vectorielle face aux typos
- Combine recherche vectorielle (tolérante aux typos) + filtrage LIKE strict

**Exemples** :

```python
# Test avec typos dans le pattern LIKE
hybrid_like_search(
    query_text="loyr impay",  # Typos dans la recherche vectorielle
    like_query="libelle LIKE '%LOYER%'",  # Pattern LIKE correct
    limit=10
)

# Test avec typos dans le pattern LIKE lui-même
hybrid_like_search(
    query_text="loyer",
    like_query="libelle LIKE '%LOYR%'",  # Typo dans le pattern LIKE
    limit=10
)
```

**Cas d'usage métier** :

- Recherche avec saisie utilisateur imparfaite
- Tolérance aux erreurs de frappe dans les recherches

---

#### TEST 12 : LIKE avec Variations Linguistiques

**Source** : inputs-clients (RC-02, RC-04), inputs-ibm (Synonym Recognition)  
**Complexité** : ⭐⭐⭐

**Description** :

- Recherche avec variations de mots (synonymes, pluriels, accents)
- Teste la capacité de la recherche vectorielle à gérer les variations sémantiques

**Exemples** :

```python
# Recherche avec synonymes
hybrid_like_search(
    query_text="achat courses",  # Recherche vectorielle avec synonymes
    like_query="libelle LIKE '%CARREFOUR%'",  # Pattern spécifique
    limit=10
)

# Recherche avec accents
hybrid_like_search(
    query_text="restaurant paris",  # Sans accents
    like_query="libelle LIKE '%RESTAURANT%'",  # Pattern avec accents possibles
    limit=10
)
```

---

### Catégorie 4 : Recherche Contextuelle et Descriptions Étendues

#### TEST 13 : LIKE avec Description Étendue (Compound Query)

**Source** : inputs-ibm (Compound and Contextual Queries)  
**Complexité** : ⭐⭐⭐⭐

**Description** :

- Recherche avec requête textuelle très détaillée (plusieurs phrases)
- Le pattern LIKE doit toujours matcher malgré le contexte étendu
- Teste la capacité à extraire l'essentiel d'une description longue

**Exemple** :

```python
hybrid_like_search(
    query_text="Je cherche toutes les opérations liées au paiement du loyer mensuel de mon appartement à Paris, qui sont généralement des prélèvements automatiques effectués en début de mois",
    like_query="libelle LIKE '%LOYER%'",
    limit=10
)
```

**Cas d'usage métier** :

- Recherche avec description naturelle de l'utilisateur
- Extraction de l'intention depuis un texte libre

---

## 🔥 Tests Très Complexes

### Catégorie 5 : Recherche Hybride Multi-Critères Combinés

#### TEST 14 : LIKE + Filtres Multiples + Range Temporel + Range Montant

**Source** : inputs-ibm (Compound Queries), inputs-clients (RC-06)  
**Complexité** : ⭐⭐⭐⭐⭐

**Description** :

- Combine recherche vectorielle + LIKE + filtres temporels + filtres montant + filtres catégorie
- Teste la performance avec plusieurs filtres simultanés

**Exemple** :

```python
hybrid_like_search(
    query_text="restaurant paris",
    like_query="libelle LIKE '%RESTAURANT%'",
    filter_dict={
        "date_op": {"$gte": "2024-01-01", "$lte": "2024-12-31"},
        "montant": {"$lte": -20},  # Débits >= 20€
        "cat_auto": {"$in": ["RESTAURANT", "LOISIRS"]}
    },
    limit=10,
    vector_limit=500  # Augmenter pour compenser les filtres multiples
)
```

**Métriques critiques** :

- Temps total vs nombre de filtres
- Impact de chaque filtre sur le nombre de résultats
- Performance avec `vector_limit` élevé

---

#### TEST 15 : Multi-Field LIKE Complexe avec Filtres

**Source** : inputs-ibm (Compound Queries)  
**Complexité** : ⭐⭐⭐⭐⭐

**Description** :

- Multi-field LIKE (AND/OR) combiné avec filtres métier
- Teste la logique booléenne complexe

**Exemple** :

```python
multi_field_like_search(
    query_text="loyer impaye regularisation",
    like_queries=[
        "libelle LIKE '%LOYER%'",
        "libelle LIKE '%IMP%'",
        "libelle LIKE '%REGULAR%'"
    ],
    match_all=True,  # Tous les patterns doivent matcher
    filter_dict={
        "montant": {"$lte": -100},  # Montant significatif
        "date_op": {"$gte": "2024-01-01"}
    },
    limit=10
)
```

---

### Catégorie 6 : Recherche avec Patterns Regex Complexes

#### TEST 16 : LIKE avec Patterns Multi-Wildcards Complexes

**Source** : inputs-ibm (Complex Fuzzy Logic)  
**Complexité** : ⭐⭐⭐⭐⭐

**Description** :

- Patterns LIKE avec plusieurs wildcards et conditions complexes
- Teste la conversion regex et le filtrage client-side

**Exemples** :

```python
# Pattern avec wildcards multiples et séquences
hybrid_like_search(
    query_text="loyer",
    like_query="libelle LIKE '%LOYER%IMP%REGULAR%'",  # Contient LOYER puis IMP puis REGULAR
    limit=10
)

# Pattern avec wildcards au début, milieu et fin
hybrid_like_search(
    query_text="virement",
    like_query="libelle LIKE '*VIREMENT*IMP*'",  # Commence par n'importe quoi, contient VIREMENT et IMP
    limit=10
)
```

---

#### TEST 17 : LIKE avec Patterns Alternatifs (Regex-like)

**Source** : inputs-ibm (Boolean Search patterns)  
**Complexité** : ⭐⭐⭐⭐⭐

**Description** :

- Patterns LIKE simulant des alternatives (ex: "LOYER" OU "LOYERS")
- Nécessite plusieurs recherches combinées

**Exemple** :

```python
# Recherche avec alternatives (nécessite plusieurs appels)
results1 = hybrid_like_search(
    query_text="loyer",
    like_query="libelle LIKE '%LOYER%'",
    limit=10
)
results2 = hybrid_like_search(
    query_text="loyers",
    like_query="libelle LIKE '%LOYERS%'",
    limit=10
)
# Fusionner et dédupliquer les résultats
```

---

### Catégorie 7 : Recherche avec Performance et Volume

#### TEST 18 : LIKE avec Grand Volume de Candidats

**Source** : inputs-clients (RC-03), inputs-ibm (Performance)  
**Complexité** : ⭐⭐⭐⭐

**Description** :

- Teste la performance avec `vector_limit` très élevé
- Mesure l'impact du filtrage client-side sur un grand nombre de candidats

**Exemple** :

```python
hybrid_like_search(
    query_text="loyer",
    like_query="libelle LIKE '%LOYER%'",
    limit=10,
    vector_limit=1000  # Récupérer 1000 candidats avant filtrage
)
```

**Métriques critiques** :

- Temps de filtrage client-side vs nombre de candidats
- Efficacité du filtrage (ratio résultats finaux / candidats)
- Scalabilité avec volume croissant

---

#### TEST 19 : LIKE avec Patterns Très Sélectifs

**Source** : inputs-ibm (Precision Search)  
**Complexité** : ⭐⭐⭐⭐

**Description** :

- Patterns LIKE très spécifiques qui filtrent beaucoup
- Teste l'efficacité quand peu de résultats matchent

**Exemple** :

```python
hybrid_like_search(
    query_text="loyer impaye regularisation paris",
    like_query="libelle LIKE '%LOYER%IMP%REGULAR%PARIS%'",  # Pattern très spécifique
    limit=10,
    vector_limit=500
)
```

**Métriques critiques** :

- Ratio de filtrage (combien de candidats sont conservés)
- Performance avec patterns très sélectifs

---

### Catégorie 8 : Recherche avec Cas Limites et Robustesse

#### TEST 20 : LIKE avec Caractères Spéciaux

**Source** : inputs-clients (RC-07)  
**Complexité** : ⭐⭐⭐

**Description** :

- Patterns LIKE contenant des caractères spéciaux (é, è, ê, ç, etc.)
- Teste la gestion des accents et caractères Unicode

**Exemples** :

```python
# Pattern avec accents
hybrid_like_search(
    query_text="restaurant",
    like_query="libelle LIKE '%RESTAURANT%'",  # Peut contenir des accents dans les données
    limit=10
)

# Pattern avec caractères spéciaux
hybrid_like_search(
    query_text="café",
    like_query="libelle LIKE '%CAFE%'",  # Recherche sans accent, données avec accent
    limit=10
)
```

---

#### TEST 21 : LIKE avec Patterns Vides ou Invalides

**Source** : inputs-clients (RC-07)  
**Complexité** : ⭐⭐

**Description** :

- Teste la gestion d'erreurs avec patterns invalides
- Validation de la robustesse

**Exemples** :

```python
# Pattern vide
try:
    hybrid_like_search(
        query_text="test",
        like_query="libelle LIKE '%%'",  # Pattern vide
        limit=10
    )
except ValueError as e:
    print(f"Erreur attendue: {e}")

# Pattern invalide (sans LIKE)
try:
    hybrid_like_search(
        query_text="test",
        like_query="libelle = 'TEST'",  # Pas de LIKE
        limit=10
    )
except ValueError as e:
    print(f"Erreur attendue: {e}")
```

---

#### TEST 22 : LIKE avec Données NULL ou Manquantes

**Source** : inputs-clients (RC-07)  
**Complexité** : ⭐⭐⭐

**Description** :

- Teste le comportement avec champs NULL ou manquants
- Robustesse face aux données incomplètes

**Exemple** :

```python
# Recherche sur un champ qui peut être NULL
hybrid_like_search(
    query_text="test",
    like_query="cat_auto LIKE '%TEST%'",  # cat_auto peut être NULL
    limit=10
)
```

---

## 📊 Priorisation

### Priorité 🔴 Critique (À implémenter en premier)

1. **TEST 6** : LIKE + Filtre Temporel (Range Query)
2. **TEST 7** : LIKE + Filtre Montant (Range Query)
3. **TEST 9** : Multi-Field LIKE avec AND
4. **TEST 14** : LIKE + Filtres Multiples Combinés

**Justification** : Ces tests couvrent les cas d'usage les plus fréquents mentionnés dans inputs-ibm et inputs-clients.

---

### Priorité 🟡 Haute (À implémenter ensuite)

5. **TEST 8** : LIKE + Filtre Catégorie (IN Clause)
6. **TEST 10** : Multi-Field LIKE avec OR
7. **TEST 11** : LIKE avec Typos Simulés
8. **TEST 18** : LIKE avec Grand Volume

**Justification** : Ces tests valident des fonctionnalités importantes pour la robustesse et la performance.

---

### Priorité 🟢 Moyenne (Implémentation optionnelle)

9. **TEST 12** : LIKE avec Variations Linguistiques
10. **TEST 13** : LIKE avec Description Étendue
11. **TEST 15** : Multi-Field LIKE Complexe avec Filtres
12. **TEST 16** : LIKE avec Patterns Multi-Wildcards Complexes
13. **TEST 19** : LIKE avec Patterns Très Sélectifs
14. **TEST 20** : LIKE avec Caractères Spéciaux

**Justification** : Ces tests couvrent des cas avancés moins fréquents mais utiles pour la validation complète.

---

### Priorité ⚪ Basse (Implémentation future)

15. **TEST 17** : LIKE avec Patterns Alternatifs
16. **TEST 21** : LIKE avec Patterns Vides ou Invalides
17. **TEST 22** : LIKE avec Données NULL

**Justification** : Tests de robustesse et cas limites, moins critiques pour la démonstration initiale.

---

## 🛠️ Implémentation

### Modifications Nécessaires

#### 1. Extension de `like_wildcard_search.py`

**Fonction existante à étendre** :

- `hybrid_like_search` : ✅ Déjà supporte `filter_dict`
- `multi_field_like_search` : ✅ Déjà implémentée

**Nouvelles fonctions à ajouter** (optionnel) :

- `hybrid_search_with_ranges` : Wrapper pour simplifier les range queries
- `validate_like_pattern` : Validation des patterns LIKE avant exécution

#### 2. Extension de `40_test_like_patterns.sh`

**Structure à ajouter** :

- Section "Tests Complexes" après les tests de base
- Section "Tests Très Complexes" après les tests complexes
- Métriques de performance détaillées pour chaque test complexe
- Tableau comparatif des performances

#### 3. Génération de Rapport Améliorée

**Nouvelles sections dans le rapport** :

- Analyse comparative des performances (tests simples vs complexes)
- Impact des filtres multiples sur la latence
- Recommandations d'optimisation basées sur les métriques

---

## 📈 Métriques Supplémentaires pour Tests Complexes

Pour chaque test complexe, ajouter :

1. **Métriques de Filtrage** :
   - Nombre de candidats avant chaque filtre
   - Nombre de candidats après chaque filtre
   - Efficacité de chaque filtre (% de réduction)

2. **Métriques de Performance** :
   - Temps d'exécution CQL avec/sans filtres
   - Temps de filtrage client-side par type de filtre
   - Impact de `vector_limit` sur les performances

3. **Métriques de Qualité** :
   - Précision des résultats (pertinence)
   - Rappel (recall) si applicable
   - Ratio résultats pertinents / résultats totaux

---

## 🎯 Cas d'Usage Métier Couverts

### Inputs-Clients

| Requirement | Test(s) Correspondant(s) |
|-------------|---------------------------|
| RC-01 : Recherche avec typos | TEST 11 |
| RC-02 : Recherche sémantique | TEST 12, TEST 13 |
| RC-03 : Performance acceptable | TEST 18 |
| RC-04 : Support accents | TEST 20 |
| RC-05 : Recherche multi-mots | TEST 9, TEST 10 |
| RC-06 : Recherche avec filtres | TEST 6, TEST 7, TEST 8, TEST 14 |
| RC-07 : Robustesse | TEST 21, TEST 22 |
| RC-08 : Cohérence | Tous les tests (métriques de cohérence) |

### Inputs-IBM

| Pattern IBM | Test(s) Correspondant(s) |
|-------------|---------------------------|
| Exact Phrase Search | TEST 9 (match_all=True) |
| Boolean Search | TEST 9, TEST 10 |
| Range Queries | TEST 6, TEST 7 |
| Field-Specific Queries | TEST 8 |
| Synonym Recognition | TEST 12 |
| Compound Queries | TEST 13, TEST 14, TEST 15 |
| Fuzzy Logic Patterns | TEST 11, TEST 16 |

---

## ✅ Validation

Chaque test complexe doit :

1. ✅ Être documenté avec cas d'usage métier clair
2. ✅ Inclure des métriques de performance détaillées
3. ✅ Générer des résultats reproductibles
4. ✅ Être intégré dans le rapport markdown généré
5. ✅ Suivre les standards de qualité du projet

---

## 📝 Notes d'Implémentation

### Ordre Recommandé d'Implémentation

1. **Phase 1** (Tests Complexes Prioritaires) :
   - TEST 6, TEST 7, TEST 9, TEST 14

2. **Phase 2** (Tests Complexes Secondaires) :
   - TEST 8, TEST 10, TEST 11, TEST 18

3. **Phase 3** (Tests Très Complexes) :
   - TEST 15, TEST 16, TEST 19

4. **Phase 4** (Tests de Robustesse) :
   - TEST 20, TEST 21, TEST 22

### Estimation

- **Phase 1** : 2-3 heures
- **Phase 2** : 2-3 heures
- **Phase 3** : 3-4 heures
- **Phase 4** : 1-2 heures

**Total estimé** : 8-12 heures de développement

---

**Document créé pour guider l'extension du script 40 avec des tests complexes et très complexes basés sur les exigences inputs-clients et inputs-ibm.**
