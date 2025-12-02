# 📚 Organisation de la Documentation - Domirama2

**Date** : 2025-01-XX  
**Dernière mise à jour** : 2025-01-XX  
**Objectif** : Guide de lecture de la documentation du POC Domirama2  
**Statut** : ✅ **Documentation complète et organisée par catégories** (83 documents organisés, 18 démonstrations, 12 templates)

> **📑 Navigation rapide** : Consultez [`INDEX.md`](INDEX.md) pour un index complet de toutes les catégories.

---

## 📋 Ordre de Lecture Recommandé

### Niveau 1 : Vue d'Ensemble (01-05)

1. **[guides/01_README.md](guides/01_README.md)** - Vue d'ensemble du POC Domirama2
   - Objectifs, conformité IBM (~95%)
   - Structure, exécution
   - Comparaison Domirama1 vs Domirama2

2. **[design/02_VALUE_PROPOSITION_DOMIRAMA2.md](design/02_VALUE_PROPOSITION_DOMIRAMA2.md)** - Proposition de valeur
   - Comparaison avec HBase existant
   - Comparaison avec proposition IBM
   - Innovations au-delà de la proposition

3. **[design/03_GAPS_ANALYSIS.md](design/03_GAPS_ANALYSIS.md)** - Analyse des gaps fonctionnels
   - Gaps identifiés entre HBase et POC
   - Statut de chaque gap (démontré/non démontré)

4. **[design/04_BILAN_ECARTS_FONCTIONNELS.md](design/04_BILAN_ECARTS_FONCTIONNELS.md)** - Bilan des écarts
   - Tableau récapitulatif complet
   - Couverture fonctionnelle

5. **[design/05_AUDIT_COMPLET_GAP_FONCTIONNEL.md](design/05_AUDIT_COMPLET_GAP_FONCTIONNEL.md)** - Audit complet
   - Analyse détaillée de tous les gaps
   - Sources analysées (inputs-clients, inputs-ibm)

---

### Niveau 2 : Fonctionnalités Spécifiques (06-10)

6. **[guides/06_README_INDEX_AVANCES.md](guides/06_README_INDEX_AVANCES.md)** - Index SAI avancés
   - Configuration des index
   - Analyzers français
   - Recherche full-text

7. **[guides/07_README_FUZZY_SEARCH.md](guides/07_README_FUZZY_SEARCH.md)** - Recherche floue
   - Vector search avec ByteT5
   - Tolérance aux typos
   - Génération d'embeddings

8. **[guides/08_README_HYBRID_SEARCH.md](guides/08_README_HYBRID_SEARCH.md)** - Recherche hybride
   - Combinaison Full-Text + Vector
   - Stratégies de fallback
   - Amélioration de la pertinence

9. **[guides/09_README_MULTI_VERSION.md](guides/09_README_MULTI_VERSION.md)** - Multi-version / Time travel
   - Logique batch vs client
   - Colonnes de catégorisation
   - Stratégie multi-version

10. **[implementation/10_TIME_TRAVEL_IMPLEMENTATION.md](implementation/10_TIME_TRAVEL_IMPLEMENTATION.md)** - Implémentation time travel
    - Logique application-side
    - Exemples Java, Python, API REST

---

### Niveau 3 : Exports et Requêtes (11-13)

11. **[guides/11_README_EXPORT_INCREMENTAL.md](guides/11_README_EXPORT_INCREMENTAL.md)** - Exports incrémentaux
    - Export Parquet depuis HCD
    - Fenêtre glissante (TIMERANGE équivalent)
    - STARTROW/STOPROW équivalent

12. **[guides/12_README_EXPORT_SPARK_SUBMIT.md](guides/12_README_EXPORT_SPARK_SUBMIT.md)** - Spark submit
    - Comparaison spark-shell vs spark-submit
    - Recommandations d'utilisation

13. **[guides/13_README_REQUETES_TIMERANGE_STARTROW.md](guides/13_README_REQUETES_TIMERANGE_STARTROW.md)** - Requêtes in-base
    - Requêtes avec fenêtre glissante
    - Requêtes avec STARTROW/STOPROW
    - Valeur ajoutée SAI

---

### Niveau 4 : Features Avancées (14-17)

14. **[guides/14_README_BLOOMFILTER_EQUIVALENT.md](guides/14_README_BLOOMFILTER_EQUIVALENT.md)** - BLOOMFILTER équivalent
    - Index SAI sur clustering keys
    - Performance et comparaisons

