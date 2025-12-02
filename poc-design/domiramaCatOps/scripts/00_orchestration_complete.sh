#!/bin/bash
# ============================================
# Script d'Orchestration : Exécution Complète POC DomiramaCatOps
# ============================================
#
# OBJECTIF :
#   Ce script orchestre l'exécution complète de tous les scripts du POC
#   DomiramaCatOps dans le bon ordre, avec gestion des erreurs, validation
#   et système de checkpointing pour reprise après échec.
#
# PRÉREQUIS :
#   - HCD démarré (./scripts/setup/03_start_hcd.sh depuis la racine)
#   - Java 11 configuré via jenv (jenv local 11)
#   - Spark 3.5.1 installé et configuré
#   - Variables d'environnement configurées (.poc-profile)
#   - Python 3.8+ avec dépendances installées
#
# UTILISATION :
#   ./00_orchestration_complete.sh [--resume-from PHASE] [--checkpoint-dir DIR]
#
# OPTIONS :
#   --resume-from PHASE    : Reprendre depuis une phase spécifique (1-7)
#   --checkpoint-dir DIR   : Répertoire pour les checkpoints (défaut: .checkpoints)
#
# ============================================

set -euo pipefail

# Configuration - Utiliser setup_paths si disponible
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../utils/didactique_functions.sh" ]; then
    source "$SCRIPT_DIR/../utils/didactique_functions.sh"
    setup_paths
else
    # Fallback si les fonctions ne sont pas disponibles
    INSTALL_DIR="${ARKEA_HOME:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
    HCD_DIR="${HCD_DIR:-${INSTALL_DIR}/binaire/hcd-1.2.3}"
    SPARK_HOME="${SPARK_HOME:-${INSTALL_DIR}/binaire/spark-3.5.1}"
    HCD_HOST="${HCD_HOST:-localhost}"
    HCD_PORT="${HCD_PORT:-9042}"
fi

cd "$SCRIPT_DIR"

# Source des fonctions utilitaires
if [ -f "${SCRIPT_DIR}/../utils/didactique_functions.sh" ]; then
    source "${SCRIPT_DIR}/../utils/didactique_functions.sh"
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
    success() { echo -e "${GREEN}✅ $1${NC}"; }
    error() { echo -e "${RED}❌ $1${NC}"; }
    warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
fi

# Source du profil d'environnement
INSTALL_DIR="${INSTALL_DIR:-/Users/david.leconte/Documents/Arkea}"
if [ -f "${INSTALL_DIR}/.poc-profile" ]; then
    source "${INSTALL_DIR}/.poc-profile"
    # Exporter les variables critiques pour les scripts enfants
    export SPARK_HOME
    export HCD_HOME
    export HCD_DIR
    export INSTALL_DIR
    export JAVA_HOME
fi

# ============================================
# CONFIGURATION CHECKPOINTING
# ============================================
CHECKPOINT_DIR="${SCRIPT_DIR}/.checkpoints"
RESUME_FROM_PHASE=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --resume-from)
            RESUME_FROM_PHASE="$2"
            shift 2
            ;;
        --checkpoint-dir)
            CHECKPOINT_DIR="$2"
            shift 2
            ;;
        *)
            error "Option inconnue : $1"
            echo "Usage: $0 [--resume-from PHASE] [--checkpoint-dir DIR]"
            exit 1
            ;;
    esac
done

mkdir -p "$CHECKPOINT_DIR"
LOG_FILE="${CHECKPOINT_DIR}/orchestration_$(date +%Y%m%d_%H%M%S).log"

# Fonction de logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ============================================
# FONCTIONS UTILITAIRES
# ============================================

# Fonction pour sauvegarder un checkpoint
save_checkpoint() {
    local phase=$1
    local status=$2
    local checkpoint_file="${CHECKPOINT_DIR}/phase_${phase}.checkpoint"

    cat > "$checkpoint_file" << EOF
PHASE=$phase
STATUS=$status
TIMESTAMP=$(date +%Y-%m-%d\ %H:%M:%S)
EOF

    log "✅ Checkpoint Phase $phase sauvegardé : $checkpoint_file"
}

# Fonction pour charger un checkpoint
load_checkpoint() {
    local phase=$1
    local checkpoint_file="${CHECKPOINT_DIR}/phase_${phase}.checkpoint"

    if [ -f "$checkpoint_file" ]; then
        source "$checkpoint_file"
        log "📋 Checkpoint Phase $phase chargé : STATUS=$STATUS, TIMESTAMP=$TIMESTAMP"
        return 0
    else
        return 1
    fi
}

# Fonction pour vérifier si une phase est complète
is_phase_complete() {
    local phase=$1
    if load_checkpoint "$phase"; then
        if [ "$STATUS" = "COMPLETE" ]; then
            return 0
        fi
    fi
    return 1
}

