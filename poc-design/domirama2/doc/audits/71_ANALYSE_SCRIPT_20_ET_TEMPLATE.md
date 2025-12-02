# 📋 Analyse du Script 20 : `20_test_typo_tolerance.sh`

**Date** : 2025-11-26  
**Script analysé** : `20_test_typo_tolerance.sh`  
**Objectif** : Déterminer quel template utiliser ou créer pour enrichir le script 20

---

## 📊 Analyse du Script 20

### Type de Script

Le script 20 est un **script de test/comparaison** qui :

- ✅ Exécute 3 tests de comparaison entre `libelle` et `libelle_prefix`
- ✅ Démontre la tolérance aux typos
- ✅ Compare les comportements de deux colonnes différentes
- ✅ Affiche les résultats de chaque test
- ❌ Ne génère pas de rapport markdown
- ❌ Pas d'orchestration (pas d'appels à d'autres scripts)
- ❌ Pas de setup (pas de DDL)

### Structure Actuelle

```bash
# En-tête
# Vérifications (HCD, schéma)
# TEST 1 : Recherche avec Typo (caractère manquant)
# TEST 2 : Comparaison libelle vs libelle_prefix (stemming)
# TEST 3 : Comparaison libelle vs libelle_prefix (typo)
# Résumé
```

### Caractéristiques Spécifiques

1. **Tests de comparaison** : Compare deux colonnes (`libelle` vs `libelle_prefix`)
2. **Tests multiples** : 3 tests différents dans un seul script
3. **Focus sur la démonstration** : Montre les différences entre deux stratégies
4. **Pas de génération de rapport** : Affiche uniquement dans le terminal

---

## 🔍 Comparaison avec les Templates Existants

### Template 43 : Script Didactique Général

| Aspect | Template 43 | Script 20 |
|--------|-------------|-----------|
| **Type** | Test/Démonstration | Test/Comparaison |
| **Nombre de tests** | 1 test | 3 tests |
| **Structure** | Définition + Requête + Explication + Résultats | Tests avec comparaisons |
| **Comparaisons** | ❌ Non | ✅ Oui (libelle vs libelle_prefix) |
| **Rapport markdown** | ✅ Oui | ❌ Non |
| **Contexte** | ⚠️ Basique | ⚠️ Basique |

**Points communs** :

- ✅ Structure de test/démonstration
- ✅ Affichage de requêtes CQL
- ✅ Explications des résultats

**Différences** :

- ⚠️ Script 20 : 3 tests au lieu de 1
- ⚠️ Script 20 : Comparaisons entre colonnes
- ⚠️ Script 20 : Pas de rapport markdown

### Template 47 : Script Setup Didactique

| Aspect | Template 47 | Script 20 |
|--------|-------------|-----------|
| **Type** | Setup (DDL) | Test (DML) |
| **Action** | Crée schéma/index | Teste recherches |
| **DDL** | ✅ Oui | ❌ Non |
| **DML** | ❌ Non | ✅ Oui |

**Conclusion** : ❌ Non adapté (script 20 ne fait pas de setup)

### Template 50 : Script Ingestion Didactique

| Aspect | Template 50 | Script 20 |
|--------|-------------|-----------|
| **Type** | Ingestion (ETL) | Test (DML) |
| **Action** | Charge données | Teste recherches |
| **ETL** | ✅ Oui | ❌ Non |

