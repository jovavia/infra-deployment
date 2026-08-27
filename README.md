# Jovavia Infrastructure

Production-grade local cloud infrastructure powering the Jovavia platform.

## Components

- PostgreSQL 17
- PgBouncer
- Redis Cluster
- Apache Kafka (KRaft)
- Prometheus
- Grafana
- Loki
- Tempo
- OpenTelemetry Collector

## Usage

```bash
docker compose up -d
```

The stack is shared by all Jovavia services.
