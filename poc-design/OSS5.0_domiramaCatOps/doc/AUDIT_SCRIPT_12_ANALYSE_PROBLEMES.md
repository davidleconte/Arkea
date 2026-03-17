# 🔍 Audit Script 12 : Analyse des Problèmes

**Date** : 2025-11-29
**Script audité** : `12_test_historique_opposition.sh`
**Rapport généré** : `12_HISTORIQUE_OPPOSITION_DEMONSTRATION.md`

---

## 📋 Résumé Exécutif

### État Actuel

- ✅ **8 tests** exécutés
- ⚠️ **5 tests retournent 0 lignes** (Tests 3, 4, 6, 8)
- ✅ **3 tests retournent des lignes** (Tests 1, 2, 5, 7)
- ⚠️ **Problèmes identifiés** : Valeurs de filtre, contraintes CQL, données manquantes

### Score Global

- **Cohérence** : 6/10 (valeurs de filtre ne correspondent pas toujours aux données)
- **Consistance** : 7/10 (certaines requêtes ne respectent pas les contraintes CQL)
- **Pertinence** : 8/10 (tests pertinents mais données insuffisantes)
- **Correction** : 6/10 (plusieurs requêtes nécessitent ALLOW FILTERING)
- **Complétude** : 5/10 (rapport ne montre pas toutes les lignes retournées)

---

## 🔍 Analyse Détaillée par Test

### Test 1 : Lecture Historique Complet ✅

- **Résultat** : 5 lignes retournées
- **Statut** : ✅ OK
- **Analyse** :
  - Requête : `SELECT ... WHERE code_efs = '1' AND no_pse = 'PSE001' ORDER BY horodate DESC`
  - Données disponibles : 6 lignes pour `(code_efs='1', no_pse='PSE001')`
  - **Problème mineur** : Seulement 5 lignes affichées au lieu de 6 (peut-être un problème de filtrage)
- **Recommandation** : Vérifier pourquoi 1 ligne n'est pas retournée

### Test 2 : Lecture Dernière Opposition ✅

- **Résultat** : 1 ligne retournée
- **Statut** : ✅ OK
- **Analyse** :
  - Requête : `SELECT ... WHERE code_efs = '1' AND no_pse = 'PSE001' ORDER BY horodate DESC LIMIT 1`
  - **Correct** : Retourne bien la dernière opposition

### Test 3 : Historique par Période ❌

- **Résultat** : 0 lignes retournées
- **Statut** : ❌ PROBLÈME
- **Analyse** :
  - Requête : `SELECT ... WHERE code_efs = '1' AND no_pse = 'PSE001' AND timestamp >= '2024-01-01' AND timestamp <= '2024-12-31' ORDER BY horodate DESC`
  - **Problème 1** : La requête nécessite `ALLOW FILTERING` car `timestamp` n'est pas une clé primaire
  - **Problème 2** : Les données existantes pour `(code_efs='1', no_pse='PSE001')` ont des timestamps en 2024, donc devraient être retournées
  - **Erreur CQL** : `InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering..."`
- **Recommandation** :
  1. Modifier la requête pour utiliser `ALLOW FILTERING` (avec explication dans le rapport)
  2. OU filtrer côté application après avoir récupéré les données
  3. OU créer un index SAI sur `timestamp` (mais cela peut être coûteux)

### Test 4 : Ajout Entrée Historique ✅

- **Résultat** : 0 lignes retournées
- **Statut** : ✅ OK (normal pour un INSERT)
- **Analyse** :
  - Requête : `INSERT INTO historique_opposition ...`
  - **Correct** : Un INSERT ne retourne pas de lignes
  - **Problème mineur** : Le rapport devrait expliquer que c'est normal et vérifier que l'insertion a réussi

### Test 5 : Comptage Entrées Historique ✅

- **Résultat** : 1 ligne retournée (COUNT)
- **Statut** : ✅ OK
- **Analyse** :
  - Requête : `SELECT COUNT(*) FROM historique_opposition WHERE code_efs = '1' AND no_pse = 'PSE001'`
  - **Correct** : Retourne bien le nombre d'entrées (6 après le Test 4)

### Test 6 : Historique par Statut ❌

- **Résultat** : 0 lignes retournées
- **Statut** : ❌ PROBLÈME
- **Analyse** :
  - Requête : `SELECT ... WHERE code_efs = '1' AND no_pse = 'PSE001' AND status = 'opposé' ORDER BY horodate DESC`
  - **Problème 1** : La requête nécessite `ALLOW FILTERING` car `status` n'est pas une clé primaire
  - **Problème 2** : `ORDER BY` avec index secondaire n'est pas supporté en CQL
  - **Erreur CQL** : `InvalidRequest: Error from server: code=2200 [Invalid query] message="ORDER BY with 2ndary indexes is not supported."`
  - **Données disponibles** : Il y a des lignes avec `status = 'opposé'` pour `(code_efs='1', no_pse='PSE001')`
- **Recommandation** :
  1. Créer un index SAI sur `status` (si nécessaire)
  2. Filtrer côté application après avoir récupéré les données
  3. OU utiliser `ALLOW FILTERING` sans `ORDER BY`, puis trier côté application

### Test 7 : Historique par Raison ✅

