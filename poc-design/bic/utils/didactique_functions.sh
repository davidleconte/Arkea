#!/bin/bash
set -euo pipefail
# =============================================================================
# Fonctions Utilitaires pour Scripts Didactiques - POC BIC
# =============================================================================
# Date : 2025-12-01
# Usage : source utils/didactique_functions.sh
# =============================================================================

# ============================================
# FONCTION : Configurer les Chemins et Variables d'Environnement
# ============================================
#
# Priorité : Variables d'environnement > Fichier .poc-config.sh > Détection automatique
#
setup_paths() {
    # Détecter le répertoire du script appelant
    local caller_script="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
    SCRIPT_DIR="$(cd "$(dirname "$caller_script")" && pwd)"

    # Détecter ARKEA_HOME (racine du projet Arkea)
    # Priorité 1: Variable d'environnement ARKEA_HOME
    # Priorité 2: Détection automatique (3 niveaux au-dessus de bic/scripts)
    if [ -z "${ARKEA_HOME:-}" ]; then
        export ARKEA_HOME="$(cd "$SCRIPT_DIR/../../.." && pwd)"
    fi

    # Charger le fichier de configuration centralisé s'il existe
    local config_file="${ARKEA_HOME}/.poc-config.sh"
    if [ -f "$config_file" ]; then
        source "$config_file"
    fi

    # Définir les chemins par défaut si non définis par .poc-config.sh ou env vars
    export INSTALL_DIR="${INSTALL_DIR:-$ARKEA_HOME}" # Pour compatibilité avec anciens scripts
    export HCD_DIR="${HCD_DIR:-${ARKEA_HOME}/binaire/hcd-1.2.3}"
    export SPARK_HOME="${SPARK_HOME:-${ARKEA_HOME}/binaire/spark-3.5.1}"
    export HCD_HOST="${HCD_HOST:-localhost}"
    export HCD_PORT="${HCD_PORT:-9042}"

    # Exporter les variables pour qu'elles soient disponibles dans le script appelant
    export SCRIPT_DIR ARKEA_HOME INSTALL_DIR HCD_DIR SPARK_HOME HCD_HOST HCD_PORT
}

# ============================================
# FONCTION : Afficher un Message d'Information
# ============================================
info() {
    echo "ℹ️  $1"
}

# ============================================
# FONCTION : Afficher un Message de Succès
# ============================================
success() {
    echo "✅ $1"
}

# ============================================
# FONCTION : Afficher un Avertissement
# ============================================
warn() {
    echo "⚠️  $1"
}

# ============================================
# FONCTION : Afficher une Erreur
# ============================================
error() {
    echo "❌ $1" >&2
}

# ============================================
# FONCTION : Afficher une Section (Titre)
# ============================================
section() {
    echo "$1"
}

# ============================================
# FONCTION : Afficher un Code
# ============================================
code() {
    local code_content="$1"
    echo "```python"
    echo "$code_content" | head -20
    if [ "$(echo "$code_content" | wc -l)" -gt 20 ]; then
        echo "..."
    fi
    echo "```"
}

# ============================================
# FONCTION : Afficher un Résultat
# ============================================
result() {
    echo "📊 $1"
}

# ============================================
# FONCTION : Afficher un Résultat Attendu
# ============================================
expected() {
    echo "📋 Attendu : $1"
}

# ============================================
# FONCTION : Afficher une Démonstration
# ============================================
demo() {
    echo "🎯 $1"
}

# ============================================
# FONCTION : Vérifier que HCD est Démarré
# ============================================
check_hcd_running() {
    if ! cqlsh "$HCD_HOST" "$HCD_PORT" -e "DESCRIBE KEYSPACES;" &>/dev/null; then
        error "HCD n'est pas démarré ou n'est pas accessible"
        error "Exécutez d'abord: ${ARKEA_HOME}/scripts/setup/03_start_hcd.sh background"
        return 1
    fi
    return 0
}

# ============================================
# FONCTION : Vérifier que Kafka est Démarré
# ============================================
check_kafka_running() {
    if ! kafka-topics.sh --list --bootstrap-server "${KAFKA_BOOTSTRAP_SERVERS:-localhost:9092}" &>/dev/null; then
        error "Kafka n'est pas démarré ou n'est pas accessible"
        error "Exécutez d'abord: ${ARKEA_HOME}/scripts/setup/04_start_kafka.sh background"
        return 1
    fi
    return 0
}

