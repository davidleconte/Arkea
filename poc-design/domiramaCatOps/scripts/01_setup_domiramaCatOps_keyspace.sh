#!/bin/bash
# ============================================
# Script 01 : Configuration du Keyspace DomiramaCatOps (Version Didactique)
# Crée le keyspace domiramacatops_poc
# ============================================
#
# OBJECTIF :
#   Ce script initialise le keyspace 'domiramacatops_poc' pour le POC
#   de catégorisation des opérations.
#
# PRÉREQUIS :
#   - HCD 1.2.3 doit être démarré (exécuter: ./03_start_hcd.sh depuis la racine)
#   - Java 11 configuré via jenv (jenv local 11)
#   - HCD accessible sur localhost:9042
#
# UTILISATION :
#   ./01_setup_domiramaCatOps_keyspace.sh
#
# SORTIE :
#   - DDL complet affiché avec explications
#   - Vérifications détaillées (keyspace)
#   - Documentation structurée générée (doc/demonstrations/01_SETUP_KEYSPACE_DEMONSTRATION.md)
#
# ============================================

set -e

# ============================================
# SOURCE DES FONCTIONS UTILITAIRES
# ============================================
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -f "${SCRIPT_DIR}/../utils/didactique_functions.sh" ]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/../utils/didactique_functions.sh"
else
    # Fallback si les fonctions ne sont pas disponibles
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    CYAN=$'\033[0;36m'
    MAGENTA=$'\033[0;35m'
    BOLD=$'\033[1m'
    NC=$'\033[0m'
    info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
    success() { echo -e "${GREEN}✅ $1${NC}"; }
    warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
    error() { echo -e "${RED}❌ $1${NC}"; }
    demo() { echo -e "${CYAN}🎯 $1${NC}"; }
    code() { echo -e "${MAGENTA}📝 $1${NC}"; }
    section() { echo -e "${BOLD}${CYAN}$1${NC}"; }
    result() { echo -e "${GREEN}📊 $1${NC}"; }
    expected() { echo -e "${YELLOW}📋 $1${NC}"; }
fi

# ============================================
# CONFIGURATION
# ============================================
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
REPORT_FILE="${SCRIPT_DIR}/../doc/demonstrations/01_SETUP_KEYSPACE_DEMONSTRATION.md"

# Charger l'environnement POC (HCD déjà installé sur MBP)
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    # shellcheck source=/dev/null
    source "${INSTALL_DIR}/.poc-profile"
fi

# HCD_HOME devrait être défini par .poc-profile
HCD_DIR="${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# ============================================
# VÉRIFICATIONS
# ============================================
cd "$HCD_DIR"

# Définit Java 11 via jenv si disponible — ne doit pas échouer si jenv manquant
if command -v jenv >/dev/null 2>&1; then
    jenv local 11 || true
    eval "$(jenv init -)"
fi

info "🔍 Vérification que HCD est prêt..."
if ! "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" localhost 9042 -e 'SELECT cluster_name FROM system.local;' > /dev/null 2>&1; then
    error "HCD n'est pas prêt. Attendez quelques secondes et réessayez."
    exit 1
fi

# ============================================
# EN-TÊTE DE DÉMONSTRATION
# ============================================
if type show_demo_header >/dev/null 2>&1; then
    show_demo_header "Configuration du Keyspace DomiramaCatOps"
else
    section "DÉMARRAGE : Configuration du Keyspace DomiramaCatOps"
fi

# ============================================
# PARTIE 1: CONTEXTE HBase → HCD
# ============================================
if type show_partie >/dev/null 2>&1; then
    show_partie "1" "CONTEXTE - Migration HBase → HCD"
else
    section "1 - CONTEXTE - Migration HBase → HCD"
fi

info "📚 ÉQUIVALENCES HBase → HCD :"
echo ""
echo "   HBase :"
echo "      - Namespace : B997X04"
echo "      - Table : domirama (Column Family category)"
echo "      - Table : domirama-meta-categories (7 KeySpaces logiques)"
echo ""
echo "   HCD :"
echo "      - Keyspace : domiramacatops_poc (nouveau keyspace dédié)"
echo "      - Table : operations_by_account (depuis domirama.category)"
echo "      - Tables : 7 tables meta-categories (explosion de domirama-meta-categories)"
echo ""
echo "   Justification du nouveau keyspace :"
echo "      ✅ Séparation claire des responsabilités"
echo "      ✅ Pas de couplage avec domirama2_poc"
echo "      ✅ Conformité aux bonnes pratiques HCD (un keyspace par domaine métier)"
echo ""

