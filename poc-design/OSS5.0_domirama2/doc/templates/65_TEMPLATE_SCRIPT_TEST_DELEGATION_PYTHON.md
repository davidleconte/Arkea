# 📋 Template : Script Shell Didactique pour Tests avec Délégation Python

**Date** : 2025-11-26
**Objectif** : Template réutilisable pour créer des scripts de test/démonstration qui délèguent la logique à un script Python externe
**Type** : Scripts qui appellent un script Python externe et génèrent un rapport structuré

---

## 🎯 Principes du Template pour Délégation Python

Un script avec délégation Python didactique doit :

1. **Vérifier l'environnement** : HCD, dépendances Python, schéma, script Python présent
2. **Afficher l'objectif et la stratégie** : Contexte métier, objectifs, stratégie de démonstration
3. **Vérifier le schéma** : Colonnes nécessaires, index, contraintes
4. **Appeler le script Python avec capture** : Exécution avec capture de la sortie
5. **Parser et afficher les résultats** : Extraction des informations clés, affichage structuré
6. **Générer un rapport** : Documentation structurée pour livrable avec toutes les étapes
7. **Résumer et conclure** : Points clés validés, prochaines étapes

---

## 📝 Structure Standard pour Script avec Délégation Python

```bash
#!/bin/bash
# ============================================
# Script XX : Test [Nom] (Version Didactique)
# Démontre [fonctionnalité] via script Python externe
# ============================================
#
# OBJECTIF :
#   Ce script démontre [fonctionnalité] en appelant un script Python externe
#   qui exécute [nombre] étapes de démonstration.
#
#   Cette version didactique affiche :
#   - L'objectif et la stratégie de démonstration
#   - Le schéma nécessaire avec explications
#   - Les résultats de chaque étape de démonstration
#   - Les validations et points clés
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (si nécessaire)
#   - Python 3.8+ installé
#   - Script Python présent: examples/python/[module]/[script].py
#
# UTILISATION :
#   ./XX_test_[nom].sh
#
# SORTIE :
#   - Démonstration complète avec toutes les étapes
#   - Résultats détaillés de chaque étape
#   - Documentation structurée générée
#
# ============================================

set -e

# ============================================
# CONFIGURATION DES COULEURS
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
demo() { echo -e "${CYAN}🎯 $1${NC}"; }
code() { echo -e "${MAGENTA}📝 $1${NC}"; }
section() { echo -e "${BOLD}${CYAN}$1${NC}"; }
result() { echo -e "${GREEN}📊 $1${NC}"; }
expected() { echo -e "${YELLOW}📋 $1${NC}"; }

# ============================================
# CONFIGURATION
# ============================================
INSTALL_DIR="${ARKEA_HOME}"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/XX_[NOM]_DEMONSTRATION.md"
PYTHON_SCRIPT="${SCRIPT_DIR}/examples/python/[module]/[script].py"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Fichiers temporaires pour capture
TEMP_OUTPUT=$(mktemp /tmp/script_XX_output_XXXXXX.txt)
TEMP_RESULTS=$(mktemp /tmp/script_XX_results_XXXXXX.json)

# ============================================
# PARTIE 0 : VÉRIFICATIONS
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 0: VÉRIFICATIONS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier que HCD est démarré
info "Vérification de HCD..."
if ! pgrep -f "cassandra" > /dev/null; then
    error "HCD n'est pas démarré. Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

# Vérifier Python
info "Vérification de Python..."
if ! command -v python3 &> /dev/null; then
    error "Python 3 n'est pas installé"
    exit 1
fi
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
success "Python ${PYTHON_VERSION} disponible"

# Vérifier le script Python
info "Vérification du script Python..."
if [ ! -f "$PYTHON_SCRIPT" ]; then
    error "Script Python non trouvé: $PYTHON_SCRIPT"
    exit 1
fi
success "Script Python trouvé: $(basename "$PYTHON_SCRIPT")"

# Vérifier les dépendances Python
info "Vérification des dépendances Python..."
if ! python3 -c "import cassandra" 2>/dev/null; then
    error "Module 'cassandra' non installé. Installez avec: pip3 install cassandra-driver"
    exit 1
fi
success "Dépendances Python vérifiées"

# Vérifier le schéma (optionnel, selon le besoin)
info "Vérification du schéma..."
# Exemple de vérification
# cqlsh -e "DESCRIBE KEYSPACE domirama2_poc" > /dev/null 2>&1
# if [ $? -ne 0 ]; then
#     error "Le keyspace 'domirama2_poc' n'existe pas. Exécutez d'abord: ./10_setup_domirama2_poc.sh"
#     exit 1
# fi
success "Schéma vérifié"

echo ""

# ============================================
# PARTIE 1 : OBJECTIF ET STRATÉGIE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🎯 PARTIE 1: OBJECTIF ET STRATÉGIE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 OBJECTIF : [Description détaillée de l'objectif]"
echo "   [Détails supplémentaires]"
echo ""

info "🔧 STRATÉGIE : [Description de la stratégie]"
echo "   - [Point 1]"
echo "   - [Point 2]"
echo "   - [Point 3]"
echo ""

info "📋 ÉTAPES DE DÉMONSTRATION :"
echo "   Le script Python exécutera [nombre] étapes :"
echo "   1. [Étape 1]"
echo "   2. [Étape 2]"
echo "   3. [Étape 3]"
echo "   ..."
echo ""

# ============================================
# PARTIE 2 : DDL OU VÉRIFICATION SCHÉMA
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📐 PARTIE 2: SCHÉMA NÉCESSAIRE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📋 Colonnes nécessaires dans la table [table_name] :"
echo ""
code "   - [colonne1] : [type] - [description]"
code "   - [colonne2] : [type] - [description]"
code "   - [colonne3] : [type] - [description]"
echo ""

info "🔍 Vérification de la présence des colonnes..."
# Exemple de vérification
# COLUMNS_CHECK=$(cqlsh -e "SELECT column_name FROM system_schema.columns WHERE keyspace_name='domirama2_poc' AND table_name='operations_by_account'" 2>/dev/null | grep -c "[colonne]" || echo "0")
# if [ "$COLUMNS_CHECK" -eq "0" ]; then
#     warn "Colonne [colonne] non trouvée"
# else
#     success "Colonne [colonne] présente"
# fi
success "Toutes les colonnes nécessaires sont présentes"
echo ""

# ============================================
# PARTIE 3 : APPEL AU SCRIPT PYTHON AVEC CAPTURE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🚀 PARTIE 3: EXÉCUTION DU SCRIPT PYTHON"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📝 Exécution du script Python : $(basename "$PYTHON_SCRIPT")"
echo ""

# Exécuter le script Python et capturer la sortie
# Rediriger stdout et stderr vers le fichier temporaire
# Afficher aussi en temps réel dans le terminal
python3 "$PYTHON_SCRIPT" 2>&1 | tee "$TEMP_OUTPUT"

PYTHON_EXIT_CODE=${PIPESTATUS[0]}

if [ $PYTHON_EXIT_CODE -ne 0 ]; then
    error "Le script Python a échoué avec le code $PYTHON_EXIT_CODE"
    echo ""
    warn "Sortie du script Python :"
    cat "$TEMP_OUTPUT"
    exit 1
fi

success "Script Python exécuté avec succès"
echo ""

# ============================================
# PARTIE 4 : PARSING ET AFFICHAGE DES RÉSULTATS
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 4: ANALYSE DES RÉSULTATS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "🔍 Analyse de la sortie du script Python..."
echo ""

# Parser la sortie pour extraire les informations clés
# Exemple de parsing (à adapter selon la sortie du script Python)
python3 << PYTHON_PARSE
import re
import json
import sys

output_file = "$TEMP_OUTPUT"
results_file = "$TEMP_RESULTS"

# Lire la sortie
with open(output_file, 'r', encoding='utf-8') as f:
    output = f.read()

# Structure pour stocker les résultats
results = {
    "steps": [],
    "validations": [],
    "queries": [],
    "summary": {}
}

# Parser les étapes (exemple : chercher les lignes avec "Étape X:")
step_pattern = r'📌 Étape (\d+): (.+)'
steps = re.findall(step_pattern, output)
for step_num, step_desc in steps:
    results["steps"].append({
        "number": int(step_num),
        "description": step_desc
    })

# Parser les validations (exemple : chercher les lignes avec "✅")
validation_pattern = r'✅ (.+)'
validations = re.findall(validation_pattern, output)
results["validations"] = validations

# Parser les requêtes CQL (exemple : chercher les blocs entre ```cql)
cql_pattern = r'```cql\n(.*?)\n```'
queries = re.findall(cql_pattern, output, re.DOTALL)
results["queries"] = queries

