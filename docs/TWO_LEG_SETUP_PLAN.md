# Two-Leg Setup Plan: HCD 1.2.3 vs Cassandra 5.0 OSS

**Date**: 2026-03-17
**Author**: AdaL (AI Assistant)
**Purpose**: Audit and plan for duplicating POC Design folders to support both HCD 1.2.3 (binary) and Cassandra 5.0 OSS (Podman)

---

## 1. Executive Summary

This document outlines the plan to create a **dual-leg setup** allowing users to choose between:
- **Leg 1 (Original)**: HCD 1.2.3 with binary installation
- **Leg 2 (New)**: Cassandra 5.0 OSS with Podman containers

### Current State
- Original POCs use hardcoded binary paths (`binaire/hcd-1.2.3/`, `binaire/spark-3.5.1/`)
- Not compatible with Podman container stack

### Target State
- `poc-design/bic/` → remains for HCD 1.2.3
- `poc-design/OSS5.0_bic/` → new version for Cassandra 5.0 OSS

---

## 2. Audit Results

### 2.1 POC Folders

| POC Name | Original Path | New Path (Planned) | Shell Scripts |
|----------|--------------|-------------------|---------------|
| BIC | `poc-design/bic/` | `poc-design/OSS5.0_bic/` | 20 |
| Domirama2 | `poc-design/domirama2/` | `poc-design/OSS5.0_domirama2/` | 65 |
| DomiramaCatOps | `poc-design/domiramaCatOps/` | `poc-design/OSS5.0_domiramaCatOps/` | 74 |

**Total Scripts to Duplicate**: 190 (verified)

### 2.2 File Types to Update

| File Type | Count | Action |
|-----------|-------|--------|
| Shell scripts (.sh) | 190 | Duplicate + modify paths |
| CQL schemas (.cql) | 23 | Duplicate (mostly compatible) |
| Markdown docs (.md) | 363 | Duplicate + update port references |
| Python scripts (.py) | ~10 | Duplicate if present |
| Configuration (.yaml, .json) | ~20 | Duplicate if present |

### 2.3 Hardcoded Path Patterns

Common patterns found in scripts:

```bash
# Binary HCD paths (TO BE REPLACED)
binaire/hcd-1.2.3/bin/cqlsh
binaire/hcd-1.2.3/resources/cassandra/conf/

# Binary Spark paths (TO BE REPLACED)
binaire/spark-3.5.1/bin/spark-submit
binaire/spark-3.5.1/bin/spark-shell

# Port references (TO BE UPDATED)
9042 → 9102 (for external access)
9092 → 9192 (for external access)
8080 → 9280 (for Spark UI)
```

---

## 3. Implementation Plan

### Phase 1: Duplicate Folder Structure

```bash
# Step 1: Duplicate each POC folder with OSS5.0_ prefix
cp -r poc-design/bic poc-design/OSS5.0_bic
cp -r poc-design/domirama2 poc-design/OSS5.0_domirama2
cp -r poc-design/domiramaCatOps poc-design/OSS5.0_domiramaCatOps

# Step 2: Remove binary-specific data (checkpoints, exports)
rm -rf poc-design/OSS5.0_*/data/*
```

### Phase 2: Update Scripts for Podman

**Pattern 1: cqlsh execution**
```bash
# BEFORE (Binary)
$HCD_DIR/bin/cqlsh localhost 9042 -e "..."

# AFTER (Podman - OSS5.0)
podman exec arkea-hcd cqlsh localhost 9042 -e "..."
# OR from host: cqlsh localhost 9102 -e "..."
```

**Pattern 2: Spark submission**
```bash
# BEFORE (Binary)
$SPARK_HOME/bin/spark-submit ...

# AFTER (Podman - OSS5.0)
podman exec -it arkea-spark-master spark-submit ...
```

**Pattern 3: Kafka topics**
```bash
# BEFORE (Binary)
$KAFKA_HOME/bin/kafka-topics.sh --list --bootstrap-server localhost:9092

# AFTER (Podman - OSS5.0)
podman exec arkea-kafka kafka-topics.sh --list --bootstrap-server localhost:9092
# OR from host: localhost:9192
```

### Phase 3: Update Documentation

| Document Type | Update Required |
|--------------|-----------------|
| README.md | Add Podman setup instructions |
| Guides | Update port references |
| Design docs | Update architecture diagrams |
| Audits | Keep original (for HCD leg) |

### Phase 4: Update Configuration Files

- `.poc-config.sh` → Add `USE_PODMAN=true/false` flag
- Create `podman-compose.yml` references in OSS5.0 POCs
- Update checkpoint directories to use Podman volume paths

---

## 4. Files Requiring Changes

### 4.1 Scripts to Modify (Priority Order)

| Priority | POC | Scripts | Key Changes |
|----------|-----|---------|-------------|
| High | bic | 01-04 | cqlsh paths, keyspace setup |
| High | domirama2 | 01-10 | cqlsh, spark-submit |
| High | domiramaCatOps | 00-05 | orchestration, cqlsh |
| Medium | All | 10-50 | kafka topics, streaming |
| Low | All | 50+ | data generation, exports |

### 4.2 Documentation to Update

- `poc-design/OSS5.0_*/README.md` - New setup instructions
- `poc-design/OSS5.0_*/doc/guides/*.md` - Port references
- `poc-design/OSS5.0_*/doc/design/*.md` - Architecture

---

## 5. Rollout Steps

### Step 1: Pre-flight Check
```bash
# Verify current state
make status
# Ensure Podman stack is running
make demo
```

### Step 2: Duplicate Folders
```bash
# Create OSS5.0_ prefixed folders
cp -r poc-design/bic poc-design/OSS5.0_bic
cp -r poc-design/domirama2 poc-design/OSS5.0_domirama2
cp -r poc-design/domiramaCatOps poc-design/OSS5.0_domiramaCatOps
```

### Step 3: Script Transformation
- Replace binary paths with `podman exec` commands
- Update port references (9042→9102, 9092→9192)
- Add container name awareness

### Step 4: Test Each POC
```bash
# Test BIC on OSS5.0
cd poc-design/OSS5.0_bic
bash scripts/01_setup_bic_keyspace.sh  # Should use Podman

# Test Domirama2 on OSS5.0
cd poc-design/OSS5.0_domirama2
bash scripts/01_init_domirama2.sh
```

### Step 5: Update Main Documentation
- Update `poc-design/README.md` with dual-leg instructions
- Create `docs/TWO_LEG_SETUP_GUIDE.md`

---

## 6. Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Scripts fail on Podman | High | Test each script after conversion |
| Port conflicts | Medium | Use 9xxx range (Podman isolation) |
| Data directory conflicts | Low | Use separate volume mounts |
| Performance differences | Low | Benchmark if needed |

---

## 7. Success Criteria

- [ ] All 190 scripts duplicated
- [ ] OSS5.0 scripts use Podman containers
- [ ] Port references updated (9102, 9192, 9280)
- [ ] At least one POC verified working on OSS5.0
- [ ] Documentation updated
- [ ] User can choose between HCD 1.2.3 and Cassandra 5.0

---

## 8. Commands Summary

```bash
# Quick Start - Duplicate all POCs
for poc in bic domirama2 domiramaCatOps; do
  cp -r poc-design/$poc poc-design/OSS5.0_$poc
done

# Verify duplication
ls -d poc-design/OSS5.0_*
```

---

**End of Plan**
