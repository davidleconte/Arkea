# 📋 Template : Script Shell Didactique pour Démonstration Requêtes CQL

**Date** : 2025-11-27  
**Objectif** : Template réutilisable pour créer des scripts de démonstration de requêtes CQL très didactiques  
**Type** : Scripts qui exécutent plusieurs requêtes CQL directement via `cqlsh` pour démontrer des fonctionnalités spécifiques

---

## 🎯 Principes du Template pour Démonstration Requêtes CQL

Un script de démonstration de requêtes CQL didactique doit :

1. **Afficher les équivalences HBase → HCD** : Montrer comment chaque concept HBase est mappé en CQL
2. **Afficher les requêtes CQL complètes** : Code CQL détaillé avant exécution pour chaque requête
3. **Afficher les résultats attendus** : Ce qu'on s'attend à trouver pour chaque requête
4. **Mesurer les performances** : Temps d'exécution, nombre de lignes, plan d'exécution
5. **Afficher les résultats obtenus** : Ce qui a été obtenu avec formatage
6. **Expliquer la valeur ajoutée SAI** : Comment les index SAI améliorent les performances
7. **Comparer avec/sans SAI** : Démonstration de l'amélioration de performance
8. **Générer un rapport** : Documentation structurée pour livrable avec toutes les requêtes

---

## 📝 Structure Standard pour Script Démonstration Requêtes CQL

