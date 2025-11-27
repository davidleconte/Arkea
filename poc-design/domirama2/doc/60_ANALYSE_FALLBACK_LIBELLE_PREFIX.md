# 🔄 Analyse : Fall-back `libelle` → `libelle_prefix`

## Question

Peut-on implémenter un fall-back d'une colonne sur l'autre si pas de résultat ? Est-ce pertinent ? Faisable ?

## Contexte

- **`libelle`** : Index full-text avec stemming, asciifolding, lowercase
  - ✅ Recherche de termes complets : `libelle : 'virement'`
  - ❌ Recherche partielle : `libelle : 'carref'` → ne trouve pas "CARREFOUR"

- **`libelle_prefix`** : Index pour recherche partielle
  - ✅ Recherche partielle : `libelle_prefix : 'carref'` → trouve "CARREFOUR"
  - ⚠️ Nécessite que la colonne soit remplie (peut être NULL)

## Stratégie de Fall-back

### Concept

**Fall-back** : Si une recherche sur `libelle` ne donne pas de résultat, essayer automatiquement avec `libelle_prefix`.

**Exemple** :
```cql
-- Tentative 1 : Recherche sur libelle (terme complet)
SELECT * FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND libelle : 'carref'  -- ❌ 0 résultat

-- Fall-back : Si 0 résultat, essayer libelle_prefix
SELECT * FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND libelle_prefix : 'carref'  -- ✅ Trouve "CARREFOUR"
```

---

## Pertinence

### ✅ **OUI, c'est pertinent** pour certains cas d'usage

**Avantages** :
1. ✅ **Tolérance aux typos** : Si l'utilisateur tape "carref" au lieu de "carrefour", le fall-back trouve quand même
2. ✅ **Recherche partielle automatique** : Pas besoin de savoir si c'est un terme complet ou partiel
3. ✅ **Meilleure expérience utilisateur** : L'utilisateur obtient des résultats même avec une recherche partielle
4. ✅ **Couverture complète** : Combine les forces des deux index

**Cas d'usage pertinents** :
- 🔍 Recherche utilisateur avec termes partiels
- 🔍 Autocomplétion
- 🔍 Tolérance aux erreurs de saisie
- 🔍 Recherche progressive (terme complet → partiel)

