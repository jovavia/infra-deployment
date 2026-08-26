# ADR-0012: Database Bootstrap Strategy

| | |
|---|---|
| **Status** | Accepted |
| **Sprint** | Sprint 0 — Infrastructure Foundation |
| **Related** | [ADR-0010: PostgreSQL Multi-Database Strategy](ADR-0010-postgresql-multi-database-strategy.md), [Bootstrap Database](../setup/bootstrap-database.md), [Local Development Setup](../setup/local-development.md) |

## Context

The five Jovavia databases ADR-0010 establishes have to actually get created somewhere, by something, in a way that's safe to run more than once — every developer onboarding, every fresh environment, and every manual re-run needs the same five databases to end up existing, without erroring out or duplicating work on the databases that already exist.

## Decision

`scripts/bootstrap-postgres.sh` — a standalone bash script, not wired into any automatic startup hook — that a developer runs manually after `docker compose up -d` (`./scripts/bootstrap-postgres.sh`, per [Local Development Setup](../setup/local-development.md)). It sources `.env`, then loops over a hardcoded list of five database names, running one SQL statement per database against the running `postgres` container via `docker compose exec -T`:

```sql
SELECT 'CREATE DATABASE ${DB}'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = '${DB}'
)\gexec
```

This conditionally generates and then executes (`\gexec`) a `CREATE DATABASE` statement — but only when the database doesn't already exist. PostgreSQL, unlike MySQL, has no `CREATE DATABASE IF NOT EXISTS`; this `\gexec` pattern is the idiomatic Postgres workaround.

## Consequences

The script is safe to run on every deploy, every onboarding, and every re-run with no "has this already run" flag anywhere — re-running it against five already-existing databases is a clean no-op. It is deliberately not automatic: nothing triggers it from `docker compose up -d` itself, so a developer who forgets the step gets connection failures against databases that simply don't exist yet, not a startup error (see [Local Development Setup](../setup/local-development.md) Troubleshooting). The database list is hardcoded in the script's `DBS=(...)` array, not driven by `.env` or any other config — adding a sixth database means editing the script directly, not changing configuration. There is no corresponding teardown or rollback script (no `DROP DATABASE` counterpart) — the design goal is safe, repeated, additive execution only. Database creation happening in an imperative script rather than a declarative migration tool also means there's no record of *when* each database was actually created in a running environment, separate from Git's own history of this file — acceptable at five static, rarely-changing databases; a real gap the moment provisioning becomes more dynamic.

## Alternatives

| Option | Why not chosen |
|---|---|
| PostgreSQL image's built-in `/docker-entrypoint-initdb.d/` init scripts | Those only run once, against an empty data directory on first container initialization — they can't idempotently reconcile a database added to the list later without wiping the existing volume, which defeats the point of a safe, re-runnable bootstrap step. |
| A full schema migration tool (Flyway, golang-migrate) for database creation | Unjustified overhead for "create five fixed databases once" when no schema exists yet to migrate (see the [Decisions Log](../decisions.md)) — the right tool once each database actually has tables to migrate, not before. |
| Bake `CREATE DATABASE` statements into a custom Postgres image | Requires an image rebuild to add or change a database, and contradicts this stack's broader choice to run only unmodified upstream images with configuration mounted from files (see [Decisions Log](../decisions.md)). |

## Future Evolution

Convert to a proper migration-tool-managed step if database provisioning grows beyond "create these fixed five databases once" — e.g., once per-database schema migrations exist, unifying database creation and schema migration under one tool avoids maintaining two separate mechanisms side by side. Populate the repository's currently-empty `Makefile` with a `make bootstrap` target wrapping this script, consistent with the broader Makefile-automation gap already tracked in [Docker Compose Architecture](../architecture/docker-compose-architecture.md) and [Local Development Setup](../setup/local-development.md). Consider parameterizing the database list via configuration rather than a hardcoded array if the platform anticipates the database count changing per-environment.
