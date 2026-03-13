# ADR-0001: Use Podman instead of Docker

## Status

Accepted

## Context

The ARKEA POC project requires containerization for running HCD, Spark, and Kafka services. The team needed to choose between Docker and Podman as the container runtime.

Key considerations:

- Security requirements for financial institution (ARKEA)
- Rootless container execution preference
- Multi-platform support (macOS, Linux)
- Integration with existing tooling

## Decision

We will use **Podman** with **podman-compose** as our container runtime instead of Docker.

### Rationale

1. **Rootless by default**: Podman runs containers without root privileges, improving security
2. **Daemonless architecture**: No background daemon required, reducing attack surface
3. **Docker-compatible CLI**: `podman` commands mirror `docker` commands
4. **podman-compose compatibility**: Drop-in replacement for docker-compose
5. **Enterprise support**: Red Hat backing, suitable for financial sector

### Implementation

- Use `podman` machine on macOS (podman-wxd)
- Port allocation: 9100-9199 range for ARKEA services
- Network isolation: Dedicated `arkea-network` (10.89.10.0/24)
- Label-based resource management: `arkea.poc=true`

## Consequences

### Positive

- Enhanced security with rootless containers
- No daemon overhead on development machines
- Better alignment with enterprise security policies

### Negative

- Team needs to learn Podman-specific commands
- Some Docker-specific tooling may require adaptation
- CI/CD pipelines need Podman support

## References

- [Podman Documentation](https://podman.io/docs)
- [Podman vs Docker](https://docs.podman.io/en/latest/Introduction.html)
- [PODMAN_RULES.md](../../PODMAN_RULES.md)

---

**Author:** David LECONTE (IBM) | **Date:** 2026-03-13