```bash
#!/bin/bash
# ============================================
# Script XX : Démonstration Requêtes [Nom] (Version Didactique)
# Démontre [fonctionnalité] via requêtes CQL directes
# Équivalent HBase: [concept HBase]
# ============================================
#
# OBJECTIF :
#   Ce script démontre [fonctionnalité] en exécutant [nombre] requêtes CQL
#   directement via cqlsh.
#  
#   Cette version didactique affiche :
#   - Les équivalences HBase → HCD détaillées
#   - Les requêtes CQL complètes avant exécution
#   - Les résultats attendus pour chaque requête
#   - Les résultats obtenus avec mesure de performance
#   - La valeur ajoutée SAI (si applicable)
#   - Une documentation structurée pour livrable
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh)
#   - Schéma configuré (./10_setup_domirama2_poc.sh)
#   - Données chargées (./11_load_domirama2_data_parquet.sh)
#   - Java 11 configuré via jenv
#
# UTILISATION :
#   ./XX_demo_requetes.sh [paramètres optionnels]
#
# SORTIE :
#   - Requêtes CQL affichées avec explications
#   - Résultats de chaque requête
#   - Mesures de performance
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
INSTALL_DIR="/Users/david.leconte/Documents/Arkea"
HCD_DIR="${INSTALL_DIR}/binaire/hcd-1.2.3"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPORT_FILE="${SCRIPT_DIR}/doc/demonstrations/XX_REQUETES_DEMONSTRATION.md"

# Créer le répertoire de documentation
mkdir -p "$(dirname "$REPORT_FILE")"

# Fichiers temporaires pour capture
TEMP_OUTPUT=$(mktemp "/tmp/script_XX_output_$(date +%s).txt")
TEMP_RESULTS=$(mktemp "/tmp/script_XX_results_$(date +%s).json")

# Tableau pour stocker les résultats de chaque requête
declare -a QUERY_RESULTS

# Configuration cqlsh
CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
CQLSH="$CQLSH_BIN localhost 9042"

# ============================================
# PARTIE 0: VÉRIFICATIONS
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 0: VÉRIFICATIONS"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Vérification que HCD est démarré..."
if ! nc -z localhost 9042 2>/dev/null; then
    error "HCD n'est pas démarré sur localhost:9042"
    error "Exécutez d'abord: ./scripts/setup/03_start_hcd.sh"
    exit 1
fi
success "HCD est démarré"

info "Vérification que cqlsh est disponible..."
if [ ! -f "$CQLSH_BIN" ]; then
    error "cqlsh non trouvé : $CQLSH_BIN"
    exit 1
fi
success "cqlsh trouvé : $CQLSH_BIN"

info "Vérification du schéma..."
# Vérifier que le keyspace existe
if ! $CQLSH -e "DESCRIBE KEYSPACE domirama2_poc;" > /dev/null 2>&1; then
    error "Keyspace domirama2_poc non trouvé"
    error "Exécutez d'abord: ./10_setup_domirama2_poc.sh"
    exit 1
fi
success "Schéma vérifié : keyspace domirama2_poc existe"

# ============================================
# PARTIE 1: CONTEXTE ET STRATÉGIE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📚 PARTIE 1: CONTEXTE ET STRATÉGIE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📚 OBJECTIF : Démontrer [fonctionnalité] via requêtes CQL"
echo ""
info "🔄 ÉQUIVALENCES HBase → HCD :"
echo ""
echo "   HBase                          →  HCD (CQL)"
echo "   ──────────────────────────────    ─────────────────────────────"
echo "   [Concept HBase 1]              →  [Équivalent CQL 1]"
echo "   [Concept HBase 2]              →  [Équivalent CQL 2]"
echo "   [Concept HBase 3]              →  [Équivalent CQL 3]"
echo ""
info "💡 VALEUR AJOUTÉE SAI :"
code "   ✅ Index sur [colonne 1] pour performance optimale"
code "   ✅ Index sur [colonne 2] pour recherche [type]"
code "   ✅ Combinaison d'index pour recherche optimisée"
code "   ✅ Pas de scan complet nécessaire"
echo ""
info "📋 STRATÉGIE DE DÉMONSTRATION :"
code "   - [Nombre] requêtes CQL pour démontrer [fonctionnalité]"
code "   - Mesure de performance pour chaque requête"
code "   - Comparaison avec/sans SAI (si applicable)"
code "   - Documentation structurée pour livrable"
echo ""

# ============================================
# PARTIE 2: REQUÊTES CQL
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  🔍 PARTIE 2: REQUÊTES CQL"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# Fonction : Exécuter une Requête CQL avec Mesure de Performance
# ============================================

execute_query() {
    local query_num=$1
    local query_title="$2"
    local query_description="$3"
    local hbase_equivalent="$4"
    local query_cql="$5"
    local expected_result="$6"
    local sai_value="$7"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔍 REQUÊTE $query_num : $query_title"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    info "📚 DÉFINITION - $query_title :"
    echo "   $query_description"
    echo ""

    info "🔄 ÉQUIVALENT HBase :"
    code "   $hbase_equivalent"
    echo ""

    info "📝 Requête CQL :"
    echo "$query_cql" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            code "$line"
        fi
    done
    echo ""

    if [ -n "$sai_value" ]; then
        info "💡 VALEUR AJOUTÉE SAI :"
        echo "   $sai_value" | sed 's/^/   /'
        echo ""
    fi

    expected "📋 Résultat attendu : $expected_result"
    echo ""

    # Créer un fichier temporaire pour la requête
    TEMP_QUERY_FILE=$(mktemp "/tmp/query_${query_num}_$(date +%s).cql")
    cat > "$TEMP_QUERY_FILE" <<EOF
USE domirama2_poc;
TRACING ON;
$query_cql
EOF

    # Exécuter la requête et mesurer le temps
    info "🚀 Exécution de la requête..."
    START_TIME=$(date +%s.%N)
    QUERY_OUTPUT=$($CQLSH -f "$TEMP_QUERY_FILE" 2>&1 | tee -a "$TEMP_OUTPUT")
    EXIT_CODE=$?
    END_TIME=$(date +%s.%N)

    # Calculer le temps d'exécution (compatible macOS)
    if command -v bc >/dev/null 2>&1; then
        QUERY_TIME=$(echo "$END_TIME - $START_TIME" | bc 2>/dev/null || echo "0.000")
    else
        QUERY_TIME=$(python3 -c "print($END_TIME - $START_TIME)" 2>/dev/null || echo "0.000")
    fi

    # Extraire les métriques du tracing
    COORDINATOR_TIME=$(echo "$QUERY_OUTPUT" | grep "coordinator" | awk -F'|' '{print $4}' | tr -d ' ' | head -1 || echo "")
    TOTAL_TIME=$(echo "$QUERY_OUTPUT" | grep "total" | awk -F'|' '{print $4}' | tr -d ' ' | head -1 || echo "")

    # Compter les lignes retournées
    ROW_COUNT=$(echo "$QUERY_OUTPUT" | grep -E "^[A-Z_]+ \|" | grep -v "^code_si " | wc -l | tr -d ' ')
    if [ "$ROW_COUNT" -eq 0 ] || [ -z "$ROW_COUNT" ]; then
        ROW_COUNT=$(echo "$QUERY_OUTPUT" | grep -E "\([0-9]+ rows\)" | grep -oE "[0-9]+" | head -1 || echo "0")
    fi

    # Extraire le plan d'exécution
    EXECUTION_PLAN=$(echo "$QUERY_OUTPUT" | grep -E "(Executing|single-partition|Read|Scanned|Merging)" | head -3 | tr '\n' '; ' || echo "")

    # Filtrer les résultats pour affichage (sans tracing)
    QUERY_RESULTS_FILTERED=$(echo "$QUERY_OUTPUT" | grep -vE "^Warnings|^$|^\([0-9]+ rows\)|coordinator|total|Executing|Read|Scanned|Merging" | head -20)

    # Afficher les résultats
    if [ $EXIT_CODE -eq 0 ]; then
        result "📊 Résultats obtenus ($ROW_COUNT ligne(s)) en ${QUERY_TIME}s :"
        echo ""
        echo "$QUERY_RESULTS_FILTERED" | head -15
        if [ "$ROW_COUNT" -gt 15 ]; then
            echo "... (affichage limité à 15 lignes)"
        fi
        echo ""

        if [ -n "$COORDINATOR_TIME" ] && [ "$COORDINATOR_TIME" != "" ]; then
            info "   ⏱️  Temps coordinateur : ${COORDINATOR_TIME}μs"
        fi
        if [ -n "$TOTAL_TIME" ] && [ "$TOTAL_TIME" != "" ]; then
            info "   ⏱️  Temps total : ${TOTAL_TIME}μs"
        fi
        if [ -n "$EXECUTION_PLAN" ]; then
            info "   📋 Plan d'exécution : $EXECUTION_PLAN"
        fi

        success "✅ Requête $query_num exécutée avec succès"

        # Stocker les résultats pour le rapport
        QUERY_RESULTS+=("$query_num|$query_title|$ROW_COUNT|$QUERY_TIME|$COORDINATOR_TIME|$TOTAL_TIME|$EXIT_CODE|OK")
    else
        error "❌ Erreur lors de l'exécution de la requête $query_num"
        echo "$QUERY_OUTPUT" | tail -10
        QUERY_RESULTS+=("$query_num|$query_title|0|$QUERY_TIME|||$EXIT_CODE|ERROR")
    fi

    # Nettoyer
    rm -f "$TEMP_QUERY_FILE"
    echo ""
}

# ============================================
# REQUÊTE 1 : [Titre]
# ============================================

execute_query \
    1 \
    "[Titre Requête 1]" \
    "[Description détaillée de ce que démontre cette requête]" \
    "[Équivalent HBase : SCAN avec ...]" \
    "SELECT code_si, contrat, date_op, numero_op, libelle, montant
FROM operations_by_account
WHERE code_si = 'DEMO_MV' AND contrat = 'DEMO_001'
  AND date_op >= '2024-01-01' AND date_op < '2024-02-01'
ORDER BY date_op DESC, numero_op ASC
LIMIT 10;" \
    "[Description du résultat attendu]" \
    "[Explication de la valeur ajoutée SAI pour cette requête]"

# ============================================
# REQUÊTE 2 : [Titre]
# ============================================

execute_query \
    2 \
    "[Titre Requête 2]" \
    "[Description détaillée]" \
    "[Équivalent HBase]" \
    "SELECT ... FROM ... WHERE ...;" \
    "[Résultat attendu]" \
    "[Valeur ajoutée SAI]"

# Répéter pour chaque requête...

# ============================================
# PARTIE 3: COMPARAISON PERFORMANCE
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📊 PARTIE 3: COMPARAISON PERFORMANCE"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "📊 Comparaison Performance : Avec vs Sans SAI"
echo ""
code "Sans SAI (HBase) :"
code "  - SCAN complet de la partition"
code "  - Filtrage côté client"
code "  - Performance : O(n) où n = nombre d'opérations"
echo ""
code "Avec SAI (HCD) :"
code "  - Index sur [colonne] (clustering key)"
code "  - Index sur [colonne] (full-text SAI)"
code "  - Performance : O(log n) avec index"
code "  - Valeur ajoutée : Recherche combinée optimisée"
echo ""

# ============================================
# PARTIE 4: GÉNÉRATION RAPPORT
# ============================================
echo ""
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
section "  📄 PARTIE 4: GÉNÉRATION RAPPORT"
section "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Génération du rapport markdown structuré..."

python3 << EOF
import json
import sys
from datetime import datetime

# Lire les résultats depuis le fichier temporaire
results = []
for result in """${QUERY_RESULTS[@]}""".split():
    if result:
        parts = result.split('|')
        if len(parts) >= 8:
            results.append({
                'num': parts[0],
                'title': parts[1],
                'rows': parts[2],
                'time': parts[3],
                'coord_time': parts[4] if parts[4] else '',
                'total_time': parts[5] if parts[5] else '',
                'exit_code': parts[6],
                'status': parts[7]
            })

# Générer le rapport markdown
report = f"""# 🔍 Démonstration : Requêtes [Nom]

**Date** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Script** : XX_demo_requetes.sh
**Objectif** : Démontrer [fonctionnalité] via requêtes CQL

---

## 📋 Table des Matières

1. [Contexte et Stratégie](#contexte-et-stratégie)
2. [Requêtes Exécutées](#requêtes-exécutées)
3. [Résultats par Requête](#résultats-par-requête)
4. [Comparaison Performance](#comparaison-performance)
5. [Conclusion](#conclusion)

---

## 📚 Contexte et Stratégie

### Équivalences HBase → HCD

| Concept HBase | Équivalent HCD (CQL) |
|---------------|----------------------|
| [Concept 1] | [Équivalent 1] |
| [Concept 2] | [Équivalent 2] |
| [Concept 3] | [Équivalent 3] |

### Valeur Ajoutée SAI

- ✅ Index sur [colonne 1] pour performance optimale
- ✅ Index sur [colonne 2] pour recherche [type]
- ✅ Combinaison d'index pour recherche optimisée
- ✅ Pas de scan complet nécessaire

---

## 🔍 Requêtes Exécutées

### Tableau Récapitulatif

| Requête | Titre | Lignes | Temps (s) | Coordinateur (μs) | Total (μs) | Statut |
|---------|-------|--------|-----------|-------------------|-----------|--------|
"""

for r in results:
    report += f"| {r['num']} | {r['title']} | {r['rows']} | {r['time']} | {r['coord_time']} | {r['total_time']} | {'✅ OK' if r['status'] == 'OK' else '❌ ERROR'} |\n"

report += """
---

## 📊 Résultats par Requête

"""

for r in results:
    report += f"""### Requête {r['num']} : {r['title']}

- **Lignes retournées** : {r['rows']}
- **Temps d'exécution** : {r['time']}s
"""
    if r['coord_time']:
        report += f"- **Temps coordinateur** : {r['coord_time']}μs\n"
    if r['total_time']:
        report += f"- **Temps total** : {r['total_time']}μs\n"
    report += f"- **Statut** : {'✅ OK' if r['status'] == 'OK' else '❌ ERROR'}\n\n"

report += """---

## 📊 Comparaison Performance

### Sans SAI (HBase)

- SCAN complet de la partition
- Filtrage côté client
- Performance : O(n) où n = nombre d'opérations

### Avec SAI (HCD)

- Index sur [colonne] (clustering key)
- Index sur [colonne] (full-text SAI)
- Performance : O(log n) avec index
- Valeur ajoutée : Recherche combinée optimisée

---

## ✅ Conclusion

### Points Clés Démontrés

- ✅ [Point 1]
- ✅ [Point 2]
- ✅ [Point 3]

### Valeur Ajoutée SAI

Les index SAI apportent une amélioration significative des performances pour les requêtes avec filtres sur les colonnes indexées.

---

**Date de génération** : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""

# Écrire le rapport
with open('${REPORT_FILE}', 'w', encoding='utf-8') as f:
    f.write(report)

print(f"✅ Rapport généré : {REPORT_FILE}")
EOF

success "✅ Rapport markdown généré : $REPORT_FILE"

# Nettoyer
rm -f "$TEMP_OUTPUT" "$TEMP_RESULTS"

echo ""
success "✅ Démonstration requêtes terminée"
info ""
info "💡 Points clés démontrés :"
code "  ✅ [Point 1]"
code "  ✅ [Point 2]"
code "  ✅ [Point 3]"
code "  ✅ Valeur ajoutée SAI : [Description]"
code "  ✅ Performance optimisée vs scan complet"
echo ""
```

