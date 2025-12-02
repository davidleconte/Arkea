# 📊 Analyse : Script 27 et Applicabilité du Template Didactique

**Date** : 2025-11-26  
**Script analysé** : `27_export_incremental_parquet.sh`  
**Objectif** : Analyser le script 27 et déterminer si un template existant est applicable, doit être enrichi, ou si un template spécifique est nécessaire

---

## 📋 Table des Matières

1. [Analyse du Script 27](#analyse-du-script-27)
2. [Comparaison avec Templates Existants](#comparaison-avec-templates-existants)
3. [Recommandations](#recommandations)
4. [Conclusion](#conclusion)

---

## 🔍 Analyse du Script 27

### Objectif du Script

Le script `27_export_incremental_parquet.sh` est un **script d'export/ETL sortant** qui :

1. **Lit des données** depuis HCD (table `operations_by_account`)
2. **Filtre les données** par fenêtre de dates (équivalent TIMERANGE HBase)
3. **Exporte les données** vers des fichiers Parquet (partitionnés par date_op)
4. **Vérifie l'export** (lecture des fichiers créés, cohérence)

### Structure Actuelle du Script

```bash
# Structure actuelle (286 lignes)
1. En-tête et commentaires (lignes 1-51)
2. Configuration des couleurs (lignes 55-80)
3. Configuration des variables (lignes 82-98)
4. Vérifications (lignes 100-127)
5. Affichage info (lignes 129-160)
6. Script Spark Scala temporaire (lignes 170-260)
7. Exécution Spark (lignes 262-271)
8. Messages finaux (lignes 276-284)
```

### Fonctionnalités Actuelles

✅ **Vérifications** :

- HCD démarré
- Spark Cassandra Connector JAR présent
- Java 11 configuré

✅ **Exécution Spark** :

- Création d'un script Scala temporaire
- Exécution via `spark-shell` en mode non-interactif
- Lecture depuis HCD avec filtrage par dates
- Export Parquet avec partitionnement et compression
- Vérification de l'export

✅ **Paramètres** :

- Date début (défaut: 2024-01-01)
- Date fin (défaut: 2024-02-01)
- Chemin de sortie (défaut: /tmp/exports/domirama/incremental/2024-01)
- Compression (défaut: snappy)

### Limitations Actuelles

❌ **Pas d'affichage du code Spark** :

- Le code Scala n'est pas affiché avant exécution
- Pas d'explication des transformations
- Pas d'explication du filtrage par dates

❌ **Vérifications basiques** :

- Pas de vérification détaillée des fichiers créés
- Pas de statistiques détaillées (taille, nombre de fichiers, etc.)

❌ **Pas de documentation structurée** :

- Pas de rapport markdown généré
- Pas de documentation pour livrable

❌ **Pas d'explication didactique** :

- Pas d'explication de l'équivalence HBase → HCD
- Pas d'explication du partitionnement
- Pas d'explication de la compression

---

## 🔄 Comparaison avec Templates Existants

### Option 1 : Utiliser le Template d'Ingestion (Template 50)

**Analyse** :

| Aspect | Script 11 (Ingestion) | Script 27 (Export) |
|--------|------------------------|---------------------|
| **Direction** | Parquet → HCD | HCD → Parquet |
| **Source** | Fichier Parquet | Table HCD |
| **Destination** | Table HCD | Fichiers Parquet |
| **Code Spark** | Lecture Parquet, écriture HCD | Lecture HCD, écriture Parquet |
| **Stratégie** | Multi-version (batch) | Export incrémental |
| **Vérifications** | Données chargées | Fichiers créés |

**Verdict** : ⚠️ **Partiellement applicable**

- ✅ Structure similaire (Spark, vérifications, code Scala)
- ❌ Direction inverse (export vs ingestion)
- ❌ Vérifications différentes (fichiers vs données)
- ❌ Pas de stratégie multi-version pour l'export

### Option 2 : Créer un Template Spécifique pour Export/ETL Sortant

**Avantages** :

- Template adapté spécifiquement aux scripts d'export
- Structure claire et dédiée
- Sections pertinentes pour les exports
- Facile à utiliser et maintenir

**Inconvénients** :

- Un template supplémentaire à maintenir
- Nécessite de choisir le bon template

**Verdict** : ✅ **Recommandé**

### Option 3 : Enrichir le Template d'Ingestion pour Gérer les Deux Directions

**Avantages** :

- Un seul template
- Sections optionnelles selon la direction

**Inconvénients** :

- Template très complexe
- Difficile à comprendre et utiliser
- Risque d'erreurs

**Verdict** : ⚠️ **Possible mais non recommandé**

---

## ✅ Recommandations

### Recommandation Finale

**Créer un template spécifique pour les scripts d'export/ETL sortant** (`66_TEMPLATE_SCRIPT_EXPORT_DIDACTIQUE.md`).

### Justification

1. **Différences fondamentales** :
   - Script 27 = Export (HCD → Parquet)
   - Script 11 = Ingestion (Parquet → HCD)
   - Script 10 = DDL (création de schéma)
   - Script 25 = DML (tests de recherche)
   - Besoins différents, structure différente

2. **Pertinence du besoin** :
   - Script 27 doit afficher le code Spark complet
   - Script 27 doit expliquer le filtrage par dates (TIMERANGE équivalent)
   - Script 27 doit expliquer le partitionnement et la compression
   - Script 27 doit vérifier les fichiers créés (pas les données chargées)

3. **Maintenabilité** :
   - Templates clairs et dédiés
   - Chaque template adapté à son usage
   - Facile à comprendre et utiliser

### Structure du Template Spécifique

Le template spécifique pour export (`66_TEMPLATE_SCRIPT_EXPORT_DIDACTIQUE.md`) doit inclure :

1. **PARTIE 0: Vérifications**
   - HCD démarré
   - Spark installé et configuré
   - Spark Cassandra Connector disponible
   - Répertoire de sortie accessible

2. **PARTIE 1: Contexte et Stratégie**
   - Équivalences HBase → HCD pour l'export
   - Explication du filtrage par dates (TIMERANGE)
   - Explication du partitionnement
   - Explication de la compression

3. **PARTIE 2: Code Spark - Lecture depuis HCD**
   - Code Spark pour lire depuis HCD
   - Explications du filtrage par dates
   - Vérifications (nombre d'opérations trouvées)

4. **PARTIE 3: Code Spark - Export Parquet**
   - Code Spark pour exporter vers Parquet
   - Explications du partitionnement
   - Explications de la compression
   - Options de performance

5. **PARTIE 4: Vérification de l'Export**
   - Lecture des fichiers créés
   - Vérification de la cohérence
   - Statistiques détaillées (taille, nombre de fichiers)

6. **PARTIE 5: Génération du Rapport**
   - Documentation structurée pour livrable
   - Code Spark complet
   - Résultats de l'export
   - Statistiques

7. **PARTIE 6: Résumé et Conclusion**
   - Points clés démontrés
   - Prochaines étapes

---

## 💡 Conclusion

### Recommandation

**Créer un template spécifique pour les scripts d'export** (`66_TEMPLATE_SCRIPT_EXPORT_DIDACTIQUE.md`).

### Prochaines Étapes

1. Créer le template `66_TEMPLATE_SCRIPT_EXPORT_DIDACTIQUE.md`
2. Appliquer le template au script 27
3. Tester l'exécution complète
4. Vérifier la génération du rapport markdown

---

**✅ Analyse terminée !**
