# 📚 Organisation de la Documentation - Domirama2

**Date** : 2024-11-27  
**Objectif** : Guide de lecture de la documentation du POC Domirama2  
**Statut** : ✅ **Documentation complète et à jour** (35+ documents, 18 démonstrations, 12 templates)

---

## 📋 Ordre de Lecture Recommandé

### Niveau 1 : Vue d'Ensemble (01-05)

1. **01_README.md** - Vue d'ensemble du POC Domirama2
   - Objectifs, conformité IBM (~95%)
   - Structure, exécution
   - Comparaison Domirama1 vs Domirama2

2. **02_VALUE_PROPOSITION_DOMIRAMA2.md** - Proposition de valeur
   - Comparaison avec HBase existant
   - Comparaison avec proposition IBM
   - Innovations au-delà de la proposition

3. **03_GAPS_ANALYSIS.md** - Analyse des gaps fonctionnels
   - Gaps identifiés entre HBase et POC
   - Statut de chaque gap (démontré/non démontré)

4. **04_BILAN_ECARTS_FONCTIONNELS.md** - Bilan des écarts
   - Tableau récapitulatif complet
   - Couverture fonctionnelle

5. **05_AUDIT_COMPLET_GAP_FONCTIONNEL.md** - Audit complet
   - Analyse détaillée de tous les gaps
   - Sources analysées (inputs-clients, inputs-ibm)

---

### Niveau 2 : Fonctionnalités Spécifiques (06-10)

6. **06_README_INDEX_AVANCES.md** - Index SAI avancés
   - Configuration des index
   - Analyzers français
   - Recherche full-text

7. **07_README_FUZZY_SEARCH.md** - Recherche floue
   - Vector search avec ByteT5
   - Tolérance aux typos
   - Génération d'embeddings

8. **08_README_HYBRID_SEARCH.md** - Recherche hybride
   - Combinaison Full-Text + Vector
   - Stratégies de fallback
   - Amélioration de la pertinence

9. **09_README_MULTI_VERSION.md** - Multi-version / Time travel
   - Logique batch vs client
   - Colonnes de catégorisation
   - Stratégie multi-version

10. **10_TIME_TRAVEL_IMPLEMENTATION.md** - Implémentation time travel
    - Logique application-side
    - Exemples Java, Python, API REST

---

### Niveau 3 : Exports et Requêtes (11-13)

11. **11_README_EXPORT_INCREMENTAL.md** - Exports incrémentaux
    - Export Parquet depuis HCD
    - Fenêtre glissante (TIMERANGE équivalent)
    - STARTROW/STOPROW équivalent

12. **12_README_EXPORT_SPARK_SUBMIT.md** - Spark submit
    - Comparaison spark-shell vs spark-submit
    - Recommandations d'utilisation

13. **13_README_REQUETES_TIMERANGE_STARTROW.md** - Requêtes in-base
    - Requêtes avec fenêtre glissante
    - Requêtes avec STARTROW/STOPROW
    - Valeur ajoutée SAI

---

### Niveau 4 : Features Avancées (14-17)

14. **14_README_BLOOMFILTER_EQUIVALENT.md** - BLOOMFILTER équivalent
    - Index SAI sur clustering keys
    - Performance et comparaisons

15. **15_README_COLONNES_DYNAMIQUES.md** - Colonnes dynamiques
    - MAP<TEXT, TEXT> pour colonnes dynamiques
    - Filtrage sur MAP
    - Comparaison avec HBase

16. **16_README_REPLICATION_SCOPE.md** - REPLICATION_SCOPE
    - Multi-cluster / Multi-datacenter
    - Consistency levels
    - Configuration Java driver

17. **17_README_DSBULK.md** - DSBulk
    - Bulk load/unload
    - Support Parquet
    - Comparaison avec Spark

---

### Niveau 5 : Data API (18-21)

18. **18_README_DATA_API.md** - Data API
    - Configuration et utilisation
    - Clients disponibles (Python, Java, TypeScript)
    - Exemples de code

