# 📋 Analyse : Script 28 - Fenêtre Glissante (spark-submit)

**Date** : 2025-11-26
**Script analysé** : `28_demo_fenetre_glissante_spark_submit.sh`
**Objectif** : Déterminer le template approprié ou créer un nouveau template

---

## 🔍 Analyse du Script 28

### Caractéristiques Principales

1. **Type de script** : Export avec fenêtre glissante (plusieurs exports en boucle)
2. **Méthode d'exécution** : Utilise `spark-shell -i` (pas vraiment `spark-submit` malgré le nom)
3. **Structure** :
   - Vérifications préalables (HCD, Spark, etc.)
   - Fonction `export_window()` qui crée un script Scala temporaire
   - Boucle sur plusieurs fenêtres (ex: 3 mois)
   - Vérification des exports créés
4. **Spécificités** :
   - Crée un script Scala temporaire avec paramètres dynamiques (année, mois)
   - Exécute plusieurs exports en séquence (fenêtre glissante)
   - Pas de génération de rapport markdown automatique
   - Pas de structure didactique complète

### Code Scala Temporaire

Le script crée dynamiquement un script Scala avec :

- Paramètres injectés : `startDate`, `endDate`, `outputPath`
- Lecture depuis HCD avec filtrage par dates
- Exclusion de la colonne `libelle_embedding` (type VECTOR)
- Export Parquet avec partitionnement
- Vérification de l'export

### Équivalences HBase → HCD

- **TIMERANGE HBase** → `WHERE date_op >= startDate AND date_op < endDate`
- **Fenêtre glissante** → Boucle sur plusieurs périodes (ex: mois par mois)
- **Export incrémental** → Mode `overwrite` pour idempotence

---

## 📊 Comparaison avec Templates Existants

### Template 66 : Script Export Didactique

**Points communs** :

- ✅ Export HCD → Parquet
- ✅ Filtrage par dates (TIMERANGE)
- ✅ Structure didactique avec explications
- ✅ Génération de rapport markdown

**Différences** :

- ❌ Template 66 : Export unique (une seule période)
- ✅ Script 28 : Fenêtre glissante (plusieurs périodes en boucle)
- ❌ Template 66 : Utilise DSBulk + Spark (pour éviter problème VECTOR)
- ✅ Script 28 : Utilise Spark directement (exclut VECTOR dans SELECT)
- ❌ Template 66 : Pas de boucle sur plusieurs fenêtres
- ✅ Script 28 : Boucle sur plusieurs fenêtres (ex: 3 mois)

### Template 65 : Script Test avec Délégation Python

**Points communs** :

- ✅ Structure didactique
- ✅ Génération de rapport markdown

**Différences** :

- ❌ Template 65 : Délègue à Python
- ✅ Script 28 : Délègue à Spark/Scala
- ❌ Template 65 : Pour les tests
- ✅ Script 28 : Pour les exports

---

## 🎯 Recommandation : Nouveau Template

### Template 67 : Script Export avec Fenêtre Glissante

**Justification** :

1. **Spécificité** : La fenêtre glissante (boucle sur plusieurs périodes) est un pattern unique
2. **Complexité** : Nécessite une structure spécifique pour gérer plusieurs exports
3. **Didactique** : Doit afficher les résultats pour chaque fenêtre
4. **Rapport** : Doit documenter toutes les fenêtres exportées

### Structure Proposée

```bash
#!/bin/bash
# ============================================
# Script XX : Export Fenêtre Glissante (Version Didactique)
# Exporte les données depuis HCD vers Parquet via Spark
# Équivalent HBase: TIMERANGE avec fenêtre glissante
# ============================================
#
# OBJECTIF :
#   Ce script démontre la fenêtre glissante pour les exports incrémentaux,
#   équivalent au TIMERANGE HBase avec décalage progressif.
#
#   Cette version didactique affiche :
#   - Le code Spark complet pour chaque fenêtre avec explications
#   - Les équivalences HBase → HCD détaillées
#   - Les résultats d'export détaillés pour chaque fenêtre
#   - La cinématique complète de chaque étape
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Spark 3.5.1 installé et configuré
#   - Spark Cassandra Connector 3.5.0 disponible
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./XX_export_fenetre_glissante.sh [window_days] [shift_days] [start_date] [end_date]
#
# PARAMÈTRES :
#   $1 : Taille de la fenêtre en jours (optionnel, défaut: 30)
#   $2 : Décalage de la fenêtre en jours (optionnel, défaut: 30)
#   $3 : Date de début (format: YYYY-MM-DD, optionnel, défaut: 2024-01-01)
#   $4 : Date de fin (format: YYYY-MM-DD, optionnel, défaut: 2024-04-01)
#
# SORTIE :
#   - Code Spark complet affiché avec explications pour chaque fenêtre
#   - Fichiers Parquet créés pour chaque fenêtre
#   - Statistiques de chaque export
#   - Vérification de chaque export
#   - Documentation structurée générée
#
# ============================================

# PARTIE 1: VÉRIFICATIONS
# - HCD démarré
# - Spark disponible
# - Répertoires de sortie

# PARTIE 2: CONFIGURATION
# - Paramètres de la fenêtre glissante
# - Calcul des dates pour chaque fenêtre
# - Configuration Spark

# PARTIE 3: FONCTION EXPORT_WINDOW
# - Création du script Scala temporaire
# - Affichage du code Spark avec explications
# - Exécution via spark-shell
# - Capture des résultats
# - Vérification de l'export

# PARTIE 4: BOUCLE FENÊTRE GLISSANTE
# - Pour chaque fenêtre :
#   - Calcul des dates (start_date, end_date)
#   - Appel à export_window()
#   - Affichage des résultats
#   - Stockage des statistiques

# PARTIE 5: VÉRIFICATION GLOBALE
# - Liste des exports créés
# - Statistiques globales
# - Vérification de cohérence

# PARTIE 6: GÉNÉRATION DU RAPPORT
# - Parsing des résultats de chaque fenêtre
# - Génération du rapport markdown structuré
# - Tableau récapitulatif de toutes les fenêtres
```

### Différences avec Template 66

| Aspect | Template 66 | Template 67 (Proposé) |
|--------|-------------|----------------------|
| **Nombre d'exports** | 1 export unique | Plusieurs exports (fenêtre glissante) |
| **Boucle** | Non | Oui (pour chaque fenêtre) |
| **Rapport** | 1 section export | 1 section par fenêtre + récapitulatif |
| **Statistiques** | 1 jeu de stats | Stats par fenêtre + stats globales |
| **Vérification** | 1 vérification | Vérification par fenêtre + globale |

---

## ✅ Conclusion

**Recommandation** : **Créer un nouveau Template 67** spécifiquement pour les scripts avec fenêtre glissante.

**Raisons** :

1. ✅ Pattern unique (boucle sur plusieurs fenêtres)
2. ✅ Nécessite une structure spécifique pour gérer plusieurs exports
3. ✅ Rapport markdown doit documenter toutes les fenêtres
4. ✅ Statistiques doivent être agrégées par fenêtre et globalement

**Prochaines étapes** :

1. Créer le Template 67 : `67_TEMPLATE_SCRIPT_EXPORT_FENETRE_GLISSANTE_DIDACTIQUE.md`
2. Appliquer le template au script 28 pour créer `28_demo_fenetre_glissante_v2_didactique.sh`
3. Tester et valider la version didactique

---

**Date de création** : 2025-11-26
**Auteur** : Analyse automatique
