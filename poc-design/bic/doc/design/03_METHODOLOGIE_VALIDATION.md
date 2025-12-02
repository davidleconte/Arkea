# 🔍 Méthodologie de Validation - POC BIC

**Date** : 2025-12-01  
**Version** : 1.0.0  
**Objectif** : Définir la méthodologie de validation pour chaque script BIC  
**Référence** : Niveau de qualité au moins égal à `domiramaCatOps`

---

## 📋 Vue d'Ensemble

Chaque script doit être validé selon **5 dimensions** avant d'être considéré comme terminé :

1. **Pertinence** : Le script répond-il aux exigences BIC ?
2. **Cohérence** : Le script est-il cohérent avec les autres scripts ?
3. **Intégrité** : Le script fonctionne-t-il correctement ?
4. **Consistance** : Le script est-il reproductible ?
5. **Conformité** : Le script est-il conforme aux exigences clients/IBM ?

---

## 🔍 DIMENSION 1 : PERTINENCE

### Définition

Le script répond-il aux exigences BIC identifiées dans les inputs-clients et inputs-ibm ?

### Critères de Validation

#### Pour les Scripts de Setup (01-04)

- ✅ Le script crée-t-il les éléments nécessaires (keyspace, tables, index) ?
- ✅ Le schéma est-il conforme aux exigences IBM ?
- ✅ Les noms sont-ils cohérents avec le périmètre BIC ?

#### Pour les Scripts de Génération (05-07)

- ✅ Les données générées couvrent-elles tous les use cases BIC ?
- ✅ Le format des données est-il conforme (Parquet, JSON) ?
- ✅ Les données sont-elles réalistes et variées ?

#### Pour les Scripts d'Ingestion (08-10)

- ✅ L'ingestion respecte-t-elle les exigences (batch, temps réel, JSON) ?
- ✅ Le mapping des données est-il correct ?
- ✅ Les performances sont-elles acceptables ?

#### Pour les Scripts de Test (11-20)

- ✅ Les tests couvrent-ils les use cases BIC requis ?
- ✅ Les tests sont-ils complets et pertinents ?
- ✅ Les résultats sont-ils validés ?

#### Pour les Scripts de Démonstration (21-25)

- ✅ Les démonstrations couvrent-elles tous les use cases BIC ?
- ✅ Les scénarios sont-ils réalistes ?
- ✅ La documentation est-elle complète ?

### Checklist Pertinence

- [ ] Le script répond à un use case BIC identifié
- [ ] Le script est nécessaire pour la démonstration
- [ ] Le script couvre les fonctionnalités requises
- [ ] Le script est aligné avec les exigences clients/IBM

---

## 🔍 DIMENSION 2 : COHÉRENCE

### Définition

Le script est-il cohérent avec les autres scripts et la structure globale du POC BIC ?

### Critères de Validation

#### Cohérence Structurelle

- ✅ Le script utilise-t-il `setup_paths()` depuis `utils/didactique_functions.sh` ?
- ✅ Le script suit-il la même structure que les scripts domiramaCatOps ?
- ✅ Le script utilise-t-il les mêmes conventions de nommage ?

#### Cohérence Fonctionnelle

- ✅ Le script utilise-t-il les mêmes variables d'environnement ?
- ✅ Le script utilise-t-il les mêmes chemins et configurations ?
- ✅ Le script est-il compatible avec les scripts précédents ?

#### Cohérence Documentaire

- ✅ Le script génère-t-il des rapports dans `doc/demonstrations/` ?
- ✅ Le format des rapports est-il cohérent ?
- ✅ La documentation est-elle structurée de la même manière ?

### Checklist Cohérence

- [ ] Le script utilise `setup_paths()`
- [ ] Le script utilise les fonctions didactiques (`info`, `success`, `error`, etc.)
- [ ] Le script suit la même structure que domiramaCatOps
- [ ] Le script utilise les mêmes conventions de nommage
- [ ] Le script est compatible avec les scripts précédents
- [ ] Le script génère des rapports cohérents

---

## 🔍 DIMENSION 3 : INTÉGRITÉ

### Définition

Le script fonctionne-t-il correctement et sans erreurs ?

### Critères de Validation

#### Intégrité Technique

- ✅ Le script s'exécute-t-il sans erreurs ?
- ✅ Les vérifications préalables sont-elles complètes ?
- ✅ La gestion d'erreurs est-elle robuste ?
- ✅ Les résultats sont-ils corrects ?

