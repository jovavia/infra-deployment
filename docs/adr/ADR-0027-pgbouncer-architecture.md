# ADR-0027: PgBouncer Connection Pooling Architecture

| | |
|---|---|
| **Status** | Accepted |
| **Sprint** | Sprint 0 — Infrastructure Foundation |
| **Referenced by** | `docker/pgbouncer/conf/pgbouncer.ini.template` (header comment cites this ADR directly) |
| **Related** | [ADR-0031: Metrics Exporters (postgres_exporter, pgbouncer_exporter)](ADR-0031-metrics-exporters.md), [Connection Pooling & PgBouncer (Reference)](../concepts/connection-pooling-and-pgbouncer.md) |

## Purpose

Decide how Jovavia services connect to PostgreSQL: directly, or through a pooling layer — and if pooled, in which pooling mode. This ADR records that decision and the reasoning, so the choice of **PgBouncer in transaction-pooling mode** isn't re-litigated from scratch every time a new service is added.

## Architecture

**Context.** PostgreSQL allocates a full backend OS process per connection, with meaningful fixed memory overhead (roughly 5–10MB per backend) regardless of whether that connection is actively running a query. `postgresql.conf` sets `max_connections = 300`. Jovavia is a multi-service platform (`jovavia_identity`, `jovavia_pulse`, `jovavia_guardian`, `jovavia_vault`, `jovavia_event_mesh` — see [Bootstrap Database](../setup/bootstrap-database.md)) where each service, scaled horizontally, would otherwise hold its own connection pool directly against Postgres. A handful of services at a handful of replicas each easily exceeds 300 raw connections, especially once connection pool libraries on the client side (HikariCP, pgbouncer-less driver pools, etc.) default to holding idle connections open rather than closing them between requests.

**Decision.** Every service connects to PgBouncer (`:6432`), never to PostgreSQL (`:5432`) directly, except for administrative/migration tooling. PgBouncer runs in **transaction pooling mode** (`pool_mode = transaction`): a server-side Postgres connection is assigned to a client only for the duration of a single transaction, then returned to the pool immediately — not held for the client's entire session.

```mermaid
sequenceDiagram
    participant S as Jovavia Service
    participant PB as PgBouncer :6432
    participant PG as PostgreSQL :5432

    S->>PB: BEGIN; SELECT ...
    PB->>PG: assign idle server connection
    PG-->>PB: result
    PB-->>S: result
    S->>PB: COMMIT
    PB->>PG: COMMIT
    PB->>PB: return server connection to pool (available for a DIFFERENT client)
    Note over PB: Client's logical session persists;<br/>the underlying server connection does not.
```

**Alternatives considered:**

| Option | Why not chosen |
|---|---|
| No pooling (direct-to-Postgres) | Doesn't scale past a handful of service replicas before hitting `max_connections`; every new service or replica directly reduces headroom for every other service. |
| Session pooling mode | Holds a server connection for the client's entire session (until disconnect) — closer to direct connections in resource cost, defeats most of the purpose of pooling for typically-short-lived HTTP-request-scoped database usage. |
| Statement pooling mode | Maximum multiplexing, but breaks multi-statement transactions and most session-level features (prepared statements, `SET` variables) — too restrictive for general-purpose service use without significant application-level constraints. |
| Client-side pooling only (e.g., HikariCP per service, no PgBouncer) | Doesn't solve the cross-service aggregate connection problem — each service's pool is sized independently with no shared view of total load against Postgres. |

Transaction pooling was chosen as the correct middle ground: high connection multiplexing (many clients share few server connections) while remaining compatible with normal transactional service code, at the cost of session-level features most services don't need (see Production Considerations for exactly which features that excludes).

## Configuration

```ini
# docker/pgbouncer/conf/pgbouncer.ini.template (excerpt)
[databases]
* = host=${POSTGRES_HOST} port=${POSTGRES_PORT} auth_user=${POSTGRES_USER}

[pgbouncer]
pool_mode = ${PGBOUNCER_POOL_MODE}          # transaction
max_client_conn = ${PGBOUNCER_MAX_CLIENT_CONN}       # 5000
default_pool_size = ${PGBOUNCER_DEFAULT_POOL_SIZE}   # 50
reserve_pool_size = ${PGBOUNCER_RESERVE_POOL_SIZE}   # 20
reserve_pool_timeout = ${PGBOUNCER_RESERVE_POOL_TIMEOUT}  # 5s
query_wait_timeout = ${PGBOUNCER_QUERY_WAIT_TIMEOUT}      # 120s
server_idle_timeout = ${PGBOUNCER_SERVER_IDLE_TIMEOUT}    # 300s
server_lifetime = ${PGBOUNCER_SERVER_LIFETIME}            # 3600s
```

