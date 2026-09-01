# Jovavia Repository Conventions

**Status:** Active

**Owner:** Platform Team

**Last Updated:** 2026-09-02

---

## Purpose

This document defines the engineering conventions used across the Jovavia platform repository.

Goals:

* Keep infrastructure modules consistent.
* Make the repository cloud-native and Kubernetes-ready.
* Maintain clean Git history and release management.
* Standardize documentation, ADRs, CI/CD, and naming.

This document is the source of truth for repository structure and contribution guidelines.

---

# 1. Repository Structure

The repository follows a **platform-first** layout.

```text
infra-deployment/
├── docker/                 # Infrastructure modules
│   ├── postgres/
│   ├── pgbouncer/
│   ├── prometheus/
│   ├── grafana/
│   ├── redis/
│   ├── kafka/              # Future
│   ├── loki/               # Future
│   └── tempo/              # Future
│
├── docs/
│   ├── adr/
│   ├── architecture/
│   ├── runbooks/
│   ├── diagrams/
│   └── REPOSITORY_CONVENTIONS.md
│
├── scripts/
│   ├── setup.sh
│   ├── cleanup.sh
│   └── smoke-tests.sh      # Future
│
├── .github/
│   └── workflows/
│
├── docker-compose.yml
├── .env.example
└── README.md
```

### Principles

* Every infrastructure component lives under `docker/<module>`.
* Documentation lives under `docs/`.
* Repository-level scripts live under `scripts/`.
* CI/CD configuration lives under `.github/workflows`.

---

# 2. Infrastructure Module Layout

Every module follows the same layout.

```text
docker/<module>/
├── docker-compose.yml
├── conf/
├── scripts/
├── data/
└── dashboards/             # Optional
```

### Directory Responsibilities

| Directory     | Purpose                                       |
| ------------- | --------------------------------------------- |
| `conf/`       | Runtime configuration templates.              |
| `scripts/`    | Bootstrap, health check, operational scripts. |
| `data/`       | Local development persistence only.           |
| `dashboards/` | Grafana dashboards for the module.            |

### Rules

* Never mount individual config files directly.
* Mount configuration directories (`/config`) instead.
* Scripts are mounted under `/scripts`.
* All executable scripts must have executable permission.

---

# 3. Naming Conventions

## Repository Codename

**Jovavia** is the internal codename of this project.

### Use "Jovavia"

* Repository name.
* Architecture context.
* ADR context.
* Git history.
* GitHub Releases.

### Do NOT Prefix Everything With Jovavia

Prefer generic infrastructure names.

| Good                     | Avoid                         |
| ------------------------ | ----------------------------- |
| `PostgreSQL Overview`    | `Jovavia PostgreSQL Overview` |
| `Redis Cluster Overview` | `Jovavia Redis Dashboard`     |
| `postgres`               | `jovavia-postgres`            |
| `redis-node-1`           | `jovavia-redis-node-1`        |

This keeps future rebranding simple.

---

## Environment Variables

Environment variables use uppercase snake case.

```bash
PROJECT_NAME=jovavia

POSTGRES_USER=
POSTGRES_PASSWORD=
POSTGRES_PORT=

REDIS_PASSWORD=
REDIS_BASE_PORT=

GRAFANA_PORT=
PROMETHEUS_PORT=
```

### Rules

* Prefix variables by module.
* Avoid generic names like `PASSWORD`.
* Configuration belongs in `.env.example`.

---

## Docker Resources

### Containers

```text
postgres
pgbouncer
prometheus
grafana
redis-node-1
redis-node-2
```

### Networks

```yaml
networks:
  jovavia-network:
    driver: bridge
```

Do **not** specify `name:`.

---

## Docker Volumes

Development uses bind mounts.

```yaml
./data/node-1:/data
```

Production/Kubernetes uses Persistent Volumes.

---

# 4. Branching Strategy

We follow **GitHub Flow** with feature branches.

## Branch Types

| Branch              | Purpose                 |
| ------------------- | ----------------------- |
| `main`              | Stable branch.          |
| `feature/infra-*`   | Infrastructure modules. |
| `feature/service-*` | Application services.   |
| `feature/docs-*`    | Documentation only.     |
| `hotfix/*`          | Critical fixes.         |

### Examples

```text
feature/infra-postgres
feature/infra-redis
feature/infra-kafka

feature/service-identity
feature/service-notification
```

---

# 5. Commit Message Convention

We use **Conventional Commits**.

## Build

```text
build: add Redis cluster infrastructure module
```

## Feature

```text
feat: bootstrap Redis cluster automatically
```

## Documentation

```text
docs: add Redis cluster runbook
```

