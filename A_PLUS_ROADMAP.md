# A+ Roadmap — ARKEA POC (OSS 5.0)

**Date**: 2026-03-18
**POC**: HBase/HCD → Apache Cassandra 5.0 + Spark + Kafka (Podman)
**TL;DR**: Deliver A+ with honours in 2 sprints by enforcing active-path CI gates, closing leg-aware parity, finalizing legacy containment, and publishing a reproducible validation package.

---

## 1) Objectives (Definition of A+)

- Active runtime path (`ARKEA_LEG=podman`) is fully validated in CI (check + smoke + integration/e2e).
- Documentation is unambiguous (ACTIVE vs LEGACY), with canonical source-of-truth references.
- Legacy is contained (archived or bannered), without interfering with active workflows.
- Operational evidence is reproducible and versioned.

---

## 2) Milestone Plan (1–2 Sprints)

| Milestone | Target Date | Success Criteria |
|---|---:|---|
| M1 — Active Path CI Gate ✅ DONE | 2026-03-24 | CI blocks merges unless `make check`, `make audit-active`, and podman smoke checks pass |
| M2 — Leg-Aware Script/Test Parity | 2026-03-27 | Critical setup/verify/tests are leg-aware or explicitly legacy-blocked |
| M3 — Documentation Finalization | 2026-03-31 | Canonical matrix published; legacy docs archived/bannered; no contradictory active guidance |
| M4 — Validation Evidence Pack | 2026-04-02 | Repeatable validation report committed (commands, outputs, status snapshots) |

---

## 3) Execution Board (Top 10 Actions)

| ID | Action | Owner | Effort | Priority | Status | Acceptance Criteria |
|---|---|---|---|---|---|---|
| A1 | Create canonical runtime matrix (`docs/CANONICAL_RUNTIME_MATRIX.md`) | TL/Architect | S | P0 | TODO | Ports/versions/leg behavior/java matrix published and linked from README + docs index |
| A2 | Add mandatory CI gate for active path (`ARKEA_LEG=podman`) | DevOps | M | P0 | IN_PROGRESS | PR blocked unless active checks pass |
| A3 | Complete leg-aware parity audit for setup/utils scripts | Platform Eng | M | P0 | TODO | Scripts either leg-aware or policy-blocked with explicit message |
| A4 | Add/extend guardrails for host-side legacy ports in active docs/tests | Platform Eng | S | P0 | DONE | `check-ports` + `audit-active` operational and green |
| A5 | Normalize integration/e2e test bootstrap to `.poc-config.sh` | QA/Platform | M | P1 | IN_PROGRESS | Podman lane stable; flaky/brittle port literals removed in active tests |
| A6 | Finalize legacy containment (archive or banner remaining noisy docs) | Tech Writer | M | P1 | IN_PROGRESS | Non-canonical legacy docs are archived/bannered with replacement links |
| A7 | Add PR checklist for runtime-impacting changes | Repo Admin | S | P1 | TODO | Template enforces docs/tests update when runtime behavior changes |
| A8 | Build release-quality validation script/report | QA Lead | S | P1 | TODO | Reproducible report committed with timestamp and outputs |
| A9 | Harden `80_verify_all.sh` messaging per leg (no mixed wording) | Platform Eng | S | P2 | IN_PROGRESS | Podman/binary outputs clearly separated and accurate |
| A10 | Monitoring sanity baseline (Cassandra/Kafka/Spark checks) | Ops | M | P2 | TODO | Minimal health baseline documented and validated |

---

## 4) Sprint Breakdown

### Sprint 1 (Stabilization)

- A1, A2, A3, A4, A5, A7

### Sprint 2 (Honours-Level Confidence)

- A6, A8, A9, A10

---

## 5) Risk Register (Short)

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Legacy instructions reintroduced in active docs | Medium | High | Keep `audit-active` in CI, enforce canonical links |
| Unit tests pass but runtime path regresses | Medium | High | Add podman integration/e2e gate in CI |
| Binary scripts used accidentally | Low | Medium | Maintain policy guard + explicit script headers |

---

## 6) Reporting Cadence

- **Daily (standup)**: A1–A10 status updates (TODO/IN_PROGRESS/BLOCKED/DONE)
- **Twice weekly**: Risk review + blocker escalation
- **End of sprint**: Evidence review against acceptance criteria

---

## 7) Final Exit Checklist (A+ with Honours)

- [ ] `make check` green in CI on active path
- [ ] `make audit-active` green in CI
- [ ] Podman smoke + integration/e2e scenario green
- [ ] Canonical runtime matrix published and referenced
- [ ] Legacy docs fully contained (archive/banner) with no active contradictions
- [ ] Validation evidence package committed and reproducible
