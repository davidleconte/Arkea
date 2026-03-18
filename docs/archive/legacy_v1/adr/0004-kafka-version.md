# ADR-0004: Apache Kafka Version Selection

## Status

**SUPERSEDED** - See ADR-0006: Kafka 3.7.1 Selection

> ⚠️ **Note**: This decision was superseded on 2026-03-16. The project now uses Apache Kafka 3.7.1 with official Apache container images for ARM64 compatibility. See `docs/adr/0006-kafka-3.7.1.md` for the current architecture.

## Context

The ARKEA POC requires a message streaming platform for real-time data ingestion from COBOL systems to Cassandra. We need to select an appropriate Apache Kafka version that:

1. Supports high-throughput message streaming
2. Integrates well with Spark Structured Streaming
3. Provides reliable message delivery guarantees
4. Is compatible with the target infrastructure

## Decision

We will use **Apache Kafka 3.7.1** (KRaft mode) as the streaming platform.

## Rationale

| Factor | Kafka 3.7.1 (KRaft) | Kafka 4.x |
|--------|---------------------|-----------|
| Architecture | No ZooKeeper dependency | KRaft only |
| ARM64 Support | ✅ Official Apache images | ⚠️ Limited |
| Container ecosystem | ✅ Well-supported | ⚠️ Newer |
| Spark integration | Full compatibility | Full compatibility |
| Stability | Production-ready | Newer release |

### Key Features

- **KRaft mode**: Eliminates ZooKeeper dependency, simplifying operations
- **ARM64 native**: Official Apache container images support Apple Silicon
- **Production-tested**: Mature release with proven stability
- **Container-first**: Optimized for Podman/Docker deployments

## Consequences

### Positive

- Simplified deployment without ZooKeeper
- Native ARM64 support via official Apache images
- Aligned with container-first architecture
- Reduced operational overhead

### Negative

- KRaft mode requires learning new operational patterns
- Some legacy tools may not yet support KRaft mode

## Implementation

- Image: `apache/kafka:3.7.1`
- Mode: KRaft (no ZooKeeper)
- Default port: 9192 (Podman isolation)

## References

- [Apache Kafka 3.7.1 Release Notes](https://kafka.apache.org/downloads#3.7.1)
- [KRaft Mode Documentation](https://kafka.apache.org/documentation/#kraft_mode)

## Date

2026-03-16 (Updated)
**Superseded:** Original decision from 2026-03-13