## Refactor

```text
refactor: simplify Prometheus scrape configuration
```

## Fix

```text
fix: expose Redis cluster bus ports
```

## Chore

```text
chore: update Grafana dashboard provisioning
```

### Rules

* One logical change per commit.
* Every commit must leave the repository runnable.
* Do not commit placeholder files.

---

# 6. Pull Request Guidelines

Every infrastructure PR should answer:

## What changed?

Example:

* Added Redis infrastructure module.
* Added runtime configuration templating.

## Why?

Explain architectural motivation.

## Validation

List commands executed.

```bash
docker compose config
docker compose up -d
docker compose ps
```

## Future Work

Mention intentionally deferred items.

---

# 7. ADR Convention

Architecture Decision Records live under:

```text
docs/adr/
```

### Naming

```text
ADR-0040-redis-cluster-topology.md
ADR-0041-redis-cluster-bootstrap.md
```

### Title Format

Good:

```text
ADR-0040 Redis Cluster Topology
```

Avoid:

```text
ADR-0040 Redis Cluster for Jovavia
```

### ADR Template

Every ADR contains:

* Status
* Context
* Decision
* Alternatives
* Consequences

---

# 8. Documentation Standards

## Markdown

* Use fenced code block languages.
* End every file with a newline.
* Pass `markdownlint`.

## Runbooks

Every module eventually includes:

```text
docs/runbooks/
    postgres-runbook.md
    pgbouncer-runbook.md
    redis-runbook.md
```

Runbooks contain:

* Health checks.
* Common failures.
* Recovery steps.
* Validation commands.

---

## Architecture Docs

Live under:

```text
docs/architecture/
```

Examples:

* Redis Cluster
* Kafka Event Bus
* Identity Service
* Observability Stack

---

# 9. GitHub Actions Standards

Every module adds validation before merge.

## Required Checks

| Check                        | Status                     |
| ---------------------------- | -------------------------- |
| Docker Compose validation    | Required                   |
| YAML lint                    | Required                   |
| Markdown lint                | Required                   |
| ShellCheck                   | Required                   |
| Prometheus config validation | Required (when applicable) |

### Optional Future Checks

* Hadolint.
* Trivy image scan.
* Checkov Terraform scan.
* Kubernetes manifest validation.

---

# 10. Release Strategy

## Feature Branch Workflow

```text
feature branch
      ↓
GitHub Actions
      ↓
PR Review
      ↓
Merge to main
```

## Tags

Tags follow semantic versioning.

```text
v0.1.0
v0.2.0
v0.3.0
v1.0.0
```

Do **not** include the project name in tags.

---

## Releases

Every release contains:

* Summary.
* New infrastructure modules.
* ADRs introduced.
* Runbooks added.

---

# 11. Cloud-Native Design Principles

Every infrastructure module must be portable to Kubernetes.

## Rules

* Configuration through environment variables.
* Runtime templates under `/config`.
* Operational scripts under `/scripts`.
* No hardcoded passwords.
* No Docker-specific paths inside application configuration.

### Topology Is Configuration

Values like:

* Redis masters.
* Kafka brokers.
* Replica count.

must come from configuration (`.env`, Helm values, Terraform variables), not hardcoded scripts.

---

# 12. Observability Standard

Every infrastructure component eventually ships with:

| Artifact                 | Required |
| ------------------------ | -------- |
| Exporter                 | ✅        |
| Prometheus scrape config | ✅        |
| Grafana dashboard        | ✅        |
| Alert rules              | ✅        |
| Runbook                  | ✅        |

Examples:

* PostgreSQL Exporter
* PgBouncer Exporter
* Redis Exporter

---

# 13. Security Rules

## Never Commit

* Real passwords.
* API keys.
* Tokens.
* Certificates.
* Generated user lists.

## Allowed

`.env.example` contains placeholders and development defaults only.

Secrets belong in:

* Local `.env`.
* GitHub Secrets.
* Kubernetes Secrets (future).

---

# 14. Testing Rules

Infrastructure commits should include smoke tests before merge.

Example Redis validation:

```bash
docker compose config

docker compose up -d redis-node-1 redis-node-2

docker compose ps

docker compose exec redis-node-1 redis-cli ping
```

If smoke tests fail, the commit should not be merged.

---

# 15. Repository Philosophy

Jovavia is built as a production-grade platform engineering portfolio.

Design priorities:

1. Cloud-native first.
2. Infrastructure as Code.
3. Observable by default.
4. Secure by default.
5. Kubernetes-ready.
6. Small, reviewable commits.
7. Documentation and ADRs evolve alongside implementation.

This repository favors long-term maintainability over short-term convenience.