# ============================================
# PARTIE 2: DDL - Keyspace
# ============================================
if type show_partie >/dev/null 2>&1; then
    show_partie "2" "DDL - CRÉATION DU KEYSPACE"
else
    section "2 - DDL - CRÉATION DU KEYSPACE"
fi

expected "📋 Résultat attendu :"
echo "   Keyspace domiramacatops_poc créé avec SimpleStrategy (POC)"
echo "   ou NetworkTopologyStrategy (production)"
echo ""

info "📝 DDL - Création du Keyspace :"
echo ""
code "CREATE KEYSPACE IF NOT EXISTS domiramacatops_poc"
code "WITH REPLICATION = {"
code "  'class': 'SimpleStrategy',"
code "  'replication_factor': 1"
code "};"
echo ""

info "🚀 Exécution du DDL..."
read -r -d '' KEYSpace_DDL <<'EOF' || true
CREATE KEYSPACE IF NOT EXISTS domiramacatops_poc
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};
EOF

# Exécute le DDL et filtre les warnings
"${HCD_HOME:-$HCD_DIR}/bin/cqlsh" localhost 9042 -e "$KEYSpace_DDL" 2>&1 | grep -v 'Warnings' || true

sleep 2

# Vérification
info "🔍 Vérification de la création du keyspace..."
KEYSpace_CHECK=$(
  "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" localhost 9042 -e 'DESCRIBE KEYSPACE domiramacatops_poc;' 2>&1 \
  | grep -v 'Warnings' \
  | head -20
)

if echo "$KEYSpace_CHECK" | grep -q 'domiramacatops_poc'; then
    success "✅ Keyspace domiramacatops_poc créé"
    echo ""
    result "📊 Détails du keyspace :"
    echo "   ┌─────────────────────────────────────────────────────────┐"
    echo "$KEYSpace_CHECK" | sed 's/^/   │ /'
    echo "   └─────────────────────────────────────────────────────────┘"
else
    error "❌ Échec de la création du keyspace"
    exit 1
fi
echo ""

# ============================================
# PARTIE 3: VÉRIFICATIONS COMPLÈTES
# ============================================
if type show_partie >/dev/null 2>&1; then
    show_partie "3" "VÉRIFICATIONS COMPLÈTES"
else
    section "3 - VÉRIFICATIONS COMPLÈTES"
fi

if type check_hcd_status >/dev/null 2>&1; then
    check_hcd_status
fi

if type check_jenv_java_version >/dev/null 2>&1; then
    check_jenv_java_version
fi

info "🔍 Vérification complète du keyspace..."
echo ""

# Vérification 1: Keyspace existe
expected "📋 Vérification 1 : Keyspace"
echo "   Attendu : Keyspace domiramacatops_poc existe"
KEYSpace_EXISTS=$(
  "${HCD_HOME:-$HCD_DIR}/bin/cqlsh" localhost 9042 -e "SELECT keyspace_name FROM system_schema.keyspaces WHERE keyspace_name = 'domiramacatops_poc';" 2>&1 \
  | grep -v 'Warnings' \
  | grep -c 'domiramacatops_poc' || echo '0'
)

if [ "${KEYSpace_EXISTS}" -gt 0 ]; then
    success "✅ Keyspace domiramacatops_poc existe"
else
    error "❌ Keyspace domiramacatops_poc n'existe pas"
    exit 1
fi
echo ""

# ============================================
# PARTIE 4: RÉSUMÉ ET CONCLUSION
# ============================================
if type show_partie >/dev/null 2>&1; then
    show_partie "4" "RÉSUMÉ ET CONCLUSION"
else
    section "4 - RÉSUMÉ ET CONCLUSION"
fi

info "📊 Résumé de la configuration :"
echo ""
echo "   ✅ Keyspace domiramacatops_poc créé"
echo "   ✅ SimpleStrategy configurée (POC local)"
echo "   ✅ replication_factor = 1 (POC local)"
echo ""

