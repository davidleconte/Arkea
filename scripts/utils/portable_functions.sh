#!/bin/bash
# =============================================================================
# Fonctions Portables Cross-Platform
# =============================================================================
# Date : 2025-12-01
# Usage : source scripts/utils/portable_functions.sh
# Objectif : Fonctions portables pour macOS, Linux et Windows (WSL2)
# =============================================================================

# =============================================================================
# FONCTION : Obtenir le chemin réel (remplace readlink -f)
# =============================================================================
#
# Usage: get_realpath <path>
# Retourne: Chemin réel absolu
#
get_realpath() {
    local path="$1"

    if [ -z "$path" ]; then
        return 1
    fi

    # macOS (BSD) - readlink -f n'existe pas
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Utiliser Python pour obtenir le chemin réel
        if command -v python3 &> /dev/null; then
            python3 -c "import os; print(os.path.realpath('$path'))" 2>/dev/null || echo "$path"
        else
            # Fallback : utiliser cd et pwd
            local dir_path
            dir_path=$(cd "$(dirname "$path")" && pwd)
            echo "${dir_path}/$(basename "$path")"
        fi
    # Linux (GNU) - readlink -f disponible
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        readlink -f "$path" 2>/dev/null || echo "$path"
    # Windows (Git Bash / WSL2)
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == *"wsl"* ]]; then
        # WSL2 ou Git Bash
        if command -v readlink &> /dev/null; then
            readlink -f "$path" 2>/dev/null || echo "$path"
        else
            # Fallback : utiliser cd et pwd
            local dir_path
            dir_path=$(cd "$(dirname "$path")" && pwd)
            echo "${dir_path}/$(basename "$path")"
        fi
    else
        # Fallback générique
        local dir_path
        dir_path=$(cd "$(dirname "$path")" && pwd)
        echo "${dir_path}/$(basename "$path")"
    fi
}

# =============================================================================
# FONCTION : Vérifier si un port est utilisé (remplace lsof)
# =============================================================================
#
# Usage: check_port <port>
# Retourne: 0 si le port est utilisé, 1 sinon
#
check_port() {
    local port="$1"

    if [ -z "$port" ]; then
        return 1
    fi

    # macOS / Linux - utiliser lsof
    if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v lsof &> /dev/null; then
            lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null 2>&1
            return $?
        fi
    fi

    # Windows (Git Bash) - utiliser netstat
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        if command -v netstat &> /dev/null; then
            netstat -an | grep -q ":$port.*LISTEN"
            return $?
        fi
    fi

    # WSL2 - utiliser ss ou netstat
    if [[ "$OSTYPE" == *"wsl"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v ss &> /dev/null; then
            ss -tuln | grep -q ":$port "
            return $?
        elif command -v netstat &> /dev/null; then
            netstat -tuln | grep -q ":$port "
            return $?
        fi
    fi

    # Fallback : essayer de se connecter au port
    if command -v nc &> /dev/null; then
        nc -z localhost "$port" >/dev/null 2>&1
        return $?
    fi

    # Si aucune méthode n'est disponible, retourner 1 (port non utilisé)
    return 1
}

# =============================================================================
# FONCTION : Tuer un processus par nom (remplace pkill)
# =============================================================================
#
# Usage: kill_process <pattern>
# Exemple: kill_process "cassandra"
#
kill_process() {
    local pattern="$1"

    if [ -z "$pattern" ]; then
        return 1
    fi

    # macOS / Linux - utiliser pkill
    if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v pkill &> /dev/null; then
            pkill -f "$pattern" 2>/dev/null || true
            return 0
        fi
    fi

    # Windows (Git Bash) / WSL2 - utiliser taskkill ou kill
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        # Git Bash sur Windows
        if command -v taskkill &> /dev/null; then
            taskkill //F //IM "$pattern" 2>/dev/null || true
            return 0
        fi
    fi

    # WSL2 / Linux - utiliser pgrep + kill
    if [[ "$OSTYPE" == *"wsl"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v pgrep &> /dev/null; then
            pgrep -f "$pattern" | xargs kill -9 2>/dev/null || true
            return 0
        fi
    fi

    # Fallback : utiliser ps + grep + kill
    if command -v ps &> /dev/null; then
        ps aux | grep -i "$pattern" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null || true
        return 0
    fi

    return 1
}

# =============================================================================
# FONCTION : Détecter l'OS
# =============================================================================
#
# Usage: detect_os
# Retourne: "macos", "linux", "windows", ou "unknown"
#
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == *"wsl"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# =============================================================================
# FONCTION : Vérifier si une commande existe (portable)
# =============================================================================
#
# Usage: command_exists <command>
# Retourne: 0 si la commande existe, 1 sinon
#
command_exists() {
    local cmd="$1"
    command -v "$cmd" &> /dev/null
}
