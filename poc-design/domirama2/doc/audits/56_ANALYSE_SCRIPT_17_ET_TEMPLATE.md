# 📊 Analyse : Script 17 et Applicabilité du Template Didactique

**Date** : 2025-11-26  
**Script analysé** : `17_test_advanced_search.sh`  
**Objectif** : Analyser le script 17 et déterminer si un template existant est applicable, doit être enrichi, ou si un template spécifique est nécessaire

---

## 📋 Table des Matières

1. [Analyse du Script 17](#analyse-du-script-17)
2. [Analyse du Fichier CQL de Test](#analyse-du-fichier-cql-de-test)
3. [Comparaison avec Script 15](#comparaison-avec-script-15)
4. [Comparaison avec Templates Existants](#comparaison-avec-templates-existants)
5. [Recommandations](#recommandations)
6. [Conclusion](#conclusion)

---

## 🔍 Analyse du Script 17

### Objectif du Script

Le script `17_test_advanced_search.sh` est un **script de test/recherche avancé** qui :

1. **Exécute des tests de recherche full-text avancés** avec différents types d'index SAI
2. **Démontre les capacités de différents index SAI** (fulltext, exact, keyword, ngram, french, whitespace)
3. **Teste des recherches complexes** (stemming, noms propres, phrases, recherches partielles)
4. **Valide la pertinence** des résultats avec différents types d'index

### Structure Actuelle du Script

```bash
# Structure actuelle (138 lignes)
1. En-tête et commentaires (lignes 1-39)
2. Configuration des couleurs (lignes 43-52)
3. Configuration des variables (lignes 54-57)
4. Vérifications (lignes 59-72)
5. Sélection d'un compte (lignes 79-95)
6. Vérification des index (lignes 98-104)
7. Remplacement des placeholders (lignes 106-108)
8. Exécution du fichier CQL (ligne 113)
9. Messages finaux (lignes 117-137)
```

### Fonctionnalités Actuelles

✅ **Vérifications** :
- HCD démarré
- Keyspace existe
- Index avancés existent (vérification optionnelle)

✅ **Sélection de compte** :
- Sélection automatique d'un compte avec des données
- Utilisation d'un compte connu (code_si=1, contrat=5913101072)
- Remplacement des placeholders dans le fichier CQL

✅ **Exécution** :
- Exécution du fichier CQL de test via `cqlsh -f`
- Filtrage des warnings

✅ **Messages** :
- Messages informatifs sur les types de recherches testées
- Explications sur les différents types d'index SAI

### Limitations Actuelles

❌ **Pas d'affichage didactique** :
- Pas d'affichage des requêtes CQL avant exécution
- Pas d'explication des différents types d'index SAI
- Pas de capture des résultats

❌ **Pas de documentation** :
- Pas de génération de rapport markdown
- Pas de validation de la pertinence des résultats

❌ **Pas d'explications** :
- Pas d'explication des différences entre les types d'index
- Pas d'explication des cas d'usage pour chaque index

---

## 📄 Analyse du Fichier CQL de Test

### Fichier : `schemas/05_domirama2_search_advanced.cql`

**Contenu** : 20 tests de recherche avancés

**Types de tests** :

1. **Recherche avec stemming français** (idx_libelle_fulltext)
   - Test 1 : 'loyers' → trouve "LOYER" (pluriel)

2. **Recherche exacte** (idx_libelle_exact)
   - Test 2 : 'CARREFOUR' (noms propres)

3. **Recherche de phrase complète** (idx_libelle_keyword)
   - Test 3 : 'PAIEMENT PAR CARTE BANCAIRE' (phrases exactes)

4. **Recherche partielle N-Gram** (idx_libelle_ngram)
   - Test 4 : 'carref' → trouve "CARREFOUR" (typos et recherches partielles)

5. **Recherche multi-termes complexes**
   - Test 5 : 'virement' AND 'permanent' AND 'mensuel'

6. **Recherche avec stop words** (idx_libelle_french)
   - Test 6 : 'banque' AND 'paris' (ignore "de", "du", "des")

7. **Recherche avec accents et asciifolding**
   - Test 7 : 'impayé' AND 'régularisation' (avec accents)

8. **Recherche triple terme avec proximité**
   - Test 8 : 'prelevement' AND 'automatique' AND 'facture'

9. **Recherche avec filtre montant**
   - Test 9 : 'loyer' AND 'paris' AND montant < -1000

10. **Recherche avec filtre catégorie**
    - Test 10 : 'virement' AND 'impaye' AND cat_auto = 'VIREMENT'

11. **Recherche avec filtre type opération**
    - Test 11 : 'prelevement' AND type_operation = 'PRELEVEMENT'

12. **Recherche avec date (range)**
    - Test 12 : 'loyer' AND date_op >= '2024-01-01' AND date_op < '2025-01-01'

13. **Recherche complexe multi-critères**
    - Test 13 : 'virement' AND 'sepa' AND cat_auto = 'VIREMENT' AND type_operation = 'VIREMENT' AND montant > 0

14. **Recherche avec variations (stemming)**
    - Test 14 : 'prelevements' → trouve "PRELEVEMENT" (pluriel)

15. **Recherche avec noms propres**
    - Test 15 : 'EDF' AND 'ORANGE' (sans stemming)

16. **Recherche avec codes et numéros**
    - Test 16 : '1234567890' (numéro de chèque)

17. **Recherche avec abréviations**
    - Test 17 : 'DAB' AND 'SEPA'

18. **Recherche avec localisation précise**
    - Test 18 : 'paris' AND '15eme' AND '16eme'

19. **Recherche avec termes techniques**
    - Test 19 : 'contactless' AND 'instantané'

20. **Recherche avec combinaison complexe**
    - Test 20 : Multi-critères (libellé + catégorie + type + montant + date)

### Différences Clés avec Script 15

| Aspect | Script 15 | Script 17 |
|--------|-----------|-----------|
| **Focus** | Analyzers d'un index | Types d'index différents |
| **Index utilisé** | `idx_libelle_fulltext_advanced` (un seul) | Plusieurs index (fulltext, exact, keyword, ngram, french, whitespace) |
| **Tests** | 20 tests complexes (multi-termes, accents, stemming) | 20 tests avancés (différents types d'index) |
| **Objectif** | Démontrer les analyzers | Démontrer les différents types d'index SAI |

---

## 🔄 Comparaison avec Script 15

### Similarités

✅ **Structure similaire** :
- Même format de script shell
- Même logique de sélection de compte
- Même exécution via `cqlsh -f`

✅ **Type de script** :
- Script de test/recherche
- Tests de recherche full-text avec SAI
- 20 tests dans le fichier CQL

✅ **Objectif similaire** :
- Démontrer les capacités de recherche full-text
- Valider la pertinence des résultats

### Différences

| Aspect | Script 15 | Script 17 |
|--------|-----------|-----------|
| **Focus principal** | Analyzers (lowercase, asciifolding, stemming) | Types d'index (fulltext, exact, keyword, ngram, french) |
| **Index** | Un seul index avec analyzers | Plusieurs index avec configurations différentes |
| **Cas d'usage** | Recherches générales avec variations | Recherches spécialisées (exact, phrase, partielle) |
| **Complexité** | Complexe (multi-termes, accents) | Avancé (différents types d'index) |

### Conclusion

Le script 17 est **complémentaire** au script 15 :
- Script 15 : Démontre les **analyzers** d'un index
- Script 17 : Démontre les **différents types d'index** SAI

---

## 📊 Comparaison avec Templates Existants

### Template Didactique Général (`43_TEMPLATE_SCRIPT_DIDACTIQUE.md`)

**Applicabilité** : ✅ **Applicable avec enrichissements**

**Structure** :
- 4-6 parties didactiques
- Affichage DDL/DML
- Capture des résultats
- Génération de documentation

**Adaptations nécessaires** :
- Ajouter section "Types d'Index SAI" (explication de chaque type)
- Ajouter section "Cas d'Usage par Type d'Index"
- Adapter la capture des résultats pour les différents types d'index
- Ajouter validation de la pertinence avec différents types d'index

### Template Script 15 (`15_fulltext_complex_template.md`)

**Applicabilité** : ⚠️ **Partiellement applicable**

**Similarités** :
- Tests de recherche full-text
- 20 tests dans le fichier CQL
- Structure didactique similaire

**Différences** :
- Script 15 : Focus sur analyzers
- Script 17 : Focus sur types d'index

**Conclusion** : Le template du script 15 peut servir de **base**, mais nécessite des adaptations pour les types d'index.

### Template Setup (`47_TEMPLATE_SCRIPT_SETUP_DIDACTIQUE.md`)

**Applicabilité** : ❌ **Non applicable**

**Raison** : Template pour scripts de setup/DDL, pas pour scripts de test.

### Template Ingestion (`50_TEMPLATE_SCRIPT_INGESTION_DIDACTIQUE.md`)

**Applicabilité** : ❌ **Non applicable**

**Raison** : Template pour scripts d'ingestion/ETL, pas pour scripts de test.

---

## 💡 Recommandations

### Option 1 : Utiliser le Template Didactique Général avec Enrichissements (Recommandé) ⭐

**Avantages** :
- Réutilise le template existant
- Cohérence avec les autres scripts de test didactiques
- Adaptations mineures nécessaires

**Adaptations nécessaires** :
- Ajouter section "Types d'Index SAI" (explication de chaque type)
- Ajouter section "Cas d'Usage par Type d'Index"
- Adapter la capture des résultats pour les différents types d'index
- Ajouter validation de la pertinence avec différents types d'index

**Structure proposée** :
1. **PARTIE 1** : CONTEXTE - Types d'Index SAI
   - Explication de chaque type d'index (fulltext, exact, keyword, ngram, french, whitespace)
   - Cas d'usage pour chaque type
   - Configuration dans le schéma

2. **PARTIE 2** : DÉFINITION - Différences entre Types d'Index
   - Comparaison des types d'index
   - Quand utiliser quel index
   - Avantages/inconvénients

3. **PARTIE 3** : REQUÊTES CQL - Tests Avancés
   - Affichage d'exemples de requêtes CQL
   - Explication de chaque type de test

4. **PARTIE 4** : EXÉCUTION DES TESTS
   - Exécution du fichier CQL complet (20 tests)
   - Capture des résultats

5. **PARTIE 5** : VALIDATION DE LA PERTINENCE
   - Validation de quelques tests clés
   - Comparaison des résultats avec différents types d'index

6. **PARTIE 6** : RÉSUMÉ ET CONCLUSION
   - Résumé des tests
   - Points clés démontrés
   - Génération de documentation

**Verdict** : ✅ **Recommandé**

### Option 2 : Créer un Template Spécifique pour Tests Avancés

**Avantages** :
- Template dédié aux tests avancés
- Sections spécifiques (types d'index, cas d'usage)

**Inconvénients** :
- Duplication avec template didactique général
- Maintenance de deux templates similaires
- Pas de valeur ajoutée significative

**Verdict** : ❌ **Non recommandé**

### Option 3 : Réutiliser le Template du Script 15 avec Adaptations

**Avantages** :
- Template déjà adapté pour les tests de recherche
- Structure similaire

**Inconvénients** :
- Focus sur analyzers plutôt que types d'index
- Adaptations importantes nécessaires
- Risque de confusion

**Verdict** : ⚠️ **Possible mais non optimal**

---

## 📊 Tableau Récapitulatif

| Aspect | Template Didactique | Script 17 Actuel | Script 17 Didactique | Template à Utiliser |
|--------|-------------------|-----------------|---------------------|---------------------|
| **Type** | Test/DML | Test/Recherche | Test/Recherche | Template Didactique (enrichi) |
| **Structure** | 4-6 parties | Basique | 4-6 parties | 4-6 parties (adaptées) |
| **Affichage CQL** | Oui | Non | Oui | Oui (avec explications) |
| **Capture résultats** | Oui | Non | Oui | Oui (formaté) |
| **Types d'Index SAI** | Non spécifique | Mentionnés | Expliqués | Section dédiée |
| **Cas d'Usage** | Non spécifique | Mentionnés | Expliqués | Section dédiée |
| **Documentation** | Génération markdown | Non générée | Génération markdown | Génération markdown |

---

## 🔄 Différences Clés à Adapter

### 1. Types d'Index SAI

**À expliquer** :
- **idx_libelle_fulltext** : Recherches générales avec stemming
- **idx_libelle_exact** : Noms propres et codes exacts
- **idx_libelle_keyword** : Phrases complètes
- **idx_libelle_ngram** : Recherches partielles et typos
- **idx_libelle_french** : Français avancé avec stop words
- **idx_libelle_whitespace** : Recherches rapides

### 2. Cas d'Usage par Type d'Index

**À expliquer** :
- **Quand utiliser fulltext** : Recherches générales avec variations
- **Quand utiliser exact** : Noms propres, codes, numéros
- **Quand utiliser keyword** : Phrases exactes
- **Quand utiliser ngram** : Recherches partielles, typos
- **Quand utiliser french** : Recherches françaises avec stop words
- **Quand utiliser whitespace** : Recherches rapides sans traitement

### 3. Capture des Résultats

**À adapter** :
- Capturer le nombre de résultats pour chaque requête
- Afficher un échantillon des résultats
- Valider la pertinence avec différents types d'index
- Comparer les résultats entre différents types d'index

---

## ✅ Conclusion

**✅ Le template didactique général est applicable avec des enrichissements spécifiques pour les tests de recherche avancés et les différents types d'index SAI !**

**Recommandation finale** : Utiliser le **Template Didactique Général** (`43_TEMPLATE_SCRIPT_DIDACTIQUE.md`) avec les enrichissements suivants :

1. **Section "Types d'Index SAI"** : Explication de chaque type d'index
2. **Section "Cas d'Usage"** : Quand utiliser quel index
3. **Adaptation de la capture** : Résultats formatés par type d'index
4. **Validation** : Comparaison des résultats avec différents types d'index

**Structure proposée** : 6 parties didactiques (similaire au script 15, mais avec focus sur types d'index plutôt que analyzers)

---

**📝 Prochaines étapes** :
1. Créer le script didactique `17_test_advanced_search_v2_didactique.sh`
2. Appliquer le template didactique général avec enrichissements
3. Tester le script et valider les résultats
4. Générer la documentation markdown





