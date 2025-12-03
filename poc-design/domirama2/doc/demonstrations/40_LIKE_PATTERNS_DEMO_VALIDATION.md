# 🔍 Rapport de Validation : Patterns LIKE avec Wildcards

**Date** : 2025-12-03  
**Script** : Validation manuelle des résultats  
**Objectif** : Vérifier l'intégralité, la cohérence, la consistance et la justesse des résultats

---

## 📊 Résumé Exécutif

Cette validation a identifié plusieurs problèmes dans le rapport généré automatiquement :

### Problèmes Identifiés

1. **❌ Patterns regex incorrects** : Les patterns `*LOYER` et `LOYER*` ne sont pas correctement implémentés
2. **❌ Requêtes CQL théoriques** : Affichent `LIKE ''` au lieu du pattern réel
3. **⚠️  Incohérences de comptage** : Différences entre le rapport (5 résultats) et la vérification (6 résultats)
4. **❌ TEST 4** : Utilise `libelle` au lieu de `cat_auto` dans la requête CQL théorique

---

## 🔍 Détail des Problèmes

### Problème 1 : Patterns Regex Incorrects

**Pattern `*LOYER` (se termine par LOYER)** :

- Regex actuelle : `.*LOYER`
- Problème : Cette regex matche "LOYER" n'importe où dans la chaîne, pas seulement à la fin
- Regex correcte : `.*LOYER$` (avec `$` pour ancrer à la fin)

**Pattern `LOYER*` (commence par LOYER)** :

- Regex actuelle : `LOYER.*`
- Problème : Cette regex matche "LOYER" n'importe où dans la chaîne, pas seulement au début
- Regex correcte : `^LOYER.*` (avec `^` pour ancrer au début)

**Impact** :

- Les résultats incluent des libellés qui ne respectent pas la sémantique SQL LIKE
- Exemple : `*LOYER` devrait trouver uniquement les libellés se terminant par "LOYER", mais trouve aussi "LOYER IMPAYE REGULARISATION"

### Problème 2 : Requêtes CQL Théoriques Vides

**Symptôme** : Toutes les requêtes CQL théoriques affichent `LIKE ''` au lieu du pattern réel

**Cause** : Bug dans le script de génération du rapport (ligne 1071 du script)

**Exemple** :

```cql
-- Actuel (incorrect)
AND libelle LIKE ''  -- ❌ Non supporté en CQL

-- Attendu (correct)
AND libelle LIKE '%LOYER%'  -- ❌ Non supporté en CQL
```

### Problème 3 : Incohérences de Comptage

**TEST 1** : Rapport indique 5 résultats, vérification trouve 6 résultats
**TEST 2** : Rapport indique 5 résultats, vérification trouve 6 résultats
**TEST 3** : Rapport indique 5 résultats, vérification trouve 6 résultats

**Cause** : Le script limite à 5 résultats (`limit=5`), mais la vérification montre qu'il y a 6 résultats disponibles

### Problème 4 : TEST 4 - Champ Incorrect

**TEST 4** : Test sur `cat_auto LIKE '%IMP%'`

- Requête CQL théorique utilise : `libelle LIKE ''`
- Devrait utiliser : `cat_auto LIKE '%IMP%'`

**Cause** : Bug dans l'extraction du champ depuis la requête LIKE

---

## ✅ Validations Réussies

### Conversion Wildcards → Regex

✅ `'%LOYER%'` → `'.*LOYER.*'` (correct)  
✅ `'LOYER*'` → `'LOYER.*'` (correct pour matching, mais devrait être `^LOYER.*` pour précision)  
✅ `'*LOYER'` → `'.*LOYER'` (correct pour matching, mais devrait être `.*LOYER$` pour précision)  
✅ `'%LOYER%IMP%'` → `'.*LOYER.*IMP.*'` (correct)

### Parsing Requêtes LIKE

✅ `"libelle LIKE '%LOYER%'"` → field=`libelle`, regex=`.*LOYER.*`  
✅ `"cat_auto LIKE 'IMP*'"` → field=`cat_auto`, regex=`IMP.*`

### Cohérence des Données

✅ Total libellés vérifiés : 85  
✅ Contenant 'LOYER' : 6  
✅ Contenant 'IMP' : 13  
✅ Contenant 'LOYER' et 'IMP' : 5

### Matching des Patterns

✅ Tous les résultats matchent les patterns regex générés  
⚠️  Mais les patterns `*LOYER` et `LOYER*` ne respectent pas la sémantique SQL LIKE stricte

---

## 🔧 Corrections Nécessaires

### Correction 1 : Améliorer `build_regex_pattern`

```python
def build_regex_pattern(query_pattern: str, strict: bool = False) -> str:
    """
    Convertit un pattern avec wildcards (* ou %) en regex pattern.

    Args:
        query_pattern: Pattern avec wildcards
        strict: Si True, ajoute ^ et $ pour ancrer début/fin (comportement SQL LIKE strict)

    Returns:
        regex_pattern: Pattern regex pour filtrage client-side
    """
    placeholder = "__WILDCARD__"
    temp_pattern = query_pattern.replace("*", placeholder).replace("%", placeholder)
    escaped = re.escape(temp_pattern)
    regex_pattern = escaped.replace(placeholder, ".*")

    if strict:
        # Ajouter ^ au début si le pattern commence par un wildcard
        if query_pattern.startswith(("*", "%")):
            regex_pattern = ".*" + regex_pattern
        else:
            regex_pattern = "^" + regex_pattern

        # Ajouter $ à la fin si le pattern se termine par un wildcard
        if query_pattern.endswith(("*", "%")):
            regex_pattern = regex_pattern + ".*"
        else:
            regex_pattern = regex_pattern + "$"

    return regex_pattern
```

### Correction 2 : Corriger l'extraction du pattern dans le script

```python
# Dans le script de génération du rapport
if "LIKE" in like_query:
    parts = like_query.split("LIKE")
    field = parts[0].strip()
    # Extraire le pattern entre guillemets simples ou doubles
    pattern_part = parts[1].strip()
    # Enlever les guillemets simples ou doubles
    like_pattern_value = pattern_part.strip("'\"")
else:
    field = "libelle"
    like_pattern_value = ""
```

### Correction 3 : Documenter les Limitations

Le rapport devrait mentionner que :

- Les patterns `*LOYER` et `LOYER*` utilisent une sémantique flexible (matchent "LOYER" n'importe où)
- Pour une sémantique SQL LIKE stricte, il faudrait utiliser `^LOYER.*` et `.*LOYER$`
- La recherche vectorielle peut retourner des résultats qui ne respectent pas strictement le pattern LIKE

---

## 📝 Recommandations

1. **Corriger le script de génération** pour afficher correctement les patterns dans les requêtes CQL théoriques
2. **Améliorer `build_regex_pattern`** pour supporter une option `strict` qui ajoute `^` et `$`
3. **Documenter les limitations** dans le rapport principal
4. **Ajouter des tests unitaires** pour valider les patterns regex générés
5. **Harmoniser les comptages** entre le rapport et la vérification

---

## ✅ Conclusion

Les résultats sont **globalement cohérents** mais présentent des **problèmes de précision** dans l'implémentation des patterns LIKE. Les corrections proposées amélioreront la justesse et la cohérence du rapport.
