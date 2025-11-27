# 📊 Analyse Comparative : Scripts 28 - Fenêtre Glissante

**Date** : 2025-11-27  
**Objectif** : Comparer les apports fonctionnels des différentes versions du script 28  
**Scripts analysés** :
- `28_demo_fenetre_glissante.sh` (version originale)
- `28_demo_fenetre_glissante_spark_submit.sh` (version spark-submit)
- `28_demo_fenetre_glissante_v2_didactique.sh` (version didactique v2)

---

## 📋 Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Comparaison fonctionnelle détaillée](#comparaison-fonctionnelle-détaillée)
3. [Apports spécifiques par version](#apports-spécifiques-par-version)
4. [Recommandations d'utilisation](#recommandations-dutilisation)
5. [Conclusion](#conclusion)

---

## 📊 Vue d'ensemble

### Caractéristiques générales

| Caractéristique | Version Originale | Version spark-submit | Version Didactique v2 |
|----------------|-------------------|---------------------|----------------------|
| **Lignes de code** | 276 | 337 | 749 |
| **Méthode d'export** | Spark direct | Spark direct | DSBulk + Spark |
| **Gestion VECTOR** | Exclusion dans SELECT | Exclusion dans SELECT | DSBulk → JSON → Spark |
| **Documentation auto** | ❌ Non | ❌ Non | ✅ Oui (markdown) |
| **Structure didactique** | ❌ Basique | ⚠️ Partielle | ✅ Complète |
| **Paramètres** | Fenêtre/décalage (jours) | Fenêtre/décalage (jours) | Année/mois/nb_mois/compression |
| **Vérifications** | Basiques | Basiques | Complètes (HCD, Spark, DSBulk, Java) |
| **Rapport markdown** | ❌ Non | ❌ Non | ✅ Oui (structuré) |

---

## 🔍 Comparaison fonctionnelle détaillée

### 1. Méthode d'export des données

#### Version Originale (`28_demo_fenetre_glissante.sh`)
```scala
// Lecture directe depuis HCD avec Spark
val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("table" -> "operations_by_account", "keyspace" -> "domirama2_poc"))
  .load()
  .select(/* colonnes sans libelle_embedding */)
  .filter(col("date_op") >= startDate && col("date_op") < endDate)
```
- ✅ **Avantage** : Simple, direct
- ❌ **Limitation** : Échoue si le type VECTOR est présent dans le schéma (même exclu dans SELECT)

#### Version spark-submit (`28_demo_fenetre_glissante_spark_submit.sh`)
```scala
// Même approche que version originale
val df = spark.read
  .format("org.apache.spark.sql.cassandra")
  .options(Map("table" -> "operations_by_account", "keyspace" -> "domirama2_poc"))
  .load()
  .select(/* colonnes sans libelle_embedding */)
  .filter(col("date_op") >= startDate && col("date_op") < endDate)
```
- ✅ **Avantage** : Structure plus détaillée (statistiques, vérification)
- ❌ **Limitation** : Même problème VECTOR que version originale

#### Version Didactique v2 (`28_demo_fenetre_glissante_v2_didactique.sh`)
```bash
# ÉTAPE 1 : DSBulk exporte HCD → JSON
dsbulk unload --connector.name json \
  --query.file query.cql \
  --connector.json.url /tmp/json_export \
  --connector.json.compression gzip

# ÉTAPE 2 : Spark convertit JSON → Parquet
val df_json = spark.read.json(jsonPath)
df_json.write.parquet(outputPath)
```
- ✅ **Avantage** : Contourne le problème VECTOR (DSBulk gère le type VECTOR)
- ✅ **Avantage** : Préservation de la colonne vector (en format JSON string)
- ✅ **Avantage** : Deux options : garder vector en JSON ou reconvertir en ArrayType

---

### 2. Gestion des paramètres

#### Version Originale
```bash
# Paramètres : window_days, shift_days (optionnels, défaut: 7, 1)
./28_demo_fenetre_glissante.sh [window_days] [shift_days]
```
- ⚠️ **Limitation** : Paramètres en jours, pas en mois
- ⚠️ **Limitation** : Fenêtre fixe (3 mois hardcodés dans la boucle)

#### Version spark-submit
```bash
# Mêmes paramètres que version originale
./28_demo_fenetre_glissante_spark_submit.sh [window_days] [shift_days]
```
- ⚠️ **Limitation** : Même limitation que version originale

#### Version Didactique v2
```bash
# Paramètres : start_year, start_month, num_months, compression
./28_demo_fenetre_glissante_v2_didactique.sh [start_year] [start_month] [num_months] [compression]
# Exemple : ./28_demo_fenetre_glissante_v2_didactique.sh 2024 11 2 snappy
```
- ✅ **Avantage** : Paramètres flexibles (année, mois, nombre de mois)
- ✅ **Avantage** : Compression configurable (snappy, gzip, lz4)
- ✅ **Avantage** : Fenêtres calculées dynamiquement

---

### 3. Structure didactique et documentation

#### Version Originale
- ❌ Pas de structure didactique
- ❌ Pas d'explications détaillées
- ❌ Pas de rapport markdown
- ⚠️ Affichage minimal (succès/erreur)

#### Version spark-submit
- ⚠️ Structure partiellement didactique
- ✅ Statistiques affichées (date_min, date_max, comptes_uniques)
- ✅ Vérification de l'export (lecture Parquet)
- ❌ Pas de rapport markdown
- ⚠️ Explications limitées

#### Version Didactique v2
- ✅ Structure didactique complète (6 parties)
- ✅ Explications détaillées pour chaque étape
- ✅ Code Spark affiché avant exécution
- ✅ Équivalences HBase → HCD documentées
- ✅ Rapport markdown automatique avec :
  - Tableau récapitulatif des fenêtres
  - Résultats détaillés par fenêtre
  - Statistiques globales
  - Conclusion structurée

---

### 4. Gestion des erreurs et vérifications

#### Version Originale
```bash
# Vérifications minimales
- HCD démarré (nc -z localhost 9042)
- Spark Cassandra Connector JAR présent
```
- ⚠️ Vérifications basiques
- ❌ Pas de vérification DSBulk
- ❌ Pas de vérification Java
- ❌ Pas de gestion d'erreurs détaillée

#### Version spark-submit
```bash
# Mêmes vérifications que version originale
- HCD démarré
- Spark Cassandra Connector JAR présent
- Script Scala présent (pour spark-submit)
```
- ⚠️ Vérifications basiques
- ❌ Pas de vérification DSBulk
- ❌ Pas de vérification Java

#### Version Didactique v2
```bash
# Vérifications complètes
- HCD démarré
- Spark installé et configuré
- DSBulk installé et accessible
- Java configuré (jenv)
- Répertoire de sortie accessible
```
- ✅ Vérifications complètes
- ✅ Gestion d'erreurs détaillée
- ✅ Messages d'erreur explicites

---

### 5. Extraction et affichage des résultats

#### Version Originale
```bash
# Affichage minimal
grep -E "(✅|⚠️|opérations|Export|Terminé|count)" | head -10
```
- ⚠️ Affichage filtré (peut perdre des informations)
- ❌ Pas d'extraction structurée des résultats
- ❌ Pas de stockage des résultats pour rapport

#### Version spark-submit
```bash
# Affichage filtré similaire
grep -E "(✅|⚠️|📥|📊|💾|🔍|opérations|Export|Terminé|count|Statistiques|Vérification)" | head -15
```
- ⚠️ Affichage filtré (peut perdre des informations)
- ⚠️ Extraction partielle (statistiques affichées)
- ❌ Pas de stockage des résultats pour rapport

#### Version Didactique v2
```bash
# Capture complète dans TEMP_OUTPUT
spark-shell ... 2>&1 | tee -a "$TEMP_OUTPUT" > /dev/null

# Extraction robuste depuis TEMP_OUTPUT
count=$(grep -i "Total opérations" "$TEMP_OUTPUT" | tail -1 | grep -oE "[0-9]+" | head -1)
count_read=$(grep -i "vérification ok.*opérations lues" "$TEMP_OUTPUT" | tail -1 | grep -oE "[0-9]+" | head -1)

# Stockage dans WINDOW_RESULTS pour rapport
WINDOW_RESULTS+=("$window_id|$start_date|$end_date|$output_path|$count|$count_read")
```
- ✅ Capture complète de la sortie
- ✅ Extraction robuste avec fallbacks multiples
- ✅ Stockage structuré des résultats
- ✅ Génération de rapport markdown automatique

---

### 6. Fonctionnalités spécifiques

#### Version Originale
- ✅ Export par fenêtre glissante
- ✅ Mode overwrite (idempotence)
- ✅ Partitionnement par date_op
- ❌ Pas de vérification post-export
- ❌ Pas de statistiques détaillées

#### Version spark-submit
- ✅ Export par fenêtre glissante
- ✅ Mode overwrite (idempotence)
- ✅ Partitionnement par date_op
- ✅ Vérification post-export (lecture Parquet)
- ✅ Statistiques détaillées (date_min, date_max, comptes_uniques)
- ✅ Compression configurable (hardcodée: snappy)

#### Version Didactique v2
- ✅ Export par fenêtre glissante
- ✅ Mode overwrite (idempotence)
- ✅ Partitionnement par date_op
- ✅ Vérification post-export (lecture Parquet)
- ✅ Statistiques détaillées (date_min, date_max, comptes_uniques)
- ✅ Compression configurable (paramètre)
- ✅ **NOUVEAU** : Gestion du type VECTOR via DSBulk
- ✅ **NOUVEAU** : Préservation de la colonne vector (optionnelle)
- ✅ **NOUVEAU** : Rapport markdown structuré
- ✅ **NOUVEAU** : Structure didactique complète

---

## 🎯 Apports spécifiques par version

### Version Originale (`28_demo_fenetre_glissante.sh`)

**Apports** :
- ✅ Démonstration de base de la fenêtre glissante
- ✅ Code simple et lisible
- ✅ Fonctionne si pas de colonne VECTOR

**Limitations** :
- ❌ Échoue avec colonne VECTOR (même exclue)
- ❌ Pas de documentation automatique
- ❌ Paramètres peu flexibles
- ❌ Pas de vérification post-export

**Cas d'usage** :
- Démonstration rapide sans colonne VECTOR
- Apprentissage de base du concept

---

### Version spark-submit (`28_demo_fenetre_glissante_spark_submit.sh`)

**Apports par rapport à version originale** :
- ✅ Statistiques détaillées (date_min, date_max, comptes_uniques)
- ✅ Vérification post-export (lecture Parquet)
- ✅ Code plus structuré et commenté
- ✅ Meilleure gestion des erreurs

**Limitations** :
- ❌ Même problème VECTOR que version originale
- ❌ Pas de documentation automatique
- ❌ Paramètres peu flexibles
- ⚠️ Nom "spark-submit" mais utilise `spark-shell -i`

**Cas d'usage** :
- Démonstration avec vérifications (sans colonne VECTOR)
- Production (si pas de colonne VECTOR)

---

### Version Didactique v2 (`28_demo_fenetre_glissante_v2_didactique.sh`)

**Apports par rapport aux versions précédentes** :

#### 1. Résolution du problème VECTOR
- ✅ Utilise DSBulk pour contourner le problème VECTOR
- ✅ DSBulk exporte vers JSON (gère le type VECTOR)
- ✅ Spark lit le JSON (pas de problème VECTOR)
- ✅ Option de préservation de la colonne vector

#### 2. Documentation automatique
- ✅ Génération de rapport markdown structuré
- ✅ Tableau récapitulatif des fenêtres
- ✅ Résultats détaillés par fenêtre
- ✅ Statistiques globales
- ✅ Conclusion avec points clés

#### 3. Structure didactique complète
- ✅ 6 parties structurées (Vérifications, Contexte, Fonction, Calcul, Boucle, Rapport)
- ✅ Explications détaillées pour chaque étape
- ✅ Code Spark affiché avant exécution
- ✅ Équivalences HBase → HCD documentées
- ✅ Cinématique complète de chaque étape

#### 4. Paramètres flexibles
- ✅ Année de début configurable
- ✅ Mois de début configurable
- ✅ Nombre de mois configurable
- ✅ Compression configurable (snappy, gzip, lz4)

#### 5. Vérifications complètes
- ✅ Vérification HCD, Spark, DSBulk, Java
- ✅ Vérification répertoire de sortie
- ✅ Gestion d'erreurs détaillée

#### 6. Extraction robuste des résultats
- ✅ Capture complète de la sortie
- ✅ Extraction avec fallbacks multiples
- ✅ Stockage structuré des résultats
- ✅ Génération de rapport automatique

**Cas d'usage** :
- ✅ **Production** : Avec colonne VECTOR
- ✅ **Démonstration** : Pour livrable client
- ✅ **Documentation** : Pour intégration dans restitution
- ✅ **Apprentissage** : Pour comprendre le processus complet

---

## 📊 Tableau comparatif synthétique

| Fonctionnalité | Originale | spark-submit | Didactique v2 |
|---------------|-----------|--------------|---------------|
| **Export fonctionnel** | ✅ Oui (sans VECTOR) | ✅ Oui (sans VECTOR) | ✅ Oui (avec VECTOR) |
| **Gestion VECTOR** | ❌ Échoue | ❌ Échoue | ✅ DSBulk + Spark |
| **Statistiques** | ❌ Non | ✅ Oui | ✅ Oui |
| **Vérification export** | ❌ Non | ✅ Oui | ✅ Oui |
| **Documentation auto** | ❌ Non | ❌ Non | ✅ Oui (markdown) |
| **Structure didactique** | ❌ Non | ⚠️ Partielle | ✅ Complète |
| **Paramètres flexibles** | ⚠️ Limités | ⚠️ Limités | ✅ Complets |
| **Vérifications** | ⚠️ Basiques | ⚠️ Basiques | ✅ Complètes |
| **Rapport markdown** | ❌ Non | ❌ Non | ✅ Oui |
| **Préservation vector** | ❌ Non | ❌ Non | ✅ Oui (option) |
| **Compression configurable** | ⚠️ Hardcodée | ⚠️ Hardcodée | ✅ Paramètre |

---

## 💡 Recommandations d'utilisation

### Version Originale
**Utiliser pour** :
- Démonstration rapide sans colonne VECTOR
- Apprentissage de base du concept
- Tests simples

**Ne pas utiliser pour** :
- Production (pas de vérifications)
- Tables avec colonne VECTOR
- Documentation client

---

### Version spark-submit
**Utiliser pour** :
- Démonstration avec vérifications (sans colonne VECTOR)
- Production (si pas de colonne VECTOR)
- Tests avec statistiques

**Ne pas utiliser pour** :
- Tables avec colonne VECTOR
- Documentation client (pas de rapport)
- Démonstrations didactiques complètes

---

### Version Didactique v2
**Utiliser pour** :
- ✅ **Production** : Avec ou sans colonne VECTOR
- ✅ **Démonstration client** : Rapport markdown structuré
- ✅ **Documentation** : Pour intégration dans restitution
- ✅ **Apprentissage** : Structure didactique complète
- ✅ **Livrables** : Documentation automatique

**Toujours utiliser** :
- Quand la colonne VECTOR est présente
- Pour les démonstrations client
- Pour générer de la documentation

---

## ✅ Conclusion

### Apports fonctionnels de la version Didactique v2

La version `28_demo_fenetre_glissante_v2_didactique.sh` apporte des **améliorations fonctionnelles significatives** par rapport aux versions précédentes :

1. **Résolution du problème VECTOR** : Utilise DSBulk + Spark au lieu de Spark direct
2. **Documentation automatique** : Génération de rapport markdown structuré
3. **Structure didactique** : 6 parties avec explications détaillées
4. **Paramètres flexibles** : Année, mois, nombre, compression configurables
5. **Vérifications complètes** : HCD, Spark, DSBulk, Java
6. **Extraction robuste** : Capture complète avec fallbacks multiples
7. **Préservation vector** : Option de garder la colonne vector (JSON ou ArrayType)

### Recommandation finale

**Pour la production et les démonstrations client** : Utiliser **exclusivement** la version Didactique v2 (`28_demo_fenetre_glissante_v2_didactique.sh`).

**Justification** :
- ✅ Fonctionne avec colonne VECTOR
- ✅ Documentation automatique pour livrables
- ✅ Structure didactique pour démonstrations
- ✅ Paramètres flexibles pour différents cas d'usage
- ✅ Vérifications complètes pour robustesse

Les versions originales peuvent être conservées pour référence historique, mais ne doivent plus être utilisées en production.

---

**Date de création** : 2025-11-27  
**Auteur** : Analyse comparative des scripts 28  
**Version** : 1.0


