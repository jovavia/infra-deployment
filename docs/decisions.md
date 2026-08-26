# Decisions Log

A running index of every architecturally significant decision made in `infra-deployment`, Sprint 0. Full-format ADRs live in `docs/adr/` and are linked below; smaller decisions that shaped the codebase but don't warrant a standalone ADR are recorded directly in this log, in the same spirit — a decision, its reasoning, and what would trigger revisiting it.

## Purpose

Six months from now, someone will ask "why is it built this way?" about something in this repository. This document exists so the answer is "read the log," not "ask whoever remembers" or, worse, "reverse-engineer it from the code." Every row below links to the file where the decision is actually implemented.

## Full ADRs

| ID | Title | Status | Summary |
|---|---|---|---|
| [ADR-0027](adr/ADR-0027-pgbouncer-architecture.md) | PgBouncer Connection Pooling Architecture | Accepted | Every service connects through PgBouncer in transaction-pooling mode, never directly to PostgreSQL. |
| [ADR-0031](adr/ADR-0031-metrics-exporters.md) | Metrics Exporters | Accepted | `postgres_exporter` and `pgbouncer_exporter` as dedicated sidecar containers translate SQL-shaped state into Prometheus's scrape format. |
| [ADR-0032](adr/ADR-0032-grafana-provisioning.md) | Grafana Provisioning | Accepted | File-based provisioning (datasources + dashboards) reconciled on every container start; documents the `foldersFromFilesStructure` behavior. |
| [ADR-0033](adr/ADR-0033-prometheus-alerting.md) | Prometheus Alerting Rules | Accepted, partially implemented | Four alert rules across two components; explicitly records the absence of Alertmanager as an accepted, temporary Sprint 0 gap. |

## Smaller Decisions

**One PostgreSQL instance, five logical databases (not five instances).** `bootstrap-postgres.sh` creates `jovavia_identity`, `jovavia_pulse`, `jovavia_guardian`, `jovavia_vault`, `jovavia_event_mesh` inside one `postgres:17` container. Chosen over five separate instances to avoid multiplying operational surface (connections, backups, resource limits) for isolation `pg_hba.conf`/role-based access already provides within one instance. Revisit if any single Jovavia database's load profile requires independent scaling or failure isolation from the others. See [Infrastructure Overview](architecture/infrastructure-overview.md) and [Bootstrap Database](setup/bootstrap-database.md).

**PostgreSQL 17, pinned, no `:latest` anywhere in the stack.** Every image across all six services is version-pinned (see [Infrastructure Overview](architecture/infrastructure-overview.md) Configuration table). Deliberate: reproducible builds, deliberate upgrade decisions instead of silent drift on every `docker pull`.

**Docker Compose `include:` composition over a monolithic `docker-compose.yml`.** One file per component under `docker/<component>/`, orchestrated by a root file containing only an `include:` list. Chosen for isolation of concerns and a clean migration path (each component file maps to one future Kubernetes manifest/Helm subchart). Cost: cross-file dependencies (network ownership, `depends_on` chains) are less discoverable than in one file. Full reasoning in [Docker Compose Architecture](architecture/docker-compose-architecture.md).

**Config mounted from files, never baked into images.** `postgresql.conf`, `pg_hba.conf`, `pgbouncer.ini.template`, `prometheus.yml`, `alert.rules.yml`, and Grafana's provisioning YAML are all mounted read-only from the repository, not embedded in custom-built images. Every service uses an unmodified upstream image. Chosen so the entire runtime configuration is visible and diffable in version control, and so no custom image build/registry pipeline is needed at this stage.

**`.env` for configuration and credentials, git-ignored, templated by `.env.example`.** Standard, low-infrastructure-cost pattern appropriate for local development. Explicitly flagged across [Environment Variables](setup/environment-variables.md), [PgBouncer Runbook](runbooks/pgbouncer-runbook.md), and [Grafana Runbook](runbooks/grafana-runbook.md) as needing replacement by a real secrets manager before any shared/production environment — this decision's scope is deliberately bounded to Sprint 0.

**Database creation via idempotent script, not baked into the Postgres image or a migration tool.** `bootstrap-postgres.sh`'s `WHERE NOT EXISTS ... \gexec` pattern creates the five Jovavia databases safely on repeated runs. Chosen over image-embedded `CREATE DATABASE` (inflexible, requires image rebuild to change) and over a full migration tool (unjustified overhead for "create five fixed databases once"). Revisit if database provisioning becomes dynamic (e.g., per-tenant). See [Bootstrap Database](setup/bootstrap-database.md).

**No schema migration tool (Flyway/Liquibase) yet — no schema exists yet to migrate.** Sprint 0 creates databases, not tables. This decision is scoped narrowly: the moment any Jovavia service needs its first table, a migration tool decision becomes necessary and should be made per-service (each Jovavia database likely belongs to one owning service, which should own its own migration history).

**Alertmanager deliberately deferred, not forgotten.** Recorded explicitly in [ADR-0033: Prometheus Alerting Rules](adr/ADR-0033-prometheus-alerting.md) rather than left as a silent gap discovered later — alert rules exist and evaluate correctly; nothing routes a firing alert to a human yet. This is the most important entry in this log to re-read before treating this environment as production-ready or handing it to an on-call rotation.

**Feature Branch Per Infrastructure Milestone.**

- *Context.* `infra-deployment` builds out platform infrastructure incrementally — Postgres and observability first, Redis and Kafka next, individual services after that. Landing all of it on `main` in one branch would make each milestone's review indistinguishable from the others, and would force an all-or-nothing merge decision on work that's naturally separable by component.
- *Decision.* Each infrastructure milestone gets its own feature branch, named `feature/infra-<component>` for platform-level work (`feature/infra-observability`, `feature/infra-redis`, `feature/infra-kafka`) or `feature/<service-name>` once a milestone is service-scoped rather than platform-scoped (`feature/identity-service`). A branch is only merged to `main` after a dedicated documentation cleanup review confirms `docs/` is 100% consistent with what the branch actually implements — the review this very log entry was added during is an instance of that process for `feature/infra-observability`.
- *Consequences.* Each milestone is reviewable and revertible independently, and `main` always reflects a state where implementation and documentation agree. The cost is more branches to track and a documentation-cleanup step that must not be skipped under deadline pressure — skipping it is exactly how the drift this log exists to prevent (see Troubleshooting above) gets introduced in the first place.

## Operational Notes

New entries in either table should be added at the time the decision is made, not reconstructed later from memory — the value of this log is proportional to how close to the decision it was written.

## Troubleshooting

If a decision recorded here appears to no longer match the actual code, treat the code as ground truth and flag the discrepancy for correction — this log is a record of intent and reasoning, not a substitute for reading the actual configuration when the two disagree.

## Production Considerations

Several entries above ("Smaller Decisions") are explicitly scoped to Sprint 0's local-development context and are flagged as needing revisiting before production use — this log doubles as a pre-production checklist by search: every occurrence of "revisit," "before any shared," or "deferred" above is a known, tracked gap, not an oversight.

## Future Improvements

- As Sprint 1+ introduces per-service schema ownership, add a decision entry (or a full ADR, if the choice is non-obvious) for each service's migration tool choice.
- Once Alertmanager, secrets management, and network segmentation land (all referenced above as deferred), update their entries here from "deferred" to "resolved," linking to the ADR or PR that closed the gap — keeping this log a living record rather than a Sprint 0 snapshot.
