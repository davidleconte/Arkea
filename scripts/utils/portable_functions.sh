#!/usr/bin/env bash
set -euo pipefail

# Detect the operating system (macOS, Linux, WSL)
detect_os() {
    case "$OSTYPE" in
        darwin*)      echo "macos" ;;
        linux-gnu*)   echo "linux" ;;
        linux*)       echo "linux" ;;
        msys*)        echo "windows" ;;
        cygwin*)      echo "windows" ;;
        *)            echo "unknown" ;;
    esac
}

# Return an absolute path in a portable way (macOS compatible).
get_realpath() {
    local path="$1"
    if [ -d "$path" ]; then
        (cd "$path" && pwd)
    elif [ -f "$path" ]; then
        local dir
        dir="$(cd "$(dirname "$path")" && pwd)"
        echo "$dir/$(basename "$path")"
    else
        # Fallback: return input unchanged
        echo "$path"
    fi
}

# Check whether localhost TCP port is reachable.
# Portable: works with Bash /dev/tcp or falls back to nc (netcat).
check_port() {
    local port="$1"
    if [ -n "${BASH_VERSION:-}" ] && [ -e /dev/tcp ]; then
        (echo >"/dev/tcp/localhost/$port") >/dev/null 2>&1
    elif command -v nc >/dev/null 2>&1; then
        nc -z localhost "$port" >/dev/null 2>&1
    else
        # Fallback: try Python if available
        python3 -c "import socket; s=socket.socket(); s.settimeout(1); exit(0 if s.connect_ex(('localhost', $port))==0 else 1)" 2>/dev/null
    fi
}