15. **[guides/15_README_COLONNES_DYNAMIQUES.md](guides/15_README_COLONNES_DYNAMIQUES.md)** - Colonnes dynamiques
    - MAP<TEXT, TEXT> pour colonnes dynamiques
    - Filtrage sur MAP
    - Comparaison avec HBase

16. **[guides/16_README_REPLICATION_SCOPE.md](guides/16_README_REPLICATION_SCOPE.md)** - REPLICATION_SCOPE
    - Multi-cluster / Multi-datacenter
    - Consistency levels
    - Configuration Java driver

17. **[guides/17_README_DSBULK.md](guides/17_README_DSBULK.md)** - DSBulk
    - Bulk load/unload
    - Support Parquet
    - Comparaison avec Spark

---

### Niveau 5 : Data API (18-21)

18. **[guides/18_README_DATA_API.md](guides/18_README_DATA_API.md)** - Data API
    - Configuration et utilisation
    - Clients disponibles (Python, Java, TypeScript)
    - Exemples de code

19. **[implementation/19_VALEUR_AJOUTEE_DATA_API.md](implementation/19_VALEUR_AJOUTEE_DATA_API.md)** - Valeur ajoutée Data API
    - Analyse par cas d'usage
    - Comparaison avec CQL direct
    - Recommandations

20. **[implementation/20_IMPLEMENTATION_OFFICIELLE_DATA_API.md](implementation/20_IMPLEMENTATION_OFFICIELLE_DATA_API.md)** - Implémentation officielle
    - Conformité avec documentation officielle
    - Code Python et HTTP
    - Preuve de conformité

21. **[implementation/21_STATUT_DATA_API.md](implementation/21_STATUT_DATA_API.md)** - Statut Data API
    - Configuration vs déploiement réel
    - Déploiement Stargate avec Podman

---

### Niveau 6 : Démonstrations et Analyses (22-28)

22. **[results/22_DEMONSTRATION_RESUME.md](results/22_DEMONSTRATION_RESUME.md)** - Résumé des démonstrations
    - Vue d'ensemble des démonstrations
    - Fonctionnalités testées

23. **[results/23_DEMONSTRATION_VALIDATION.md](results/23_DEMONSTRATION_VALIDATION.md)** - Validation des démonstrations
    - Validation que les besoins sont satisfaits
    - Comparaison avec HBase

24. **[design/24_PARQUET_VS_ORC_ANALYSIS.md](design/24_PARQUET_VS_ORC_ANALYSIS.md)** - Analyse Parquet vs ORC
    - Comparaison des formats
    - Recommandation Parquet

25. **[design/25_ANALYSE_DEPENDANCES_POC2.md](design/25_ANALYSE_DEPENDANCES_POC2.md)** - Analyse dépendances
    - JARs requis (SequenceFile, OperationDecoder)
    - Migration vers Parquet

26. **[design/26_ANALYSE_MIGRATION_CSV_PARQUET.md](design/26_ANALYSE_MIGRATION_CSV_PARQUET.md)** - Migration CSV → Parquet
    - Justification du changement
    - Implications techniques

27. **[audits/AUDIT_COMPLET_2025.md](audits/AUDIT_COMPLET_2025.md)** - Audit complet du répertoire (2025)
    - Structure et organisation
    - Points forts et améliorations
    - Recommandations
    - **Note** : Les audits précédents sont archivés dans `archive/audits/`

---

## 🎯 Parcours de Lecture Recommandé

### Pour Comprendre le POC (Débutant)
1. [guides/01_README.md](guides/01_README.md)
2. [design/02_VALUE_PROPOSITION_DOMIRAMA2.md](design/02_VALUE_PROPOSITION_DOMIRAMA2.md)
3. [design/03_GAPS_ANALYSIS.md](design/03_GAPS_ANALYSIS.md)

