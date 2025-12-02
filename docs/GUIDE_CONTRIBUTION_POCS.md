# 📝 Guide de Contribution aux POCs - ARKEA

**Date** : 2025-12-02  
**Objectif** : Standards et conventions pour contribuer aux POCs  
**Version** : 1.0.0

---

## 📋 Vue d'Ensemble

Ce guide définit les **standards communs** pour contribuer aux POCs du projet ARKEA :

- **BIC** (Base d'Interaction Client)
- **domirama2** (Domirama v2)
- **domiramaCatOps** (Domirama Catégorisation des Opérations)

---

## 🎯 Principes Fondamentaux

### 1. Scripts Didactiques

Tous les scripts doivent être **didactiques** :

- ✅ **Documentation complète** : En-tête avec description, usage, exemples
- ✅ **Explications détaillées** : Commentaires pour chaque étape importante
- ✅ **Génération automatique** : Rapports `.md` auto-générés
- ✅ **Coloration** : Utilisation de couleurs pour la lisibilité
- ✅ **Validation** : Contrôles de pertinence, cohérence, intégrité

### 2. Structure Standard

Chaque POC suit la même structure :

```
poc-design/<poc-name>/
├── scripts/          # Scripts d'automatisation (numérotés)
├── doc/              # Documentation
│   ├── design/       # Design et architecture
│   ├── guides/       # Guides d'utilisation
│   ├── demonstrations/ # Rapports auto-générés
│   └── audits/       # Audits et analyses
├── schemas/          # Schémas CQL
├── utils/            # Fonctions utilitaires
└── README.md         # Documentation principale
```

### 3. Conventions de Nommage

#### Scripts

- **Format** : `NN_description.sh` (numérotés par ordre d'exécution)
- **Exemples** :
  - `01_setup_keyspace.sh`
  - `05_generate_data.sh`
  - `11_test_pagination.sh`

#### Documentation

- **Format** : `NN_DESCRIPTION.md` (numérotés par ordre de lecture)
- **Exemples** :
  - `01_README.md`
  - `02_PLAN_MISE_EN_OEUVRE.md`
  - `11_TEST_PAGINATION_DEMONSTRATION.md`

#### Schémas CQL

- **Format** : `NN_create_table_name.cql` (numérotés par ordre d'exécution)
- **Exemples** :
  - `01_create_keyspace.cql`
  - `02_create_table_operations.cql`

---

## 📝 Standards pour Scripts

### En-tête Standard

```bash
#!/bin/bash
set -euo pipefail
# =============================================================================
# Script NN : Description du Script
# =============================================================================
# Date : YYYY-MM-DD
# Usage : ./NN_description.sh [options]
# Description : Description détaillée du script
# =============================================================================
```

### Fonctions Utilitaires

Utiliser les fonctions utilitaires communes :

```bash
# Charger les fonctions didactiques
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../utils/didactique_functions.sh" ]; then
    source "$SCRIPT_DIR/../utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si fonctions non disponibles
    source ../../.poc-profile
fi
```

### Génération de Rapports

Tous les scripts de test/démonstration doivent générer un rapport `.md` :

```bash
REPORT_FILE="$SCRIPT_DIR/../doc/demonstrations/NN_DESCRIPTION_DEMONSTRATION.md"

generate_report_header() {
    cat > "$REPORT_FILE" <<EOF
# 📊 Démonstration : Description

**Date** : $(date +%Y-%m-%d)  
**Script** : \`NN_description.sh\`  
**Objectif** : Description de la démonstration

---

## 📋 Résultats

EOF
}

# ... exécution des tests ...

generate_report_footer() {
    cat >> "$REPORT_FILE" <<EOF

---

**Généré automatiquement par** : \`NN_description.sh\`
EOF
}
```

### Validation

Tous les scripts doivent valider :

- ✅ **Pertinence** : Les résultats sont-ils pertinents ?
- ✅ **Cohérence** : Les résultats sont-ils cohérents ?
- ✅ **Intégrité** : Les données sont-elles intégres ?
- ✅ **Consistance** : Les résultats sont-ils consistants ?
- ✅ **Conformité** : Conforme aux exigences ?
- ✅ **Justesse** : Les résultats sont-ils corrects ?
- ✅ **Comparaison** : Résultats attendus vs obtenus

---

## 🏗️ Standards pour Documentation

### README.md Principal

Chaque POC doit avoir un `README.md` complet avec :

1. **Vue d'ensemble** : Description du POC
2. **Caractéristiques principales** : Liste des fonctionnalités
3. **Structure du projet** : Organisation des fichiers
4. **Installation** : Guide d'installation
5. **Utilisation** : Guide d'utilisation
6. **Scripts** : Liste des scripts avec descriptions
7. **Documentation** : Liens vers la documentation
8. **Conformité** : Score de conformité avec les exigences

### Documentation de Design

Tous les POCs doivent avoir :

- `doc/design/00_ANALYSE_POC.md` : Analyse complète du POC
- `doc/design/01_STRUCTURE_CREEE.md` : Structure créée
- `doc/design/02_PLAN_MISE_EN_OEUVRE.md` : Plan d'implémentation
- `doc/design/03_METHODOLOGIE_VALIDATION.md` : Méthodologie de validation

### Documentation de Démonstrations

Tous les scripts de test/démonstration génèrent :

- `doc/demonstrations/NN_DESCRIPTION_DEMONSTRATION.md` : Rapport auto-généré

---

## 🧪 Standards pour Tests

### Structure d'un Test

```bash
#!/bin/bash
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/didactique_functions.sh"
setup_paths

# Variables de test
TEST_NAME="test_description"
PASSED=0
FAILED=0

# Fonction de test
test_function() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    if [ "$expected" = "$actual" ]; then
        echo "✅ $test_name"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo "❌ $test_name (expected: $expected, got: $actual)"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Tests
test_function "test_1" "expected_value" "actual_value"

# Résumé
echo ""
echo "Tests passés: $PASSED"
echo "Tests échoués: $FAILED"
exit $FAILED
```

### Contrôles Obligatoires

Tous les tests doivent :

1. **Vérifier la pertinence** : Les résultats sont-ils pertinents ?
2. **Vérifier la cohérence** : Les résultats sont-ils cohérents ?
3. **Vérifier l'intégrité** : Les données sont-elles intégres ?
4. **Vérifier la consistance** : Les résultats sont-ils consistants ?
5. **Vérifier la conformité** : Conforme aux exigences ?
6. **Vérifier la justesse** : Les résultats sont-ils corrects ?
7. **Comparer attendus/obtenus** : Résultats attendus vs obtenus

---

## 🔧 Standards pour Schémas CQL

### Structure Standard

```cql
-- =============================================================================
-- Schéma NN : Description
-- =============================================================================
-- Date : YYYY-MM-DD
-- Usage : cqlsh -f schemas/NN_create_table_name.cql
-- Description : Description du schéma
-- =============================================================================

-- Création du keyspace (si nécessaire)
CREATE KEYSPACE IF NOT EXISTS poc_keyspace
WITH REPLICATION = {
    'class': 'SimpleStrategy',
    'replication_factor': 1
};

USE poc_keyspace;

-- Création de la table
CREATE TABLE IF NOT EXISTS table_name (
    -- Colonnes
    PRIMARY KEY (partition_key, clustering_key)
) WITH ...
```

### Index SAI

```cql
-- Index full-text
CREATE CUSTOM INDEX IF NOT EXISTS idx_column_fulltext
ON table_name (column)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex'
WITH OPTIONS = {
    'index_analyzer': '{
        "tokenizer": "standard",
        "filters": ["lowercase", "asciifolding", "frenchLightStem"]
    }'
};

-- Index vector
CREATE CUSTOM INDEX IF NOT EXISTS idx_column_vector
ON table_name (column_embedding)
USING 'org.apache.cassandra.index.sai.StorageAttachedIndex'
WITH OPTIONS = {
    'index_mode': 'vector',
    'dimensions': 768
};
```

---

## 📊 Standards pour Rapports

### Format Standard

```markdown
# 📊 Démonstration : Description

**Date** : YYYY-MM-DD  
**Script** : `NN_description.sh`  
**Objectif** : Description de la démonstration

---

## 📋 Résultats

### Test 1 : Description

**Résultat** : ✅ Succès / ❌ Échec

**Détails** :
- ...
- ...

### Test 2 : Description

...

---

## 📊 Statistiques

- **Tests passés** : X
- **Tests échoués** : Y
- **Taux de succès** : Z%

---

**Généré automatiquement par** : `NN_description.sh`
```

---

## ✅ Checklist de Contribution

Avant de soumettre une contribution :

- [ ] Scripts avec `set -euo pipefail`
- [ ] Documentation complète (en-tête, commentaires)
- [ ] Génération automatique de rapports `.md`
- [ ] Validation (pertinence, cohérence, intégrité, etc.)
- [ ] Tests avec contrôles obligatoires
- [ ] Schémas CQL avec commentaires
- [ ] README.md à jour
- [ ] Conventions de nommage respectées
- [ ] Structure standard respectée
- [ ] Pas de chemins hardcodés
- [ ] Utilisation de variables d'environnement

---

## 📚 Ressources

- **CONTRIBUTING.md** : Guide général de contribution
- **GUIDE_CHOIX_POC.md** : Guide de choix de POC
- **GUIDE_COMPARAISON_POCS.md** : Comparaison détaillée
- **poc-design/*/README.md** : Documentation de chaque POC

---

**Pour plus d'informations, voir** :
- `CONTRIBUTING.md` - Guide général
- `docs/GUIDE_CHOIX_POC.md` - Guide de choix
- `poc-design/*/README.md` - Documentation des POCs

