# ADR-0004: Apache Kafka Version Selection

## Status

Accepted

## Context

The ARKEA POC requires a message streaming platform for real-time data ingestion from COBOL systems to HCD. We need to select an appropriate Apache Kafka version that:

1. Supports high-throughput message streaming
2. Integrates well with Spark Structured Streaming
3. Provides reliable message delivery guarantees
4. Is compatible with the target infrastructure

## Decision

We will use **Apache Kafka 4.1.1** (KRaft mode) as the streaming platform.

## Rationale

| Factor | Kafka 4.1.1 (KRaft) | Kafka 3.x (ZooKeeper) |
|--------|---------------------|------------------------|
| Architecture | No ZooKeeper dependency | ZooKeeper required |
| Operational complexity | Lower | Higher |
| Performance | Improved | Standard |
| Future support | Active | Deprecated path |
| Spark integration | Full compatibility | Full compatibility |

### Key Features

- **KRaft mode**: Eliminates ZooKeeper dependency, simplifying operations
- **Improved performance**: Better throughput and latency
- **Enhanced security**: Improved ACL and authentication mechanisms
- **Future-proof**: Aligned with Kafka's architectural direction

## Consequences

### Positive

- Simplified deployment without ZooKeeper
- Better performance for high-throughput scenarios
- Aligned with Kafka's future architecture
- Reduced operational overhead

### Negative

- KRaft mode is newer, potentially less community knowledge
- Some legacy tools may not yet support KRaft mode

## Implementation

- Download: `kafka_2.13-4.1.1.tgz`
- Mode: KRaft (no ZooKeeper)
- Default port: 9092 (or 9192 for Podman isolation)

## References

- [Apache Kafka 4.1.1 Release Notes](https://kafka.apache.org/downloads#4.1.1)
- [KRaft Mode Documentation](https://kafka.apache.org/documentation/#kraft_mode)

## Date

2026-03-13
