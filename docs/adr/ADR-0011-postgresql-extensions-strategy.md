# ADR-0011: PostgreSQL Extensions Strategy

| | |
|---|---|
| **Status** | Accepted |
| **Sprint** | Sprint 0 — Infrastructure Foundation |
| **Related** | [ADR-0031: Metrics Exporters](ADR-0031-metrics-exporters.md), [PostgreSQL Internals (Reference)](../concepts/postgresql-internals.md), [PostgreSQL Runbook](../runbooks/postgres-runbook.md) |

## Context

No Jovavia service has a schema yet — Sprint 0 creates five empty databases (see ADR-0010), nothing more. Extensions still matter at this stage for one reason: instance-level query performance visibility, which is a monitoring concern, not a schema concern, and which is expensive to retrofit later because one class of extension configuration (`shared_preload_libraries`) can only be changed with a full PostgreSQL restart, not applied live.

## Decision

Enable exactly one extension mechanism at the server level: `shared_preload_libraries = 'pg_stat_statements'` in `postgresql.conf`. No other PostgreSQL extension is loaded, created, or planned for at Sprint 0 — no `pgcrypto`, no `uuid-ossp`, no `pg_trgm`, nothing schema-oriented, because no schema exists yet to need them.

## Consequences

`pg_stat_statements` begins collecting per-query-shape execution statistics (calls, total time, rows) in shared memory the moment PostgreSQL starts, because `shared_preload_libraries` loading happens at server start regardless of any per-database action. This is the honest gap worth stating plainly: loading the library is not the same as activating the extension. Querying the `pg_stat_statements` view requires `CREATE EXTENSION pg_stat_statements;` to have been run *inside* a specific database, and `scripts/bootstrap-postgres.sh` (see ADR-0012) does not run that statement in any of the five Jovavia databases today. As implemented, `pg_stat_statements` is preloaded and collecting, but not yet queryable via SQL in any database, and not yet exposed through `postgres_exporter` (see ADR-0031) — the data exists in memory but nothing currently reads it out.

Choosing not to preemptively enable other extensions keeps the server's extension surface area minimal and matches this platform's broader pattern of not provisioning ahead of an actual consumer without a specific reason to (contrast with `JOVAVIA_ENV`/`JOVAVIA_REGION`/`JOVAVIA_PLATFORM` in `.env.example`, which *are* deliberately pre-provisioned — the difference is that those are free to leave unused, while an unused extension is server-level surface area with its own upgrade and compatibility considerations).

## Alternatives

| Option | Why not chosen |
|---|---|
| No extensions at all | `pg_stat_statements` is the standard, low-overhead way to get query-level performance visibility, and `shared_preload_libraries` is a restart-only setting — better to pay that cost now, upfront, than as a disruptive change once real query traffic exists to want visibility into. |
| Preemptively enable common schema-oriented extensions (`pgcrypto`, `uuid-ossp`, `pg_trgm`) now | No schema exists yet in any Jovavia database to consume them (see the [Decisions Log](../decisions.md)'s explicit note that no migration tool is needed yet because "no schema exists yet to migrate") — enabling extensions with no current consumer is speculative surface area, not a justified decision. |
| Run `CREATE EXTENSION pg_stat_statements;` in `bootstrap-postgres.sh` now, closing the activation gap immediately | The correct near-term fix, but not yet implemented — recorded here as Future Evolution rather than claimed as done. |

## Future Evolution

Add `CREATE EXTENSION IF NOT EXISTS pg_stat_statements;` to `scripts/bootstrap-postgres.sh` for each of the five databases, so the view this ADR's decision already pays the restart cost for is actually queryable. Once queryable, expose it through `postgres_exporter`'s custom-queries feature (already tracked as a Future Improvement in ADR-0031 and [PostgreSQL Internals (Reference)](../concepts/postgresql-internals.md)) so query-level performance data reaches Prometheus and Grafana alongside the instance-level metrics already collected. Revisit additional extensions only when a concrete schema or service need actually justifies one — not preemptively.
