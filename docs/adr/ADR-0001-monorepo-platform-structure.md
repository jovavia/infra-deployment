# ADR-0001: Monorepo Platform Structure

| | |
|---|---|
| **Status** | Accepted |
| **Sprint** | Sprint 0 — Infrastructure Foundation |
| **Related** | [ADR-0002: Docker Compose Modular Architecture](ADR-0002-docker-compose-modular-architecture.md), [Infrastructure Overview](../architecture/infrastructure-overview.md), [Decisions Log](../decisions.md) |

## Context

Sprint 0 stands up six interdependent infrastructure components — PostgreSQL, PgBouncer, two metrics exporters, Prometheus, and Grafana — each with its own configuration files, provisioning assets, and (for PgBouncer) startup scripts. Before deciding how those components compose together at the Docker Compose level (see ADR-0002), a prior question has to be settled: do they live in one repository, or several? The `infra-deployment` repository is also explicitly where `docs/` — architecture, ADRs, runbooks, setup guides — lives, and that documentation constantly cross-links between components (the PgBouncer runbook links to the PostgreSQL runbook, the networking doc links to the Compose architecture doc, and so on).

## Decision

`infra-deployment` is a single repository containing every Sprint 0 infrastructure component under one `docker/` tree (`docker/postgres/`, `docker/pgbouncer/`, `docker/postgres-exporter/`, `docker/pgbouncer-exporter/`, `docker/prometheus/`, `docker/grafana/`), one `scripts/` directory for operational scripts (`bootstrap-postgres.sh`), and one `docs/` tree covering the whole stack — not split into one repository per component. A single root `docker-compose.yml`, one `.env`/`.env.example` pair, and one `README.md` describe the entire platform infrastructure surface from this one repository.

## Consequences

A single `git clone` and a single `docker compose up -d` bring up the entire stack — there is no multi-repository checkout-and-pin-versions step before local development can start. Cross-component changes (e.g., adding a new exporter that both a Prometheus scrape config and a Grafana datasource need to know about) land in one pull request instead of being coordinated across repositories. Documentation cross-linking (see the [Decisions Log](../decisions.md) and every `docs/` file's `Related` links) works with plain relative paths because everything really is in one place.

The cost is that the repository's surface area grows with every component the platform adds, and there is no per-component ownership boundary today — no `CODEOWNERS`, no independent versioning or release cadence per component. A change to Grafana provisioning and a change to PostgreSQL's `pg_hba.conf` currently carry the same review and merge process, because they're the same repository.

## Alternatives

| Option | Why not chosen |
|---|---|
| One repository per component (`infra-postgres`, `infra-pgbouncer`, `infra-prometheus`, ...) | Six repositories for six services is excessive coordination overhead at Sprint 0 scale, and the root `docker-compose.yml`'s `include:` pattern (ADR-0002) would need to reach across repository boundaries — solving a problem this decision avoids by construction. |
| One repository per environment (`infra-local`, `infra-staging`, `infra-prod`) | Environment differences in this stack are `.env` values, not structural differences in which services run — a per-environment repository would triplicate the entire `docker/` tree for no benefit over one repository with environment-specific `.env` files. |
| A single platform monorepo including application/service source code alongside infrastructure | Not chosen for Sprint 0 — no Jovavia service source code exists yet, and `infra-deployment` today contains infrastructure only. Whether a future service like `identity-service` joins this repository or gets its own is explicitly left open (see Future Evolution and the [Decisions Log](../decisions.md)'s Feature Branch Per Infrastructure Milestone entry, which already anticipates a distinctly-scoped `feature/identity-service` branch). |

## Future Evolution

Revisit this decision the moment the first Jovavia service (e.g. `identity-service`) needs source code somewhere — decide deliberately whether it joins `infra-deployment` or gets its own repository, rather than defaulting either way by inertia. Whichever way that goes, keep infrastructure-as-code and application source code separable in principle even if they end up co-located, so a future split is a directory move rather than a rewrite. As components listed in the repository's own `README.md` roadmap are actually implemented, they land under this same repository's `docker/` tree following ADR-0002's pattern — this ADR's scope is "one repository," not which components that repository eventually contains.
