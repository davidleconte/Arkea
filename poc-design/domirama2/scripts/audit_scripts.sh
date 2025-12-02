#!/bin/bash
# Script d'audit automatique des scripts shell
# Génère un rapport d'audit complet

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_FILE="${SCRIPT_DIR}/../doc/audits/AUDIT_SCRIPTS_SHELL_2025_V2.md"

echo "🔍 Audit des scripts shell..."
echo ""

# Statistiques
TOTAL=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*.sh" | wc -l | tr -d ' ')
NUMEROTES=$(find "$SCRIPT_DIR" -maxdepth 1 -name "[0-9]*.sh" | wc -l | tr -d ' ')
DIDACTIQUES=$(find "$SCRIPT_DIR" -maxdepth 1 -name "*_v2_didactique*.sh" | wc -l | tr -d ' ')

# Standards
SET_EOU_PIPEFAIL=$(grep -l "set -euo pipefail" "$SCRIPT_DIR"/*.sh 2>/dev/null | wc -l | tr -d ' ')
SETUP_PATHS=$(grep -l "setup_paths" "$SCRIPT_DIR"/*.sh 2>/dev/null | wc -l | tr -d ' ')
LOCALHOST_HARDCODE=$(grep -l "localhost" "$SCRIPT_DIR"/*.sh 2>/dev/null | grep -v "HCD_HOST" | wc -l | tr -d ' ')
CHEMINS_HARDCODE=$(grep -l "/Users/david\|/home/\|/opt/" "$SCRIPT_DIR"/*.sh 2>/dev/null | wc -l | tr -d ' ')

# Générer le rapport
cat > "$REPORT_FILE" << EOF
# 🔍 Audit Complet : Scripts Shell - domirama2/scripts/

**Date** : $(date +%Y-%m-%d)  
**Objectif** : Audit exhaustif de tous les scripts shell dans \`scripts/\`  
**Total Scripts** : $TOTAL scripts

---

## 📊 Vue d'Ensemble

### Statistiques

| Catégorie | Nombre | Statut |
|-----------|--------|--------|
| **Total scripts** | $TOTAL | ✅ |
| **Scripts numérotés** | $NUMEROTES | ✅ |
| **Versions didactiques** | $DIDACTIQUES | ✅ |

### Standards

| Standard | Nombre | Pourcentage | Statut |
|----------|--------|-------------|--------|
| **set -euo pipefail** | $SET_EOU_PIPEFAIL | $(echo "scale=0; $SET_EOU_PIPEFAIL * 100 / $TOTAL" | bc)% | ⚠️ |
| **setup_paths()** | $SETUP_PATHS | $(echo "scale=0; $SETUP_PATHS * 100 / $TOTAL" | bc)% | ⚠️ |
| **localhost hardcodé** | $LOCALHOST_HARDCODE | $(echo "scale=0; $LOCALHOST_HARDCODE * 100 / $TOTAL" | bc)% | ❌ |
| **Chemins hardcodés** | $CHEMINS_HARDCODE | $(echo "scale=0; $CHEMINS_HARDCODE * 100 / $TOTAL" | bc)% | ❌ |

---

## 📋 Analyse Détaillée par Script

EOF

# Analyser chaque script
for script in "$SCRIPT_DIR"/*.sh; do
    if [ -f "$script" ]; then
        basename_script=$(basename "$script")
        echo "### $basename_script" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        # Shebang
        shebang=$(head -1 "$script" | grep -oE '#!/.*' || echo "MANQUANT")
        echo "- **Shebang** : \`$shebang\`" >> "$REPORT_FILE"
        
        # set -euo pipefail
        if grep -q "set -euo pipefail" "$script"; then
            echo "- **set -euo pipefail** : ✅ OUI" >> "$REPORT_FILE"
        else
            echo "- **set -euo pipefail** : ❌ NON" >> "$REPORT_FILE"
        fi
        
        # setup_paths
        if grep -q "setup_paths" "$script"; then
            echo "- **setup_paths()** : ✅ OUI" >> "$REPORT_FILE"
        else
            echo "- **setup_paths()** : ❌ NON" >> "$REPORT_FILE"
        fi
        
        # localhost hardcodé
        if grep -q "localhost" "$script" && ! grep -q "HCD_HOST" "$script"; then
            echo "- **localhost hardcodé** : ⚠️ OUI" >> "$REPORT_FILE"
        else
            echo "- **localhost hardcodé** : ✅ NON" >> "$REPORT_FILE"
        fi
        
        # Chemins hardcodés
        if grep -q "/Users/david\|/home/\|/opt/" "$script"; then
            echo "- **Chemins hardcodés** : ⚠️ OUI" >> "$REPORT_FILE"
        else
            echo "- **Chemins hardcodés** : ✅ NON" >> "$REPORT_FILE"
        fi
        
        echo "" >> "$REPORT_FILE"
    fi
done

echo "✅ Rapport généré : $REPORT_FILE"

