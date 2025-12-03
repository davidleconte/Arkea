# Plan d'Implémentation : Scripts LIKE et Wildcard pour domirama2

**Date** : 2025-12-03  
**Objectif** : Créer deux scripts dédiés à la mise en œuvre des patterns LIKE et wildcard via le CQL API pour domirama2, basés sur les démonstrations du fichier `inputs-ibm/[fuzzy_and_complex_search_with_vector_search].py`

---

## 📋 Analyse Préliminaire

### 1. Analyse des Inputs

#### inputs-ibm/

- **Fichier de référence** : `[fuzzy_and_complex_search_with_vector_search].py`
- **Patterns identifiés** :
  - **LIKE Pattern** : Syntaxe `"field LIKE 'pattern'"` avec wildcards `*` ou `%`
  - **Wildcard Pattern** : Support de `*` (n'importe quels caractères) et `%` (n'importe quels caractères)
  - **Approche hybride** : Recherche vectorielle (ANN) + filtrage client-side avec regex

#### inputs-clients/

- Documents d'analyse HBase existant
- Pas de spécifications directes sur LIKE/wildcard

#### poc-design/domirama2/scripts/

- **Scripts existants** : 40+ scripts de setup, test, démonstration
- **Patterns similaires** : Recherche full-text, fuzzy search, vector search
- **Manque** : Scripts dédiés LIKE/wildcard

### 2. Analyse du Schéma domirama2

#### Structure de la Table `operations_by_account`

**Colonnes pertinentes pour LIKE/wildcard** :

- `libelle` (TEXT) : Libellé de l'opération - **Cible principale pour LIKE**
- `libelle_embedding` (VECTOR<FLOAT, 1472>) : Embeddings ByteT5 - **Pour recherche hybride**
- `cat_auto` (TEXT) : Catégorie automatique - **Cible secondaire**
- `cat_user` (TEXT) : Catégorie utilisateur - **Cible secondaire**
- `type_operation` (TEXT) : Type d'opération - **Cible secondaire**

**Index disponibles** :

- `idx_libelle_fulltext_advanced` : Index SAI full-text sur `libelle`
- `idx_libelle_embedding_vector` : Index vectoriel sur `libelle_embedding`
- `idx_cat_auto` : Index SAI sur `cat_auto`
- `idx_cat_user` : Index SAI sur `cat_user`

#### Vérification de la Compatibilité

✅ **Le jeu de données actuel permet d'y répondre** :

1. **Colonnes textuelles** : `libelle`, `cat_auto`, `cat_user` existent et contiennent du texte
2. **Colonne vectorielle** : `libelle_embedding` existe (VECTOR<FLOAT, 1472>)
3. **Index appropriés** : Index SAI full-text et vectoriel disponibles
4. **Données de test** : Scripts de chargement de données existent (11_load_domirama2_data_*.sh)

**Exemples de requêtes possibles** :

- `libelle LIKE '%LOYER%'` : Trouve tous les libellés contenant "LOYER"
- `libelle LIKE 'LOYER*'` : Trouve les libellés commençant par "LOYER"
- `cat_auto LIKE '%IMP%'` : Trouve les catégories contenant "IMP"
- Recherche hybride : Vector search + LIKE sur `libelle`

---

## 🎯 Plan d'Implémentation

### Script 1 : `40_test_like_patterns.sh`

**Objectif** : Tester et démontrer les patterns LIKE avec wildcards via CQL API

**Fonctionnalités** :

1. **Parsing de requêtes LIKE** :
   - Syntaxe : `"field LIKE 'pattern'"`
   - Support des wildcards : `*` et `%`
   - Conversion en regex pour filtrage client-side

2. **Recherche hybride** :
   - Recherche vectorielle sur `libelle_embedding` (ANN)
   - Filtrage client-side avec regex sur le champ spécifié
   - Combinaison des deux approches

3. **Tests de cas d'usage** :
   - LIKE avec wildcard au début : `'%LOYER%'`
   - LIKE avec wildcard à la fin : `'LOYER*'`
   - LIKE avec wildcards multiples : `'%LOYER%IMP%'`
   - LIKE sur différentes colonnes : `libelle`, `cat_auto`, `cat_user`

**Structure** :

```bash
#!/bin/bash
# Script 40 : Tests des patterns LIKE avec wildcards
#
# Fonctions :
# - build_regex_pattern() : Convertit wildcards en regex
# - parse_explicit_like() : Parse requête LIKE
# - test_like_patterns() : Exécute tests LIKE
# - demonstrate_hybrid_like() : Recherche hybride + LIKE
```

### Script 2 : `41_demo_wildcard_search.sh`

**Objectif** : Démonstration complète de la recherche avec wildcards (approche avancée)

**Fonctionnalités** :

