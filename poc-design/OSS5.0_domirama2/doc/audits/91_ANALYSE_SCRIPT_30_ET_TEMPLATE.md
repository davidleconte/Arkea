# 📋 Analyse : Script 30 - Requêtes STARTROW/STOPROW

**Date** : 2025-11-27
**Script analysé** : `30_demo_requetes_startrow_stoprow.sh`
**Objectif** : Déterminer le template approprié ou créer un nouveau template

---

## 🔍 Analyse du Script 30

### Caractéristiques Principales

1. **Type de script** : Démonstration de requêtes CQL avec ciblage précis (STARTROW/STOPROW équivalent)
2. **Méthode d'exécution** : Utilise `cqlsh` directement (pas Spark, pas Python)
3. **Structure** :
   - Vérifications préalables (HCD)
   - 3 exemples de requêtes CQL
   - Explications des équivalences HBase → HCD
   - Comparaison performance (avec/sans SAI)
4. **Spécificités** :
   - Exécute des requêtes CQL directement via `cqlsh`
   - Plusieurs exemples de requêtes (date précise, date + numero_op, avec SAI)
   - Pas de génération de rapport markdown automatique
   - Pas de structure didactique complète
   - Pas de capture structurée des résultats
   - Pas de mesure de performance détaillée

### Code CQL Exécuté

Le script exécute 3 requêtes CQL différentes :

1. **Requête 1** : Ciblage par date précise (plage de dates)
2. **Requête 2** : Ciblage par date + numéro opération (plage complète)
3. **Requête 3** : Ciblage avec SAI (date + numero_op + full-text search)

### Équivalences HBase → HCD

- **STARTROW/STOPROW HBase** → `WHERE date_op >= start AND date_op <= end AND numero_op >= start AND numero_op <= end`
- **SCAN avec plages de rowkeys** → `SELECT ... WHERE clustering_keys BETWEEN ...`
- **Ciblage précis** → Filtrage par clustering keys (date_op, numero_op)

### Valeur Ajoutée SAI

- Index sur `date_op` (clustering key) pour performance
- Index sur `numero_op` (clustering key) pour performance
- Index sur `libelle` (full-text SAI) pour recherche textuelle
- Combinaison des index pour recherche optimisée

---

## 📊 Comparaison avec Templates Existants

### Template 68 : Script Démonstration Requêtes CQL

**Points communs** :

- ✅ Structure didactique avec explications
- ✅ Affichage de requêtes CQL
- ✅ Génération de rapport markdown
- ✅ Capture de résultats
- ✅ Mesure de performance
- ✅ Équivalences HBase → HCD
- ✅ Valeur ajoutée SAI

**Différences** :

- ⚠️ Template 68 : Générique pour toutes les requêtes CQL
- ✅ Script 30 : Spécifique aux requêtes STARTROW/STOPROW
- ⚠️ Template 68 : Peut être utilisé pour TIMERANGE, STARTROW/STOPROW, etc.
- ✅ Script 30 : Focus sur ciblage précis par clustering keys

**Verdict** : **Template 68 est parfaitement adapté** pour le script 30. C'est exactement le même pattern que le script 29 (TIMERANGE), mais avec un concept différent (STARTROW/STOPROW).

---

### Template 43 : Script Didactique Général

**Points communs** :

- ✅ Structure didactique avec explications
- ✅ Affichage de requêtes CQL
- ✅ Génération de rapport markdown

**Différences** :

- ⚠️ Template 43 : Générique (peut être pour setup, test, etc.)
- ✅ Script 30 : Spécifique aux requêtes CQL avec STARTROW/STOPROW
- ⚠️ Template 43 : Peut utiliser Spark ou Python
- ✅ Script 30 : Utilise uniquement `cqlsh`
- ❌ Template 43 : Pas de mesure de performance obligatoire
- ✅ Script 30 : Nécessite mesure de performance

**Verdict** : Template 43 pourrait être adapté, mais Template 68 est plus approprié car spécifique aux requêtes CQL.

---

### Template 63 : Script d'Orchestration

**Points communs** :

- ✅ Plusieurs démonstrations
- ✅ Structure didactique
- ✅ Génération de rapport

**Différences** :

- ❌ Template 63 : Orchestre plusieurs scripts
- ✅ Script 30 : Exécute plusieurs requêtes dans un seul script
- ❌ Template 63 : Appelle d'autres scripts
- ✅ Script 30 : Exécute directement des requêtes CQL
- ❌ Template 63 : Trop complexe pour ce cas d'usage

