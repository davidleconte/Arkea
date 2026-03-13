# ⚠️ IMPERATIVE RULES: Podman Isolation Management

**Status**: **MANDATORY - NON-NEGOTIABLE**
**Version**: 1.0.0
**Date**: 2026-03-13
**Enforcement**: All agents, developers, and automation MUST comply

---

## 🚨 CRITICAL CONSTRAINTS

### RULE 1: Podman Machine is SHARED and IMMUTABLE

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                       PODMAN MACHINE (podman-wxd)                         ║
║                      24GB RAM | 12 CPUs | 250GB Disk                      ║
║                                                                           ║
║  ⚠️  THIS MACHINE CANNOT BE DELETED OR REMOVED                            ║
║  ⚠️  OTHER PROJECTS ARE RUNNING - DO NOT DISRUPT                          ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

**IMPERATIVE**:
- ✅ MUST use existing `podman-wxd` machine
- ❌ MUST NOT delete, remove, or recreate the machine
- ❌ MUST NOT stop or restart the machine without explicit approval
- ❌ MUST NOT modify machine resources (RAM, CPU, disk)

---

### RULE 2: Podman & Podman-Compose ONLY

**IMPERATIVE**:
- ✅ MUST use `podman` command (NOT `docker`)
- ✅ MUST use `podman-compose` command (NOT `docker-compose`)
- ❌ MUST NOT install or use Docker
- ❌ MUST NOT install or use docker-compose
- ❌ MUST NOT reference Docker in any configuration

**Command Translation Table**:

| Docker Command | Podman Equivalent |
|----------------|-------------------|
| `docker ps` | `podman ps` |
| `docker-compose up` | `podman-compose up` |
| `docker build` | `podman build` |
| `docker exec` | `podman exec` |
| `docker volume` | `podman volume` |
| `docker network` | `podman network` |

---

### RULE 3: Project Isolation Model

**IMPERATIVE**: All ARKEA resources MUST follow the 5-layer isolation model:

#### Layer 1: Network Isolation
```
arkea-network:     10.89.10.0/24  ← ARKEA POC containers (ISOLATED)
```

**Rules**:
- ✅ MUST create dedicated network: `arkea-network`
- ✅ MUST use subnet: `10.89.10.0/24`
- ❌ MUST NOT use other project networks
- ❌ MUST NOT share networks with other projects

#### Layer 2: Volume Isolation
```
arkea-hcd-data:    HCD data (ARKEA only)
arkea-hcd-logs:    HCD logs (ARKEA only)
arkea-spark-data:  Spark data (ARKEA only)
arkea-kafka-data:  Kafka data (ARKEA only)
```

**Rules**:
- ✅ MUST prefix all volumes with `arkea-`
- ❌ MUST NOT use volumes from other projects
- ❌ MUST NOT share volumes between projects

#### Layer 3: Resource Limits
```
arkea-pod:  4 CPUs | 8GB RAM (33% CPU, 33% RAM)
```

**Rules**:
- ✅ MUST limit to 4 CPUs maximum
- ✅ MUST limit to 8GB RAM maximum
- ❌ MUST NOT exceed these limits (other projects need resources)

#### Layer 4: Port Mapping
```
ARKEA Port Allocation (Base: 9100):
├── HCD CQL:     9102 → 9042 (container)
├── HCD Solr:    9045 → 8983 (container)
├── Spark UI:    9180 → 8080 (container)
├── Spark MS:    9177 → 7077 (container)
├── Kafka:       9192 → 9092 (container)
└── Kafka UI:    9190 → 9090 (container)
```

**IMPERATIVE Port Rules**:
- ✅ MUST check port availability BEFORE starting any service
- ✅ MUST use ports in the 9100-9199 range for ARKEA
- ❌ MUST NOT use default ports (9042, 9092, 8080) - conflicts with other projects
- ❌ MUST NOT use ports from other project ranges:
  - 9040-9099: dse-test project
  - 9050-9059: project-a
  - 9060-9069: project-b

#### Layer 5: Label-Based Management
```
All resources MUST have: label=project:arkea
```

**Rules**:
- ✅ MUST tag all resources with `--label project=arkea`
- ✅ MUST use labels to filter and manage resources
- ❌ MUST NOT operate on resources without checking labels first

---

