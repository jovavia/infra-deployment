# ADR-0002: Docker Compose Modular Architecture

| | |
|---|---|
| **Status** | Accepted |
| **Sprint** | Sprint 0 — Infrastructure Foundation |
| **Related** | [ADR-0001: Monorepo Platform Structure](ADR-0001-monorepo-platform-structure.md), [ADR-0004: Shared Docker Network](ADR-0004-shared-docker-network.md), [Docker Compose Architecture](../architecture/docker-compose-architecture.md), [Docker Compose Networking (Reference)](../concepts/docker-compose-networking.md) |

## Context

Six services (PostgreSQL, PgBouncer, two exporters, Prometheus, Grafana) need to start together as one stack via a single `docker compose up -d`, inside the one repository ADR-0001 establishes. The straightforward approach — one `docker-compose.yml` with six `services:` entries — stays readable at six services, but Sprint 0 is explicitly the foundation for a platform expected to keep adding components (see Future Evolution); a monolithic file's readability doesn't scale with that growth, and every component's config, provisioning assets, and scripts already need somewhere to live regardless of how the Compose files are organized.

## Decision

Each component gets its own directory under `docker/<component>/`, self-contained with its own `docker-compose.yml`, its own `conf/` (or `provisioning/`) subdirectory, and its own entrypoint scripts where needed (`docker/pgbouncer/start-pgbouncer.sh`). The repository root's `docker-compose.yml` contains no service definitions of its own — its entire content is a Compose Specification `include:` list naming all six component files:

```yaml
# docker-compose.yml (repository root)
include:
  - ./docker/postgres/docker-compose.yml
  - ./docker/pgbouncer/docker-compose.yml
  - ./docker/postgres-exporter/docker-compose.yml
  - ./docker/pgbouncer-exporter/docker-compose.yml
  - ./docker/prometheus/docker-compose.yml
  - ./docker/grafana/docker-compose.yml
```

`include:` merges every referenced file into one logical Compose project at parse time — service names, networks, and volumes resolve against the *combined* project, which is what lets `docker/pgbouncer/docker-compose.yml` reference the `jovavia-network` that a different file, `docker/postgres/docker-compose.yml`, actually owns (see ADR-0004).

## Consequences

Each component directory is a self-contained unit that can be understood, reviewed, and modified without touching the other five — a change to Grafana's provisioning never requires opening PostgreSQL's compose file. Adding a new component means adding one new `docker/<component>/docker-compose.yml` and one new line to the root `include:` list; no existing file needs to change.

The cost is real: cross-file dependencies (the network-ownership pattern in ADR-0004, `depends_on` conditions referencing services defined in a different file) are less discoverable than they'd be in one file, because grepping a single component's `docker-compose.yml` doesn't show what depends on it or what it depends on unless you already know to check the root `include:` list. Running a component's compose file in isolation (`docker compose -f docker/prometheus/docker-compose.yml up`) also behaves differently than running it as part of the full `include:`-merged project — see ADR-0004's network-ownership failure mode.

## Alternatives

| Option | Why not chosen |
|---|---|
| One monolithic `docker-compose.yml` with all services inline | Readable at six services, but doesn't scale with the component growth Sprint 0 is explicitly built toward, and gives every future component author a single, ever-growing file to merge-conflict against. |
| Docker Compose `extends` (the older single-service inheritance mechanism) | A different, narrower mechanism than `include:` — `extends` merges individual service definitions from another file, not whole projects, and doesn't give each component a clean, independently-runnable Compose project the way `include:` does. `include:` is also the current Compose Specification mechanism; `extends` predates it. |
| `docker-compose.override.yml` layering per component | Override files are designed for local, uncommitted developer tweaks layered on top of a base file, not for organizing the base architecture itself — using them for structural composition would invert their intended purpose. |

## Future Evolution

File count grows linearly with components, and that is the intended shape — as the platform adds components beyond Sprint 0's six (per the repository's own `README.md` roadmap), each one follows this same pattern: one `docker/<component>/docker-compose.yml`, one more `include:` line, no existing file touched. Consider Compose `profiles:` per service once component count makes "start just the database layer" a common enough need to justify it over separate compose invocations.