# Fonction pour exécuter un script avec gestion d'erreurs améliorée
execute_script() {
    local script=$1
    local description=$2
    local script_path="${SCRIPT_DIR}/${script}"
    local use_retry=${3:-false}  # Par défaut, pas de retry

    if [ ! -f "$script_path" ]; then
        error "Script non trouvé : $script_path"
        log "❌ ERREUR : Script non trouvé : $script_path"
        return 1
    fi

    # Vérifier que le script est exécutable
    if [ ! -x "$script_path" ]; then
        warn "Script non exécutable, ajout des permissions..."
        chmod +x "$script_path" || {
            error "Impossible de rendre le script exécutable : $script_path"
            return 1
        }
    fi

    info "Exécution : $description"
    log "🚀 Exécution : $description (Script: $script)"
    echo "   Script : $script_path"

    local start_time=$(date +%s)
    local exit_code=0

    # Exécuter le script et capturer le code de sortie
    if bash "$script_path" 2>&1 | tee -a "$LOG_FILE"; then
        exit_code=0
    else
        exit_code=${PIPESTATUS[0]}
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ $exit_code -eq 0 ]; then
        success "$description terminé avec succès (${duration}s)"
        log "✅ SUCCÈS : $description terminé en ${duration}s"
        return 0
    else
        error "$description a échoué (${duration}s, code: $exit_code)"
        log "❌ ÉCHEC : $description échoué en ${duration}s (code: $exit_code)"

        # Diagnostic automatique pour les scripts critiques
        if [ "$use_retry" = "true" ]; then
            diagnose_error "$script" "$exit_code" "$LOG_FILE"
        fi

        return $exit_code
    fi
}

# Fonction pour exécuter plusieurs scripts en parallèle
execute_scripts_parallel() {
    local scripts=("$@")
    local pids=()
    local failed_scripts=()

    for script in "${scripts[@]}"; do
        local script_path="${SCRIPT_DIR}/${script}"
        if [ -f "$script_path" ]; then
            info "Exécution en parallèle : $script"
            log "🚀 Exécution parallèle : $script"
            bash "$script_path" >> "$LOG_FILE" 2>&1 &
            pids+=($!)
        else
            warn "Script non trouvé : $script_path (ignoré)"
            log "⚠️  Script non trouvé : $script_path (ignoré)"
        fi
    done

    # Attendre la fin de tous les scripts et collecter les résultats
    local failed=0
    local index=0
    for pid in "${pids[@]}"; do
        local script="${scripts[$index]}"
        if ! wait "$pid"; then
            error "Script en parallèle a échoué : $script (PID: $pid)"
            log "❌ ÉCHEC : Script en parallèle $script (PID: $pid)"
            failed_scripts+=("$script")
            failed=1
        else
            log "✅ SUCCÈS : Script en parallèle $script terminé"
        fi
        ((index++))
    done

    if [ $failed -eq 1 ]; then
        error "Scripts échoués : ${failed_scripts[*]}"
        return 1
    fi

    success "Tous les scripts en parallèle terminés"
    log "✅ Tous les scripts en parallèle terminés"
    return 0
}

# Fonction pour valider la connectivité HCD avec retry
validate_hcd_connection() {
    local max_retries=3
    local retry_delay=2

    HCD_DIR="${HCD_DIR:-${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}}"

    for i in $(seq 1 $max_retries); do
        if "${HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT now() FROM system.local;" > /dev/null 2>&1; then
            success "✅ HCD connecté (tentative $i/$max_retries)"
            log "✅ Validation : HCD connecté (tentative $i/$max_retries)"
            return 0
        else
            if [ $i -lt $max_retries ]; then
                warn "⚠️  Tentative $i/$max_retries : HCD non accessible, retry dans ${retry_delay}s..."
                log "⚠️  Tentative $i/$max_retries : HCD non accessible, retry dans ${retry_delay}s..."
                sleep $retry_delay
                retry_delay=$((retry_delay * 2))  # Backoff exponentiel
            fi
        fi
    done

    error "❌ HCD non accessible après $max_retries tentatives"
    log "❌ Validation : HCD non accessible après $max_retries tentatives"
    return 1
}

