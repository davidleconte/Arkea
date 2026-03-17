# OSS5.0 Script Conversion Template

This document shows how to convert an HCD 1.2.3 script to work with Cassandra 5.0 OSS (Podman).

## Pattern 1: Script Header - Add Podman Detection

```bash
# AFTER (add after setup_paths call)
if [ "$HCD_DIR" = "podman" ] || [ -z "$HCD_DIR" ]; then
    if podman ps --filter "name=arkea-hcd" --format "{{.Names}}" 2>/dev/null | grep -q "arkea-hcd"; then
        CQLSH="podman exec arkea-hcd cqlsh localhost 9042"
        PODMAN_MODE=true
    else
        echo "ERROR: Container arkea-hcd not running. Run 'make demo' first."
        exit 1
    fi
else
    # Binary mode (keep original)
    CQLSH_BIN="${HCD_DIR}/bin/cqlsh"
    CQLSH="$CQLSH_BIN $HCD_HOST $HCD_PORT"
    PODMAN_MODE=false
fi
```

## Pattern 2: Schema File Execution

```bash
# BEFORE:
$CQLSH -f "$SCHEMA_FILE"

# AFTER:
if [ "$PODMAN_MODE" = "true" ]; then
    podman cp "$SCHEMA_FILE" arkea-hcd:/tmp/$(basename "$SCHEMA_FILE")
    podman exec arkea-hcd cqlsh localhost 9042 -f /tmp/$(basename "$SCHEMA_FILE")
else
    $CQLSH -f "$SCHEMA_FILE"
fi
```

## Pattern 3: Inline CQL Commands

```bash
# BEFORE:
$CQLSH -e "CREATE TABLE..."

# AFTER (no change needed - works with both):
$CQLSH -e "CREATE TABLE..."
```

## Pattern 4: Spark Jobs (for later scripts)

```bash
# BEFORE:
$SPARK_HOME/bin/spark-submit ...

# AFTER:
if [ "$SPARK_HOME" = "podman" ]; then
    podman exec arkea-spark-master spark-submit ...
else
    $SPARK_HOME/bin/spark-submit ...
fi
```

## Pattern 5: Kafka Commands

```bash
# BEFORE:
$KAFKA_HOME/bin/kafka-topics.sh --list --bootstrap-server localhost:9092

# AFTER:
podman exec arkea-kafka /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```

## Quick Conversion Steps

1. Find: `CQLSH_BIN="${HCD_DIR}/bin/cqlsh"`
2. Replace with: Podman detection block (Pattern 1)
3. Find: `$CQLSH -f "$SCHEMA_FILE"`
4. Replace with: Schema execution block (Pattern 2)
5. Test with: `bash scripts/XX_*.sh`

## Verified Working Scripts

- ✅ 01_setup_bic_keyspace.sh
- ✅ 02_setup_bic_tables.sh
- ⏳ 03_setup_bic_indexes.sh (needs conversion)
- ⏳ 04_verify_setup.sh (needs conversion)
- ⏳ Scripts 05+ (need conversion)

## Files to Update

Total: ~190 scripts across 3 POCs
- bic: 20 scripts
- domirama2: 65 scripts
- domiramaCatOps: 74 scripts