# ============================================
# FONCTION : Exécuter une Commande CQL
# ============================================
execute_cql() {
    local cql_command="$1"
    local keyspace="${2:-}"

    if [ -n "$keyspace" ]; then
        cqlsh "$HCD_HOST" "$HCD_PORT" -e "USE $keyspace; $cql_command"
    else
        cqlsh "$HCD_HOST" "$HCD_PORT" -e "$cql_command"
    fi
}

# ============================================
# FONCTION : Exécuter une Commande CQL de Manière Sûre (Gestion d'Erreurs)
# ============================================
#
# Usage : execute_cql_safe "SELECT * FROM table" [keyspace] [expected_errors]
#
# Paramètres :
#   $1 : Commande CQL à exécuter
#   $2 : Keyspace (optionnel)
#   $3 : Erreurs attendues (optionnel, regex pour ignorer certaines erreurs)
#
# Retour :
#   0 : Succès ou erreur attendue
#   1 : Erreur critique
#
execute_cql_safe() {
    local cql_command="$1"
    local keyspace="${2:-}"
    local expected_errors="${3:-}"
    local output
    local exit_code=0

    # Construire la commande cqlsh
    local cqlsh_cmd
    if [ -n "$keyspace" ]; then
        cqlsh_cmd="USE $keyspace; $cql_command"
    else
        cqlsh_cmd="$cql_command"
    fi

    # Exécuter la commande et capturer la sortie
    output=$(cqlsh "$HCD_HOST" "$HCD_PORT" -e "$cqlsh_cmd" 2>&1) || exit_code=$?

    # Vérifier si c'est une erreur attendue
    if [ $exit_code -ne 0 ]; then
        if [ -n "$expected_errors" ]; then
            if echo "$output" | grep -qE "$expected_errors"; then
                # Erreur attendue, ne pas échouer
                return 0
            fi
        fi

        # Erreur critique
        error "Erreur CQL : $cql_command"
        error "Sortie : $output"
        return 1
    fi

    # Succès
    echo "$output"
    return 0
}

# ============================================
# FONCTION : Vérifier que Spark est Démarré
# ============================================
check_spark_running() {
    if [ -z "${SPARK_HOME:-}" ] || [ ! -d "$SPARK_HOME" ]; then
        error "SPARK_HOME n'est pas défini ou le répertoire n'existe pas"
        error "Définissez SPARK_HOME ou configurez .poc-config.sh"
        return 1
    fi

    if [ ! -f "$SPARK_HOME/bin/spark-submit" ]; then
        error "spark-submit n'est pas trouvé dans $SPARK_HOME/bin"
        return 1
    fi

    return 0
}

# ============================================
# FONCTION : Vérifier la Santé d'Ingestion (Post-Ingestion)
# ============================================
check_ingestion_health() {
    local keyspace="$1"
    local table="$2"
    local expected_min_count="${3:-1}"
    local actual_count

    info "Vérification de la santé de l'ingestion..."

    # Compter les lignes dans la table
    actual_count=$(execute_cql_safe "SELECT COUNT(*) FROM $table;" "$keyspace" 2>/dev/null | grep -E "^\s+[0-9]+" | tr -d ' ' || echo "0")

    if [ -z "$actual_count" ] || [ "$actual_count" = "0" ]; then
        warn "⚠️  Aucune donnée trouvée dans $keyspace.$table après ingestion"
        return 1
    fi

    if [ "$actual_count" -lt "$expected_min_count" ]; then
        warn "⚠️  Nombre de lignes ($actual_count) inférieur au minimum attendu ($expected_min_count)"
        return 1
    fi

    success "✅ Ingestion réussie : $actual_count lignes dans $keyspace.$table"
    return 0
}

# ============================================
# FONCTION : Générer un Rapport de Démonstration
# ============================================
generate_demo_report() {
    local script_name="$1"
    local report_file="$2"
    local content="$3"

    mkdir -p "$(dirname "$report_file")"
    cat > "$report_file" << EOF
$content
EOF

    success "Rapport généré : $report_file"
}
