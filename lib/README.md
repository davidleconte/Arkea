# 📚 ARKEA Shared Library

**Version** : 1.0.0
**Date** : 2025-03-13
**Author** : David LECONTE (IBM WW|Tiger Team - Watsonx.Data GPS)

---

## Overview

This directory contains shared libraries and utilities used across all POCs (BIC, Domirama2, DomiramaCatOps). Centralizing common functions ensures consistency, reduces duplication, and simplifies maintenance.

---

## Files

| File | Description |
|------|-------------|
| `common.sh` | Core bash library with logging, OS detection, port checking, and service management |

---

## Usage

### In Bash Scripts

```bash
#!/bin/bash
set -euo pipefail

# Source the common library
source "$(dirname "$0")/../lib/common.sh"

# Use logging functions
log_info "Starting operation..."
log_success "Operation completed!"

# Check service status
hcd_status || log_error "HCD not running"

# Wait for a port
wait_for_port 9042 "localhost" 30
```

### Available Functions

#### Logging
- `log_debug` - Debug level logging (only when LOG_LEVEL=DEBUG)
- `log_info` - Information logging
- `log_warn` - Warning logging
- `log_error` - Error logging (to stderr)
- `log_success` - Success logging
- `log_section` - Formatted section header

#### OS Detection
- `detect_os` - Returns: macos, linux, windows, unknown
- `get_realpath` - Portable realpath implementation

#### Port Management
- `check_port <port> [host] [timeout]` - Check if port is open
- `wait_for_port <port> [host] [max_wait]` - Wait for port to be available

#### Service Status
- `hcd_status` - Check HCD/Cassandra status
- `kafka_status` - Check Kafka status
- `spark_status` - Check Spark configuration

#### CQL Helpers
- `cql_exec <query>` - Execute CQL query
- `cql_exec_file <file>` - Execute CQL file

#### Validation
- `validate_env` - Validate environment configuration

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_LEVEL` | INFO | Logging level (DEBUG, INFO, WARN, ERROR) |
| `LOG_DIR` | `$PROJECT_ROOT/logs` | Log directory |
| `HCD_HOST` | localhost | HCD hostname |
| `HCD_PORT` | 9042 | HCD native transport port |
| `KAFKA_HOST` | localhost | Kafka hostname |
| `KAFKA_PORT` | 9092 | Kafka broker port |

---

## Dependencies

The library depends on:
- `.poc-config.sh` - Project configuration (sourced automatically if present)
- Standard Unix utilities: `nc`, `python3`, `lsof` (optional)

---

## Best Practices

1. **Always source at script start** - Library must be sourced before using functions
2. **Check return values** - Service status functions return 0 on success, 1 on failure
3. **Use logging functions** - Consistent output format across all scripts
4. **Set LOG_LEVEL=DEBUG** - For verbose output during development

---

## Contributing

When adding new functions:
1. Document with header comments
2. Follow existing naming conventions
3. Test on macOS and Linux
4. Update this README

---

**Part of ARKEA POC Migration Project** 🚀
