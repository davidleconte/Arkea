# ADR-0003: Apache Spark Version Selection

## Status

Accepted

## Context

The ARKEA POC requires a distributed data processing framework for migrating from HBase to HCD (Cassandra). We need to select an appropriate Apache Spark version that:

1. Supports Cassandra integration via spark-cassandra-connector
2. Provides stable streaming capabilities for Kafka integration
3. Is compatible with the HCD 1.2.3 (Cassandra 4.0.11) platform
4. Has long-term support and active community

## Decision

We will use **Apache Spark 3.5.1** as the distributed processing engine.

## Rationale

| Factor | Spark 3.5.1 | Alternative (3.4.x) |
|--------|-------------|---------------------|
| spark-cassandra-connector | 3.5.0 compatible | 3.4.1 compatible |
| Kafka streaming | Structured Streaming mature | Less mature |
| Java 17 support | Full support | Partial |
| Bug fixes | Active | Maintenance only |
| Community | Active | Declining |

## Consequences

### Positive

- Full compatibility with spark-cassandra-connector 3.5.0
- Enhanced Structured Streaming for Kafka-to-HCD pipeline
- Better Java 17 compatibility for modern environments
- Active community support and bug fixes

### Negative

- Requires Java 11+ (not compatible with Java 8)
- Larger memory footprint than earlier versions

## Implementation

- Download: `spark-3.5.1-bin-hadoop3.tgz`
- Connector: `org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.1`
- Cassandra Connector: `com.datastax.spark:spark-cassandra-connector_2.12:3.5.0`

## References

- [Apache Spark 3.5.1 Release Notes](https://spark.apache.org/releases/spark-release-3-5-1.html)
- [spark-cassandra-connector Documentation](https://github.com/DataStax/spark-cassandra-connector)

## Date

2026-03-13