# Fonction de diagnostic automatique des erreurs
diagnose_error() {
    local script=$1
    local exit_code=$2
    local log_file=$3

    error "🔍 Diagnostic de l'erreur pour $script (code: $exit_code)..."
    log "🔍 Diagnostic de l'erreur pour $script (code: $exit_code)"

    # Analyser les dernières lignes du log
    local last_lines=$(tail -30 "$log_file" 2>/dev/null || echo "")

    # Détecter les erreurs communes
    if echo "$last_lines" | grep -qi "connection.*refused\|timeout\|Connection refused"; then
        error "❌ Problème de connexion HCD détecté"
        warn "💡 Suggestion : Vérifier que HCD est démarré (./scripts/setup/03_start_hcd.sh depuis la racine)"
        log "💡 Suggestion : Vérifier que HCD est démarré"
    elif echo "$last_lines" | grep -qi "no such file\|file not found\|FileNotFoundError"; then
        error "❌ Fichier manquant détecté"
        warn "💡 Suggestion : Vérifier que les phases précédentes ont réussi"
        log "💡 Suggestion : Vérifier que les phases précédentes ont réussi"
    elif echo "$last_lines" | grep -qi "out of memory\|java.*heap\|OutOfMemoryError"; then
        error "❌ Problème de mémoire détecté"
        warn "💡 Suggestion : Augmenter JAVA_OPTS ou réduire le volume de données"
        log "💡 Suggestion : Augmenter JAVA_OPTS"
    elif echo "$last_lines" | grep -qi "permission denied\|Permission denied"; then
        error "❌ Problème de permissions détecté"
        warn "💡 Suggestion : Vérifier les permissions sur les fichiers et répertoires"
        log "💡 Suggestion : Vérifier les permissions"
    elif echo "$last_lines" | grep -qi "syntax error\|SyntaxError"; then
        error "❌ Erreur de syntaxe détectée"
        warn "💡 Suggestion : Vérifier la syntaxe du script Python/Bash"
        log "💡 Suggestion : Vérifier la syntaxe"
    else
        error "❌ Erreur non catégorisée"
        warn "💡 Consulter le log complet : $log_file"
        log "💡 Consulter le log complet : $log_file"
    fi

    # Afficher les dernières lignes du log
    echo ""
    echo "📋 Dernières lignes du log :"
    echo "$last_lines" | tail -10
    echo ""
}

# Fonction pour exécuter un script avec retry automatique
execute_script_with_retry() {
    local script=$1
    local description=$2
    local max_retries=${3:-3}
    local retry_delay=${4:-2}

    local attempt=1
    local last_error=0

    while [ $attempt -le $max_retries ]; do
        if execute_script "$script" "$description (tentative $attempt/$max_retries)"; then
            return 0
        else
            last_error=$?
            if [ $attempt -lt $max_retries ]; then
                warn "⚠️  Échec tentative $attempt/$max_retries, retry dans ${retry_delay}s..."
                log "⚠️  Échec tentative $attempt/$max_retries, retry dans ${retry_delay}s..."
                sleep $retry_delay
                retry_delay=$((retry_delay * 2))  # Backoff exponentiel
            else
                # Diagnostic après échec définitif
                diagnose_error "$script" "$last_error" "$LOG_FILE"
            fi
        fi
        ((attempt++))
    done

    error "❌ Échec définitif après $max_retries tentatives"
    log "❌ Échec définitif après $max_retries tentatives"
    return $last_error
}

