# ADR-0002: Migration from HBase to HCD

## Status

**SUPERSEDED** - See ADR-0005: Migration to Apache Cassandra 5.0

> ⚠️ **Note**: This decision was superseded on 2026-03-16. The project now uses Apache Cassandra 5.0.6 instead of DataStax HCD 1.2.3. See `docs/adr/0005-cassandra-5.0.md` for the current architecture.

## Context

ARKEA currently runs COBOL applications on HBase. The modernization initiative requires migrating to a more maintainable, scalable, and cloud-ready database platform.

Key considerations:

- Existing HBase workloads and data models
- Integration with Spark for ETL/ELT pipelines
- Support for financial data patterns (time-series, transactions)
- Operational complexity and maintenance costs

## Decision

We will migrate from **HBase** to **DataStax HCD** (Hyper-Converged Database, based on Cassandra 4.0.11).

### Rationale

1. **Cassandra ecosystem**: Wide-column store similar to HBase, easier migration
2. **Spark integration**: Native spark-cassandra-connector support
3. **Operational simplicity**: No Hadoop dependency, easier cluster management
4. **Cloud-ready**: Better support for hybrid/multi-cloud deployments
5. **IBM partnership**: HCD is part of IBM Watsonx.Data ecosystem

### Migration Strategy

- Phase 1: Schema mapping (HBase → CQL)
- Phase 2: Data migration using Spark
- Phase 3: Application refactoring (COBOL → Python)
- Phase 4: Kafka streaming pipelines for real-time updates

## Consequences

### Positive

- Modern Python-based stack (vs COBOL)
- Better cloud portability
- Reduced operational complexity
- Active community and commercial support

### Negative

- Learning curve for Cassandra CQL
- Data model transformation required
- Application rewrite effort significant

## References

- [HCD Documentation](https://docs.datastax.com/en/hcd/)
- [Cassandra 4.0 Features](https://cassandra.apache.org/doc/latest/cassandra/)
- [SYNTHESE_USE_CASES_POC.md](../../SYNTHESE_USE_CASES_POC.md)

---

**Author:** David LECONTE (IBM) | **Date:** 2026-03-13
**Superseded:** 2026-03-16 by ADR-0005
