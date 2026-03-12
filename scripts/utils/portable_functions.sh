#!/usr/bin/env bash

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
check_port() {
    local port="$1"
    (echo >"/dev/tcp/localhost/$port") >/dev/null 2>&1
}
