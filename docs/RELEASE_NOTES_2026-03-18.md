# Release Notes — 2026-03-18

**Date**: 2026-03-18
**Branch**: `main`
**Scope**: Runtime hardening, documentation rationalization, audit tooling, and execution roadmap

---

## TL;DR

This release stabilizes the **OSS 5.0 Podman path** as the default operating mode, adds strong guardrails against legacy drift, and delivers a structured roadmap to reach **A+ with honours**.

---

## Included Commits

1. `0292caf` — **feat(runtime): add dual-leg selector with OSS5 default guard**
   - Adds runtime leg selection (`podman` vs `binary`)
   - Enforces single-leg startup to avoid conflicts
   - Blocks binary leg by default unless explicitly enabled

2. `947fd28` — **docs: rationalize active guidance and archive references**
   - Cleans active documentation
   - Archives legacy setup/plan/ADR documents into `docs/archive/legacy_v1/`
   - Fixes active references to moved files

3. `0038645` — **chore(hardening): add leg-aware verify and active-doc port guard**
   - Makes verification/test helpers leg-aware
   - Adds `scripts/utils/97_guard_host_ports.sh`
   - Wires `check-ports` into `make check`
   - Aligns active API examples with host-mapped ports

4. `26d8b2e` — **chore(hardening): enforce binary guard and leg-aware audit/test normalization**
   - Adds binary-only guard to legacy HCD start script
   - Splits `80_verify_all.sh` HCD checks by runtime leg
   - Normalizes e2e/performance tests to config-driven ports
   - Adds `make audit-active`
   - Adds historical notices in key docs

5. `0f0d5b5` — **docs(roadmap): add A+ execution board with milestones and acceptance criteria**
   - Adds `A_PLUS_ROADMAP.md` with milestone plan, owners, priorities, risks, and exit checklist

6. `4f36a0f` — **fix: harden dual-leg streaming ports and integration test reliability**
   - Replaces hardcoded host-side legacy ports in setup/test scripts with config-driven host ports (`9102`/`9192`)
   - Adds timeout guards to integration command helpers and improves test diagnostics
   - Adds Cassandra readiness retry in container-stack integration tests
   - Aligns Windows and Kafka/HCD result docs with active host port mapping

---

## Operational Impact

### Default Runtime

- **Active path**: `ARKEA_LEG=podman`
- **Host ports**: Cassandra `9102`, Kafka `9192`
- **Internal container ports**: Cassandra `9042`, Kafka `9092` (valid in `podman exec` context)

### Safety Controls

- Binary leg blocked by default policy
- Active docs/test-doc host-port leak guard enabled
- `make audit-active` available for focused active-scope auditing

---

## Validation Summary

- `make check` ✅ passed
- Unit test suite ✅ passed (`132 passed`)
- Active docs/test docs host-port guard ✅ passed
- Branch synced to remote `main` ✅

---

## Known Follow-Ups (Road to A+)

Tracked in `A_PLUS_ROADMAP.md`:

- CI gate hardening on active path
- Full leg-aware parity for remaining peripheral scripts/tests
- Final legacy containment and governance automation