#### Intégrité Fonctionnelle

- ✅ Le script réalise-t-il toutes les opérations prévues ?
- ✅ Les données sont-elles correctement traitées ?
- ✅ Les résultats sont-ils validés ?

#### Intégrité des Données

- ✅ Les données sont-elles correctement chargées ?
- ✅ Les données sont-elles correctement transformées ?
- ✅ Les données sont-elles correctement exportées ?

### Checklist Intégrité

- [ ] Le script s'exécute sans erreurs
- [ ] Les vérifications préalables sont complètes
- [ ] La gestion d'erreurs est robuste (`set -euo pipefail`)
- [ ] Les résultats sont corrects et validés
- [ ] Les données sont correctement traitées
- [ ] Les opérations sont complètes

---

## 🔍 DIMENSION 4 : CONSISTANCE

### Définition

Le script est-il reproductible et produit-il des résultats cohérents ?

### Critères de Validation

#### Reproductibilité

- ✅ Le script produit-il les mêmes résultats à chaque exécution ?
- ✅ Les données générées sont-elles reproductibles ?
- ✅ Les tests sont-ils déterministes ?

#### Consistance des Résultats

- ✅ Les résultats sont-ils cohérents entre les exécutions ?
- ✅ Les performances sont-elles constantes ?
- ✅ Les métriques sont-elles cohérentes ?

#### Consistance des Données

- ✅ Les données sont-elles cohérentes avec le schéma ?
- ✅ Les données sont-elles cohérentes entre les scripts ?
- ✅ Les formats sont-ils cohérents ?

### Checklist Consistance

- [ ] Le script est reproductible
- [ ] Les résultats sont cohérents entre les exécutions
- [ ] Les données sont cohérentes avec le schéma
- [ ] Les formats sont cohérents
- [ ] Les performances sont constantes
- [ ] Les tests sont déterministes

---

## 🔍 DIMENSION 5 : CONFORMITÉ

### Définition

Le script est-il conforme aux exigences clients (inputs-clients) et IBM (inputs-ibm) ?

### Critères de Validation

#### Conformité aux Exigences Clients

- ✅ Le script répond-il aux exigences identifiées dans `inputs-clients` ?
- ✅ Le script couvre-t-il les use cases BIC requis ?
- ✅ Le script respecte-t-il les contraintes métier ?

#### Conformité aux Exigences IBM

- ✅ Le script est-il conforme au schéma proposé par IBM ?
- ✅ Le script utilise-t-il les fonctionnalités HCD recommandées ?
- ✅ Le script respecte-t-il les bonnes pratiques IBM ?

#### Conformité Technique

- ✅ Le script respecte-t-il les standards de qualité ?
- ✅ Le script est-il conforme aux bonnes pratiques ?
- ✅ Le script respecte-t-il les contraintes techniques ?

### Checklist Conformité

- [ ] Le script répond aux exigences clients (inputs-clients)
- [ ] Le script répond aux exigences IBM (inputs-ibm)
- [ ] Le script est conforme au schéma proposé
- [ ] Le script utilise les fonctionnalités HCD recommandées
- [ ] Le script respecte les bonnes pratiques
- [ ] Le script respecte les contraintes techniques

---

## 📊 NIVEAU DE QUALITÉ MINIMUM

### Référence : domiramaCatOps

Le niveau de qualité doit être **au moins égal** à celui de `domiramaCatOps`.

### Critères de Qualité Obligatoires

#### 1. Structure du Script

- ✅ `set -euo pipefail` en première ligne
- ✅ Utilisation de `setup_paths()` depuis `utils/didactique_functions.sh`
- ✅ Documentation inline complète (OBJECTIF, PRÉREQUIS, UTILISATION, SORTIE)

#### 2. Messages et Affichage

- ✅ Messages colorés complets :
  - `info()` - Informations
  - `success()` - Succès
  - `error()` - Erreurs
  - `warn()` - Avertissements
  - `demo()` - Démonstrations
  - `code()` - Code
  - `section()` - Sections
  - `result()` - Résultats
  - `expected()` - Attentes

#### 3. Vérifications Préalables

- ✅ Vérification que HCD est démarré
- ✅ Vérification que les prérequis sont présents
- ✅ Vérification que les fichiers nécessaires existent
- ✅ Vérification que le schéma est configuré

#### 4. Gestion d'Erreurs

