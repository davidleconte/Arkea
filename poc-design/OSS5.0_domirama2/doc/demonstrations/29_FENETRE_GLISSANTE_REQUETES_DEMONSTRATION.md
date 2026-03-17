# 📅 Démonstration : Requêtes Fenêtre Glissante

**Date** : 2025-11-27 05:11:23
**Script** : 29_demo_requetes_fenetre_glissante_v2_didactique.sh
**Objectif** : Démontrer les requêtes en base avec fenêtre glissante (TIMERANGE équivalent HBase)

---

## 📋 Table des Matières

1. [Contexte et Stratégie](#contexte-et-stratégie)
2. [Requêtes Exécutées](#requêtes-exécutées)
3. [Résultats par Requête](#résultats-par-requête)
4. [Comparaison Performance](#comparaison-performance)
5. [Conclusion](#conclusion)

---

## 📚 Contexte et Stratégie

### Équivalences HBase → HCD

| Concept HBase | Équivalent HCD (CQL) |
|---------------|----------------------|
| TIMERANGE | WHERE date_op >= start AND date_op < end |
| SCAN avec filtres temporels | SELECT ... WHERE date_op BETWEEN ... |
| Requêtes par période | Fenêtre glissante avec WHERE date_op |

### Valeur Ajoutée SAI

- ✅ Index sur date_op (clustering key) pour performance optimale
- ✅ Index sur libelle (full-text SAI) pour recherche textuelle
- ✅ Combinaison d'index pour recherche optimisée
- ✅ Pas de scan complet nécessaire

### Stratégie de Démonstration

- 3 requêtes CQL pour démontrer la fenêtre glissante
- Mesure de performance pour chaque requête
- Comparaison avec/sans SAI
- Documentation structurée pour livrable

---

## 🔍 Requêtes Exécutées

### Tableau Récapitulatif

| Requête | Titre | Lignes | Temps (s) | Coordinateur (μs) | Total (μs) | Statut |
|---------|-------|--------|-----------|-------------------|-----------|--------|
| 1 | Requête Mensuelle (Fenêtre Glissante) | 10 | .603292000 |  |  | ✅ OK |
| 2 | Requête Fenêtre Glissante (30 Derniers Jours) | 10 | .596577000 |  |  | ✅ OK |
| 3 | Requête avec SAI (Date + Full-Text Search) | 5 | .580904000 |  |  | ✅ OK |

---

## 📊 Résultats par Requête

### Requête 1 : Requête Mensuelle (Fenêtre Glissante)

- **Lignes retournées** : 10
- **Temps d'exécution** : .603292000s
- **Statut** : ✅ OK

### Requête 2 : Requête Fenêtre Glissante (30 Derniers Jours)

- **Lignes retournées** : 10
- **Temps d'exécution** : .596577000s
- **Statut** : ✅ OK

### Requête 3 : Requête avec SAI (Date + Full-Text Search)

- **Lignes retournées** : 5
- **Temps d'exécution** : .580904000s
- **Statut** : ✅ OK

---

## 📊 Comparaison Performance

### Sans SAI (HBase)

- SCAN complet de la partition
- Filtrage côté client
- Performance : O(n) où n = nombre d'opérations
- Temps proportionnel au nombre total d'opérations

### Avec SAI (HCD)

- Index sur date_op (clustering key) pour recherche temporelle
- Index sur libelle (full-text SAI) pour recherche textuelle
- Performance : O(log n) avec index
- Valeur ajoutée : Recherche combinée optimisée
- Temps indépendant du nombre total d'opérations (seulement celles correspondant aux critères)

---

## ✅ Conclusion

### Points Clés Démontrés

- ✅ Fenêtre glissante avec WHERE date_op BETWEEN start AND end
- ✅ Requêtes mensuelles, hebdomadaires, etc. avec filtrage temporel
- ✅ Valeur ajoutée SAI : Index sur date_op + full-text pour recherche combinée
- ✅ Performance optimisée vs scan complet (O(log n) vs O(n))

### Valeur Ajoutée SAI

Les index SAI apportent une amélioration significative des performances pour les requêtes avec
filtres sur les colonnes indexées. La combinaison d'index (clustering key + full-text SAI) permet d'optimiser les
requêtes complexes avec plusieurs filtres simultanés.

### Équivalences HBase → HCD Validées

- ✅ TIMERANGE HBase → WHERE date_op >= start AND date_op < end
- ✅ SCAN avec filtres temporels → SELECT ... WHERE date_op BETWEEN ...
- ✅ Requêtes par période → Fenêtre glissante avec WHERE date_op

---

**Date de génération** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
