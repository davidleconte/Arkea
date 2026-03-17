# 🔍 Tests Supplémentaires pour Fuzzy Search avec Vector Search

**Date** : 2025-01-XX
**Dernière mise à jour** : 2025-01-XX
**Version** : 2.0
**Cas d'usage** : Recherche floue avec ByteT5 et HCD
**Script actuel** : `16_test_fuzzy_search.sh`

**Références Inputs-IBM** :
- Section "Recherche vectorielle pour requêtes sémantiques avancées" - Vector Search avec HCD
- Section "Recherche full-text intégrée avec CQL analyzers" - Full-text search avec analyzers Lucene

**Références Inputs-Clients** :
- Section "Catégorisation des opérations" - Besoins de recherche par libellé avec tolérance aux typos

**Scripts Associés** :
- `16_test_fuzzy_search.sh` - Tests fuzzy search
- `17_demonstration_fuzzy_search.sh` - Démonstration fuzzy search complète
- `18_test_hybrid_search.sh` - Tests recherche hybride

---

## 📋 Résumé des Tests Actuels

### Tests Implémentés (Script 16)

1. ✅ **Recherches avec typos** (caractères manquants, inversés)
   - 'loyr impay' au lieu de 'loyer impayé'
   - 'loyr parsi' au lieu de 'loyer paris'
   - 'viremnt impay' au lieu de 'virement impayé'
   - 'carrefur' au lieu de 'carrefour'
   - 'paiemnt cart' au lieu de 'paiement carte'

2. ✅ **Recherches correctes** (baseline)
   - 'LOYER IMPAYE'
   - 'LOYER PARIS'
   - 'VIREMENT IMPAYE'
   - 'CARREFOUR'
   - 'PAIEMENT CARTE'

---

## 🎯 Tests Supplémentaires Recommandés

### 1. **Tests de Performance** ⚠️ MANQUANT

**Objectif** : Mesurer la latence et le débit de la recherche vectorielle

**Tests à Ajouter** :
- ⏱️ **Latence moyenne** : Mesurer le temps de réponse pour 100 requêtes
- ⏱️ **Latence P95/P99** : Mesurer les latences aux percentiles 95 et 99
- 📊 **Débit** : Nombre de requêtes par seconde supportées
- 📊 **Temps de génération d'embedding** : Temps pour encoder une requête avec ByteT5
- 📊 **Temps de recherche HCD** : Temps d'exécution de la requête ANN seule
- 📊 **Temps total** : De la requête utilisateur au résultat final

**Métriques Attendues** :
- Latence moyenne : < 100ms
- Latence P95 : < 200ms
- Latence P99 : < 500ms
- Débit : > 10 requêtes/seconde

**Implémentation** :
```python
import time
import statistics

def benchmark_search(session, queries, iterations=100):
    latencies = []
    for _ in range(iterations):
        for query in queries:
            start = time.time()
            # Recherche vectorielle
            results = vector_search(session, query_embedding, code_si, contrat)
            latency = (time.time() - start) * 1000  # ms
            latencies.append(latency)

    return {
        'mean': statistics.mean(latencies),
        'p95': statistics.quantiles(latencies, n=20)[18],
        'p99': statistics.quantiles(latencies, n=100)[98],
        'throughput': len(queries) * iterations / sum(latencies) * 1000
    }
```

---

### 2. **Tests de Précision/Recall** ⚠️ MANQUANT

**Objectif** : Évaluer la qualité des résultats retournés

**Tests à Ajouter** :
- 🎯 **Précision** : Pourcentage de résultats pertinents parmi ceux retournés
- 🎯 **Recall** : Pourcentage de résultats pertinents trouvés parmi tous les pertinents
- 🎯 **F1-Score** : Moyenne harmonique de précision et recall
- 🎯 **MRR (Mean Reciprocal Rank)** : Position moyenne du premier résultat pertinent
- 🎯 **NDCG (Normalized Discounted Cumulative Gain)** : Qualité du classement des résultats

**Jeu de Test Recommandé** :
- 50 requêtes avec résultats attendus annotés manuellement
- Comparaison résultats attendus vs résultats obtenus

**Implémentation** :
```python
def evaluate_precision_recall(expected_results, actual_results):
    relevant_found = len(set(expected_results) & set(actual_results))
    precision = relevant_found / len(actual_results) if actual_results else 0
    recall = relevant_found / len(expected_results) if expected_results else 0
    f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
    return {'precision': precision, 'recall': recall, 'f1': f1}
```

---

### 3. **Tests avec Accents/Diacritiques** ⚠️ MANQUANT