info "💡 Équivalences HBase → HCD validées :"
echo ""
echo "   ✅ Namespace B997X04 → Keyspace domiramacatops_poc"
echo ""

info "📝 Prochaines étapes :"
echo ""
echo "   - Script 02: Création de la table operations_by_account"
echo "   - Script 03: Création des tables meta-categories"
echo "   - Script 04: Création des index SAI"
echo ""

success "✅ Configuration du keyspace terminée !"
info "📝 Documentation générée : $REPORT_FILE"
echo ""

# ============================================
# GÉNÉRATION DU RAPPORT
# ============================================
info "📝 Génération du rapport de démonstration..."
REPORT_DATE=$(date +"%Y-%m-%d %H:%M:%S")

python3 <<'PYEOF' > "$REPORT_FILE"
import os
from datetime import datetime

backtick = chr(96)
code_block_start = backtick + backtick + backtick + "cql\n"
code_block_end = "\n" + backtick + backtick + backtick + "\n"

report = ""
report += "# 🏗️ Démonstration : Configuration du Keyspace DomiramaCatOps\n\n"
report += f"**Date** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
report += "**Script** : 01_setup_domiramaCatOps_keyspace.sh\n"
report += "**Objectif** : Démontrer la création du keyspace HCD pour DomiramaCatOps\n\n"
report += "---\n\n"
report += "## 📋 Table des Matières\n\n"
report += "1. [Contexte HBase → HCD](#contexte-hbase--hcd)\n"
report += "2. [DDL - Keyspace](#ddl-keyspace)\n"
report += "3. [Vérifications](#vérifications)\n"
report += "4. [Conclusion](#conclusion)\n\n"
report += "---\n\n"
report += "## 📚 Contexte HBase → HCD\n\n"
report += "### Équivalences\n\n"
report += "| Concept HBase | Équivalent HCD | Statut |\n"
report += "|---------------|----------------|--------|\n"
report += "| Namespace `B997X04` | Keyspace `domiramacatops_poc` | ✅ |\n\n"
report += "### Justification du Nouveau Keyspace\n\n"
report += "✅ **Séparation claire des responsabilités**\n"
report += "✅ **Pas de couplage avec domirama2_poc**\n"
report += "✅ **Conformité aux bonnes pratiques HCD** (un keyspace par domaine métier)\n\n"
report += "---\n\n"
report += "## 📋 DDL - Keyspace\n\n"
report += "### DDL Exécuté\n\n"
report += code_block_start
report += "CREATE KEYSPACE IF NOT EXISTS domiramacatops_poc\n"
report += "WITH REPLICATION = {\n"
report += "  \"class\": \"SimpleStrategy\",\n"
report += "  \"replication_factor\": 1\n"
report += "};\n"
report += code_block_end + "\n"
report += "### Explication\n\n"
report += "- **Keyspace** = Equivalent d un namespace HBase\n"
report += "- **SimpleStrategy** = Pour POC local - 1 noeud\n"
report += "- **NetworkTopologyStrategy** = Pour production (multi-datacenter)\n"
report += "- **replication_factor** = Nombre de copies des données\n\n"
report += "### Vérification\n\n"
report += "✅ Keyspace domiramacatops_poc créé\n\n"
report += "---\n\n"
report += "## 🔍 Vérifications\n\n"
report += "### Résumé des Vérifications\n\n"
report += "| Vérification | Attendu | Obtenu | Statut |\n"
report += "|--------------|---------|--------|--------|\n"
report += "| Keyspace existe | domiramacatops_poc | domiramacatops_poc | ✅ |\n\n"
report += "---\n\n"
report += "## ✅ Conclusion\n\n"
report += "Le keyspace DomiramaCatOps a été créé avec succès :\n\n"
report += "✅ **Keyspace** : domiramacatops_poc\n"
report += "✅ **Stratégie** : SimpleStrategy (POC local)\n"
report += "✅ **Réplication** : replication_factor = 1\n\n"
report += "### Prochaines Étapes\n\n"
report += "- Script 02: Création de la table operations_by_account\n"
report += "- Script 03: Création des tables meta-categories\n"
report += "- Script 04: Création des index SAI\n\n"
report += "---\n\n"
report += "**✅ Configuration terminée avec succès !**\n"

print(report, end="")
PYEOF

success "✅ Rapport généré : $REPORT_FILE"
echo ""
