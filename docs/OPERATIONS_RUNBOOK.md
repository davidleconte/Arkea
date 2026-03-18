# ARKEA POC Operations Runbook

**Version:** 1.0
**Last Updated:** 2026-03-13
**Author:** David LECONTE (IBM WW|Tiger Team - Watsonx.Data GPS)

---

## Table of Contents

1. [Service Overview](#service-overview)
2. [Startup Procedures](#startup-procedures)
3. [Shutdown Procedures](#shutdown-procedures)
4. [Health Checks](#health-checks)
5. [Troubleshooting](#troubleshooting)
6. [Backup & Recovery](#backup--recovery)
7. [Monitoring](#monitoring)

---

## Service Overview

| Service | Port | Purpose | Dependencies |
|---------|------|---------|--------------|
| Cassandra 5.0 | 9102 | Primary database (host mapped) | - |
| Cassandra Graph | 9182 | Graph integration (host mapped) | Cassandra |
| Spark Master | 9280 | Job orchestration (host mapped) | - |
| Spark Worker | 9281 | Job execution (host mapped) | Spark Master |
| Kafka 3.7.1 | 9192 | Message streaming (host mapped) | KRaft |
| Prometheus | 9090 | Metrics collection | All services |
| Grafana | 3000 | Visualization | Prometheus |

*All listed service ports are host-mapped ports in the ARKEA range (9100-9199 where applicable).*

---

## Startup Procedures

### Quick Start (All Services)

```bash
make start
# or
make podman-up
```

### Individual Services

```bash
# HCD only
./scripts/setup/03_start_hcd.sh

# Kafka only
./scripts/setup/04_start_kafka.sh

# Spark only
./scripts/setup/05_start_spark.sh
```

### Verification

```bash
make status
# or
./scripts/utils/80_verify_all.sh
```

---

## Shutdown Procedures

### Graceful Shutdown

```bash
make stop
# or
make podman-down
```

### Emergency Shutdown

```bash
make podman-nuke  # ⚠️ Removes all containers and volumes
```

---

## Health Checks

### HCD/Cassandra

```bash
# Check CQL connectivity
cqlsh localhost 9102 -e "DESCRIBE KEYSPACES;"

# Check cluster status
nodetool status
```

### Kafka

```bash
# List topics
kafka-topics.sh --bootstrap-server localhost:9192 --list

# Consumer group lag
kafka-consumer-groups.sh --bootstrap-server localhost:9192 --describe --all-groups
```

### Spark

```bash
# Check master UI
curl -s http://localhost:9180 | head -20

# List running applications
spark-submit --master spark://localhost:7077 --status
```

### Prometheus

```bash
# Check targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'
```

---

## Troubleshooting

### Common Issues

#### HCD Won't Start

**Symptoms:** Connection refused on host port 9102

**Diagnosis:**

```bash
# Check if port is in use
lsof -i :9102

# Check container logs
podman logs hcd-container --tail 50
```

**Resolution:**

1. Kill process using the port
2. Check Podman machine is running: `podman machine list`
3. Restart HCD: `./scripts/setup/03_start_hcd.sh --restart`

---

#### Kafka Connection Issues

**Symptoms:** Producer/Consumer timeout

**Diagnosis:**

```bash
# Check Kafka process
ps aux | grep kafka

# Check logs
podman logs kafka-container --tail 50
```

**Resolution:**

1. Verify Kafka broker health on port 9192
2. Check network connectivity
3. Review `server.properties` for advertised.listeners

---

#### Spark Job Fails

**Symptoms:** Job stuck or fails with OOM

**Diagnosis:**

```bash
# Check executor logs
ls -la logs/spark/

# Check memory settings
echo $SPARK_EXECUTOR_MEMORY
```

**Resolution:**

1. Increase executor memory: `--executor-memory 4g`
2. Check for data skew
3. Review GC logs

---

### Log Locations

| Service | Log Path |
|---------|----------|
| HCD | `logs/hcd/` |
| Kafka | `logs/kafka/` |
| Spark | `logs/spark/` |
| Application | `logs/` |

---

## Backup & Recovery

### HCD Backup

```bash
# Create snapshot
nodetool snapshot

# Export schema
cqlsh localhost 9102 -e "DESCRIBE KEYSPACE arkea;" > backup/schema.cql

# Export data (using spark)
spark-submit --class com.arkea.backup.HcdExport backup-job.jar
```

### Kafka Backup

```bash
# Mirror Maker for replication
kafka-mirror-maker.sh --consumer.config source.properties \
  --producer.config target.properties \
  --whitelist "arkea.*"
```

### Recovery

```bash
# Restore HCD from snapshot
nodetool refresh -- arkea keyspace_name

# Restore Kafka topics
kafka-topics.sh --bootstrap-server localhost:9192 --create --topic restored-topic
```

---

## Monitoring

### Grafana Dashboards

Access: `<http://localhost:3000>` (admin/admin)

**Pre-configured Dashboards:**

- HCD Cassandra Overview
- Spark Overview
- Kafka Overview

### Prometheus Alerts

Alert rules are defined in `monitoring/prometheus/alerts.yml`

**Key Alerts:**

- `HCDNodeDown`: HCD node unreachable
- `KafkaConsumerLag`: Consumer lag exceeds threshold
- `SparkJobFailure`: High job failure rate

### Metrics Endpoints

| Service | Endpoint |
|---------|----------|
| HCD | `http://hcd:7070/metrics` |
| Spark | `http://spark-master:8081/metrics/prometheus` |
| Kafka | `http://kafka:7071/metrics` |

---

## Contacts

| Role | Name | Contact |
|------|------|---------|
| Project Lead | David LECONTE | <david.leconte1@ibm.com> |
| IBM Watsonx.Data | Tiger Team | <watsonx-data@ibm.com> |

---

Generated with AdaL | IBM WW|Tiger Team - Watsonx.Data GPS