**Cas d'usage moins pertinents** :
- ⚠️ Recherche exacte (on veut uniquement les termes complets)
- ⚠️ Performance critique (deux requêtes au lieu d'une)

---

## Faisabilité

### ✅ **OUI, c'est faisable** avec plusieurs approches

### Approche 1 : Côté Application (Recommandée)

**Principe** : L'application exécute d'abord la recherche sur `libelle`, puis sur `libelle_prefix` si aucun résultat.

**Avantages** :
- ✅ Contrôle total sur la logique
- ✅ Peut combiner les résultats des deux recherches
- ✅ Peut ajouter de la logique métier (score, tri, etc.)
- ✅ Performance optimisée (ne fait la 2ème requête que si nécessaire)

**Inconvénients** :
- ⚠️ Nécessite du code applicatif
- ⚠️ Deux requêtes potentielles

**Exemple en Java** :
```java
public List<Operation> search(String searchTerm) {
    // Tentative 1 : Recherche sur libelle (terme complet)
    List<Operation> results = searchOnLibelle(searchTerm);
    
    // Fall-back : Si aucun résultat, essayer libelle_prefix
    if (results.isEmpty()) {
        results = searchOnLibellePrefix(searchTerm);
    }
    
    return results;
}
```

**Exemple en Python** :
```python
def search_operations(search_term):
    # Tentative 1 : Recherche sur libelle
    results = session.execute(
        "SELECT * FROM operations_by_account "
        "WHERE code_si = ? AND contrat = ? AND libelle : ?",
        (code_si, contrat, search_term)
    )
    
    # Fall-back : Si aucun résultat, essayer libelle_prefix
    if not results:
        results = session.execute(
            "SELECT * FROM operations_by_account "
            "WHERE code_si = ? AND contrat = ? AND libelle_prefix : ?",
            (code_si, contrat, search_term)
        )
    
    return results
```

### Approche 2 : Requête CQL avec UNION (Limité)

**Principe** : Utiliser UNION pour combiner les deux recherches.

**Limitation** : ❌ **CQL ne supporte pas UNION** dans les versions récentes de Cassandra/HCD.

**Alternative** : Utiliser une requête avec OR (mais moins efficace) :
```cql
-- ⚠️ Cette approche n'est pas optimale
SELECT * FROM operations_by_account
WHERE code_si = '1' AND contrat = '5913101072'
  AND (libelle : 'carref' OR libelle_prefix : 'carref')
LIMIT 10;
```

**Problèmes** :
- ❌ Performance : Les deux index sont consultés même si le premier trouve des résultats
- ❌ Pas de priorité : Les résultats de `libelle` et `libelle_prefix` sont mélangés
- ⚠️ Peut retourner des doublons si les deux conditions matchent

### Approche 3 : Vue Matérialisée (Non recommandée)

**Principe** : Créer une vue qui combine les deux colonnes.

**Problèmes** :
- ❌ Complexité élevée
- ❌ Maintenance difficile
- ❌ Performance dégradée
- ❌ Pas adapté pour ce cas d'usage

### Approche 4 : Spark/ETL (Pour batch)

**Principe** : Utiliser Spark pour faire le fall-back lors du traitement batch.

**Cas d'usage** : Recherche dans des fichiers Parquet/CSV avant insertion.

**Exemple** :
```scala
val searchTerm = "carref"
val results = df.filter(
  col("libelle").contains(searchTerm) || 
  col("libelle_prefix").contains(searchTerm)
)
```

---

## Recommandation : Approche Hybride

### Stratégie Recommandée

**1. Recherche principale sur `libelle`** (terme complet)
- ✅ Meilleure pertinence (stemming, asciifolding)
- ✅ Performance optimale
- ✅ Résultats les plus précis

**2. Fall-back sur `libelle_prefix`** (si aucun résultat)
- ✅ Pour recherche partielle
- ✅ Pour tolérance aux typos
- ✅ Seulement si la recherche principale échoue

**3. Combinaison optionnelle** (pour certains cas)
- ⚠️ Recherche sur les deux colonnes simultanément
- ⚠️ Fusionner et dédupliquer les résultats
- ⚠️ Trier par pertinence (libelle en premier)

### Implémentation Recommandée

```python
def search_with_fallback(code_si, contrat, search_term, limit=10):
    """
    Recherche avec fall-back libelle → libelle_prefix
    """
    # Tentative 1 : Recherche sur libelle (terme complet)
    query1 = f"""
        SELECT * FROM operations_by_account
        WHERE code_si = '{code_si}'
          AND contrat = '{contrat}'
          AND libelle : '{search_term}'
        LIMIT {limit}
    """
    results1 = session.execute(query1)
    
    if results1:
        # Si on a des résultats, les retourner
        return list(results1)
    
    # Fall-back : Recherche sur libelle_prefix (partielle)
    query2 = f"""
        SELECT * FROM operations_by_account
        WHERE code_si = '{code_si}'
          AND contrat = '{contrat}'
          AND libelle_prefix : '{search_term}'
        LIMIT {limit}
    """
    results2 = session.execute(query2)
    
    return list(results2)
```

### Variante : Recherche Combinée (Plus de résultats)

```python
def search_combined(code_si, contrat, search_term, limit=10):
    """
    Recherche combinée : libelle OU libelle_prefix
    Déduplique et trie par pertinence
    """
    # Recherche sur libelle
    query1 = f"""
        SELECT * FROM operations_by_account
        WHERE code_si = '{code_si}'
          AND contrat = '{contrat}'
          AND libelle : '{search_term}'
        LIMIT {limit * 2}
    """
    results1 = set(session.execute(query1))
    
    # Recherche sur libelle_prefix
    query2 = f"""
        SELECT * FROM operations_by_account
        WHERE code_si = '{code_si}'
          AND contrat = '{contrat}'
          AND libelle_prefix : '{search_term}'
        LIMIT {limit * 2}
    """
    results2 = set(session.execute(query2))
    
    # Fusionner et dédupliquer (par clé primaire)
    all_results = results1.union(results2)
    
    # Trier par pertinence : libelle en premier
    sorted_results = sorted(
        all_results,
        key=lambda x: (x not in results1, x.date_op),
        reverse=True
    )
    
    return sorted_results[:limit]
```

---

## Performance

### Impact sur les Performances

**Approche Fall-back (séquentielle)** :
- ✅ **Meilleure performance** : Ne fait la 2ème requête que si nécessaire
- ✅ **Latence minimale** : Si la 1ère requête trouve, pas de 2ème requête
- ⚠️ **Latence maximale** : 2 requêtes si la 1ère échoue

**Approche Combinée (parallèle)** :
- ⚠️ **Performance moyenne** : Toujours 2 requêtes
- ⚠️ **Latence constante** : Attente des 2 requêtes
- ✅ **Plus de résultats** : Combine les deux sources

**Recommandation** : Utiliser le fall-back séquentiel pour la performance, la recherche combinée pour la couverture maximale.

---

## Cas d'Usage Concrets

### Cas 1 : Recherche Utilisateur

**Scénario** : L'utilisateur tape "carref" dans la barre de recherche.

**Sans fall-back** :
- Recherche sur `libelle : 'carref'` → 0 résultat
- ❌ Utilisateur frustré

**Avec fall-back** :
- Recherche sur `libelle : 'carref'` → 0 résultat
- Fall-back sur `libelle_prefix : 'carref'` → Trouve "CARREFOUR"
- ✅ Utilisateur satisfait

### Cas 2 : Recherche Exacte

**Scénario** : L'utilisateur tape "virement" (terme complet).

**Sans fall-back** :
- Recherche sur `libelle : 'virement'` → Trouve des résultats
- ✅ Fonctionne parfaitement

**Avec fall-back** :
- Recherche sur `libelle : 'virement'` → Trouve des résultats
- Fall-back non déclenché (déjà des résultats)
- ✅ Performance identique

### Cas 3 : Recherche Partielle

**Scénario** : L'utilisateur tape "loyr" (typo de "loyer").

**Sans fall-back** :
- Recherche sur `libelle : 'loyr'` → 0 résultat
- ❌ Pas de résultat

**Avec fall-back** :
- Recherche sur `libelle : 'loyr'` → 0 résultat
- Fall-back sur `libelle_prefix : 'loyr'` → Peut trouver "LOYER"
- ✅ Tolérance aux typos

---

## Conclusion

### ✅ **OUI, c'est pertinent et faisable**

**Pertinence** : ✅ **Élevée**
- Améliore l'expérience utilisateur
- Tolérance aux typos et recherches partielles
- Couverture complète des cas d'usage

**Faisabilité** : ✅ **Élevée**
- Implémentation simple côté application
- Pas de modification de schéma nécessaire
- Performance acceptable

**Recommandation** : ✅ **Implémenter le fall-back côté application**

**Approche recommandée** :
1. Recherche principale sur `libelle` (terme complet)
2. Fall-back sur `libelle_prefix` si aucun résultat
3. Optionnel : Recherche combinée pour certains cas d'usage

**Performance** : ✅ **Acceptable**
- Latence minimale si la 1ère requête trouve
- Latence maximale = 2 requêtes (acceptable pour la tolérance aux typos)