1. **Recherche avec wildcards multiples** :
   - Patterns complexes : `'*LOYER*IMP*'`
   - Combinaison de plusieurs wildcards
   - Support de patterns imbriqués

2. **Recherche hybride avancée** :
   - Vector search + LIKE sur plusieurs champs
   - Filtrage combiné (AND/OR)
   - Tri par similarité vectorielle + score LIKE

3. **Cas d'usage métier** :
   - Recherche de libellés partiels (typos tolérées)
   - Recherche de catégories avec patterns
   - Recherche combinée libellé + catégorie

**Structure** :

```bash
#!/bin/bash
# Script 41 : Démonstration recherche wildcard avancée
#
# Fonctions :
# - advanced_wildcard_search() : Recherche avec patterns complexes
# - multi_field_like_search() : LIKE sur plusieurs champs
# - business_use_cases() : Cas d'usage métier
```

---

## 🔧 Implémentation Technique

### Fonctions Python à Intégrer

#### 1. `build_regex_pattern(query_pattern)`

```python
def build_regex_pattern(query_pattern):
    """
    Convertit un pattern avec wildcards (* ou %) en regex.

    Args:
        query_pattern: Pattern avec wildcards (ex: "%LOYER%", "LOYER*")

    Returns:
        regex_pattern: Pattern regex pour filtrage client-side
    """
    placeholder = "__WILDCARD__"
    temp_pattern = query_pattern.replace("*", placeholder).replace("%", placeholder)
    escaped = re.escape(temp_pattern)
    regex_pattern = escaped.replace(placeholder, ".*")
    return regex_pattern
```

#### 2. `parse_explicit_like(query)`

```python
def parse_explicit_like(query):
    """
    Parse une requête LIKE et extrait le champ et le pattern.

    Args:
        query: Requête au format "field LIKE 'pattern'"

    Returns:
        (field, regex_pattern): Tuple avec nom du champ et pattern regex
    """
    pattern = r"(\w+)\s+LIKE\s+'(.+)'"
    match = re.search(pattern, query, re.IGNORECASE)
    if match:
        field = match.group(1)
        like_pattern = match.group(2)
        regex = build_regex_pattern(like_pattern)
        return field, regex
    return None, None
```

#### 3. `hybrid_like_search(session, query_text, like_query, filter_dict=None, limit=5)`

```python
def hybrid_like_search(session, query_text, like_query, filter_dict=None, limit=5):
    """
    Recherche hybride combinant vector search et LIKE pattern.

    Args:
        session: Session Cassandra
        query_text: Texte pour recherche vectorielle
        like_query: Requête LIKE (ex: "libelle LIKE '%LOYER%'")
        filter_dict: Filtres additionnels (optionnel)
        limit: Nombre de résultats

    Returns:
        Liste de résultats filtrés
    """
    # 1. Encoder query_text en vecteur
    # 2. Exécuter recherche vectorielle (ANN)
    # 3. Parser like_query pour obtenir field et regex
    # 4. Filtrer résultats client-side avec regex
    # 5. Retourner résultats triés par similarité
```

### Intégration avec CQL API

**Approche** :

1. **Recherche vectorielle CQL** :

   ```cql
   SELECT libelle, cat_auto, cat_user, montant,
          similarity_cosine(libelle_embedding, ?) AS sim
   FROM domirama2_poc.operations_by_account
   WHERE code_si = ? AND contrat = ?
   ORDER BY libelle_embedding ANN OF ? LIMIT ?
   ```

2. **Filtrage client-side** :
   - Appliquer regex sur les résultats de la recherche vectorielle
   - Filtrer sur le champ spécifié dans la requête LIKE
   - Conserver le tri par similarité vectorielle

---

## 📊 Cas d'Usage Métier

### Cas 1 : Recherche de Libellés Partiels

**Requête** : `libelle LIKE '%LOYER%'`  
**Usage** : Trouver toutes les opérations contenant "LOYER" dans le libellé  
**Bénéfice** : Tolère les variations ("LOYER", "LOYERS", "LOYER IMPAYE")

### Cas 2 : Recherche avec Typos

**Requête** : `libelle LIKE '%LOYR%'` (typo)  
**Usage** : Trouver "LOYER" malgré la typo  
**Bénéfice** : Recherche vectorielle trouve les résultats sémantiquement proches

### Cas 3 : Recherche de Catégories

**Requête** : `cat_auto LIKE '%IMP%'`  
**Usage** : Trouver toutes les catégories contenant "IMP"  
**Bénéfice** : Filtrage rapide sur catégories automatiques

### Cas 4 : Recherche Combinée

**Requête** : Vector search "loyer impayé" + `libelle LIKE '%LOYER%'`  
**Usage** : Recherche sémantique + filtrage textuel précis  
**Bénéfice** : Meilleure précision grâce à la combinaison

---

## ✅ Vérification de Compatibilité

### Données Disponibles