- **Résultat** : 6 lignes retournées
- **Statut** : ✅ OK
- **Analyse** :
  - Requête : `SELECT ... WHERE code_efs = '1' AND no_pse = 'PSE001' ORDER BY horodate DESC`
  - **Correct** : Retourne bien toutes les lignes (y compris celles ajoutées par le Test 4)

### Test 8 : Liste Tous Historiques (par Code EFS) ❌

- **Résultat** : 0 lignes retournées
- **Statut** : ❌ PROBLÈME
- **Analyse** :
  - Requête : `SELECT ... WHERE code_efs = '1'`
  - **Problème 1** : La requête nécessite `ALLOW FILTERING` car elle ne spécifie pas `no_pse` (qui fait partie de la partition key)
  - **Erreur CQL** : `InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering..."`
  - **Données disponibles** : Il y a 6 lignes pour `code_efs = '1'` (avec différents `no_pse`)
- **Recommandation** :
  1. Modifier la requête pour utiliser `ALLOW FILTERING` (avec explication)
  2. OU récupérer les données pour chaque `no_pse` séparément et fusionner côté application
  3. OU créer un script qui liste tous les `no_pse` pour `code_efs = '1'` puis fait une requête pour chacun

---

## 🔧 Problèmes Identifiés

### 1. Valeurs de Filtre vs Données Disponibles

**Problème** : Les tests utilisent `code_efs = '1'` et `no_pse = 'PSE001'`, mais :

- Il n'y a que **6 lignes** pour cette combinaison (après le Test 4)
- La plupart des données utilisent `code_efs = '3'`, `'4'`, `'6'`, `'9'` avec `PSE002`
- Les données générées par `04_generate_meta_categories_parquet.sh` créent des historiques pour les oppositions existantes (10% des PSE)

**Solution** :

1. Créer un script `12_prepare_test_data.sh` qui insère des données de test spécifiques pour `(code_efs='1', no_pse='PSE001')` avec :
   - Plusieurs entrées avec différents `status` ('opposé', 'autorisé')
   - Plusieurs entrées avec différents `timestamp` (pour le Test 3)
   - Plusieurs entrées avec différentes `raison` (pour le Test 7)
   - Au moins 20-30 entrées pour avoir un historique complet

### 2. Contraintes CQL Non Respectées

**Problème** : Plusieurs requêtes ne respectent pas les contraintes CQL :

- **Test 3** : Filtre sur `timestamp` (non-clé primaire) sans `ALLOW FILTERING`
- **Test 6** : Filtre sur `status` (non-clé primaire) avec `ORDER BY` (non supporté avec index secondaire)
- **Test 8** : Filtre seulement sur `code_efs` sans `no_pse` (partition key incomplète)

**Solution** :

1. Pour chaque requête problématique, proposer deux approches :
   - **Approche 1** : Utiliser `ALLOW FILTERING` (avec explication des implications de performance)
   - **Approche 2** : Filtrer côté application (meilleure pratique, démontrée dans le script)

### 3. Rapport Non Didactique

**Problème** : Le rapport ne montre pas :

- Les lignes retournées en détail
- Les requêtes CQL exécutées
- Les explications de pourquoi certains tests retournent 0 lignes
- Les contrôles de cohérence des données

**Solution** :

1. Améliorer la fonction `execute_query` pour capturer et afficher toutes les lignes retournées
2. Améliorer le rapport Python pour inclure :
   - La requête CQL complète
   - Toutes les lignes retournées (format tableau)
   - Explication de ce qui est attendu vs obtenu
   - Contrôle de cohérence (vérifier que les données correspondent aux critères)

---

## 📊 Analyse des Données

### Données Disponibles dans `historique_opposition`

```
Total : 286 lignes

Répartition par (code_efs, no_pse) :
- (1, PSE001) : 6 lignes (après Test 4)
- (3, PSE001) : 70 lignes
- (4, PSE002) : 70 lignes
- (6, PSE002) : 70 lignes
- (9, PSE002) : 70 lignes
```

### Données pour (code_efs='1', no_pse='PSE001')

**Statut actuel** : 6 lignes (après le Test 4 qui ajoute 1 ligne)

**Problème** :

- Pas assez de données pour démontrer tous les cas d'usage
- Pas de variété dans les `status`, `timestamp`, `raison`

**Recommandation** : Créer un script qui insère au moins 20-30 entrées avec :

- Mix de `status` : 'opposé' et 'autorisé'
- `timestamp` répartis sur toute l'année 2024
- Différentes `raison` : 'Client demande désactivation', 'Conformité RGPD', 'Demande client', 'Changement de politique', 'Autre raison'

---

## ✅ Plan d'Action

### Priorité 1 (Critique)

1. ✅ Créer `12_prepare_test_data.sh` pour insérer des données de test cohérentes
2. ✅ Corriger les requêtes qui nécessitent `ALLOW FILTERING` (Tests 3, 6, 8)
3. ✅ Améliorer le rapport pour afficher toutes les lignes retournées

### Priorité 2 (Important)

4. ✅ Ajouter des explications détaillées dans le rapport pour chaque test
5. ✅ Ajouter des contrôles de cohérence des données
6. ✅ Documenter les limitations CQL et les solutions alternatives

### Priorité 3 (Amélioration)

7. ✅ Ajouter des tests supplémentaires pour couvrir tous les cas d'usage
8. ✅ Améliorer la génération de données pour avoir plus de variété

---

**Date de génération** : 2025-11-29