19. **19_VALEUR_AJOUTEE_DATA_API.md** - Valeur ajoutée Data API
    - Analyse par cas d'usage
    - Comparaison avec CQL direct
    - Recommandations

20. **20_IMPLEMENTATION_OFFICIELLE_DATA_API.md** - Implémentation officielle
    - Conformité avec documentation officielle
    - Code Python et HTTP
    - Preuve de conformité

21. **21_STATUT_DATA_API.md** - Statut Data API
    - Configuration vs déploiement réel
    - Déploiement Stargate avec Podman

---

### Niveau 6 : Démonstrations et Analyses (22-28)

22. **22_DEMONSTRATION_RESUME.md** - Résumé des démonstrations
    - Vue d'ensemble des démonstrations
    - Fonctionnalités testées

23. **23_DEMONSTRATION_VALIDATION.md** - Validation des démonstrations
    - Validation que les besoins sont satisfaits
    - Comparaison avec HBase

24. **24_PARQUET_VS_ORC_ANALYSIS.md** - Analyse Parquet vs ORC
    - Comparaison des formats
    - Recommandation Parquet

25. **25_ANALYSE_DEPENDANCES_POC2.md** - Analyse dépendances
    - JARs requis (SequenceFile, OperationDecoder)
    - Migration vers Parquet

26. **26_ANALYSE_MIGRATION_CSV_PARQUET.md** - Migration CSV → Parquet
    - Justification du changement
    - Implications techniques

27. **27_AUDIT_COMPLET_DOMIRAMA2.md** - Audit complet du répertoire
    - Structure et organisation
    - Points forts et améliorations
    - Recommandations

28. **28_REORGANISATION_COMPLETE.md** - Réorganisation complète
    - Actions de réorganisation
    - Nouvelle structure
    - Bénéfices

---

## 🎯 Parcours de Lecture Recommandé

### Pour Comprendre le POC (Débutant)
1. 01_README.md
2. 02_VALUE_PROPOSITION_DOMIRAMA2.md
3. 03_GAPS_ANALYSIS.md

### Pour Implémenter une Fonctionnalité
- Recherche : 06, 07, 08
- Multi-version : 09, 10
- Exports : 11, 12, 13
- Features : 14, 15, 16, 17
- Data API : 18, 19, 20, 21

### Pour Auditer/Valider
- 04_BILAN_ECARTS_FONCTIONNELS.md
- 05_AUDIT_COMPLET_GAP_FONCTIONNEL.md
- 22_DEMONSTRATION_RESUME.md
- 23_DEMONSTRATION_VALIDATION.md
- 27_AUDIT_COMPLET_DOMIRAMA2.md

---

## 📁 Structure

```
doc/
├── 00_ORGANISATION_DOC.md (ce fichier)
├── 01_README.md
├── 02_VALUE_PROPOSITION_DOMIRAMA2.md
├── ...
├── 42_DEMONSTRATION_COMPLETE_DOMIRAMA.md
├── 43_SYNTHESE_COMPLETE_ANALYSE_2024.md
├── demonstrations/ (18 démonstrations auto-générées)
│   ├── 10_SETUP_DEMONSTRATION.md
│   ├── 11_INGESTION_DEMONSTRATION.md
│   ├── ...
│   └── 30_STARTROW_STOPROW_REQUETES_DEMONSTRATION.md
└── templates/ (12 templates réutilisables)
    ├── 43_TEMPLATE_SCRIPT_DIDACTIQUE.md
    ├── 47_TEMPLATE_SCRIPT_SETUP_DIDACTIQUE.md
    ├── ...
    └── 69_TEMPLATE_HEREDOC_PYTHON_BACKTICKS.md
```

---

**✅ Documentation organisée et numérotée pour faciliter la lecture !**

**Mise à jour** : 2024-11-27
- ✅ **35+ documents** à la racine de `doc/`
- ✅ **18 démonstrations** .md générées automatiquement dans `doc/demonstrations/`
- ✅ **12 templates** réutilisables dans `doc/templates/`
- ✅ **Synthèse complète** d'analyse (`43_SYNTHESE_COMPLETE_ANALYSE_2024.md`)