# Compter les étapes
results["summary"] = {
    "total_steps": len(results["steps"]),
    "total_validations": len(results["validations"]),
    "total_queries": len(results["queries"])
}

# Sauvegarder les résultats
with open(results_file, 'w', encoding='utf-8') as f:
    json.dump(results, f, indent=2, ensure_ascii=False)

# Afficher le résumé
print(f"📊 Résumé de l'analyse :")
print(f"   - Étapes détectées : {results['summary']['total_steps']}")
print(f"   - Validations détectées : {results['summary']['total_validations']}")
print(f"   - Requêtes CQL détectées : {results['summary']['total_queries']}")
PYTHON_PARSE

echo ""

# Afficher les étapes détectées
if [ -f "$TEMP_RESULTS" ]; then
    info "📋 Étapes de démonstration détectées :"
    python3 << PYTHON_DISPLAY
import json

with open("$TEMP_RESULTS", 'r', encoding='utf-8') as f:
    results = json.load(f)

for step in results.get("steps", []):
    print(f"   {step['number']}. {step['description']}")
PYTHON_DISPLAY
    echo ""
fi

# ============================================
# PARTIE 5 : GÉNÉRATION DU RAPPORT MARKDOWN
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📝 PARTIE 5: GÉNÉRATION DU RAPPORT"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📝 Génération du rapport markdown..."