The `[databases]` wildcard entry (`* = host=... port=... auth_user=...`) is deliberate: rather than one stanza per Jovavia database, PgBouncer transparently proxies a connection request for *any* database name that exists on the target Postgres instance to that same instance — meaning all five Jovavia databases are poolable through this one PgBouncer instance with zero config changes when a sixth database is added by [Bootstrap Database](../setup/bootstrap-database.md)'s script.

The client-facing credential this ADR's config relies on (`auth_file`, referenced from `pgbouncer.ini.template`) is not a file committed to git — it's templated from `${POSTGRES_USER}`/`${POSTGRES_PASSWORD}` and generated fresh at container startup (`userlist.template` → `start-pgbouncer.sh` → `/tmp/userlist.txt`), so no plaintext password lives in version control. Full mechanics in [PgBouncer Runbook](../runbooks/pgbouncer-runbook.md).

`default_pool_size = 50` is per-database, per-user — meaning the effective ceiling on concurrent server connections PgBouncer will open is `50 × (number of distinct database/user pairs actually used)`, well under `max_connections = 300`, leaving headroom for direct administrative connections and `reserve_pool_size`'s burst capacity.

## Operational Notes

Because transaction pooling returns the server connection between transactions, **connection count in `pg_stat_activity` reflects active transaction load, not client count** — this is the entire point, and it's also the thing most likely to confuse someone debugging "why does Postgres show fewer connections than PgBouncer's client count." `pgbouncer_pools_client_active_connections` (client-facing) and `pgbouncer_pools_server_active_connections` (Postgres-facing) are two different, independently-meaningful metrics — both are on the custom PgBouncer Grafana dashboard (see [Observability](../architecture/observability.md)).

## Troubleshooting

**Clients see `query_wait_timeout` errors under load.** All 50 (per default_pool_size) server connections for a database/user pair are busy longer than 120 seconds. This is either a genuine capacity problem (raise `default_pool_size`, verify Postgres has headroom under `max_connections` to support it) or a symptom of slow queries holding transactions open longer than expected — check `pg_stat_activity` for long-running transactions before assuming pool sizing is the fix. See [PgBouncer Runbook](../runbooks/pgbouncer-runbook.md).

**A service reports "prepared statement does not exist" or session-variable-related errors.** Transaction pooling mode does not guarantee the same underlying server connection across transactions, which breaks session-scoped state: `SET` statements outside a transaction, session-level advisory locks held across transactions, and (depending on driver) server-side prepared statements not re-issued per transaction. This is a known, accepted limitation of the chosen pooling mode — the fix is application-level (issue `SET LOCAL` inside transactions instead of session-level `SET`; use client-side/protocol-level prepared statement handling that's pool-safe), not a PgBouncer config change.

## Production Considerations

- `default_pool_size = 50` and `reserve_pool_size = 20` were chosen as reasonable defaults for Sprint 0's single-instance, no-real-traffic state — they have not been load-tested against actual Jovavia service traffic patterns and should be revisited with real numbers before this is trusted as a production capacity plan.
- `max_client_conn = 5000` is generous headroom on the client-facing side — appropriate given PgBouncer's own per-client memory cost is far lower than Postgres's per-backend cost, but still worth monitoring (`pgbouncer_pools_client_active_connections` + `pgbouncer_pools_client_waiting_connections`) rather than assumed infinite.
- Transaction pooling mode's incompatibility with session-level Postgres features needs to be a documented constraint for every Jovavia service author, not just infrastructure — an ORM or query builder that assumes session semantics (some connection-pooling-unaware ORM configurations do) will fail in ways that are confusing to debug without knowing this ADR exists.

## Future Improvements

- Load-test `default_pool_size`/`reserve_pool_size` against representative Jovavia service traffic once real services exist, and tune from measured data rather than defaults.
- Consider per-database pool sizing (moving from the wildcard `[databases] * = ...` entry to explicit per-database stanzas) if the five Jovavia databases develop meaningfully different load profiles — the wildcard entry is simplicity-optimized today, not load-optimized.
- On Kubernetes migration, evaluate PgBouncer as a per-service sidecar versus a shared Deployment — the current single-shared-instance model is simplest operationally but is a single point of failure and a shared blast radius for pool exhaustion across all five databases and all Jovavia services.