# Fonction de validation après une phase (améliorée)
validate_phase() {
    local phase=$1
    local validation_type=$2

    info "🔍 Validation Phase $phase : $validation_type"
    log "🔍 Validation Phase $phase : $validation_type"

    # Toujours vérifier HCD avant validation
    if ! validate_hcd_connection; then
        error "❌ Validation Phase $phase échouée : HCD non accessible"
        return 1
    fi

    HCD_DIR="${HCD_DIR:-${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}}"

    case "$phase" in
        1)
            # Validation Phase 1 : Keyspace, tables, index
            if ! "${HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE KEYSPACE domiramacatops_poc;" > /dev/null 2>&1; then
                error "❌ Keyspace domiramacatops_poc n'existe pas"
                log "❌ Validation : Keyspace manquant"
                return 1
            fi
            success "✅ Keyspace domiramacatops_poc existe"
            log "✅ Validation : Keyspace existe"

            # Vérifier les tables principales
            local tables=("operations_by_account" "acceptations" "oppositions" "feedbacks_libelles")
            local missing_tables=()

            for table in "${tables[@]}"; do
                if ! "${HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE TABLE domiramacatops_poc.${table};" > /dev/null 2>&1; then
                    missing_tables+=("$table")
                fi
            done

            if [ ${#missing_tables[@]} -eq 0 ]; then
                success "✅ Toutes les tables principales créées (${#tables[@]})"
                log "✅ Validation : Toutes les tables principales créées"
            else
                warn "⚠️  Tables manquantes : ${missing_tables[*]}"
                log "⚠️  Validation : Tables manquantes : ${missing_tables[*]}"
            fi
            ;;
        2)
            # Validation Phase 2 : Fichiers Parquet générés (avec validation schéma)
            local parquet_file="${SCRIPT_DIR}/../data/operations_20000.parquet"
            if [ ! -f "$parquet_file" ]; then
                warn "⚠️  Fichier operations_20000.parquet non trouvé"
                log "⚠️  Validation : Fichier Parquet operations manquant"
                return 1
            fi

            success "✅ Fichier operations_20000.parquet existe"
            log "✅ Validation : Fichier Parquet operations existe"

            # Validation schéma Parquet (si Python disponible)
            if command -v python3 &> /dev/null; then
                local validation_result=$(python3 << EOF 2>/dev/null
import pyarrow.parquet as pq
import sys

try:
    table = pq.read_table("$parquet_file")
    row_count = len(table)
    required_columns = ['code_si', 'contrat', 'date_op', 'libelle']
    missing_columns = [col for col in required_columns if col not in table.column_names]

    if missing_columns:
        print(f"MISSING_COLUMNS:{','.join(missing_columns)}")
        sys.exit(1)

    if row_count < 20000:
        print(f"INSUFFICIENT_ROWS:{row_count}")
        sys.exit(1)

    print(f"SUCCESS:{row_count}")
    sys.exit(0)
except Exception as e:
    print(f"ERROR:{str(e)}")
    sys.exit(1)
EOF
)

                if echo "$validation_result" | grep -q "SUCCESS:"; then
                    local row_count=$(echo "$validation_result" | cut -d: -f2)
                    success "✅ Schéma Parquet valide : $row_count lignes"
                    log "✅ Validation : Schéma Parquet valide ($row_count lignes)"
                else
                    warn "⚠️  Schéma Parquet invalide : $validation_result"
                    log "⚠️  Validation : Schéma Parquet invalide : $validation_result"
                fi
            fi
            ;;
        3)
            # Validation Phase 3 : Données chargées (avec validation qualité)
            local total=$("${HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT COUNT(*) FROM domiramacatops_poc.operations_by_account;" 2>&1 | grep -oE '[0-9]+' | head -1 || echo "0")

            if [ "$total" -eq 0 ]; then
                warn "⚠️  Aucune opération chargée"
                log "⚠️  Validation : Aucune opération chargée"
                return 1
            fi

            success "✅ $total opérations chargées"
            log "✅ Validation : $total opérations chargées"

            # Validation qualité données
            local categorized=$("${HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT COUNT(*) FROM domiramacatops_poc.operations_by_account WHERE cat_auto IS NOT NULL;" 2>&1 | grep -oE '[0-9]+' | head -1 || echo "0")
            local with_embeddings=$("${HCD_DIR}/bin/cqlsh" "$HCD_HOST" "$HCD_PORT" -e "SELECT COUNT(*) FROM domiramacatops_poc.operations_by_account WHERE libelle_embedding IS NOT NULL;" 2>&1 | grep -oE '[0-9]+' | head -1 || echo "0")

            local cat_percent=$((categorized * 100 / total))
            local emb_percent=$((with_embeddings * 100 / total))

            if [ "$cat_percent" -lt 90 ]; then
                warn "⚠️  Catégorisation insuffisante : $cat_percent% < 90%"
                log "⚠️  Validation : Catégorisation insuffisante ($cat_percent%)"
            else
                success "✅ Catégorisation OK : $cat_percent%"
                log "✅ Validation : Catégorisation OK ($cat_percent%)"
            fi

            if [ "$emb_percent" -lt 90 ]; then
                warn "⚠️  Embeddings insuffisants : $emb_percent% < 90%"
                log "⚠️  Validation : Embeddings insuffisants ($emb_percent%)"
            else
                success "✅ Embeddings OK : $emb_percent%"
                log "✅ Validation : Embeddings OK ($emb_percent%)"
            fi
            ;;
        4)
            # Validation Phase 4 : Rapports de démonstration générés
            local report_count=$(find "${SCRIPT_DIR}/../doc/demonstrations" -name "*_DEMONSTRATION.md" -type f 2>/dev/null | wc -l | tr -d ' ')
            if [ "$report_count" -gt 0 ]; then
                success "✅ $report_count rapports de démonstration générés"
                log "✅ Validation : $report_count rapports générés"
            else
                warn "⚠️  Aucun rapport de démonstration généré"
                log "⚠️  Validation : Aucun rapport généré"
            fi
            ;;
        *)
            log "⚠️  Validation Phase $phase : Type non défini"
            ;;
    esac

    return 0
}

# ============================================
# VÉRIFICATIONS PRÉALABLES
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 ORCHESTRATION COMPLÈTE - POC DOMIRAMACATOPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🚀 DÉMARRAGE ORCHESTRATION COMPLÈTE"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $RESUME_FROM_PHASE -gt 0 ]; then
    info "📋 Reprise depuis Phase $RESUME_FROM_PHASE"
    log "📋 Reprise depuis Phase $RESUME_FROM_PHASE"
else
    info "🆕 Nouvelle exécution complète"
    log "🆕 Nouvelle exécution complète"
fi

info "Vérifications préalables..."
log "🔍 Vérifications préalables..."

# Vérifier HCD
HCD_DIR="${HCD_DIR:-${HCD_HOME:-${INSTALL_DIR}/binaire/hcd-1.2.3}}"
if command -v "${HCD_DIR}/bin/cqlsh" &> /dev/null || [ -f "${HCD_DIR}/bin/cqlsh" ]; then
    success "HCD détecté"
    log "✅ HCD détecté : ${HCD_DIR}"
else
    error "HCD non détecté. Veuillez démarrer HCD avec ./scripts/setup/03_start_hcd.sh"
    log "❌ HCD non détecté"
    exit 1
fi

# Vérifier Java
if command -v java &> /dev/null; then
    java_version=$(java -version 2>&1 | head -1)
    success "Java détecté : $java_version"
    log "✅ Java détecté : $java_version"
else
    error "Java non détecté. Veuillez configurer Java 11 avec jenv"
    log "❌ Java non détecté"
    exit 1
fi