### RULE 4: Pre-Flight Port Conflict Detection

**IMPERATIVE**: Before ANY container start, MUST run port conflict check:

```bash
# REQUIRED: Check these ports before starting
PORTS_TO_CHECK="9102 9045 9180 9177 9192 9190"

for port in $PORTS_TO_CHECK; do
    if lsof -i :$port >/dev/null 2>&1; then
        echo "[ERROR] Port $port is already in use!"
        echo "Process using port: $(lsof -i :$port | tail -1)"
        exit 1
    fi
done
```

**Alternative ports if conflicts detected**:
- HCD CQL: 9112, 9122
- Spark UI: 9280, 9380
- Kafka: 9292, 9392

---

### RULE 5: Resource Cleanup

**IMPERATIVE**: MUST clean up only ARKEA resources, NEVER touch other projects:

```bash
# ✅ CORRECT: Filter by label
podman ps --filter "label=project=arkea"
podman pod rm -f arkea-pod
podman network rm arkea-network
podman volume rm arkea-hcd-data arkea-hcd-logs

# ❌ FORBIDDEN: Remove all resources
podman system prune -af  # NEVER DO THIS
podman volume prune      # NEVER DO THIS
```

---

## 📋 ARKEA Project Resource Manifest

### Pod Structure
```
arkea-pod/
├── arkea-hcd        (HCD 1.2.3 / Cassandra 4.0.11)
├── arkea-spark      (Spark 3.5.1)
└── arkea-kafka      (Kafka 4.1.1)
```

### Network
```
Name:    arkea-network
Subnet:  10.89.10.0/24
Gateway: 10.89.10.1
Labels:  project=arkea
```

### Volumes
```
arkea-hcd-data      → /var/lib/cassandra
arkea-hcd-logs      → /var/log/cassandra
arkea-spark-data    → /opt/spark/work
arkea-kafka-data    → /var/lib/kafka/data
```

### Port Mappings
| Host Port | Container Port | Service | Purpose |
|-----------|----------------|---------|---------|
| 9102 | 9042 | HCD | CQL Native Transport |
| 9045 | 8983 | HCD | Solr HTTP |
| 9180 | 8080 | Spark | Web UI |
| 9177 | 7077 | Spark | Master |
| 9192 | 9092 | Kafka | Broker |
| 9190 | 9090 | Kafka | Control Center |

---

## 🔒 Compliance Verification

### Before Starting ARKEA Services
```bash
# 1. Verify machine is running
podman machine ls | grep podman-wxd

# 2. Check existing projects (DO NOT MODIFY)
podman pod ps

# 3. Verify port availability
./scripts/utils/check_ports.sh

# 4. Create ARKEA network if not exists
podman network create --subnet=10.89.10.0/24 --label project=arkea arkea-network
```

### Status Check Commands
```bash
# List ARKEA resources ONLY
podman ps --filter "label=project=arkea"
podman pod ps --filter "label=project=arkea"
podman volume ls --filter "label=project=arkea"
podman network ls --filter "label=project=arkea"
```

---

## 🚫 FORBIDDEN ACTIONS

| Action | Consequence |
|--------|-------------|
| Delete podman-wxd machine | **CRITICAL** - Other projects destroyed |
| Use Docker instead of Podman | **CRITICAL** - Architecture violation |
| Use default ports (9042, 9092) | **HIGH** - Port conflicts |
| Remove unlabeled resources | **HIGH** - May delete other projects |
| Exceed 4 CPUs / 8GB RAM | **MEDIUM** - Resource starvation |
| Share networks with other projects | **MEDIUM** - Isolation breach |

---

## 📚 Reference Documentation

- Podman Architecture: `/Users/david.leconte/Documents/Work/Labs/adal/podman-architecture/PODMAN_ARCHITECTURE.md`
- Podman Commands: `/Users/david.leconte/Documents/Work/Labs/adal/podman-architecture/PODMAN_COMMANDS.md`
- Architectural Improvements: `/Users/david.leconte/Documents/Work/Labs/adal/podman-architecture/ARCHITECTURAL_IMPROVEMENTS.md`

---

** THESE RULES ARE IMPERATIVE AND NON-NEGOTIABLE **

All agents, scripts, and developers MUST follow these rules without exception.
Violation may cause disruption to other critical projects on the shared machine.