**Objectif** : Vérifier la robustesse aux accents et caractères spéciaux

**Tests à Ajouter** :
- ✅ 'PAIEMENT CAFE' vs 'PAIEMENT CAFÉ' (accent aigu)
- ✅ 'RESTAURANT PARIS' vs 'RESTAURANT PARÎS' (accent circonflexe)
- ✅ 'VIREMENT COMPTE' vs 'VIREMENT COMPTÉ' (accent aigu final)
- ✅ 'LOYER PAYE' vs 'LOYER PAYÉ' (accent aigu)
- ✅ 'CARTE CREDIT' vs 'CARTE CRÉDIT' (accent aigu)

**Résultats Attendus** :
- Les deux variantes (avec/sans accent) doivent retourner des résultats similaires
- La recherche doit être insensible aux accents

---

### 4. **Tests avec Abréviations** ⚠️ MANQUANT

**Objectif** : Vérifier la compréhension des abréviations courantes

**Tests à Ajouter** :
- ✅ 'CB' vs 'CARTE BLEUE' vs 'CARTE BANCAIRE'
- ✅ 'VIREMENT' vs 'VIRT' vs 'VIR'
- ✅ 'PAIEMENT' vs 'PAYMT' vs 'PAY'
- ✅ 'RESTAURANT' vs 'RESTAU' vs 'REST'
- ✅ 'SUPERMARCHE' vs 'SUPER' vs 'SUP'

**Résultats Attendus** :
- Les abréviations doivent trouver les libellés complets correspondants
- Score de similarité acceptable (> 0.7)

---

### 5. **Tests avec Synonymes** ⚠️ MANQUANT

**Objectif** : Vérifier la compréhension sémantique (synonymes)

**Tests à Ajouter** :
- ✅ 'LOYER' vs 'LOCATION' vs 'LOUER'
- ✅ 'PAIEMENT' vs 'REGLEMENT' vs 'VERSEMENT'
- ✅ 'RESTAURANT' vs 'BRASSERIE' vs 'BISTROT'
- ✅ 'SUPERMARCHE' vs 'HYPERMARCHE' vs 'EPICERIE'
- ✅ 'VIREMENT' vs 'TRANSFERT' vs 'VERSEMENT'

**Résultats Attendus** :
- Les synonymes doivent retourner des résultats pertinents
- Score de similarité acceptable (> 0.6)

---

### 6. **Tests Comparatifs : Vector vs Full-Text** ⚠️ MANQUANT

**Objectif** : Comparer les performances et résultats entre Vector Search et Full-Text Search

**Tests à Ajouter** :
- 📊 **Même requête** : Comparer résultats Vector vs Full-Text
- 📊 **Requête avec typo** : Vector doit trouver, Full-Text ne trouve pas
- 📊 **Requête exacte** : Full-Text doit être plus rapide et précis
- 📊 **Latence** : Comparer temps de réponse
- 📊 **Pertinence** : Comparer qualité des résultats

**Implémentation** :
```python
def compare_vector_vs_fulltext(session, query, code_si, contrat):
    # Vector Search
    start_vector = time.time()
    vector_results = vector_search(session, query_embedding, code_si, contrat)
    vector_time = time.time() - start_vector

    # Full-Text Search
    start_ft = time.time()
    ft_results = fulltext_search(session, query, code_si, contrat)
    ft_time = time.time() - start_ft

    return {
        'vector': {'results': vector_results, 'time': vector_time},
        'fulltext': {'results': ft_results, 'time': ft_time}
    }
```

---

### 7. **Tests de Limites** ⚠️ MANQUANT

**Objectif** : Tester les limites et cas limites de la recherche

**Tests à Ajouter** :
- 🔢 **Limite de résultats** : Tester avec LIMIT 1, 5, 10, 50, 100
- 🔢 **Requête vide** : Comportement avec requête vide ou None
- 🔢 **Requête très longue** : Requête de 500+ caractères
- 🔢 **Requête très courte** : Requête d'un seul caractère
- 🔢 **Requête avec chiffres** : 'CB 1234' vs 'CARTE BLEUE 1234'
- 🔢 **Requête avec caractères spéciaux** : 'PAIEMENT #123' vs 'PAIEMENT 123'
- 🔢 **Requête avec emojis** : 'PAIEMENT 😊' (comportement attendu)

**Résultats Attendus** :
- Gestion gracieuse des cas limites
- Pas d'erreur système
- Résultats cohérents

---

### 8. **Tests de Cohérence** ⚠️ MANQUANT