**Verdict** : Template 63 est trop complexe et pas adapté.

---

## 🎯 Recommandation : Utiliser Template 68

### Justification

1. **Même pattern que script 29** : Le script 30 suit exactement le même pattern que le script 29, mais démontre un concept différent (STARTROW/STOPROW vs TIMERANGE)
2. **Template 68 déjà créé** : Le Template 68 a été créé spécifiquement pour ce type de script (démonstration requêtes CQL)
3. **Structure identique** : Les deux scripts ont la même structure (3 requêtes, équivalences HBase → HCD, valeur ajoutée SAI)
4. **Réutilisation optimale** : Pas besoin de créer un nouveau template, Template 68 est parfaitement adapté

### Différences entre Script 29 et Script 30

| Aspect | Script 29 (TIMERANGE) | Script 30 (STARTROW/STOPROW) |
|--------|----------------------|------------------------------|
| **Concept HBase** | TIMERANGE | STARTROW/STOPROW |
| **Équivalent CQL** | WHERE date_op >= start AND date_op < end | WHERE date_op >= start AND date_op <= end AND numero_op >= start AND numero_op <= end |
| **Focus** | Fenêtre glissante temporelle | Ciblage précis par clustering keys |
| **Clustering keys utilisés** | date_op uniquement | date_op + numero_op |
| **Structure** | Identique (3 requêtes) | Identique (3 requêtes) |
| **Template** | Template 68 | **Template 68** |

### Structure Proposée avec Template 68

Le script 30 version didactique suivra exactement la même structure que le script 29 :

1. **PARTIE 0** : Vérifications (HCD, cqlsh, schéma)
2. **PARTIE 1** : Contexte et stratégie (équivalences HBase → HCD, valeur ajoutée SAI)
3. **PARTIE 2** : Requêtes CQL (3 requêtes avec fonction `execute_query()`)
   - Requête 1 : Ciblage par date précise
   - Requête 2 : Ciblage par date + numéro opération
   - Requête 3 : Ciblage avec SAI (date + numero_op + full-text)
4. **PARTIE 3** : Comparaison performance (avec/sans SAI)
5. **PARTIE 4** : Génération rapport (markdown structuré)

---

## 📝 Différences avec les Autres Templates

| Aspect | Template 43 | Template 63 | Template 65 | **Template 68** |
|--------|-------------|-------------|-------------|-----------------|
| **Type** | Générique | Orchestration | Délégation Python | **Requêtes CQL** |
| **Méthode** | Spark/Python | Appels scripts | Python | **cqlsh direct** |
| **Nombre requêtes** | 1 | N scripts | 1 | **N requêtes CQL** |
| **Mesure performance** | ⚠️ Optionnelle | ❌ Non | ⚠️ Optionnelle | **✅ Obligatoire** |
| **Valeur ajoutée SAI** | ⚠️ Optionnelle | ❌ Non | ❌ Non | **✅ Obligatoire** |
| **Équivalences HBase** | ⚠️ Optionnelles | ❌ Non | ❌ Non | **✅ Obligatoires** |
| **Tracing CQL** | ❌ Non | ❌ Non | ❌ Non | **✅ Oui** |

---

## ✅ Conclusion

### Recommandation

**Utiliser Template 68** : Script Démonstration Requêtes CQL

**Justification** :

1. Le script 30 suit exactement le même pattern que le script 29
2. Template 68 a été créé spécifiquement pour ce type de script
3. La structure est identique (3 requêtes, équivalences HBase → HCD, valeur ajoutée SAI)
4. Pas besoin de créer un nouveau template, réutilisation optimale

### Prochaines Étapes

1. Appliquer le Template 68 au script 30 pour créer `30_demo_requetes_startrow_stoprow_v2_didactique.sh`
2. Adapter les 3 requêtes avec les comptes réels (comme pour script 29)
3. Générer le rapport markdown automatique
4. Tester et valider

### Points Clés à Adapter

- **Équivalences HBase → HCD** : STARTROW/STOPROW → WHERE sur clustering keys
- **Requête 1** : Ciblage par date précise (plage de dates)
- **Requête 2** : Ciblage par date + numéro opération (plage complète)
- **Requête 3** : Ciblage avec SAI (date + numero_op + full-text search)
- **Valeur ajoutée SAI** : Index sur clustering keys (date_op, numero_op) + full-text

---

**Date de création** : 2025-11-27
**Auteur** : Analyse du script 30
**Version** : 1.0
