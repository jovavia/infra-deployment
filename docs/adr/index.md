# Architecture Decision Records

Every ADR for `infra-deployment`, indexed in numeric order. Each record follows the same shape: Context, Decision, Consequences, Alternatives, Future Evolution. See the [Decisions Log](../decisions.md) for a narrative summary of these plus smaller, non-ADR decisions.

## Implemented

| ID | Title | Status |
|---|---|---|
| [ADR-0001](ADR-0001-monorepo-platform-structure.md) | Monorepo Platform Structure | Accepted |
| [ADR-0002](ADR-0002-docker-compose-modular-architecture.md) | Docker Compose Modular Architecture | Accepted |
| [ADR-0003](ADR-0003-environment-configuration-strategy.md) | Environment Configuration Strategy | Accepted |
| [ADR-0004](ADR-0004-shared-docker-network.md) | Shared Docker Network | Accepted |
| [ADR-0010](ADR-0010-postgresql-multi-database-strategy.md) | PostgreSQL Multi-Database Strategy | Accepted |
| [ADR-0011](ADR-0011-postgresql-extensions-strategy.md) | PostgreSQL Extensions Strategy | Accepted |
| [ADR-0012](ADR-0012-database-bootstrap-strategy.md) | Database Bootstrap Strategy | Accepted |
| [ADR-0027](ADR-0027-pgbouncer-architecture.md) | PgBouncer Connection Pooling Architecture | Accepted |
| [ADR-0031](ADR-0031-metrics-exporters.md) | Metrics Exporters (postgres_exporter, pgbouncer_exporter) | Accepted |
| [ADR-0032](ADR-0032-grafana-provisioning.md) | Grafana Provisioning (File-Based, Not UI/API) | Accepted |
| [ADR-0033](ADR-0033-prometheus-alerting.md) | Prometheus Alerting Rules | Accepted, partially implemented |

**Reading order, if you want one:** ADR-0001 → ADR-0004 establish the repository and its foundational structure (one repo, modular Compose files, one `.env`, one shared network). ADR-0010 → ADR-0012 establish the data layer (multi-database strategy, extensions, bootstrap). ADR-0027 → ADR-0033 establish connection pooling and the observability pipeline on top of that foundation.

**On the numbering.** IDs are not sequential (0001–0004, then 0010–0012, then 0027, 0031–0033) by design, not oversight — gaps are reserved for ADRs that belong conceptually between these (e.g. 0005–0009 for repository- and workflow-level decisions beyond ADR-0001–0004's scope, 0013–0026 for data-layer decisions beyond ADR-0010–0012's scope) rather than forcing every new ADR to the end of the list regardless of topic. A gap in the sequence means "reserved for a related future decision," not "missing" or "deleted."

## Related

- [Decisions Log](../decisions.md) — full index of both ADRs and smaller, non-ADR decisions, in one running log.
- [Documentation Index](../index.md) — the full `docs/` reading order, ADRs included.
