# Templates pour Scripts Didactiques - DomiramaCatOps

Ce répertoire contient tous les templates réutilisables pour créer des scripts shell didactiques dans le cadre du POC DomiramaCatOps.

## Liste des Templates

### Templates Généraux

1. **43_TEMPLATE_SCRIPT_DIDACTIQUE.md**
   - Template de base pour scripts didactiques généraux
   - Structure standard avec sections : vérifications, contexte, exécution, résultats, rapport
   - **Contexte** : DomiramaCatOps POC

2. **47_TEMPLATE_SCRIPT_SETUP_DIDACTIQUE.md**
   - Template pour scripts de configuration/setup
   - Inclut vérifications d'environnement, création de schéma, index SAI
   - **Adapté pour** : `domiramacatops_poc` keyspace

3. **50_TEMPLATE_SCRIPT_INGESTION_DIDACTIQUE.md**
   - Template pour scripts d'ingestion/ETL
   - Inclut lecture de données Parquet, transformation, chargement dans HCD
   - **Stratégie** : Multi-version (batch écrit uniquement cat_auto, client écrit cat_user)

### Templates Spécialisés

4. **63_TEMPLATE_SCRIPT_ORCHESTRATION_DIDACTIQUE.md**
   - Template pour scripts d'orchestration
   - Coordination de plusieurs scripts et démonstrations
   - **Usage** : Scripts qui appellent plusieurs autres scripts

5. **65_TEMPLATE_SCRIPT_TEST_DELEGATION_PYTHON.md**
   - Template pour scripts qui délèguent à Python
   - Intégration Python dans scripts shell
   - **Usage** : Tests complexes nécessitant Python (embeddings, time travel, etc.)

6. **66_TEMPLATE_SCRIPT_EXPORT_DIDACTIQUE.md**
   - Template pour scripts d'export
   - Export de données HCD vers Parquet/JSON
   - **Équivalences** : HBase TIMERANGE → HCD WHERE date_op

7. **68_TEMPLATE_SCRIPT_DEMO_REQUETES_CQL.md**
   - Template pour démonstrations de requêtes CQL
   - Mesure de performance, équivalences HBase → HCD
   - **Usage** : Démonstrations directes via cqlsh

### Templates Techniques

8. **69_TEMPLATE_HEREDOC_PYTHON_BACKTICKS.md**
   - Solution pour gérer les backticks dans heredoc Python
   - Résout les problèmes d'interprétation shell des backticks markdown
   - **Usage** : Génération de rapports markdown avec blocs de code

## Utilisation

Pour utiliser un template :

1. Lire le template correspondant à votre besoin
2. Copier la structure dans votre nouveau script
3. Adapter les sections selon votre contexte DomiramaCatOps
4. Suivre les conventions de nommage : `XX_description_didactique.sh`
5. Utiliser `source utils/didactique_functions.sh` pour les fonctions utilitaires

## Conventions DomiramaCatOps

- **Keyspace** : `domiramacatops_poc`
- **Table principale** : `operations_by_account`
- **Tables meta-categories** : 7 tables (acceptation_client, opposition_categorisation, etc.)
- Tous les scripts didactiques doivent générer un rapport markdown automatique
- Les rapports sont stockés dans `doc/demonstrations/`
- Les scripts doivent être préfixés par leur numéro d'ordre d'exécution
- Les templates doivent être documentés avec des exemples concrets

## Fonctions Utilitaires

Le fichier `utils/didactique_functions.sh` contient des fonctions réutilisables :

- `info()`, `success()`, `warn()`, `error()` : Affichage coloré
- `show_cql_query()` : Affichage formaté de requêtes CQL
- `execute_and_display()` : Exécution et affichage de requêtes
- `show_test_section()` : Affichage de sections de test
- `show_hbase_context()` : Affichage des équivalences HBase → HCD
- `generate_report()` : Génération de rapports markdown
- `check_schema()` : Vérification du schéma

**Utilisation** :

```bash
source utils/didactique_functions.sh
```

## Différences avec Domirama2

Les templates DomiramaCatOps sont adaptés pour :

- **Keyspace** : `domiramacatops_poc` (au lieu de `domirama2_poc`)
- **Tables multiples** : 8 tables au total (1 operations + 7 meta-categories)
- **Stratégie multi-version** : Colonnes cat_auto, cat_user, cat_date_user, cat_validee
- **Recherche avancée** : libelle_prefix, libelle_tokens, libelle_embedding
- **Règles personnalisées** : Table `regles_personnalisees`
- **Feedbacks** : Tables `feedback_par_libelle` et `feedback_par_ics`

## Dernière Mise à Jour

2025-01-XX : Tous les templates ont été dupliqués et adaptés depuis domirama2 vers domiramaCatOps.
