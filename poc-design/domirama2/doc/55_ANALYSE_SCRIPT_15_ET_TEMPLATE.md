# 📊 Analyse : Script 15 et Applicabilité du Template Didactique

**Date** : 2025-11-26  
**Script analysé** : `15_test_fulltext_complex.sh`  
**Objectif** : Analyser le script 15 et déterminer si un template existant est applicable, doit être enrichi, ou si un template spécifique est nécessaire

---

## 📋 Table des Matières

1. [Analyse du Script 15](#analyse-du-script-15)
2. [Analyse du Fichier CQL de Test](#analyse-du-fichier-cql-de-test)
3. [Comparaison avec Templates Existants](#comparaison-avec-templates-existants)
4. [Comparaison avec Scripts Similaires](#comparaison-avec-scripts-similaires)
5. [Recommandations](#recommandations)
6. [Conclusion](#conclusion)

---

## 🔍 Analyse du Script 15

### Objectif du Script

Le script `15_test_fulltext_complex.sh` est un **script de test/recherche** qui :

1. **Exécute des tests de recherche full-text complexes** avec SAI
2. **Démontre les capacités des analyzers** (lowercase, asciifolding, frenchLightStem)
3. **Teste les recherches multi-termes** (plusieurs mots simultanément)
4. **Valide la pertinence** des résultats avec différents analyzers

### Structure Actuelle du Script

```bash
# Structure actuelle (125 lignes)
1. En-tête et commentaires (lignes 1-42)
2. Configuration des couleurs (lignes 46-55)
3. Configuration des variables (lignes 57-60)
4. Vérifications (lignes 62-75)
5. Sélection dynamique d'un compte (lignes 82-98)
6. Remplacement des placeholders (lignes 100-102)
7. Exécution du fichier CQL (ligne 105)
8. Messages finaux (lignes 109-124)
```

### Fonctionnalités Actuelles

✅ **Vérifications** :
- HCD démarré
- Keyspace existe

✅ **Sélection dynamique** :
- Sélection automatique d'un compte avec des données
- Remplacement des placeholders dans le fichier CQL

✅ **Exécution** :
- Exécution du fichier CQL de test via `cqlsh -f`
- Filtrage des warnings

✅ **Messages** :
- Messages informatifs sur les types de recherches testées
- Explications sur les capacités des analyzers

### Limitations Actuelles

❌ **Pas d'affichage des requêtes CQL** :
- Les requêtes ne sont pas affichées avant exécution
- Pas d'explication de chaque requête

❌ **Pas de capture des résultats** :
- Les résultats ne sont pas capturés et formatés
- Pas de validation automatique des résultats

❌ **Pas d'explications détaillées** :
- Pas d'explications sur les analyzers (lowercase, asciifolding, stemming)
- Pas d'explications sur les recherches multi-termes
- Pas d'explications sur les équivalences HBase → HCD

❌ **Pas de documentation générée** :
- Pas de rapport markdown généré automatiquement
- Pas de structure didactique

---

## 📋 Analyse du Fichier CQL de Test

### Contenu du Fichier

Le fichier `schemas/06_domirama2_search_fulltext_complex.cql` contient des tests de recherche full-text complexes :

1. **Recherches multi-termes** :
   - 'loyer paris' (2 termes)
   - 'virement impayé' (2 termes avec accent)
   - 'ratp navigo paris' (3 termes)

2. **Gestion des accents (asciifolding)** :
   - 'impayé' → trouve 'IMPAYE'
   - 'café' → trouve 'CAFE'

3. **Racinisation française (frenchLightStem)** :
   - 'loyers' → trouve 'LOYER'
   - 'virements' → trouve 'VIREMENT'

4. **Recherches combinées** :
   - Full-text + filtre par montant
   - Full-text + filtre par catégorie

### Types de Tests

| Type | Description | Analyzer Utilisé | Exemple |
|------|-------------|-----------------|---------|
| **Multi-termes** | Plusieurs mots simultanément | Tous | 'loyer paris' |
| **Asciifolding** | Accents ignorés | asciifolding | 'impayé' → 'IMPAYE' |
| **Stemming** | Pluriel/singulier | frenchLightStem | 'loyers' → 'LOYER' |
| **Lowercase** | Insensible à la casse | lowercase | 'Loyer' → 'LOYER' |
| **Combiné** | Full-text + filtres | Tous | libelle : 'loyer' AND montant < -500 |

---

## 📊 Comparaison avec Templates Existants

### Template Didactique Général (`43_TEMPLATE_SCRIPT_DIDACTIQUE.md`)

**Focus** : Scripts de test/DML  
**Type** : Tests de recherche, validations  
**Structure** : 4-6 parties didactiques

| Aspect | Template Didactique | Besoin Script 15 | Applicable ? |
|--------|-------------------|-----------------|--------------|
| **Type** | Test/DML | Test/Recherche | ✅ Oui |
| **Structure** | 4-6 parties | 4-6 parties | ✅ Oui |
| **Affichage CQL** | Oui (requêtes) | Oui (requêtes) | ✅ Oui |
| **Capture résultats** | Oui | Oui (nécessaire) | ✅ Oui |
| **Explications** | Détaillées | Détaillées | ✅ Oui |
| **Documentation** | Génération markdown | Génération markdown | ✅ Oui |
| **Analyzers SAI** | Non spécifique | Spécifique (analyzers) | ⚠️ À enrichir |

**Conclusion** : Le template est **applicable** mais doit être **enrichi** pour les analyzers SAI.

### Template Setup (`47_TEMPLATE_SCRIPT_SETUP_DIDACTIQUE.md`)

**Focus** : Scripts de setup/DDL  
**Type** : Création de schémas, index  
**Structure** : 6 parties didactiques

| Aspect | Template Setup | Besoin Script 15 | Applicable ? |
|--------|---------------|-----------------|--------------|
| **Type** | Setup/DDL | Test/DML | ❌ Non |
| **Structure** | 6 parties | 4-6 parties | ⚠️ Partiel |
| **Focus** | DDL | DML/Requêtes | ❌ Non |

**Conclusion** : Le template setup n'est **pas applicable** (focus différent).

### Template Ingestion (`50_TEMPLATE_SCRIPT_INGESTION_DIDACTIQUE.md`)

**Focus** : Scripts d'ingestion/ETL  
**Type** : Chargement de données  
**Structure** : 7 parties didactiques

| Aspect | Template Ingestion | Besoin Script 15 | Applicable ? |
|--------|-------------------|-----------------|--------------|
| **Type** | ETL/Ingestion | Test/Recherche | ❌ Non |
| **Structure** | 7 parties | 4-6 parties | ⚠️ Partiel |
| **Focus** | Spark/ETL | CQL/Recherche | ❌ Non |

**Conclusion** : Le template ingestion n'est **pas applicable** (focus différent).

---

## 📊 Comparaison avec Scripts Similaires

### Script 12 (Search Tests) - Version Didactique

Le script `12_test_domirama2_search_v2_didactique.sh` est un script de test didactique qui :

- ✅ Affiche les requêtes CQL avant exécution
- ✅ Capture et formate les résultats
- ✅ Explique chaque test en détail
- ✅ Génère une documentation markdown
- ✅ Structure didactique (6 parties)

**Similarités avec Script 15** :
- Type : Test de recherche full-text
- Format : CQL queries
- Objectif : Valider des fonctionnalités de recherche

**Différences** :
- Script 12 : Tests basiques (opérateurs SAI)
- Script 15 : Tests complexes (analyzers, multi-termes)

**Conclusion** : Le script 12 peut servir de **référence** pour améliorer le script 15.

### Script 25 (Hybrid Search) - Version Didactique

Le script `25_test_hybrid_search_v2_didactique.sh` traite également de recherches complexes.

**Conclusion** : Le script 25 peut servir de **référence** pour les recherches complexes.

---

## 💡 Recommandations

### Option 1 : Utiliser le Template Didactique Général avec Enrichissements (Recommandé) ⭐

**Avantages** :
- Réutilise le template existant
- Cohérence avec les autres scripts de test didactiques
- Adaptations mineures nécessaires

**Adaptations nécessaires** :
- Ajouter section "Analyzers SAI" (explication lowercase, asciifolding, stemming)
- Ajouter section "Recherches Multi-Termes" (explication AND implicite)
- Adapter la capture des résultats pour les recherches complexes
- Ajouter validation de la pertinence avec analyzers

**Verdict** : ✅ **Recommandé**

### Option 2 : Créer un Template Spécifique pour Tests Complexes

**Avantages** :
- Template dédié aux tests complexes
- Sections spécifiques (analyzers, multi-termes)

**Inconvénients** :
- Duplication avec template didactique général
- Maintenance de deux templates similaires
- Pas de valeur ajoutée significative

**Verdict** : ❌ **Non recommandé**

### Option 3 : Enrichir le Template Didactique Général

**Avantages** :
- Un seul template pour tous les tests
- Sections conditionnelles selon le type de test

**Inconvénients** :
- Template plus complexe
- Sections conditionnelles à gérer
- Risque de confusion

**Verdict** : ⚠️ **Possible mais non recommandé**

---

## ✅ Conclusion

### Recommandation Finale

**Utiliser le template didactique général avec des enrichissements spécifiques pour les tests de recherche complexes et les analyzers SAI**.

### Justification

1. **Structure identique** :
   - Les scripts de test ont la même structure (affichage CQL, exécution, capture résultats)
   - Les différences sont mineures (analyzers, multi-termes)

2. **Adaptations simples** :
   - Ajouter section "Analyzers SAI"
   - Ajouter section "Recherches Multi-Termes"
   - Adapter la capture des résultats

3. **Cohérence** :
   - Même structure didactique que les scripts 12 et 25
   - Même niveau de détail
   - Même génération de documentation

### Adaptations à Apporter

1. **PARTIE 1** : Ajouter section "Analyzers SAI" (explication lowercase, asciifolding, stemming)
2. **PARTIE 2** : Ajouter section "Recherches Multi-Termes" (explication AND implicite)
3. **PARTIE 3** : Afficher les requêtes CQL avec explications
4. **PARTIE 4** : Exécuter les requêtes et capturer les résultats
5. **PARTIE 5** : Valider la pertinence avec analyzers
6. **PARTIE 6** : Générer la documentation markdown

### Prochaines Étapes

1. ⏳ **Créer version didactique** : `15_test_fulltext_complex_v2_didactique.sh`
2. ⏳ **Adapter le template** : Utiliser le template didactique avec enrichissements analyzers
3. ⏳ **Tester** : Exécuter le script amélioré et vérifier la documentation générée
4. ⏳ **Valider** : S'assurer que la documentation est complète et pertinente

---

## 📊 Tableau Récapitulatif

| Aspect | Template Didactique | Script 15 Actuel | Script 15 Didactique | Template à Utiliser |
|--------|-------------------|-----------------|---------------------|---------------------|
| **Type** | Test/DML | Test/Recherche | Test/Recherche | Template Didactique (enrichi) |
| **Structure** | 4-6 parties | Basique | 4-6 parties | 4-6 parties (adaptées) |
| **Affichage CQL** | Oui | Non | Oui | Oui (avec explications) |
| **Capture résultats** | Oui | Non | Oui | Oui (formaté) |
| **Analyzers SAI** | Non spécifique | Mentionnés | Expliqués | Section dédiée |
| **Multi-termes** | Non spécifique | Mentionnés | Expliqués | Section dédiée |
| **Documentation** | Génération markdown | Non générée | Génération markdown | Génération markdown |

---

## 🔄 Différences Clés à Adapter

### 1. Analyzers SAI

**À expliquer** :
- **lowercase** : Insensible à la casse ('Loyer' → 'LOYER')
- **asciifolding** : Accents ignorés ('impayé' → 'IMPAYE')
- **frenchLightStem** : Racinisation française ('loyers' → 'loyer')
- **stop words** : Mots vides ignorés ('le', 'la', 'de', etc.)

### 2. Recherches Multi-Termes

**À expliquer** :
- **AND implicite** : 'loyer paris' = 'loyer' AND 'paris'
- **Ordre des termes** : Peu importe l'ordre
- **Pertinence** : Résultats contenant tous les termes

### 3. Capture des Résultats

**À adapter** :
- Capturer le nombre de résultats pour chaque requête
- Afficher un échantillon des résultats
- Valider la pertinence avec analyzers

---

**✅ Conclusion : Le template didactique général est applicable avec des enrichissements spécifiques pour les tests de recherche complexes et les analyzers SAI !**