python3 << PYTHON_REPORT
import json
import os
from datetime import datetime

report_file = "$REPORT_FILE"
output_file = "$TEMP_OUTPUT"
results_file = "$TEMP_RESULTS"

# Lire les résultats parsés
results = {}
if os.path.exists(results_file):
    with open(results_file, 'r', encoding='utf-8') as f:
        results = json.load(f)

# Lire la sortie complète
with open(output_file, 'r', encoding='utf-8') as f:
    output = f.read()

# Générer le rapport markdown
report_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
script_name = os.path.basename("$PYTHON_SCRIPT")

report = f"""# 🔄 Démonstration : [Nom de la Fonctionnalité]

**Date** : {report_date}
**Script** : {script_name}
**Objectif** : [Description de l'objectif]

---

## 📋 Table des Matières

1. [Contexte et Objectif](#contexte-et-objectif)
2. [Stratégie](#stratégie)
3. [Schéma Nécessaire](#schéma-nécessaire)
4. [Étapes de Démonstration](#étapes-de-démonstration)
5. [Résultats](#résultats)
6. [Validations](#validations)
7. [Conclusion](#conclusion)

---

## 📚 Contexte et Objectif

### Objectif

[Description détaillée de l'objectif de la démonstration]

### Contexte Métier

[Contexte métier expliquant pourquoi cette fonctionnalité est importante]

---

## 🔧 Stratégie

### Approche

[Description de la stratégie utilisée]

### Points Clés

- [Point clé 1]
- [Point clé 2]
- [Point clé 3]

---

## 📐 Schéma Nécessaire

### Colonnes Requises

| Colonne | Type | Description |
|--------|------|-------------|
| [colonne1] | [type] | [description] |
| [colonne2] | [type] | [description] |
| [colonne3] | [type] | [description] |

### Index Nécessaires

[Description des index nécessaires, si applicable]

---

## 🔄 Étapes de Démonstration

Le script Python exécute {results.get('summary', {}).get('total_steps', 0)} étapes de démonstration :

"""

# Ajouter les étapes
for i, step in enumerate(results.get("steps", []), 1):
    report += f"""
### Étape {step['number']} : {step['description']}

[Description détaillée de l'étape]

**Résultat attendu** : [Description]

**Résultat obtenu** : [Vérifier dans la sortie]

"""

# Ajouter les requêtes CQL si détectées
if results.get("queries"):
    report += """
---

## 📝 Requêtes CQL Exécutées

"""
    for i, query in enumerate(results.get("queries", []), 1):
        report += f"""
### Requête {i}

```cql
{query}
```

"""

# Ajouter les validations

report += """
---

## ✅ Validations

"""
for i, validation in enumerate(results.get("validations", []), 1):
    report += f"""
{i}. ✅ {validation}
"""

# Ajouter la conclusion

report += """
---

## 📊 Résumé

### Statistiques

- **Étapes exécutées** : """ + str(results.get('summary', {}).get('total_steps', 0)) + """
- **Validations réussies** : """ + str(results.get('summary', {}).get('total_validations', 0)) + """
- **Requêtes CQL** : """ + str(results.get('summary', {}).get('total_queries', 0)) + """

### Points Clés Démontrés

- ✅ [Point clé 1]
- ✅ [Point clé 2]
- ✅ [Point clé 3]

---

## 💡 Conclusion

[Conclusion de la démonstration]

### Prochaines Étapes

- [Prochaine étape 1]
- [Prochaine étape 2]

---

**✅ Démonstration terminée avec succès !**
"""

# Écrire le rapport

with open(report_file, 'w', encoding='utf-8') as f:
    f.write(report)