### Pour Implémenter une Fonctionnalité
- **Recherche** : [guides/06_README_INDEX_AVANCES.md](guides/06_README_INDEX_AVANCES.md), [guides/07_README_FUZZY_SEARCH.md](guides/07_README_FUZZY_SEARCH.md), [guides/08_README_HYBRID_SEARCH.md](guides/08_README_HYBRID_SEARCH.md)
- **Multi-version** : [guides/09_README_MULTI_VERSION.md](guides/09_README_MULTI_VERSION.md), [implementation/10_TIME_TRAVEL_IMPLEMENTATION.md](implementation/10_TIME_TRAVEL_IMPLEMENTATION.md)
- **Exports** : [guides/11_README_EXPORT_INCREMENTAL.md](guides/11_README_EXPORT_INCREMENTAL.md), [guides/12_README_EXPORT_SPARK_SUBMIT.md](guides/12_README_EXPORT_SPARK_SUBMIT.md), [guides/13_README_REQUETES_TIMERANGE_STARTROW.md](guides/13_README_REQUETES_TIMERANGE_STARTROW.md)
- **Features** : [guides/14_README_BLOOMFILTER_EQUIVALENT.md](guides/14_README_BLOOMFILTER_EQUIVALENT.md), [guides/15_README_COLONNES_DYNAMIQUES.md](guides/15_README_COLONNES_DYNAMIQUES.md), [guides/16_README_REPLICATION_SCOPE.md](guides/16_README_REPLICATION_SCOPE.md), [guides/17_README_DSBULK.md](guides/17_README_DSBULK.md)
- **Data API** : [guides/18_README_DATA_API.md](guides/18_README_DATA_API.md), [implementation/19_VALEUR_AJOUTEE_DATA_API.md](implementation/19_VALEUR_AJOUTEE_DATA_API.md), [implementation/20_IMPLEMENTATION_OFFICIELLE_DATA_API.md](implementation/20_IMPLEMENTATION_OFFICIELLE_DATA_API.md), [implementation/21_STATUT_DATA_API.md](implementation/21_STATUT_DATA_API.md)

### Pour Auditer/Valider
- [design/04_BILAN_ECARTS_FONCTIONNELS.md](design/04_BILAN_ECARTS_FONCTIONNELS.md)
- [design/05_AUDIT_COMPLET_GAP_FONCTIONNEL.md](design/05_AUDIT_COMPLET_GAP_FONCTIONNEL.md)
- [results/22_DEMONSTRATION_RESUME.md](results/22_DEMONSTRATION_RESUME.md)
- [results/23_DEMONSTRATION_VALIDATION.md](results/23_DEMONSTRATION_VALIDATION.md)
- [audits/AUDIT_COMPLET_2025.md](audits/AUDIT_COMPLET_2025.md)

---

## 📁 Structure

```
doc/
├── INDEX.md                        # Index de navigation (nouveau)
├── 00_ORGANISATION_DOC.md          # Ce fichier (guide de lecture)
├── design/                         # Design et architecture (15 fichiers)
│   ├── 02_VALUE_PROPOSITION_DOMIRAMA2.md
│   ├── 03_GAPS_ANALYSIS.md
│   ├── 04_BILAN_ECARTS_FONCTIONNELS.md
│   └── ...
├── guides/                         # Guides et références (15 fichiers)
│   ├── 01_README.md
│   ├── 06_README_INDEX_AVANCES.md
│   ├── 07_README_FUZZY_SEARCH.md
│   └── ...
├── implementation/                 # Implémentations (8 fichiers)
│   ├── 10_TIME_TRAVEL_IMPLEMENTATION.md
│   ├── 20_IMPLEMENTATION_OFFICIELLE_DATA_API.md
│   └── ...
├── results/                        # Résultats de tests (3 fichiers)
│   ├── 22_DEMONSTRATION_RESUME.md
│   ├── 23_DEMONSTRATION_VALIDATION.md
│   └── 42_DEMONSTRATION_COMPLETE_DOMIRAMA.md
├── corrections/                    # Corrections appliquées (5 fichiers)
│   ├── 44_GUIDE_AMELIORATION_SCRIPTS.md
│   └── ...
├── audits/                         # Audits et analyses (37 fichiers)
│   ├── AUDIT_COMPLET_2025.md
│   ├── AUDIT_SCRIPTS_SHELL_2025.md
│   └── ...
├── archive/                         # Archives (audits et documents historiques)
│   └── audits/                     # Audits précédents
├── demonstrations/                  # 18 démonstrations auto-générées
│   ├── 10_SETUP_DEMONSTRATION.md
│   ├── 11_INGESTION_DEMONSTRATION.md
│   └── ...
└── templates/                       # 12 templates réutilisables
    ├── 43_TEMPLATE_SCRIPT_DIDACTIQUE.md
    └── ...
```

---

**✅ Documentation organisée par catégories pour faciliter la navigation !**

**Mise à jour** : 2025-01-XX
- ✅ **83 documents** organisés en 6 catégories
- ✅ **18 démonstrations** .md générées automatiquement dans `doc/demonstrations/`
- ✅ **12 templates** réutilisables dans `doc/templates/`
- ✅ **INDEX.md** créé pour navigation rapide
- ✅ **Structure alignée** avec domiramaCatOps