# Vérifier Spark
if command -v spark-submit &> /dev/null; then
    success "Spark détecté dans PATH"
    log "✅ Spark détecté dans PATH"
elif [ -n "$SPARK_HOME" ]; then
    success "Spark détecté via SPARK_HOME : $SPARK_HOME"
    export PATH="$SPARK_HOME/bin:$PATH"
    info "SPARK_HOME ajouté au PATH : $SPARK_HOME/bin"
    log "✅ Spark détecté via SPARK_HOME : $SPARK_HOME"
else
    warn "Spark non détecté (certains scripts peuvent échouer)"
    warn "Vérifier que SPARK_HOME est défini dans .poc-profile"
    log "⚠️  Spark non détecté"
fi

success "Vérifications préalables terminées"
log "✅ Vérifications préalables terminées"
echo ""

# ============================================
# PHASE 1 : SETUP
# ============================================
if [ $RESUME_FROM_PHASE -le 1 ]; then
    if is_phase_complete 1; then
        info "⏭️  Phase 1 déjà complète, passage à la Phase 2"
        log "⏭️  Phase 1 déjà complète, sautée"
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  📋 PHASE 1 : SETUP ET CONFIGURATION"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "📋 PHASE 1 : SETUP ET CONFIGURATION"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Validation préalable : HCD connecté
        if ! validate_hcd_connection; then
            error "❌ Phase 1 : HCD non accessible"
            save_checkpoint 1 "FAILED"
            exit 1
        fi

        execute_script "01_setup_domiramaCatOps_keyspace.sh" "Création keyspace" || { save_checkpoint 1 "FAILED"; exit 1; }
        execute_script "02_setup_operations_by_account.sh" "Création table operations" || { save_checkpoint 1 "FAILED"; exit 1; }
        execute_script "03_setup_meta_categories_tables.sh" "Création tables meta-categories" || { save_checkpoint 1 "FAILED"; exit 1; }
        execute_script "04_create_indexes.sh" "Création index SAI" || { save_checkpoint 1 "FAILED"; exit 1; }

        # Scripts additionnels pour colonnes dynamiques
        if [ -f "${SCRIPT_DIR}/13_create_meta_flags_indexes.sh" ]; then
            execute_script "13_create_meta_flags_indexes.sh" "Création index meta_flags" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/13_create_meta_flags_map_indexes.sh" ]; then
            execute_script "13_create_meta_flags_map_indexes.sh" "Création index meta_flags MAP" || warn "Script optionnel ignoré"
        fi

        validate_phase 1 "Keyspace, tables, index"
        save_checkpoint 1 "COMPLETE"
        success "✅ Phase 1 terminée"
        log "✅ Phase 1 terminée"
        echo ""
    fi
fi

# ============================================
# PHASE 2 : GÉNÉRATION
# ============================================
if [ $RESUME_FROM_PHASE -le 2 ]; then
    if is_phase_complete 2; then
        info "⏭️  Phase 2 déjà complète, passage à la Phase 3"
        log "⏭️  Phase 2 déjà complète, sautée"
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  📦 PHASE 2 : GÉNÉRATION DE DONNÉES"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "📦 PHASE 2 : GÉNÉRATION DE DONNÉES"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Génération en parallèle (sauf embeddings)
        execute_scripts_parallel \
            "04_generate_operations_parquet.sh" \
            "04_generate_meta_categories_parquet.sh" || { save_checkpoint 2 "FAILED"; exit 1; }

        # Génération embeddings (séquentiel, nécessite opérations)
        execute_script "05_generate_libelle_embedding.sh" "Génération embeddings ByteT5" || { save_checkpoint 2 "FAILED"; exit 1; }

        # Génération données pertinentes pour fuzzy search
        if [ -f "${SCRIPT_DIR}/16_generate_relevant_test_data.sh" ]; then
            execute_script "16_generate_relevant_test_data.sh" "Génération données pertinentes" || warn "Script optionnel ignoré"
        fi

        # Génération fichiers Parquet manquants (meta-categories)
        if [ -f "${SCRIPT_DIR}/06_generate_missing_meta_categories_parquet.sh" ]; then
            execute_script "06_generate_missing_meta_categories_parquet.sh" "Génération fichiers Parquet manquants" || warn "Script optionnel ignoré"
        fi

        validate_phase 2 "Fichiers Parquet générés"
        save_checkpoint 2 "COMPLETE"
        success "✅ Phase 2 terminée"
        log "✅ Phase 2 terminée"
        echo ""
    fi
fi

