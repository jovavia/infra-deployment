# ADR-0003: Environment Configuration Strategy

| | |
|---|---|
| **Status** | Accepted |
| **Sprint** | Sprint 0 — Infrastructure Foundation |
| **Related** | [ADR-0001: Monorepo Platform Structure](ADR-0001-monorepo-platform-structure.md), [Environment Variables](../setup/environment-variables.md), [Local Development Setup](../setup/local-development.md) |

## Context

Six independently-composed services (ADR-0002) need a shared set of configuration values — hostnames, ports, credentials, pool sizes — without duplicating those values six times or hardcoding them into any compose file. At the same time, real credentials (`POSTGRES_PASSWORD`, `GRAFANA_ADMIN_PASSWORD`) must never end up committed to a shared repository.

## Decision

One `.env` file at the repository root, git-ignored, holds every configuration value the stack needs. Every component's `docker-compose.yml` independently declares `env_file: [../../.env]` — one physical file, read six times, rather than one shared variable namespace assembled some other way. `.env.example` is the committed template every developer copies from (`cp .env.example .env`) and is the actual source of truth for which variables exist and what their documented defaults are.

Three platform-identity variables — `JOVAVIA_ENV`, `JOVAVIA_REGION`, `JOVAVIA_PLATFORM` — are present in `.env.example` today even though no current compose file reads them; they're provisioned ahead of the components in the platform's roadmap that will need them, rather than added later as a breaking change to `.env.example`'s shape.

## Consequences

A variable used by one service and irrelevant to another is simply ignored by the service that doesn't consume it — not an error, and not something Compose warns about, which means a misspelled variable name in `.env` fails silently into whatever default is baked into the relevant compose file's `${VAR:-default}` syntax (where one exists) rather than failing loudly. `.env` being git-ignored only works because every developer actually follows the convention; nothing technical prevents a real `.env` from being force-added to version control. Because `env_file` values are read at container *creation*, not continuously, a changed `.env` value requires `docker compose up -d --force-recreate <service>` to actually take effect on a running container, not just a restart.

The three not-yet-consumed platform variables are intentional forward-provisioning, not dead configuration — but they currently do nothing, which is itself worth knowing rather than assuming they gate some behavior they don't yet gate.

## Alternatives

| Option | Why not chosen |
|---|---|
| One `.env` file per component (`docker/postgres/.env`, `docker/pgbouncer/.env`, ...) | Fragments a single logical configuration surface across six files, several of which share the same variables (`POSTGRES_HOST`, `POSTGRES_USER`) — recreating, six times over, the exact duplication a single shared `.env` avoids. |
| Bake configuration into custom-built images | Requires an image rebuild to change any value, and contradicts this stack's broader choice (see [Decisions Log](../decisions.md)) to mount configuration from files against unmodified upstream images rather than build custom ones. |
| A secrets manager (Vault, cloud-native equivalent) from Sprint 0 | Real infrastructure dependency and operational overhead not justified for a single-developer local stack — the right choice once this environment leaves a single developer's machine, not before (see Future Evolution). |

## Future Evolution

Wire up `JOVAVIA_ENV` to actually gate environment-specific behavior (stricter `pg_hba.conf` rules, different logging verbosity) once more than one environment shape actually exists to differentiate between. Replace `.env`-file secrets with a real secrets manager for any environment beyond local development — the single highest-leverage security improvement available to this stack, touching PostgreSQL, PgBouncer, and Grafana credentials simultaneously since they all currently trace back to values in this one file.