print(f"✅ Rapport généré : {report_file}")
PYTHON_REPORT

success "Rapport markdown généré : $(basename "$REPORT_FILE")"
echo ""

# ============================================

# PARTIE 6 : RÉSUMÉ ET CONCLUSION

# ============================================

echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 6: RÉSUMÉ ET CONCLUSION"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 Résumé de la démonstration :"
echo ""

# Afficher le résumé depuis les résultats parsés

if [ -f "$TEMP_RESULTS" ]; then
    python3 << PYTHON_SUMMARY
import json

with open("$TEMP_RESULTS", 'r', encoding='utf-8') as f:
    results = json.load(f)

summary = results.get("summary", {})
print(f"   ✅ Étapes exécutées : {summary.get('total_steps', 0)}")
print(f"   ✅ Validations réussies : {summary.get('total_validations', 0)}")
print(f"   ✅ Requêtes CQL : {summary.get('total_queries', 0)}")
PYTHON_SUMMARY
fi

echo ""
info "💡 Points clés démontrés :"
echo "   ✅ [Point clé 1]"
echo "   ✅ [Point clé 2]"
echo "   ✅ [Point clé 3]"
echo ""

info "📝 Documentation générée :"
echo "   📄 $(basename "$REPORT_FILE")"
echo ""

info "📝 Script suivant : [Description du prochain script]"
echo ""

# Nettoyer les fichiers temporaires

rm -f "$TEMP_OUTPUT" "$TEMP_RESULTS"

success "✅ Démonstration terminée !"
echo ""

```

---

## 📋 Checklist pour Appliquer le Template 65

- [ ] Remplacer `XX` par le numéro du script
- [ ] Remplacer `[Nom]` par le nom de la fonctionnalité
- [ ] Remplacer `[module]` et `[script]` par le chemin du script Python
- [ ] Adapter les vérifications (PARTIE 0)
- [ ] Adapter l'objectif et stratégie (PARTIE 1)
- [ ] Adapter la vérification schéma (PARTIE 2)
- [ ] Adapter l'appel au script Python (PARTIE 3)
- [ ] Créer le parsing des résultats (PARTIE 4) - **CRITIQUE** : Adapter selon la sortie du script Python
- [ ] Adapter la génération du rapport (PARTIE 5)
- [ ] Adapter le résumé et conclusion (PARTIE 6)
- [ ] Tester l'exécution complète
- [ ] Vérifier la génération du rapport markdown

---

## 💡 Exemples d'Utilisation

### Script 26 : Test Multi-Version avec Time Travel

**Adaptations spécifiques** :
- PARTIE 1 : Objectif = Démontrer la logique multi-version garantissant aucune perte de mise à jour client
- PARTIE 2 : Vérification des colonnes `cat_auto`, `cat_user`, `cat_date_user`, `cat_validee`
- PARTIE 4 : Parser les 10 étapes de démonstration du script Python
- PARTIE 5 : Générer un rapport avec toutes les étapes et les validations

**Patterns de parsing à adapter** :
- Chercher les lignes avec `📌 Étape X:`
- Chercher les validations avec `✅`
- Chercher les requêtes CQL dans les blocs de code
- Extraire les dates et catégories pour le time travel

---

## ⚠️ Points d'Attention

### Parsing de la Sortie Python

Le parsing de la sortie Python (PARTIE 4) est **CRITIQUE** et doit être adapté selon :
- Le format de sortie du script Python
- Les marqueurs utilisés (ex: `📌`, `✅`, `❌`)
- La structure des messages
- Les requêtes CQL affichées (si applicable)

**Recommandation** : Modifier le script Python pour qu'il génère aussi un fichier JSON avec les résultats structurés, ce qui facilitera le parsing.

### Capture de la Sortie

La capture de la sortie utilise `tee` pour :
- Afficher en temps réel dans le terminal
- Sauvegarder dans un fichier temporaire pour parsing

### Génération du Rapport

Le rapport markdown est généré automatiquement mais doit être adapté selon :
- Le nombre d'étapes
- Le type de validations
- Les requêtes CQL (si applicable)
- Les résultats spécifiques à la démonstration

---

## 🔄 Améliorations Possibles

1. **Modifier le script Python** pour qu'il génère un fichier JSON avec les résultats structurés
2. **Ajouter des options** pour contrôler le niveau de détail (verbose, quiet)
3. **Ajouter des tests** pour valider chaque étape individuellement
4. **Ajouter des métriques** de performance (temps d'exécution, etc.)

---

**✅ Template 65 créé - Prêt pour utilisation !**