✅ **Table `operations_by_account`** :

- Colonne `libelle` (TEXT) : ✅ Présente
- Colonne `libelle_embedding` (VECTOR<FLOAT, 1472>) : ✅ Présente (schéma fuzzy)
- Colonne `cat_auto` (TEXT) : ✅ Présente
- Colonne `cat_user` (TEXT) : ✅ Présente

✅ **Index disponibles** :

- Index SAI full-text sur `libelle` : ✅ Présent
- Index vectoriel sur `libelle_embedding` : ✅ Présent (schéma fuzzy)

✅ **Données de test** :

- Scripts de chargement : ✅ Présents (11_load_domirama2_data_*.sh)
- Données d'exemple : ✅ Disponibles (operations_sample.csv)

### Prérequis

**Pour exécuter les scripts** :

1. ✅ HCD démarré
2. ✅ Keyspace `domirama2_poc` créé
3. ✅ Table `operations_by_account` créée
4. ✅ Colonne `libelle_embedding` ajoutée (via schéma fuzzy)
5. ✅ Données chargées dans la table
6. ✅ Embeddings générés (via script 22_generate_embeddings.sh)
7. ✅ Python 3.8+ avec cassandra-driver, transformers, torch

---

## 📝 Structure des Scripts

### Script 40 : `40_test_like_patterns.sh`

**Emplacement** : `poc-design/domirama2/scripts/40_test_like_patterns.sh`

**Structure** :

```bash
#!/bin/bash
# Script 40 : Tests des patterns LIKE avec wildcards
#
# Sections :
# 1. Configuration et vérifications
# 2. Fonctions utilitaires (build_regex_pattern, parse_explicit_like)
# 3. Tests de base LIKE
# 4. Recherche hybride LIKE + Vector
# 5. Tests sur différentes colonnes
# 6. Rapport de résultats
```

**Tests inclus** :

- Test 1 : LIKE simple `'%LOYER%'`
- Test 2 : LIKE avec wildcard début `'LOYER*'`
- Test 3 : LIKE avec wildcard fin `'*LOYER'`
- Test 4 : LIKE hybride + vector search
- Test 5 : LIKE sur `cat_auto`
- Test 6 : LIKE sur `cat_user`

### Script 41 : `41_demo_wildcard_search.sh`

**Emplacement** : `poc-design/domirama2/scripts/41_demo_wildcard_search.sh`

**Structure** :

```bash
#!/bin/bash
# Script 41 : Démonstration recherche wildcard avancée
#
# Sections :
# 1. Configuration et vérifications
# 2. Fonctions avancées (multi-field, patterns complexes)
# 3. Cas d'usage métier
# 4. Comparaison performances
# 5. Rapport détaillé
```

**Démonstrations incluses** :

- Demo 1 : Patterns complexes avec wildcards multiples
- Demo 2 : Recherche multi-champs (libelle + cat_auto)
- Demo 3 : Cas d'usage métier (recherche typos)
- Demo 4 : Comparaison LIKE vs Full-text vs Vector
- Demo 5 : Performance et optimisation

---

## 🚀 Prochaines Étapes

1. **Création des scripts** :
   - Script 40 : Tests LIKE de base
   - Script 41 : Démonstration wildcard avancée

2. **Intégration Python** :
   - Module Python réutilisable pour fonctions LIKE/wildcard
   - Intégration avec scripts shell existants

3. **Documentation** :
   - Guide d'utilisation des scripts
   - Exemples de requêtes LIKE
   - Cas d'usage métier

4. **Tests** :
   - Tests unitaires des fonctions Python
   - Tests d'intégration avec données réelles
   - Validation des performances

---

## 📌 Notes Importantes

### Limitations CQL

⚠️ **CQL ne supporte pas nativement LIKE** :

- Solution : Recherche vectorielle + filtrage client-side avec regex
- Approche hybride : Combine ANN (vector) + regex (client-side)

### Performance

⚠️ **Filtrage client-side** :

- Nécessite de récupérer plus de résultats que nécessaire
- Filtrage appliqué après récupération des données
- Impact sur performance si trop de résultats

**Optimisation** :

- Utiliser recherche vectorielle pour réduire le nombre de résultats
- Appliquer filtres CQL standards avant filtrage LIKE
- Limiter le nombre de résultats récupérés

---

## ✅ Conclusion

**Le jeu de données actuel dans le keyspace domirama2 permet d'implémenter les patterns LIKE et wildcard** :

✅ Colonnes textuelles disponibles (`libelle`, `cat_auto`, `cat_user`)  
✅ Colonne vectorielle disponible (`libelle_embedding`)  
✅ Index appropriés (SAI full-text, vectoriel)  
✅ Données de test disponibles  
✅ Approche hybride possible (vector + regex client-side)

**Les deux scripts peuvent être créés et testés avec les données existantes.**
