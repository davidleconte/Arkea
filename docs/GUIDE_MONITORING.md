# 📊 Guide de Monitoring - ARKEA

**Date** : 2026-03-13
**Version** : 1.0.0
**Objectif** : Guide complet pour le monitoring et l'observabilité du projet ARKEA

---

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Stratégie de Monitoring](#stratégie-de-monitoring)
3. [Métriques Clés](#métriques-clés)
4. [Configuration Prometheus](#configuration-prometheus)
5. [Configuration Grafana](#configuration-grafana)
6. [Alertes](#alertes)
7. [Bonnes Pratiques](#bonnes-pratiques)

---

## 🎯 Vue d'Ensemble

### Objectifs du Monitoring

1. ✅ **Disponibilité** : Surveiller la disponibilité des services
2. ✅ **Performance** : Surveiller les performances et latences
3. ✅ **Capacité** : Surveiller l'utilisation des ressources
4. ✅ **Erreurs** : Détecter les erreurs et anomalies

### Composants à Monitorer

- **HCD/Cassandra** : Base de données principale
- **Kafka** : Streaming de données
- **Spark** : Traitement distribué
- **Applications** : Applications métier

---

## 📊 Stratégie de Monitoring

### Architecture Recommandée

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   HCD       │────▶│  Prometheus  │────▶│   Grafana   │
│   Kafka     │     │  (Collecte)  │     │ (Visualisation)
│   Spark     │     └──────────────┘     └─────────────┘
└─────────────┘            │
                            │
                    ┌───────▼───────┐
                    │    Alertmanager│
                    │    (Alertes)   │
                    └───────────────┘
```

### Outils Recommandés

- **Prometheus** : Collecte et stockage de métriques
- **Grafana** : Visualisation et dashboards
- **Alertmanager** : Gestion des alertes
- **JMX Exporter** : Export métriques Java (HCD, Kafka, Spark)

---

## 📈 Métriques Clés

### HCD/Cassandra

#### Métriques de Disponibilité

- `cassandra_up` : Disponibilité du nœud
- `cassandra_node_status` : Statut du nœud (UP/DOWN)

#### Métriques de Performance

- `cassandra_client_request_latency` : Latence des requêtes client
- `cassandra_client_request_throughput` : Débit des requêtes
- `cassandra_read_latency` : Latence de lecture
- `cassandra_write_latency` : Latence d'écriture

#### Métriques de Capacité

- `cassandra_disk_usage` : Utilisation disque
- `cassandra_heap_memory_used` : Mémoire heap utilisée
- `cassandra_compaction_tasks` : Tâches de compaction

### Kafka

#### Métriques de Performance

- `kafka_broker_request_latency` : Latence des requêtes
- `kafka_messages_in_per_sec` : Messages entrants/seconde
- `kafka_messages_out_per_sec` : Messages sortants/seconde
- `kafka_bytes_in_per_sec` : Bytes entrants/seconde
- `kafka_bytes_out_per_sec` : Bytes sortants/seconde

#### Métriques de Capacité

- `kafka_log_size` : Taille des logs
- `kafka_partition_count` : Nombre de partitions
- `kafka_consumer_lag` : Lag des consommateurs

### Spark

#### Métriques de Performance

- `spark_job_duration` : Durée des jobs
- `spark_task_duration` : Durée des tâches
- `spark_stage_duration` : Durée des stages

#### Métriques de Capacité

- `spark_executor_memory_used` : Mémoire utilisée
- `spark_executor_cpu_used` : CPU utilisée
- `spark_shuffle_read_bytes` : Bytes lus en shuffle

---

## ⚙️ Configuration Prometheus

### Fichier de Configuration

**Fichier** : `monitoring/prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # HCD/Cassandra
  - job_name: 'cassandra'
    static_configs:
      - targets: ['localhost:7072']  # JMX Exporter
    metrics_path: '/metrics'

  # Kafka
  - job_name: 'kafka'
    static_configs:
      - targets: ['localhost:7073']  # JMX Exporter
    metrics_path: '/metrics'

  # Spark
  - job_name: 'spark'
    static_configs:
      - targets: ['localhost:4040']  # Spark UI
    metrics_path: '/metrics'
```

### Installation

```bash
# Installer Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvfz prometheus-2.45.0.linux-amd64.tar.gz
cd prometheus-2.45.0

# Copier la configuration
cp monitoring/prometheus/prometheus.yml prometheus.yml

# Démarrer Prometheus
./prometheus --config.file=prometheus.yml
```

---

## 📊 Configuration Grafana

### Dashboards Recommandés

#### Dashboard HCD/Cassandra

**Métriques à afficher** :

- Latence des requêtes (moyenne, p95, p99)
- Débit des requêtes (lectures, écritures)
- Utilisation mémoire
- Utilisation disque
- Tâches de compaction

#### Dashboard Kafka

**Métriques à afficher** :

- Débit des messages (entrants, sortants)
- Latence des requêtes
- Lag des consommateurs
- Taille des logs

#### Dashboard Spark

**Métriques à afficher** :

- Durée des jobs
- Utilisation mémoire
- Utilisation CPU
- Bytes traités

### Installation

```bash
# Installer Grafana
wget https://dl.grafana.com/oss/release/grafana-10.2.0.linux-amd64.tar.gz
tar xvfz grafana-10.2.0.linux-amd64.tar.gz
cd grafana-10.2.0

# Démarrer Grafana
./bin/grafana-server
```

### Configuration Prometheus comme Source

1. Se connecter à Grafana (<http://localhost:3000>)
2. Configuration → Data Sources → Add data source
3. Sélectionner Prometheus
4. URL : <http://localhost:9090>
5. Save & Test

---

## 🚨 Alertes

### Alertes Critiques

#### HCD/Cassandra

```yaml
# Alertes HCD
- alert: CassandraDown
  expr: cassandra_up == 0
  for: 1m
  annotations:
    summary: "Cassandra est down"
    description: "Le nœud Cassandra est down depuis plus de 1 minute"

- alert: HighLatency
  expr: cassandra_client_request_latency > 1000
  for: 5m
  annotations:
    summary: "Latence élevée"
    description: "La latence des requêtes est supérieure à 1s"
```

#### Kafka

```yaml
# Alertes Kafka
- alert: KafkaDown
  expr: kafka_up == 0
  for: 1m
  annotations:
    summary: "Kafka est down"
    description: "Kafka est down depuis plus de 1 minute"

- alert: HighConsumerLag
  expr: kafka_consumer_lag > 10000
  for: 5m
  annotations:
    summary: "Lag élevé"
    description: "Le lag des consommateurs est supérieur à 10000 messages"
```

### Configuration Alertmanager

**Fichier** : `monitoring/alertmanager/alertmanager.yml`

```yaml
route:
  receiver: 'default-receiver'
  group_by: ['alertname', 'cluster']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h

receivers:
  - name: 'default-receiver'
    email_configs:
      - to: 'admin@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: 'alertmanager'
        auth_password: 'password'  # pragma: allowlist secret
```

---

## ✅ Bonnes Pratiques

### Métriques à Surveiller

1. **Disponibilité** : Taux de disponibilité des services
2. **Latence** : Latence p50, p95, p99
3. **Débit** : Requêtes/seconde, messages/seconde
4. **Erreurs** : Taux d'erreur, erreurs/seconde
5. **Ressources** : CPU, mémoire, disque, réseau

### Fréquence de Collecte

- **Métriques critiques** : 15 secondes
- **Métriques standards** : 1 minute
- **Métriques long terme** : 5 minutes

### Rétention des Données

- **Données haute résolution** : 15 jours
- **Données agrégées** : 1 an
- **Alertes** : Conserver 90 jours

---

## 📚 Exemples de Configuration

### Exemple 1 : Monitoring HCD Simple

```bash
# Démarrer JMX Exporter pour HCD
java -jar jmx_prometheus_httpserver.jar 7072 conf/cassandra.yml
```

### Exemple 2 : Dashboard Grafana

**Fichier** : `monitoring/grafana/dashboards/hcd-dashboard.json`

```json
{
  "dashboard": {
    "title": "HCD Monitoring",
    "panels": [
      {
        "title": "Latence Requêtes",
        "targets": [
          {
            "expr": "cassandra_client_request_latency"
          }
        ]
      }
    ]
  }
}
```

---

## 🔧 Scripts Utilitaires

### Script de Vérification

**Fichier** : `scripts/utils/97_check_monitoring.sh`

```bash
#!/bin/bash
set -euo pipefail

# Vérifier que Prometheus est démarré
check_port 9090 && echo "✅ Prometheus démarré" || echo "❌ Prometheus non démarré"

# Vérifier que Grafana est démarré
check_port 3000 && echo "✅ Grafana démarré" || echo "❌ Grafana non démarré"
```

---

## 📊 Métriques de Référence

### Seuils Recommandés

| Métrique | Seuil Warning | Seuil Critical |
|----------|---------------|----------------|
| **Latence HCD** | >100ms | >500ms |
| **Latence Kafka** | >50ms | >200ms |
| **Utilisation CPU** | >70% | >90% |
| **Utilisation Mémoire** | >80% | >95% |
| **Utilisation Disque** | >80% | >90% |
| **Taux d'erreur** | >1% | >5% |

---

## 📚 Références

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Cassandra Metrics](https://cassandra.apache.org/doc/latest/operating/metrics.html)
- [Kafka Metrics](https://kafka.apache.org/documentation/#monitoring)

---

**Date** : 2026-03-13
**Version** : 1.0.0
**Statut** : ✅ **Guide complet**