**Conclusion** : ❌ Non adapté (script 20 ne fait pas d'ingestion)

### Template 63 : Script Orchestration Didactique

| Aspect | Template 63 | Script 20 |
|--------|-------------|-----------|
| **Type** | Orchestration | Test |
| **Orchestration** | ✅ Oui (appels scripts) | ❌ Non |
| **Multiples démos** | ✅ Oui (N démonstrations) | ⚠️ Oui (3 tests) |
| **Rapport markdown** | ✅ Oui | ❌ Non |

**Conclusion** : ⚠️ Partiellement adapté (multiples tests) mais trop complexe (orchestration non nécessaire)

---

## 🎯 Recommandation

### Option 1 : Utiliser le Template 43 (Adapté)

**Avantages** :

- ✅ Structure similaire (test/démonstration)
- ✅ Déjà conçu pour les démonstrations
- ✅ Supporte l'affichage de DML
- ✅ Peut être adapté pour plusieurs tests

**Adaptations nécessaires** :

1. **Ajouter contexte** : Pourquoi ces tests ? Équivalences HBase → HCD
2. **Structurer les 3 tests** : Chaque test avec définition, requête, explication, résultats
3. **Ajouter comparaisons** : Tableau comparatif libelle vs libelle_prefix
4. **Générer rapport markdown** : Documentation structurée
5. **Enrichir les explications** : Détails sur les différences entre colonnes

**Structure proposée** :

```bash
# PARTIE 0: CONTEXTE - Pourquoi tester la tolérance aux typos ?
# PARTIE 1: TEST 1 - Recherche avec Typo (caractère manquant)
# PARTIE 2: TEST 2 - Comparaison libelle vs libelle_prefix (stemming)
# PARTIE 3: TEST 3 - Comparaison libelle vs libelle_prefix (typo)
# PARTIE 4: RÉSUMÉ - Tableau comparatif et recommandations
# PARTIE 5: GÉNÉRATION RAPPORT
```

### Option 2 : Créer un Nouveau Template (Comparaison)

**Avantages** :

- ✅ Spécialement conçu pour scripts de comparaison
- ✅ Structure optimisée pour comparer deux colonnes/stratégies
- ✅ Tableaux comparatifs intégrés

**Inconvénients** :

- ⚠️ Nouveau template à créer et maintenir
- ⚠️ Peut-être trop spécifique (peu de scripts de comparaison)

---

## ✅ Recommandation Finale

### **Utiliser le Template 43 (Adapté) avec Enrichissements**

**Raisons** :

1. ✅ Le script 20 est fondamentalement un script de test/démonstration
2. ✅ Le Template 43 est conçu pour ce type de script
3. ✅ Les adaptations nécessaires sont mineures
4. ✅ Cohérence avec les autres scripts de test (12, 13, 15, 17)

### Adaptations à Apporter

#### 1. **PARTIE 0: CONTEXTE** (Nouveau)

```bash
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📚 PARTIE 0: CONTEXTE - Pourquoi Tester la Tolérance aux Typos ?"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 PROBLÈME : Recherches avec Typos qui Échouent"
echo ""
echo "   Scénario : Un utilisateur cherche 'LOYER' mais tape 'LOYR' (caractère 'e' manquant)"
echo "   Résultat avec index standard (libelle) : ❌ Aucun résultat trouvé"
echo ""

info "📚 SOLUTION : Colonne Dérivée libelle_prefix"
echo ""
echo "   Stratégie : Créer une colonne dérivée 'libelle_prefix' avec index N-Gram"
echo "   - Colonne dérivée : Copie de 'libelle' (remplie par les scripts de chargement)"
echo "   - Index N-Gram : Recherche partielle et tolérance aux typos"
echo "   - Recherche partielle : 'LOY' trouve 'LOYER', 'LOYERS', etc."
echo ""

info "📚 ÉQUIVALENCES HBase → HCD :"
echo ""
echo "   HBase :"
echo "      - Recherche partielle : Elasticsearch N-Gram"
echo "      - Configuration : Index Elasticsearch avec analyzer N-Gram"
echo ""
echo "   HCD :"
echo "      - Recherche partielle : Index SAI N-Gram sur colonne dérivée"
echo "      - Configuration : Index SAI avec analyzer standard + lowercase + asciifolding"
echo ""
```

#### 2. **PARTIE 1-3: TESTS** (Enrichis)

Chaque test doit inclure :

- **Définition** : Explication du concept testé
- **Requête CQL** : Affichage formaté avant exécution
- **Explication** : Ce que nous démontrons
- **Résultat attendu** : Ce qui est attendu
- **Résultats obtenus** : Capture et affichage formaté
- **Comparaison** : Si applicable, comparaison avec l'autre colonne

#### 3. **PARTIE 4: RÉSUMÉ** (Nouveau)

```bash
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 4: RÉSUMÉ - Tableau Comparatif"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 Comparaison libelle vs libelle_prefix :"
echo ""
echo "   ┌─────────────────────────────────────────────────────────┐"
echo "   │ Aspect              │ libelle          │ libelle_prefix │"
echo "   ├─────────────────────────────────────────────────────────┤"
echo "   │ Stemming            │ ✅ Oui (français)│ ❌ Non         │"
echo "   │ Asciifolding        │ ✅ Oui           │ ✅ Oui          │"
echo "   │ Recherche partielle │ ❌ Non           │ ✅ Oui (N-Gram)│"
echo "   │ Tolérance typos     │ ❌ Non           │ ✅ Oui          │"
echo "   │ Précision           │ ✅ Haute         │ ⚠️  Moyenne     │"
echo "   └─────────────────────────────────────────────────────────┘"
echo ""

info "💡 Recommandations d'Utilisation :"
echo ""
echo "   ✅ Utiliser libelle pour :"
echo "      - Recherches précises avec variations grammaticales"
echo "      - Recherches avec pluriel/singulier (loyers, loyer)"
echo ""
echo "   ✅ Utiliser libelle_prefix pour :"
echo "      - Recherches partielles (préfixe)"
echo "      - Tolérance aux typos"
echo "      - Autocomplétion"
echo ""
```

#### 4. **PARTIE 5: GÉNÉRATION RAPPORT** (Nouveau)

Générer un rapport markdown structuré avec :

- Table des matières
- Contexte et objectifs
- Détails des 3 tests avec résultats
- Tableau comparatif
- Recommandations

---

## 📋 Checklist pour Appliquer le Template 43 (Adapté)

- [ ] Ajouter PARTIE 0: Contexte (pourquoi ces tests ?)
- [ ] Enrichir chaque test avec définition, requête formatée, explication, résultats
- [ ] Ajouter PARTIE 4: Résumé avec tableau comparatif
- [ ] Ajouter PARTIE 5: Génération rapport markdown
- [ ] Filtrer les erreurs SyntaxException dans les résultats
- [ ] Capturer les résultats de chaque test pour le rapport
- [ ] Ajouter équivalences HBase → HCD
- [ ] Ajouter recommandations d'utilisation

---

## 💡 Structure Proposée du Script 20 Amélioré

```bash
#!/bin/bash
# ============================================
# Script 20 : Tests Tolérance aux Typos (Version Didactique)
# Démonstration de la recherche partielle avec libelle_prefix
# ============================================

# PARTIE 0: CONTEXTE - Pourquoi Tester la Tolérance aux Typos ?
#   - Problème : Recherches avec typos qui échouent
#   - Solution : Colonne dérivée libelle_prefix
#   - Équivalences HBase → HCD

# PARTIE 1: TEST 1 - Recherche avec Typo (caractère manquant)
#   - Définition : Recherche partielle
#   - Requête CQL : libelle_prefix : 'loyer'
#   - Explication : Ce que nous démontrons
#   - Résultats : Capture et affichage

# PARTIE 2: TEST 2 - Comparaison libelle vs libelle_prefix (stemming)
#   - Définition : Différence de comportement avec stemming
#   - Requête CQL : libelle : 'loyers' vs libelle_prefix : 'loyers'
#   - Comparaison : Résultats côte à côte
#   - Explication : Pourquoi la différence ?

# PARTIE 3: TEST 3 - Comparaison libelle vs libelle_prefix (typo)
#   - Définition : Tolérance aux typos
#   - Requête CQL : libelle : 'loyr' vs libelle_prefix : 'loy'
#   - Comparaison : Résultats côte à côte
#   - Explication : Pourquoi libelle_prefix tolère mieux les typos ?

# PARTIE 4: RÉSUMÉ - Tableau Comparatif et Recommandations
#   - Tableau comparatif libelle vs libelle_prefix
#   - Recommandations d'utilisation
#   - Cas d'usage pour chaque colonne

# PARTIE 5: GÉNÉRATION RAPPORT MARKDOWN
#   - Documentation structurée
#   - Tous les tests avec résultats
#   - Tableau comparatif
```

---

## ✅ Conclusion

**Template recommandé** : **Template 43 (Adapté)** avec enrichissements

**Raisons** :

1. ✅ Le script 20 est un script de test/démonstration (comme Template 43)
2. ✅ Les adaptations nécessaires sont mineures
3. ✅ Cohérence avec les autres scripts de test
4. ✅ Pas besoin de créer un nouveau template spécifique

**Améliorations à apporter** :

- ✅ Ajouter contexte (PARTIE 0)
- ✅ Enrichir chaque test (définition, requête, explication, résultats)
- ✅ Ajouter résumé comparatif (PARTIE 4)
- ✅ Générer rapport markdown (PARTIE 5)

---

*Analyse créée le 2025-11-26 pour déterminer le template approprié pour le script 20*
