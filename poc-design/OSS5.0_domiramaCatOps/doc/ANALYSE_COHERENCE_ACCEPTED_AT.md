# 🔍 Analyse de Cohérence : Champ `accepted_at`

**Date** : 2025-11-28
**Problème identifié** : Incohérence sémantique du champ `accepted_at`

---

## 📋 Problème Identifié

### Situation Actuelle

Dans la table `acceptation_client`, on observe :

- `accepted = false` avec `accepted_at = 2024-05-20` (renseigné)

**Question** : Est-ce cohérent qu'`accepted_at` soit renseigné si `accepted = false` ?

---

## 🔍 Analyse Sémantique

### Option 1 : `accepted_at` = "Date d'acceptation"

**Logique** :

- Si `accepted = true` → `accepted_at` doit être renseigné (date de l'acceptation)
- Si `accepted = false` → `accepted_at` devrait être `NULL` (pas d'acceptation, donc pas de date)

**Incohérence** : ❌ Les données actuelles ont `accepted = false` avec `accepted_at` renseigné

### Option 2 : `accepted_at` = "Date de décision client"

**Logique** :

- Le client prend une décision (accepter OU refuser) à une date donnée
- `accepted_at` = date de cette décision, peu importe le résultat
- Si `accepted = true` → `accepted_at` = date d'acceptation
- Si `accepted = false` → `accepted_at` = date de refus

**Cohérence** : ✅ Les données actuelles sont cohérentes avec cette interprétation

**Recommandation** : Renommer `accepted_at` en `decision_at` ou `response_at` pour plus de clarté

---

## ✅ Décision et Correction

### Décision Retenue

**Option 2** : `accepted_at` signifie **"Date de la décision client"** (acceptation OU refus)

**Justification** :

1. Plus logique métier : le client prend une décision à une date donnée
2. Permet de tracer quand le client a pris sa décision, même s'il refuse
3. Cohérent avec les données actuelles
4. Utile pour l'historique et l'audit

### Corrections Apportées

1. **Schéma CQL** : Commentaire ajouté pour clarifier la sémantique
2. **Scripts de génération** : Commentaires ajoutés pour expliquer la logique
3. **Documentation** : Ce document créé pour expliquer la décision

### Recommandation Future

Pour plus de clarté, envisager de renommer `accepted_at` en `decision_at` dans une future version :

- Plus explicite sur la sémantique
- Évite la confusion avec "date d'acceptation uniquement"
- Cohérent avec la logique métier

---

## 📊 Validation

### Données Actuelles

```
code_efs | no_contrat | no_pse | accepted | accepted_at
---------+------------+--------+----------+---------------------------------
   1     | 100000043  | PSE002 |  False   | 2024-05-20 00:00:00.000000+0000
```

**Interprétation** :

- Le client a pris la décision de **refuser** l'affichage/catégorisation
- Cette décision a été prise le **2024-05-20**
- `accepted_at` = date de cette décision (refus)

**Cohérence** : ✅ **COHÉRENT** avec l'Option 2 (date de décision)

---

## 📝 Conclusion

Les données sont **cohérentes** si on interprète `accepted_at` comme **"date de la décision client"** plutôt que **"date d'acceptation"**.

**Action** : Documentation mise à jour pour clarifier cette sémantique.

**Recommandation** : Envisager le renommage en `decision_at` pour plus de clarté dans une future version.

---

**Date de génération** : 2025-11-28