---

## 🔄 Différences avec les Autres Templates

| Aspect | Template 43 | Template 63 | Template 65 | **Template 68** |
|--------|-------------|-------------|-------------|-----------------|
| **Type** | Générique | Orchestration | Délégation Python | **Requêtes CQL** |
| **Méthode** | Spark/Python | Appels scripts | Python | **cqlsh direct** |
| **Nombre requêtes** | 1 | N scripts | 1 | **N requêtes CQL** |
| **Mesure performance** | ⚠️ Optionnelle | ❌ Non | ⚠️ Optionnelle | **✅ Obligatoire** |
| **Valeur ajoutée SAI** | ⚠️ Optionnelle | ❌ Non | ❌ Non | **✅ Obligatoire** |
| **Équivalences HBase** | ⚠️ Optionnelles | ❌ Non | ❌ Non | **✅ Obligatoires** |
| **Tracing CQL** | ❌ Non | ❌ Non | ❌ Non | **✅ Oui** |

---

## 📝 Exemple d'Utilisation

### Script 29 : Fenêtre Glissante

Le script 29 peut être refactorisé en utilisant ce template pour :

1. **Requête 1** : Requête mensuelle (fenêtre glissante)
2. **Requête 2** : Requête 30 derniers jours
3. **Requête 3** : Requête avec SAI (date + full-text)

Chaque requête suivra la structure `execute_query()` avec :

- Titre et description
- Équivalent HBase
- Code CQL complet
- Résultat attendu
- Valeur ajoutée SAI
- Mesure de performance
- Résultats obtenus

---

## ✅ Checklist pour Appliquer le Template

- [ ] Remplacer `[fonctionnalité]` par la fonctionnalité démontrée
- [ ] Remplacer `[concept HBase]` par les concepts HBase équivalents
- [ ] Définir les équivalences HBase → HCD
- [ ] Créer les fonctions `execute_query()` pour chaque requête
- [ ] Définir les résultats attendus pour chaque requête
- [ ] Expliquer la valeur ajoutée SAI pour chaque requête
- [ ] Ajouter la comparaison performance avec/sans SAI
- [ ] Tester la génération du rapport markdown
- [ ] Vérifier que toutes les métriques sont capturées

---

**Date de création** : 2025-11-27  
**Version** : 1.0
