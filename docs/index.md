# Jovavia Infrastructure Documentation

Entry point for `infra-deployment` documentation, Sprint 0 — Infrastructure Foundation (`feature/infra-observability`).

## Reading Order

New to this repository? Read in this order — each step assumes the ones before it.

1. **[Local Development Setup](setup/local-development.md)** — get the stack running on your machine first; everything else is easier to follow with it up.
2. **[Infrastructure Overview](architecture/infrastructure-overview.md)** — the map. What exists, why it exists in this shape, and how the pieces fit together.
3. **[Docker Compose Architecture](architecture/docker-compose-architecture.md)** — how the seven Compose files compose into one stack via `include:`.
4. **[Networking](architecture/networking.md)** — how every service finds every other service over `jovavia-network`, and the one ordering dependency that trips people up.
5. **[Observability](architecture/observability.md)** — the exporter → Prometheus → Grafana pipeline, and where it's honestly incomplete.
6. **[ADRs](#adrs)** — the *why* behind the decisions that shaped the above, in full detail.
7. **[Runbooks](#runbooks)** — day-to-day operation, diagnostics, and the specific problems each component is known to hit.
8. **[Concepts](#concepts)** — durable reference material, useful any time after the above rather than in sequence.

## Setup

- [Local Development Setup](setup/local-development.md)
- [Bootstrap Database](setup/bootstrap-database.md)
- [Environment Variables](setup/environment-variables.md)

## Architecture

- [Infrastructure Overview](architecture/infrastructure-overview.md)
- [Docker Compose Architecture](architecture/docker-compose-architecture.md)
- [Networking](architecture/networking.md)
- [Observability](architecture/observability.md)

## ADRs

Full index with reading order: [docs/adr/index.md](adr/index.md).

- [ADR-0001: Monorepo Platform Structure](adr/ADR-0001-monorepo-platform-structure.md)
- [ADR-0002: Docker Compose Modular Architecture](adr/ADR-0002-docker-compose-modular-architecture.md)
- [ADR-0003: Environment Configuration Strategy](adr/ADR-0003-environment-configuration-strategy.md)
- [ADR-0004: Shared Docker Network](adr/ADR-0004-shared-docker-network.md)
- [ADR-0010: PostgreSQL Multi-Database Strategy](adr/ADR-0010-postgresql-multi-database-strategy.md)
- [ADR-0011: PostgreSQL Extensions Strategy](adr/ADR-0011-postgresql-extensions-strategy.md)
- [ADR-0012: Database Bootstrap Strategy](adr/ADR-0012-database-bootstrap-strategy.md)
- [ADR-0027: PgBouncer Connection Pooling Architecture](adr/ADR-0027-pgbouncer-architecture.md)
- [ADR-0031: Metrics Exporters](adr/ADR-0031-metrics-exporters.md)
- [ADR-0032: Grafana Provisioning (File-Based, Not UI/API)](adr/ADR-0032-grafana-provisioning.md)
- [ADR-0033: Prometheus Alerting Rules](adr/ADR-0033-prometheus-alerting.md)
- [Decisions Log](decisions.md) — the running index all of the above (and smaller, non-ADR decisions) are cataloged in.

## Runbooks

- [PostgreSQL Runbook](runbooks/postgres-runbook.md)
- [PgBouncer Runbook](runbooks/pgbouncer-runbook.md)
- [Prometheus Runbook](runbooks/prometheus-runbook.md)
- [Grafana Runbook](runbooks/grafana-runbook.md)

## Concepts

Durable reference material — read any of these whenever the topic comes up, not necessarily in order.

- [Connection Pooling & PgBouncer](concepts/connection-pooling-and-pgbouncer.md)
- [Docker Compose Networking](concepts/docker-compose-networking.md)
- [Grafana Dashboards-as-Code](concepts/grafana-dashboards-as-code.md)
- [PostgreSQL Internals](concepts/postgresql-internals.md)
- [Prometheus & PromQL](concepts/prometheus-and-promql.md)