- ✅ Gestion complète des erreurs
- ✅ Messages d'erreur explicites
- ✅ Codes de retour appropriés
- ✅ Nettoyage en cas d'erreur

#### 5. Documentation Auto-Générée

- ✅ Génération de rapport didactique dans `doc/demonstrations/`
- ✅ Format Markdown structuré
- ✅ Explications détaillées
- ✅ Résultats documentés

#### 6. Code et Explications

- ✅ Code complet avec explications
- ✅ Requêtes CQL formatées et expliquées
- ✅ Code Spark avec explications détaillées
- ✅ Commentaires pertinents

#### 7. Statistiques et Résultats

- ✅ Affichage des statistiques
- ✅ Affichage des résultats
- ✅ Comparaison avec les attentes
- ✅ Métriques de performance

### Checklist Qualité

- [ ] `set -euo pipefail` présent
- [ ] `setup_paths()` utilisé
- [ ] Documentation inline complète
- [ ] Messages colorés complets
- [ ] Vérifications préalables complètes
- [ ] Gestion d'erreurs robuste
- [ ] Rapport didactique généré (si applicable)
- [ ] Code avec explications détaillées
- [ ] Statistiques et résultats affichés

---

## 🔄 PROCESSUS DE VALIDATION

### Étape 1 : Création du Script

1. Créer le script selon le plan
2. Implémenter les fonctionnalités
3. Ajouter la documentation inline
4. Ajouter les vérifications préalables
5. Ajouter la gestion d'erreurs

### Étape 2 : Validation Technique

1. Exécuter le script
2. Vérifier qu'il s'exécute sans erreurs
3. Vérifier les résultats
4. Vérifier les performances

### Étape 3 : Validation des 5 Dimensions

1. **Pertinence** : Le script répond-il aux exigences ?
2. **Cohérence** : Le script est-il cohérent avec les autres ?
3. **Intégrité** : Le script fonctionne-t-il correctement ?
4. **Consistance** : Le script est-il reproductible ?
5. **Conformité** : Le script est-il conforme aux exigences ?

### Étape 4 : Validation Qualité

1. Vérifier tous les critères de qualité
2. Comparer avec domiramaCatOps
3. S'assurer que le niveau est au moins égal

### Étape 5 : Documentation

1. Générer le rapport didactique
2. Documenter les résultats
3. Mettre à jour la documentation

---

## 📋 CHECKLIST COMPLÈTE PAR SCRIPT

Pour chaque script, vérifier :

### Structure et Code

- [ ] `set -euo pipefail` présent
- [ ] `setup_paths()` utilisé
- [ ] Documentation inline complète
- [ ] Messages colorés complets
- [ ] Vérifications préalables complètes
- [ ] Gestion d'erreurs robuste

### Fonctionnalités

- [ ] Le script réalise toutes les opérations prévues
- [ ] Les résultats sont corrects
- [ ] Les performances sont acceptables
- [ ] Les données sont correctement traitées

### Documentation

- [ ] Rapport didactique généré (si applicable)
- [ ] Format Markdown structuré
- [ ] Explications détaillées
- [ ] Résultats documentés

### Validation 5 Dimensions

- [ ] **Pertinence** : Répond aux exigences BIC
- [ ] **Cohérence** : Cohérent avec les autres scripts
- [ ] **Intégrité** : Fonctionne correctement
- [ ] **Consistance** : Reproductible
- [ ] **Conformité** : Conforme aux exigences clients/IBM

### Qualité

- [ ] Niveau au moins égal à domiramaCatOps
- [ ] Code avec explications détaillées
- [ ] Statistiques et résultats affichés
- [ ] Tests validés

---

## 🎯 RÉFÉRENCES

### Scripts de Référence (domiramaCatOps)

- `scripts/05_load_operations_data_parquet.sh` - Exemple d'ingestion batch
- `scripts/13_test_dynamic_columns.sh` - Exemple de test didactique
- `scripts/27_demo_kafka_streaming.sh` - Exemple de démonstration Kafka

### Documents de Référence

- `inputs-ibm/PROPOSITION_MECE_MIGRATION_HBASE_HCD.md` - Exigences IBM
- `inputs-clients/README.md` - Exigences clients
- `poc-design/domiramaCatOps/doc/` - Documentation de référence

---

**Date** : 2025-12-01  
**Version** : 1.0.0  
**Statut** : ✅ Méthodologie complète définie