# ============================================
# PHASE 2b : EMBEDDINGS MULTIPLES
# ============================================
if [ $RESUME_FROM_PHASE -le 2 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔤 PHASE 2b : EMBEDDINGS MULTIPLES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "🔤 PHASE 2b : EMBEDDINGS MULTIPLES"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Ajout colonnes embeddings multiples
    if [ -f "${SCRIPT_DIR}/17_add_e5_embedding_column.sh" ]; then
        execute_script "17_add_e5_embedding_column.sh" "Ajout colonne e5-large" || warn "Script optionnel ignoré"
    fi
    if [ -f "${SCRIPT_DIR}/18_add_invoice_embedding_column.sh" ]; then
        execute_script "18_add_invoice_embedding_column.sh" "Ajout colonne facturation" || warn "Script optionnel ignoré"
    fi

    # Génération embeddings multiples
    if [ -f "${SCRIPT_DIR}/18_generate_embeddings_e5_auto.sh" ]; then
        execute_script "18_generate_embeddings_e5_auto.sh" "Génération embeddings e5-large (auto)" || warn "Script optionnel ignoré"
    elif [ -f "${SCRIPT_DIR}/18_generate_embeddings_e5.sh" ]; then
        # Version alternative si e5_auto n'existe pas
        execute_script "18_generate_embeddings_e5.sh" "Génération embeddings e5-large" || warn "Script optionnel ignoré"
    fi
    if [ -f "${SCRIPT_DIR}/19_generate_embeddings_invoice.sh" ]; then
        execute_script "19_generate_embeddings_invoice.sh" "Génération embeddings facturation" || warn "Script optionnel ignoré"
    fi

    success "✅ Phase 2b terminée"
    log "✅ Phase 2b terminée"
    echo ""
fi

# ============================================
# PHASE 3 : CHARGEMENT
# ============================================
if [ $RESUME_FROM_PHASE -le 3 ]; then
    if is_phase_complete 3; then
        info "⏭️  Phase 3 déjà complète, passage à la Phase 4"
        log "⏭️  Phase 3 déjà complète, sautée"
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  📥 PHASE 3 : CHARGEMENT DES DONNÉES"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "📥 PHASE 3 : CHARGEMENT DES DONNÉES"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        PARQUET_FILE="${SCRIPT_DIR}/../data/operations_20000.parquet"
        if [ ! -f "$PARQUET_FILE" ]; then
            warn "Fichier Parquet non trouvé : $PARQUET_FILE"
            warn "Utilisation du chemin par défaut"
            PARQUET_FILE="data/operations_20000.parquet"
            log "⚠️  Fichier Parquet non trouvé, utilisation chemin par défaut"
        fi

        execute_script "05_load_operations_data_parquet.sh" "Chargement opérations (batch)" || { save_checkpoint 3 "FAILED"; exit 1; }
        execute_script "05_update_feedbacks_counters.sh" "Mise à jour feedbacks" || warn "Script optionnel ignoré"
        execute_script "06_load_meta_categories_data_parquet.sh" "Chargement meta-categories" || { save_checkpoint 3 "FAILED"; exit 1; }
        execute_script "07_load_category_data_realtime.sh" "Chargement corrections client" || { save_checkpoint 3 "FAILED"; exit 1; }

        validate_phase 3 "Données chargées"
        save_checkpoint 3 "COMPLETE"
        success "✅ Phase 3 terminée"
        log "✅ Phase 3 terminée"
        echo ""
    fi
fi

# ============================================
# PHASE 4 : TESTS FONCTIONNELS
# ============================================
if [ $RESUME_FROM_PHASE -le 4 ]; then
    if is_phase_complete 4; then
        info "⏭️  Phase 4 déjà complète, passage à la Phase 5"
        log "⏭️  Phase 4 déjà complète, sautée"
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  🧪 PHASE 4 : TESTS FONCTIONNELS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "🧪 PHASE 4 : TESTS FONCTIONNELS"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Préparation des données AVANT les tests
        info "🔧 Préparation des données de test..."
        log "🔧 Préparation des données de test..."

        if [ -f "${SCRIPT_DIR}/09_prepare_test_data.sh" ]; then
            execute_script "09_prepare_test_data.sh" "Préparation données acceptation/opposition" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/10_prepare_test_data.sh" ]; then
            execute_script "10_prepare_test_data.sh" "Préparation données règles" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/11_prepare_test_data.sh" ]; then
            execute_script "11_prepare_test_data.sh" "Préparation données feedbacks" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/12_prepare_test_data.sh" ]; then
            execute_script "12_prepare_test_data.sh" "Préparation données historique" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/13_prepare_test_data.sh" ]; then
            execute_script "13_prepare_test_data.sh" "Préparation données colonnes dynamiques" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/15_prepare_test_data.sh" ]; then
            execute_script "15_prepare_test_data.sh" "Préparation données cohérence" || warn "Script optionnel ignoré"
        fi

        # Insertion données de test avec meta_flags
        if [ -f "${SCRIPT_DIR}/13_insert_test_data_with_meta_flags.sh" ]; then
            execute_script "13_insert_test_data_with_meta_flags.sh" "Insertion données test meta_flags" || warn "Script optionnel ignoré"
        fi

        # Ajout données supplémentaires pour export
        if [ -f "${SCRIPT_DIR}/14_add_test_data_for_export.sh" ]; then
            execute_script "14_add_test_data_for_export.sh" "Ajout données pour export" || warn "Script optionnel ignoré"
        fi

        # Tests fonctionnels (en parallèle)
        execute_scripts_parallel \
            "08_test_category_search.sh" \
            "09_test_acceptation_opposition.sh" \
            "10_test_regles_personnalisees.sh" \
            "11_test_feedbacks_counters.sh" \
            "12_test_historique_opposition.sh" \
            "13_test_dynamic_columns.sh" \
            "14_test_incremental_export.sh" \
            "15_test_coherence_multi_tables.sh" || { save_checkpoint 4 "FAILED"; exit 1; }

        # Tests additionnels
        if [ -f "${SCRIPT_DIR}/14_test_all_scenarios.sh" ]; then
            execute_script "14_test_all_scenarios.sh" "Tests tous scénarios" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/14_test_all_scenarios_python.sh" ]; then
            execute_script "14_test_all_scenarios_python.sh" "Tests tous scénarios (Python)" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/14_test_edge_cases.sh" ]; then
            execute_script "14_test_edge_cases.sh" "Tests cas limites" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/14_test_sliding_window_export.sh" ]; then
            execute_script "14_test_sliding_window_export.sh" "Tests fenêtre glissante" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/14_improve_sliding_window.sh" ]; then
            execute_script "14_improve_sliding_window.sh" "Amélioration fenêtre glissante" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/14_test_startrow_stoprow.sh" ]; then
            execute_script "14_test_startrow_stoprow.sh" "Tests STARTROW/STOPROW" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/14_improve_startrow_stoprow_tests.sh" ]; then
            execute_script "14_improve_startrow_stoprow_tests.sh" "Amélioration tests STARTROW/STOPROW" || warn "Script optionnel ignoré"
        fi
        if [ -f "${SCRIPT_DIR}/14_test_incremental_export_python.sh" ]; then
            execute_script "14_test_incremental_export_python.sh" "Tests export incrémental (Python)" || warn "Script optionnel ignoré"
        fi

        validate_phase 4 "Rapports de démonstration générés"
        save_checkpoint 4 "COMPLETE"
        success "✅ Phase 4 terminée"
        log "✅ Phase 4 terminée"
        echo ""
    fi
fi

# ============================================
# PHASE 5 : RECHERCHE AVANCÉE
# ============================================
if [ $RESUME_FROM_PHASE -le 5 ]; then
    if is_phase_complete 5; then
        info "⏭️  Phase 5 déjà complète, passage à la Phase 6"
        log "⏭️  Phase 5 déjà complète, sautée"
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  🔍 PHASE 5 : RECHERCHE AVANCÉE"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "🔍 PHASE 5 : RECHERCHE AVANCÉE"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        execute_script "16_test_fuzzy_search.sh" "Tests fuzzy search" || { save_checkpoint 5 "FAILED"; exit 1; }

        # Test fuzzy search complet
        if [ -f "${SCRIPT_DIR}/16_test_fuzzy_search_complete.sh" ]; then
            execute_script "16_test_fuzzy_search_complete.sh" "Tests fuzzy search complets" || warn "Script optionnel ignoré"
        fi

        execute_script "17_demonstration_fuzzy_search.sh" "Démonstration fuzzy search" || { save_checkpoint 5 "FAILED"; exit 1; }
        execute_script "18_test_hybrid_search.sh" "Tests hybrid search" || { save_checkpoint 5 "FAILED"; exit 1; }

        # Comparaison modèles embeddings
        if [ -f "${SCRIPT_DIR}/19_test_embeddings_comparison.sh" ]; then
            execute_script "19_test_embeddings_comparison.sh" "Comparaison modèles embeddings" || warn "Script optionnel ignoré"
        fi

        save_checkpoint 5 "COMPLETE"
        success "✅ Phase 5 terminée"
        log "✅ Phase 5 terminée"
        echo ""
    fi
fi

# ============================================
# PHASE 6 : DÉMONSTRATIONS
# ============================================
if [ $RESUME_FROM_PHASE -le 6 ]; then
    if is_phase_complete 6; then
        info "⏭️  Phase 6 déjà complète, passage à la Phase 7"
        log "⏭️  Phase 6 déjà complète, sautée"
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  🎯 PHASE 6 : DÉMONSTRATIONS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "🎯 PHASE 6 : DÉMONSTRATIONS"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        execute_scripts_parallel \
            "19_demo_ttl.sh" \
            "21_demo_bloomfilter_equivalent.sh" \
            "22_demo_replication_scope.sh" \
            "24_demo_data_api.sh" \
            "25_test_feedbacks_ics.sh" \
            "26_test_decisions_salaires.sh" || { save_checkpoint 6 "FAILED"; exit 1; }

        # Kafka Streaming (séquentiel, nécessite Kafka)
        if command -v kafka-topics &> /dev/null || [ -n "$KAFKA_HOME" ]; then
            execute_script "27_demo_kafka_streaming.sh" "Démonstration Kafka Streaming" || warn "Script optionnel ignoré"
        else
            warn "Kafka non détecté, script 27 ignoré"
            log "⚠️  Kafka non détecté, script 27 ignoré"
        fi

        save_checkpoint 6 "COMPLETE"
        success "✅ Phase 6 terminée"
        log "✅ Phase 6 terminée"
        echo ""
    fi
fi

# ============================================
# PHASE 7 : TESTS COMPLEXES
# ============================================
if [ $RESUME_FROM_PHASE -le 7 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🧪 PHASE 7 : TESTS COMPLEXES (P1, P2, P3)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "🧪 PHASE 7 : TESTS COMPLEXES (P1, P2, P3)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Tests P1 (Priorité Haute)
    info "🔴 Tests P1 (Priorité Haute) :"
    log "🔴 Tests P1 (Priorité Haute)"

    if [ -f "${SCRIPT_DIR}/20_test_charge_concurrente.sh" ] || \
       [ -f "${SCRIPT_DIR}/20_test_coherence_transactionnelle.sh" ] || \
       [ -f "${SCRIPT_DIR}/20_test_migration_complexe.sh" ] || \
       [ -f "${SCRIPT_DIR}/20_test_recherche_multi_modeles_fusion.sh" ]; then

        execute_scripts_parallel \
            "20_test_charge_concurrente.sh" \
            "20_test_coherence_transactionnelle.sh" \
            "20_test_migration_complexe.sh" \
            "20_test_recherche_multi_modeles_fusion.sh" || warn "Certains tests P1 ont échoué"
    else
        warn "Aucun test P1 trouvé"
        log "⚠️  Aucun test P1 trouvé"
    fi

    # Tests P2 (Priorité Moyenne)
    info "🟡 Tests P2 (Priorité Moyenne) :"
    log "🟡 Tests P2 (Priorité Moyenne)"

    if [ -f "${SCRIPT_DIR}/21_test_aggregations.sh" ] || \
       [ -f "${SCRIPT_DIR}/21_test_contraintes_metier.sh" ] || \
       [ -f "${SCRIPT_DIR}/21_test_fenetre_glissante_complexe.sh" ] || \
       [ -f "${SCRIPT_DIR}/21_test_filtres_multiples.sh" ] || \
       [ -f "${SCRIPT_DIR}/21_test_scalabilite.sh" ]; then

        execute_scripts_parallel \
            "21_test_aggregations.sh" \
            "21_test_contraintes_metier.sh" \
            "21_test_fenetre_glissante_complexe.sh" \
            "21_test_filtres_multiples.sh" \
            "21_test_scalabilite.sh" || warn "Certains tests P2 ont échoué"
    else
        warn "Aucun test P2 trouvé"
        log "⚠️  Aucun test P2 trouvé"
    fi

    # Tests P3 (Priorité Basse)
    info "🟢 Tests P3 (Priorité Basse) :"
    log "🟢 Tests P3 (Priorité Basse)"

    if [ -f "${SCRIPT_DIR}/22_test_cache.sh" ] || \
       [ -f "${SCRIPT_DIR}/22_test_facettes.sh" ] || \
       [ -f "${SCRIPT_DIR}/22_test_pagination.sh" ] || \
       [ -f "${SCRIPT_DIR}/22_test_resilience.sh" ] || \
       [ -f "${SCRIPT_DIR}/22_test_suggestions.sh" ]; then

        execute_scripts_parallel \
            "22_test_cache.sh" \
            "22_test_facettes.sh" \
            "22_test_pagination.sh" \
            "22_test_resilience.sh" \
            "22_test_suggestions.sh" || warn "Certains tests P3 ont échoué"
    else
        warn "Aucun test P3 trouvé"
        log "⚠️  Aucun test P3 trouvé"
    fi

    success "✅ Phase 7 terminée"
    log "✅ Phase 7 terminée"
    echo ""
fi

# ============================================
# RÉSUMÉ FINAL
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎉 ORCHESTRATION COMPLÈTE TERMINÉE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🎉 ORCHESTRATION COMPLÈTE TERMINÉE"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

success "✅ Toutes les phases ont été exécutées avec succès"
echo ""
info "📊 Rapports de démonstration générés dans : doc/demonstrations/"
info "📚 Documentation complète disponible dans : doc/"
info "📋 Journal d'exécution : $LOG_FILE"
info "💾 Checkpoints sauvegardés dans : $CHECKPOINT_DIR"
echo ""

# Statistiques finales
if [ -f "$LOG_FILE" ]; then
    local total_scripts=$(grep -c "🚀 Exécution" "$LOG_FILE" || echo "0")
    local successful_scripts=$(grep -c "✅ SUCCÈS" "$LOG_FILE" || echo "0")
    local failed_scripts=$(grep -c "❌ ÉCHEC" "$LOG_FILE" || echo "0")

    info "📊 Statistiques d'exécution :"
    echo "   - Scripts exécutés : $total_scripts"
    echo "   - Scripts réussis : $successful_scripts"
    echo "   - Scripts échoués : $failed_scripts"
    log "📊 Statistiques : $total_scripts exécutés, $successful_scripts réussis, $failed_scripts échoués"
fi

success "🎉 POC DomiramaCatOps prêt pour démonstration !"
log "🎉 POC DomiramaCatOps prêt pour démonstration !"
