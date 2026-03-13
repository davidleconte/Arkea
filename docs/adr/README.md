# Architecture Decision Records (ADR)

This directory contains all architecture decisions for the ARKEA POC project.

## What is an ADR?

An Architecture Decision Record (ADR) captures a significant architecture decision along with its context and consequences.

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-0001](0001-podman-over-docker.md) | Use Podman instead of Docker | Accepted | 2026-03-13 |
| [ADR-0002](0002-hcd-over-hbase.md) | Migration from HBase to HCD | Accepted | 2026-03-13 |
| [ADR-0003](0003-spark-version.md) | Apache Spark Version Selection | Accepted | 2026-03-13 |
| [ADR-0004](0004-kafka-version.md) | Apache Kafka Version Selection | Accepted | 2026-03-13 |
| [ADR-0005](0005-python-version.md) | Python Version and Tooling Selection | Accepted | 2026-03-13 |

## How to Create an ADR

1. Copy the template: `cp docs/adr/0000-template.md docs/adr/NNNN-title.md`
2. Fill in the sections
3. Submit for review via PR

## Template

See [ADR-0000: Template](0000-template.md)
