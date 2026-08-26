# ADR-0010: PostgreSQL Multi-Database Strategy

| | |
|---|---|
| **Status** | Accepted |
| **Sprint** | Sprint 0 — Infrastructure Foundation |
| **Related** | [ADR-0012: Database Bootstrap Strategy](ADR-0012-database-bootstrap-strategy.md), [Infrastructure Overview](../architecture/infrastructure-overview.md), [Bootstrap Database](../setup/bootstrap-database.md) |

## Context

Jovavia is a multi-service platform with five distinct logical domains established at Sprint 0 — identity, pulse, guardian, vault, and event mesh. Each needs its own data boundary before any service-level code exists to actually use it. The question this ADR settles: does each domain get its own PostgreSQL instance, or do all five share one instance as separate logical databases?

## Decision

One PostgreSQL 17 container (`docker/postgres/docker-compose.yml`) holds five logical databases — `jovavia_identity`, `jovavia_pulse`, `jovavia_guardian`, `jovavia_vault`, `jovavia_event_mesh` — created by `scripts/bootstrap-postgres.sh` (see ADR-0012) rather than five separate PostgreSQL containers.

## Consequences

Real isolation between the five databases — separate catalogs, separate connection namespaces, no cross-database queries by default — without multiplying operational surface: one set of connections to size (`max_connections = 300` in `postgresql.conf`), one backup target, one set of resource limits, one container to keep healthy, instead of five of each. `pg_hba.conf` and role-based access control already provide the isolation five separate instances would otherwise exist to provide, so splitting into five instances would buy protection this stack doesn't actually lack.

The cost: all five databases share fate. A `postgres` container problem (resource exhaustion, a bad config reload, a stuck long-running transaction in one database) affects all five Jovavia domains simultaneously — there is no failure isolation between `jovavia_identity` being under load and `jovavia_vault` staying healthy. There is also no independent scaling: all five databases share `shared_buffers`, `work_mem`, and the same connection ceiling, so one domain's load profile can pressure another's headroom.

## Alternatives

| Option | Why not chosen |
|---|---|
| One PostgreSQL instance per Jovavia domain (five containers) | Multiplies operational surface — five sets of connections, five backup jobs, five sets of resource limits, five containers to keep healthy — for an isolation benefit `pg_hba.conf` and role-based access control already provide within one instance at Sprint 0's scale. |
| One database, five schemas | Weaker isolation than separate databases — no natural catalog-level boundary, and no clean place to hang per-domain connection or credential separation if that's ever needed, without the schema-qualification discipline every query would then require. |
| One shared database, no logical separation at all (all five domains in one schema) | No isolation whatsoever between domains that are conceptually distinct services — makes it trivial for one domain's code to accidentally read or write another's tables, with nothing structural preventing it. |

## Future Evolution

Revisit if any single Jovavia database's load profile requires independent scaling or failure isolation from the others — the multi-database, single-instance model is a deliberate, revisitable Sprint 0 choice, not a permanent architectural commitment. Horizontal read scaling (read replicas) is a near-certain future need given `wal_level = replica` and `hot_standby = on` are already set in `postgresql.conf` — replication-ready by design even though nothing replicates yet.