**Objectif** : Vérifier la cohérence des résultats (même requête = mêmes résultats)

**Tests à Ajouter** :
- 🔄 **Même requête répétée** : 10 fois la même requête, résultats identiques
- 🔄 **Ordre des résultats** : L'ordre doit être stable (même score = même ordre)
- 🔄 **Résultats déterministes** : Pas de variation aléatoire

**Implémentation** :
```python
def test_consistency(session, query, iterations=10):
    results_list = []
    for _ in range(iterations):
        results = vector_search(session, query_embedding, code_si, contrat)
        results_list.append([r.libelle for r in results])

    # Vérifier que tous les résultats sont identiques
    first = results_list[0]
    all_same = all(r == first for r in results_list)
    return all_same
```

---

### 9. **Tests avec Données Volumineuses** ⚠️ MANQUANT

**Objectif** : Tester la performance avec un grand volume de données

**Tests à Ajouter** :
- 📊 **10K opérations** : Latence acceptable (< 200ms)
- 📊 **100K opérations** : Latence acceptable (< 500ms)
- 📊 **1M opérations** : Latence acceptable (< 2s)
- 📊 **Scalabilité** : Latence augmente linéairement avec le volume

**Métriques Attendues** :
- Latence < 200ms pour 10K opérations
- Latence < 500ms pour 100K opérations
- Latence < 2s pour 1M opérations

---

### 10. **Tests avec Différentes Langues** ⚠️ MANQUANT

**Objectif** : Vérifier le support multilingue de ByteT5

**Tests à Ajouter** :
- 🌍 **Français** : 'LOYER IMPAYE' (déjà testé)
- 🌍 **Anglais** : 'UNPAID RENT' vs 'LOYER IMPAYE'
- 🌍 **Espagnol** : 'ALQUILER IMPAGADO' vs 'LOYER IMPAYE'
- 🌍 **Mélange** : 'LOYER UNPAID' (français + anglais)

**Résultats Attendus** :
- ByteT5 doit comprendre les différentes langues
- Résultats pertinents même avec mélange de langues

---

### 11. **Tests avec Requêtes Multi-Mots vs Mots Uniques** ⚠️ MANQUANT

**Objectif** : Comparer la pertinence selon le nombre de mots

**Tests à Ajouter** :
- 📝 **Mot unique** : 'LOYER' vs 'PAIEMENT' vs 'VIREMENT'
- 📝 **Deux mots** : 'LOYER IMPAYE' vs 'PAIEMENT CARTE'
- 📝 **Trois mots** : 'LOYER IMPAYE PARIS' vs 'PAIEMENT CARTE BANCAIRE'
- 📝 **Plusieurs mots** : 'VIREMENT COMPTE BANCAIRE PARIS'

**Résultats Attendus** :
- Plus de mots = meilleure précision
- Moins de mots = meilleur recall

---

### 12. **Tests de Robustesse** ⚠️ MANQUANT

**Objectif** : Tester la robustesse face aux requêtes malformées

