# 🔍 Démonstration : Tests Acceptation/Opposition

**Date** : 2025-11-29 18:13:18
**Script** : 09_test_acceptation_opposition.sh
**Objectif** : Démontrer acceptation/opposition via requêtes CQL

---

## 📋 Table des Matières

1. [Contexte et Stratégie](#contexte-et-stratégie)
2. [Tests Exécutés](#tests-exécutés)
3. [Résultats par Test](#résultats-par-test)
4. [Conclusion](#conclusion)

---

## 📚 Contexte et Stratégie

### Équivalences HBase → HCD

| Concept HBase | Équivalent HCD (CQL) |
|---------------|----------------------|
| GET 'ACCEPT:...' | SELECT FROM acceptation_client |
| GET 'OPPOSITION:...' | SELECT FROM opposition_categorisation |
| PUT 'ACCEPT:...' | INSERT/UPDATE acceptation_client |
| PUT 'OPPOSITION:...' | INSERT/UPDATE opposition_categorisation |

---

## 🔍 Tests Exécutés

### Tableau Récapitulatif

| Test | Titre | Lignes | Temps (s) | Coordinateur (μs) | Total (μs) | Statut |
|------|-------|--------|-----------|-------------------|-----------|--------|
| 1 | Lecture Acceptation | 1 | .811716000 |  |  | ✅ OK |
| 2 | Vérification avant Affichage | 1 | .784632000 |  |  | ✅ OK |
| 3 | Lecture Opposition | 1 | .777485000 |  |  | ✅ OK |
| 4 | Vérification avant Catégorisation | 1 | .764005000 |  |  | ✅ OK |
| 5 | Activation Opposition | 0 | .826200000 |  |  | ✅ OK |
| 6 | Désactivation Opposition | 0 | .830614000 |  |  | ✅ OK |

---

## 📊 Résultats par Test

### Test 1 : Lecture Acceptation

- **Lignes retournées** : 1
- **Temps d'exécution** : .811716000s
- **Statut** : ✅ OK

**Requête CQL exécutée :**

```cql
SELECT code_efs, no_contrat, no_pse, accepted, accepted_at
FROM acceptation_client
WHERE code_efs = '1'
  AND no_contrat = '100000043'
  AND no_pse = 'PSE002';
```

**Résultats obtenus :**

```
 code_efs | no_contrat | no_pse | accepted | accepted_at
----------+------------+--------+----------+---------------------------------
        1 |  100000043 | PSE002 |     True | 2025-11-29 17:13:08.830000+0000
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------------+-----------+----------------+-----------

```

**Validation :**

- ✅ Requête exécutée avec succès
- ✅ 1 ligne(s) retournée(s)
- ✅ Les données correspondent aux critères de recherche
- ✅ Le résultat est conforme aux attentes

**Validation de cohérence (accepted/accepted_at) :**

- ✅ Les valeurs sont cohérentes
- 💡 accepted_at = date de la décision client (acceptation OU refus)
- 💡 Si accepted = false, accepted_at = date du refus (cohérent)
- 💡 Si accepted = true, accepted_at = date de l'acceptation
- 💡 Voir [doc/ANALYSE_COHERENCE_ACCEPTED_AT.md](../ANALYSE_COHERENCE_ACCEPTED_AT.md) pour plus de détails

### Test 2 : Vérification avant Affichage

- **Lignes retournées** : 1
- **Temps d'exécution** : .784632000s
- **Statut** : ✅ OK

**Requête CQL exécutée :**

```cql
SELECT accepted
FROM acceptation_client
WHERE code_efs = '1'
  AND no_contrat = '100000043'
  AND no_pse = 'PSE002';
```

**Résultats obtenus :**

```
 accepted
----------
     True

```

**Validation :**

- ✅ Requête exécutée avec succès
- ✅ 1 ligne(s) retournée(s)
- ✅ Les données correspondent aux critères de recherche
- ✅ Le résultat est conforme aux attentes

**Validation de cohérence (accepted/accepted_at) :**

- ✅ Les valeurs sont cohérentes
- 💡 accepted_at = date de la décision client (acceptation OU refus)
- 💡 Si accepted = false, accepted_at = date du refus (cohérent)
- 💡 Si accepted = true, accepted_at = date de l'acceptation
- 💡 Voir [doc/ANALYSE_COHERENCE_ACCEPTED_AT.md](../ANALYSE_COHERENCE_ACCEPTED_AT.md) pour plus de détails

### Test 3 : Lecture Opposition

- **Lignes retournées** : 1
- **Temps d'exécution** : .777485000s
- **Statut** : ✅ OK

**Requête CQL exécutée :**

```cql
SELECT code_efs, no_pse, opposed, opposed_at
FROM opposition_categorisation
WHERE code_efs = '1'
  AND no_pse = 'PSE001';
```

**Résultats obtenus :**

```
 code_efs | no_pse | opposed | opposed_at
----------+--------+---------+---------------------------------
        1 | PSE001 |   False | 2025-11-29 17:11:47.870000+0000
-----------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------------+-----------+----------------+-----------

```

**Validation :**

- ✅ Requête exécutée avec succès
- ✅ 1 ligne(s) retournée(s)
- ✅ Les données correspondent aux critères de recherche
- ✅ Le résultat est conforme aux attentes

**Validation de cohérence (opposed/opposed_at) :**

- ✅ Les valeurs sont cohérentes
- 💡 opposed_at = date de la décision d'opposition
- 💡 Si opposed = true, opposed_at = date d'activation de l'opposition
- 💡 Si opposed = false, opposed_at = date de désactivation de l'opposition

### Test 4 : Vérification avant Catégorisation

- **Lignes retournées** : 1
- **Temps d'exécution** : .764005000s
- **Statut** : ✅ OK

**Requête CQL exécutée :**

```cql
SELECT opposed
FROM opposition_categorisation
WHERE code_efs = '1'
  AND no_pse = 'PSE001';
```

**Résultats obtenus :**

```
 opposed
---------
   False

```

**Validation :**

- ✅ Requête exécutée avec succès
- ✅ 1 ligne(s) retournée(s)
- ✅ Les données correspondent aux critères de recherche
- ✅ Le résultat est conforme aux attentes

**Validation de cohérence (opposed/opposed_at) :**

- ✅ Les valeurs sont cohérentes
- 💡 opposed_at = date de la décision d'opposition
- 💡 Si opposed = true, opposed_at = date d'activation de l'opposition
- 💡 Si opposed = false, opposed_at = date de désactivation de l'opposition

### Test 5 : Activation Opposition

- **Lignes retournées** : 0
- **Temps d'exécution** : .826200000s
- **Statut** : ✅ OK

**Requête CQL exécutée :**

```cql
UPDATE opposition_categorisation
SET opposed = true,
    opposed_at = toTimestamp(now())
WHERE code_efs = '1'
  AND no_pse = 'PSE001';
```

**Résultat :** Aucune ligne retournée

**Explication :**
- La requête est un UPDATE/INSERT, donc aucun résultat n'est retourné (normal).
- L'opération a été exécutée avec succès.
- Pour vérifier le résultat, voir la section 'Démonstration de la modification' ci-dessous.

### Test 6 : Désactivation Opposition

- **Lignes retournées** : 0
- **Temps d'exécution** : .830614000s
- **Statut** : ✅ OK

**Requête CQL exécutée :**

```cql
UPDATE opposition_categorisation
SET opposed = false,
    opposed_at = toTimestamp(now())
WHERE code_efs = '1'
  AND no_pse = 'PSE001';
```

**Résultat :** Aucune ligne retournée

**Explication :**
- La requête est un UPDATE/INSERT, donc aucun résultat n'est retourné (normal).
- L'opération a été exécutée avec succès.
- Pour vérifier le résultat, voir la section 'Démonstration de la modification' ci-dessous.

**Démonstration de la modification :**

- Valeur avant modification : True
- Valeur après modification : False
- ✅ Validation : Modification appliquée avec succès (True → False)

**Note sur la modification :**
- Les opérations UPDATE sont atomiques
- Chaque modification est garantie d'être appliquée exactement une fois
- La valeur après modification = valeur attendue (vérifiée dans le script)

---

## ✅ Conclusion

### Points Clés Démontrés

- ✅ Lecture acceptation (GET équivalent)
- ✅ Vérification avant affichage
- ✅ Lecture opposition (GET équivalent)
- ✅ Vérification avant catégorisation
- ✅ Activation/désactivation opposition

---

**Date de génération** : 2025-11-29 18:13:18
