# Templates pour Scripts Didactiques

Ce répertoire contient tous les templates réutilisables pour créer des scripts shell didactiques dans le cadre du POC Domirama2.

## Liste des Templates

### Templates Généraux

1. **43_TEMPLATE_SCRIPT_DIDACTIQUE.md**
   - Template de base pour scripts didactiques généraux
   - Structure standard avec sections : vérifications, contexte, exécution, résultats, rapport

2. **47_TEMPLATE_SCRIPT_SETUP_DIDACTIQUE.md**
   - Template pour scripts de configuration/setup
   - Inclut vérifications d'environnement, installation, configuration

3. **50_TEMPLATE_SCRIPT_INGESTION_DIDACTIQUE.md**
   - Template pour scripts d'ingestion/ETL
   - Inclut lecture de données, transformation, chargement dans HCD

### Templates Spécialisés

4. **63_TEMPLATE_SCRIPT_ORCHESTRATION_DIDACTIQUE.md**
   - Template pour scripts d'orchestration
   - Coordination de plusieurs scripts et démonstrations

5. **64_TEMPLATE_SCRIPT_TEST_MULTIPLES_EMBEDDINGS.md**
   - Template pour scripts testant plusieurs embeddings
   - Gestion de multiples colonnes vectorielles

6. **65_TEMPLATE_SCRIPT_TEST_DELEGATION_PYTHON.md**
   - Template pour scripts qui délèguent à Python
   - Intégration Python dans scripts shell

7. **66_TEMPLATE_SCRIPT_EXPORT_DIDACTIQUE.md**
   - Template pour scripts d'export
   - Export de données HCD vers Parquet/JSON

8. **67_TEMPLATE_SCRIPT_EXPORT_FENETRE_GLISSANTE_DIDACTIQUE.md**
   - Template pour exports avec fenêtre glissante
   - Export incrémental par fenêtres temporelles

9. **68_TEMPLATE_SCRIPT_DEMO_REQUETES_CQL.md**
   - Template pour démonstrations de requêtes CQL
   - Mesure de performance, équivalences HBase → HCD

10. **67_TEMPLATE_SCRIPT_19_ET_RECOMMANDATION.md**
    - Template basé sur le script 19
    - Recommandations pour enrichissement didactique

### Templates Techniques

11. **69_TEMPLATE_HEREDOC_PYTHON_BACKTICKS.md**
    - Solution pour gérer les backticks dans heredoc Python
    - Résout les problèmes d'interprétation shell des backticks markdown

12. **15_fulltext_complex_template.md**
    - Template pour recherches full-text complexes
    - Gestion des analyzers Lucene, stemming, asciifolding

## Utilisation

Pour utiliser un template :

1. Lire le template correspondant à votre besoin
2. Copier la structure dans votre nouveau script
3. Adapter les sections selon votre contexte
4. Suivre les conventions de nommage : `XX_description_v2_didactique.sh`

## Conventions

- Tous les scripts didactiques doivent générer un rapport markdown automatique
- Les rapports sont stockés dans `doc/demonstrations/`
- Les scripts doivent être préfixés par leur numéro d'ordre d'exécution
- Les templates doivent être documentés avec des exemples concrets

## Dernière Mise à Jour

2024-11-27 : Tous les templates ont été centralisés dans ce répertoire.