**Tests à Ajouter** :
- 🛡️ **Requête NULL** : Gestion gracieuse
- 🛡️ **Requête avec caractères invalides** : Gestion gracieuse
- 🛡️ **Requête avec injection SQL** : Sécurité (pas d'injection)
- 🛡️ **Requête avec caractères Unicode** : Gestion correcte
- 🛡️ **Requête avec espaces multiples** : Normalisation correcte

**Résultats Attendus** :
- Pas d'erreur système
- Gestion gracieuse des erreurs
- Messages d'erreur clairs

---

### 13. **Tests avec Seuils de Similarité** ⚠️ MANQUANT

**Objectif** : Tester différents seuils de similarité pour filtrer les résultats

**Tests à Ajouter** :
- 🎯 **Seuil 0.9** : Résultats très similaires uniquement
- 🎯 **Seuil 0.7** : Résultats similaires (recommandé)
- 🎯 **Seuil 0.5** : Résultats peu similaires (trop permissif)
- 🎯 **Seuil 0.3** : Résultats très peu similaires (non pertinent)

**Implémentation** :
```python
def vector_search_with_threshold(session, query_embedding, code_si, contrat, threshold=0.7, limit=5):
    # Recherche avec seuil de similarité
    results = vector_search(session, query_embedding, code_si, contrat, limit=limit*2)
    # Filtrer par seuil de similarité (nécessite calcul de similarité)
    filtered = [r for r in results if calculate_similarity(query_embedding, r.libelle_embedding) >= threshold]
    return filtered[:limit]
```

---

### 14. **Tests avec Requêtes Temporelles Combinées** ⚠️ MANQUANT

**Objectif** : Tester la recherche vectorielle combinée avec des filtres temporels

**Tests à Ajouter** :
- 📅 **Vector + Date** : Recherche vectorielle + filtre sur date_op
- 📅 **Vector + Période** : Recherche vectorielle + filtre sur période (TIMERANGE)
- 📅 **Vector + Montant** : Recherche vectorielle + filtre sur montant
- 📅 **Vector + Catégorie** : Recherche vectorielle + filtre sur cat_auto

**Implémentation** :
```python
def vector_search_with_filters(session, query_embedding, code_si, contrat,
                                date_start=None, date_end=None,
                                montant_min=None, montant_max=None,
                                categorie=None, limit=5):
    # Construire la requête avec filtres
    filters = []
    if date_start and date_end:
        filters.append(f"date_op >= {date_start} AND date_op < {date_end}")
    if montant_min:
        filters.append(f"montant >= {montant_min}")
    if montant_max:
        filters.append(f"montant <= {montant_max}")
    if categorie:
        filters.append(f"cat_auto = '{categorie}'")

    where_clause = " AND ".join(filters) if filters else ""
    # Requête CQL avec filtres + ANN
    ...
```

---

### 15. **Tests de Recherche Hybride** ⚠️ PARTIEL (Script 18 existe)

**Objectif** : Tester la combinaison Full-Text + Vector Search

**Tests à Ajouter** :
- 🔀 **Full-Text filtre + Vector trie** : Meilleure pertinence
- 🔀 **Vector seul avec fallback** : Si Full-Text ne trouve rien
- 🔀 **Comparaison pertinence** : Hybride vs Vector seul vs Full-Text seul

**Note** : Le script 18 (`18_test_hybrid_search.sh`) existe déjà, mais pourrait être amélioré avec ces tests.

---

## 📊 Priorisation des Tests

### Priorité 1 (Critique) - À Implémenter Immédiatement

1. **✅ Tests de Performance** - Essentiel pour la production
2. **✅ Tests Comparatifs Vector vs Full-Text** - Aide à choisir la bonne approche
3. **✅ Tests de Limites** - Évite les erreurs en production
4. **✅ Tests de Robustesse** - Sécurité et stabilité

### Priorité 2 (Haute) - À Implémenter Prochainement

5. **✅ Tests de Précision/Recall** - Qualité des résultats
6. **✅ Tests avec Accents/Diacritiques** - Cas d'usage réel
7. **✅ Tests avec Abréviations** - Cas d'usage réel
8. **✅ Tests de Cohérence** - Fiabilité

### Priorité 3 (Moyenne) - À Implémenter Plus Tard

9. **✅ Tests avec Synonymes** - Amélioration qualité
10. **✅ Tests avec Données Volumineuses** - Scalabilité
11. **✅ Tests avec Différentes Langues** - Multilingue
12. **✅ Tests avec Seuils de Similarité** - Optimisation

### Priorité 4 (Basse) - Optionnel

13. **✅ Tests avec Requêtes Multi-Mots** - Analyse fine
14. **✅ Tests avec Requêtes Temporelles Combinées** - Cas avancés
15. **✅ Tests de Recherche Hybride** - Amélioration (script 18 existe)

---

## 🔧 Recommandations d'Implémentation

### Structure Recommandée

```
scripts/
  ├── 16_test_fuzzy_search.sh (existant)
  ├── 16_test_fuzzy_search_performance.sh (nouveau)
  ├── 16_test_fuzzy_search_precision.sh (nouveau)
  ├── 16_test_fuzzy_search_robustness.sh (nouveau)
  └── 16_test_fuzzy_search_comparative.sh (nouveau)

examples/python/search/
  ├── test_vector_search.py (existant)
  ├── test_vector_search_performance.py (nouveau)
  ├── test_vector_search_precision.py (nouveau)
  ├── test_vector_search_robustness.py (nouveau)
  └── test_vector_search_comparative.py (nouveau)
```

### Script de Test Unifié

Créer un script `16_test_fuzzy_search_complete.sh` qui exécute tous les tests et génère un rapport consolidé.

---

## ✅ Conclusion

**Tests Actuels** : 10 tests (typos + recherches correctes)
**Tests Recommandés** : 15 catégories supplémentaires
**Total** : ~100+ tests individuels

**Bénéfices** :
- ✅ Couverture complète des cas d'usage
- ✅ Validation de la qualité et performance
- ✅ Détection précoce des problèmes
- ✅ Documentation complète pour la production

---

**Date de génération** : 2025-11-30
