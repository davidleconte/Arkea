# 📋 Analyse : Script 29 - Requêtes Fenêtre Glissante

**Date** : 2025-11-27  
**Script analysé** : `29_demo_requetes_fenetre_glissante.sh`  
**Objectif** : Déterminer le template approprié ou créer un nouveau template

---

## 🔍 Analyse du Script 29

### Caractéristiques Principales

1. **Type de script** : Démonstration de requêtes CQL avec fenêtre glissante (TIMERANGE équivalent)
2. **Méthode d'exécution** : Utilise `cqlsh` directement (pas Spark, pas Python)
3. **Structure** :
   - Vérifications préalables (HCD)
   - 3 exemples de requêtes CQL
   - Explications des équivalences HBase → HCD
   - Comparaison performance (avec/sans SAI)
4. **Spécificités** :
   - Exécute des requêtes CQL directement via `cqlsh`
   - Plusieurs exemples de requêtes (mensuelle, 30 jours, avec SAI)
   - Pas de génération de rapport markdown automatique
   - Pas de structure didactique complète
   - Pas de capture structurée des résultats
   - Pas de mesure de performance détaillée

### Code CQL Exécuté

Le script exécute 3 requêtes CQL différentes :

1. **Requête mensuelle** : Fenêtre glissante pour janvier 2024
2. **Requête 30 jours** : Fenêtre glissante pour 30 derniers jours
3. **Requête avec SAI** : Combinaison date + full-text search

### Équivalences HBase → HCD

- **TIMERANGE HBase** → `WHERE date_op >= start AND date_op < end`
- **SCAN avec filtres temporels** → `SELECT ... WHERE date_op BETWEEN ...`
- **Requêtes par période** → Fenêtre glissante avec WHERE date_op

### Valeur Ajoutée SAI

- Index sur `date_op` (clustering key) pour performance
- Index sur `libelle` (full-text SAI) pour recherche textuelle
- Combinaison des deux index pour recherche optimisée

---

## 📊 Comparaison avec Templates Existants

### Template 43 : Script Didactique Général

**Points communs** :
- ✅ Structure didactique avec explications
- ✅ Affichage de requêtes CQL
- ✅ Génération de rapport markdown
- ✅ Capture de résultats

**Différences** :
- ⚠️ Template 43 : Générique (peut être pour setup, test, etc.)
- ✅ Script 29 : Spécifique aux requêtes CQL avec fenêtre glissante
- ⚠️ Template 43 : Peut utiliser Spark ou Python
- ✅ Script 29 : Utilise uniquement `cqlsh`
- ⚠️ Template 43 : Structure plus générale
- ✅ Script 29 : Focus sur plusieurs exemples de requêtes

**Verdict** : Template 43 pourrait être adapté, mais pas optimal car trop générique.

---

### Template 63 : Script d'Orchestration

**Points communs** :
- ✅ Plusieurs démonstrations
- ✅ Structure didactique
- ✅ Génération de rapport

**Différences** :
- ❌ Template 63 : Orchestre plusieurs scripts
- ✅ Script 29 : Exécute plusieurs requêtes dans un seul script
- ❌ Template 63 : Appelle d'autres scripts
- ✅ Script 29 : Exécute directement des requêtes CQL
- ❌ Template 63 : Trop complexe pour ce cas d'usage

**Verdict** : Template 63 est trop complexe et pas adapté.

---

### Template 65 : Délégation Python

**Points communs** :
- ✅ Structure didactique
- ✅ Génération de rapport

**Différences** :
- ❌ Template 65 : Délègue à Python
- ✅ Script 29 : Utilise `cqlsh` directement
- ❌ Template 65 : Pour tests complexes
- ✅ Script 29 : Pour démonstrations de requêtes CQL

**Verdict** : Template 65 n'est pas adapté (délégation Python non nécessaire).

---

## 🎯 Recommandation : Nouveau Template

### Template 68 : Script Démonstration Requêtes CQL

**Justification** :
1. **Spécificité** : Les scripts de démonstration de requêtes CQL avec `cqlsh` sont un pattern unique
2. **Complexité** : Nécessite une structure spécifique pour gérer plusieurs requêtes
3. **Didactique** : Doit afficher les requêtes, résultats attendus, résultats obtenus
4. **Rapport** : Doit documenter toutes les requêtes avec leurs résultats
5. **Performance** : Doit mesurer et documenter les temps d'exécution

### Structure Proposée

```bash
#!/bin/bash
# ============================================
# Script XX : Démonstration Requêtes [Nom] (Version Didactique)
# Démontre [fonctionnalité] via requêtes CQL directes
# Équivalent HBase: [concept HBase]
# ============================================
#
# OBJECTIF :
#   Ce script démontre [fonctionnalité] en exécutant [nombre] requêtes CQL
#   directement via cqlsh.
#   
#   Cette version didactique affiche :
#   - Les équivalences HBase → HCD détaillées
#   - Les requêtes CQL complètes avant exécution
#   - Les résultats attendus pour chaque requête
#   - Les résultats obtenus avec mesure de performance
#   - La valeur ajoutée SAI (si applicable)
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./XX_demo_requetes.sh [paramètres optionnels]
#
# SORTIE :
#   - Requêtes CQL affichées avec explications
#   - Résultats de chaque requête
#   - Mesures de performance
#   - Documentation structurée générée
#
# ============================================
```

### Structure Détaillée

#### PARTIE 0: VÉRIFICATIONS
- Vérification HCD démarré
- Vérification `cqlsh` disponible
- Vérification schéma et données

#### PARTIE 1: CONTEXTE ET STRATÉGIE
- Objectif de la démonstration
- Équivalences HBase → HCD
- Valeur ajoutée SAI (si applicable)
- Stratégie de démonstration

#### PARTIE 2: REQUÊTES CQL
Pour chaque requête :
1. **Titre et description** : Explication du concept
2. **Équivalence HBase** : Comment HBase fait la même chose
3. **Requête CQL** : Code CQL complet affiché
4. **Résultat attendu** : Ce qu'on s'attend à trouver
5. **Exécution** : Lancement avec `cqlsh` et mesure du temps
6. **Résultats obtenus** : Affichage formaté des résultats
7. **Analyse** : Comparaison attendu vs obtenu, performance

#### PARTIE 3: COMPARAISON PERFORMANCE
- Comparaison avec/sans SAI
- Mesures de performance
- Valeur ajoutée des index

#### PARTIE 4: GÉNÉRATION RAPPORT
- Capture de tous les résultats
- Génération de rapport markdown structuré
- Tableau récapitulatif des requêtes
- Statistiques globales

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

---

## ✅ Conclusion

### Recommandation

**Créer Template 68** : Script Démonstration Requêtes CQL

**Justification** :
1. Les scripts de démonstration de requêtes CQL avec `cqlsh` sont un pattern unique
2. Nécessitent une structure spécifique pour gérer plusieurs requêtes
3. Doivent mesurer et documenter les performances
4. Doivent expliquer les équivalences HBase → HCD
5. Doivent mettre en avant la valeur ajoutée SAI

### Prochaines Étapes

1. Créer le template `68_TEMPLATE_SCRIPT_DEMO_REQUETES_CQL.md`
2. Appliquer le template au script 29 pour créer `29_demo_requetes_fenetre_glissante_v2_didactique.sh`
3. Générer le rapport markdown automatique
4. Tester et valider

---

**Date de création** : 2025-11-27  
**Auteur** : Analyse du script 29  
**Version** : 1.0




