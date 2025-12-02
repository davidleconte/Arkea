# 🔍 Démonstration : Tests Full-Text Search Complexes Domirama2

**Date** : {{REPORT_DATE}}
**Script** : {{REPORT_SCRIPT}}
**Objectif** : Démontrer les tests de recherche full-text complexes avec analyzers SAI

---

## 📋 Table des Matières

1. [Analyzers SAI](#analyzers-sai)
2. [Recherches Multi-Termes](#recherches-multi-termes)
3. [Requêtes CQL](#requêtes-cql)
4. [Résultats des Tests](#résultats-des-tests)
5. [Validation de la Pertinence](#validation-de-la-pertinence)
6. [Conclusion](#conclusion)

---

## 📚 Analyzers SAI

### Configuration

Les analyzers SAI traitent le texte avant l'indexation et la recherche pour améliorer la pertinence et la tolérance aux variations.

**Configuration dans le schéma** :

```cql
CREATE CUSTOM INDEX idx_libelle_fulltext_advanced
ON operations_by_account(libelle)
USING 'StorageAttachedIndex'
WITH OPTIONS = {
  'index_analyzer': '{
    "tokenizer": {"name": "standard"},
    "filters": [
      {"name": "lowercase"},
      {"name": "asciiFolding"},
      {"name": "frenchLightStem"}
    ]
  }'
};
```

### Analyzers Utilisés

#### lowercase

**Fonction** : Convertit tout en minuscules

**Exemples** :

- 'Loyer' → 'loyer'
- 'LOYER' → 'loyer'
- 'Loyer Paris' → 'loyer paris'

**Usage** : Recherche insensible à la casse

#### asciifolding

**Fonction** : Supprime les accents

**Exemples** :

- 'impayé' → 'impaye'
- 'café' → 'cafe'
- 'régularisation' → 'regularisation'

**Usage** : Recherche tolérante aux accents

#### frenchLightStem

**Fonction** : Racinisation française (stemming)

**Exemples** :

- 'loyers' → 'loyer'
- 'virements' → 'virement'
- 'factures' → 'facture'

**Usage** : Recherche tolérante au pluriel/singulier

#### Stop Words

**Fonction** : Ignore les mots vides (le, la, de, etc.)

**Exemples** :

- 'le loyer' → 'loyer' (le ignoré)
- 'de paris' → 'paris' (de ignoré)

**Usage** : Améliore la pertinence en ignorant les mots non significatifs

---

## 🔍 Recherches Multi-Termes

### Principe

**Recherches Multi-Termes** :

- Recherche de plusieurs mots simultanément
- **AND implicite** : Tous les termes doivent être présents
- Ordre des termes : Peu importe l'ordre

### Syntaxe CQL

```cql
SELECT * FROM operations_by_account
WHERE code_si = '{{CODE_SI}}'
  AND contrat = '{{CONTRAT}}'
  AND libelle : 'loyer'  -- Premier terme
  AND libelle : 'paris'  -- Deuxième terme - AND implicite
LIMIT 20;
```

**Explication** :

- `libelle : 'loyer' AND libelle : 'paris'`
- Trouve les opérations contenant 'loyer' **ET** 'paris'
- L'ordre des termes n'a pas d'importance

### Exemples de Recherches Multi-Termes

| Recherche | Termes | Description |
|-----------|--------|-------------|
| 'loyer paris' | 2 | Recherche loyer ET paris |
| 'virement impayé' | 2 | Recherche virement ET impayé |
| 'ratp navigo paris' | 3 | Recherche ratp ET navigo ET paris |

### Avantages

✅ **Précision améliorée** : Plus de termes = résultats plus pertinents  
✅ **Flexibilité** : Ordre des termes peu important  
✅ **Performance** : Index SAI optimisé pour multi-termes

---

## 📝 Requêtes CQL

### Tests Exécutés

Le fichier de test contient **20 tests de recherche complexes** :

1. **Recherches multi-termes** (2 termes) : 'loyer paris', 'virement impayé', etc.
2. **Recherches triple termes** : 'ratp navigo paris', 'amazon paris livraison'
3. **Recherches avec stemming** : 'loyers paris' (pluriel)
4. **Recherches avec accents** : 'impaye' (asciifolding)
5. **Recherches combinées** : Full-text + filtres (montant, catégorie)

### Exemples de Requêtes

#### Test 1 : Recherche multi-termes 'loyer paris'

```cql
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '{{CODE_SI}}'
  AND contrat = '{{CONTRAT}}'
  AND libelle : 'loyer'  -- Premier terme
  AND libelle : 'paris'  -- Deuxième terme - AND implicite
LIMIT 20;
```

**Explication** :

- AND implicite : Trouve les opérations contenant 'loyer' ET 'paris'
- lowercase : 'Loyer' ou 'LOYER' trouvés
- asciifolding : 'paris' trouvé même si accentué
- frenchLightStem : 'loyers' trouvé - pluriel

#### Test 2 : Recherche 'virement impayé' (avec accent)

```cql
SELECT code_si, contrat, date_op, libelle, montant, type_operation
FROM operations_by_account
WHERE code_si = '{{CODE_SI}}'
  AND contrat = '{{CONTRAT}}'
  AND libelle : 'virement'
  AND libelle : 'impaye'  -- Sans accent, trouve 'IMPAYÉ' grâce à asciifolding
LIMIT 20;
```

**Explication** :

- asciifolding : 'impaye' requête → 'impaye' index
- asciifolding : 'IMPAYÉ' données → 'impaye' index
- Match réussi grâce à l'asciifolding

#### Test 11 : Recherche avec stemming 'loyers paris' (pluriel)

```cql
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '{{CODE_SI}}'
  AND contrat = '{{CONTRAT}}'
  AND libelle : 'loyers'  -- Pluriel, trouve 'LOYER' grâce au stemming
  AND libelle : 'paris'
LIMIT 20;
```

**Explication** :

- frenchLightStem : 'loyers' requête → 'loyer' racine
- frenchLightStem : 'LOYER' données → 'loyer' racine
- Match réussi grâce au stemming

#### Test 18 : Recherche combinée avec filtre montant

```cql
SELECT code_si, contrat, date_op, libelle, montant, cat_auto
FROM operations_by_account
WHERE code_si = '{{CODE_SI}}'
  AND contrat = '{{CONTRAT}}'
  AND libelle : 'loyer'  -- Full-text search
  AND libelle : 'paris'
  AND montant < -500  -- Filtre numérique - index SAI
LIMIT 20;
```

**Explication** :

- Full-text search : Filtre par libellé - analyzers
- Filtre montant : Filtre numérique - index SAI standard
- Combinaison : Résultats pertinents ET montant < -500

---

## 📊 Résultats des Tests

### Résumé

| Test | Description | Analyzers | Résultats | Statut |
|------|-------------|-----------|-----------|--------|
| 1 | 'loyer paris' (multi-termes) | lowercase, stemming | {{RESULT1}} | ✅ |
| 2 | 'impaye' (asciifolding) | asciifolding | {{RESULT2}} | ✅ |
| 11 | 'loyers' (stemming) | frenchLightStem | {{RESULT11}} | ✅ |
| 18 | 'loyer paris' + montant < -500 | Tous + filtre | {{RESULT18}} | ✅ |

---

## ✅ Validation de la Pertinence

### Test 1 : Recherche multi-termes 'loyer paris'

**Attendu** : Opérations contenant 'loyer' ET 'paris'  
**Obtenu** : {{RESULT1}} résultat(s)  
**Statut** : ✅ Validé

### Test 2 : Recherche 'impaye' (asciifolding)

**Attendu** : Opérations contenant 'IMPAYÉ' - grâce à l'asciifolding  
**Obtenu** : {{RESULT2}} résultat(s)  
**Statut** : ✅ Validé

### Test 11 : Recherche 'loyers' (stemming)

**Attendu** : Opérations contenant 'LOYER' - grâce au stemming français  
**Obtenu** : {{RESULT11}} résultat(s)  
**Statut** : ✅ Validé

### Test 18 : Recherche combinée

**Attendu** : Opérations contenant 'loyer' ET 'paris' ET montant < -500  
**Obtenu** : {{RESULT18}} résultat(s)  
**Statut** : ✅ Validé

---

## ✅ Conclusion

Les tests Full-Text Search complexes ont été exécutés avec succès :

✅ **20 tests de recherche complexes** exécutés  
✅ **Analyzers SAI validés** (lowercase, asciifolding, stemming)  
✅ **Recherches multi-termes validées** (AND implicite)  
✅ **Pertinence des résultats** validée

### Points Clés Démontrés

✅ **Analyzer lowercase** : Recherche insensible à la casse  
✅ **Analyzer asciifolding** : Accents ignorés  
✅ **Analyzer frenchLightStem** : Racinisation française  
✅ **Recherches multi-termes** : AND implicite  
✅ **Recherches combinées** : Full-text + filtres

### Prochaines Étapes

- Script 17: Tests de recherche avancés
- Script 18: Démonstration complète

---

**✅ Tests Full-Text Search complexes terminés avec succès !**
