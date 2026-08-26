#!/usr/bin/env bash
set -euo pipefail

# Load .env
set -a
source .env
set +a

echo "🚀 Bootstrapping Jovavia PostgreSQL..."

DBS=(
  jovavia_identity
  jovavia_pulse
  jovavia_guardian
  jovavia_vault
  jovavia_event_mesh
)

for DB in "${DBS[@]}"; do
  echo "Checking $DB..."

  docker compose exec -T \
    -e PGPASSWORD="$POSTGRES_PASSWORD" postgres \
    psql -U "$POSTGRES_USER" -d postgres <<SQL
SELECT 'CREATE DATABASE ${DB}'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = '${DB}'
)\gexec
SQL

done

echo "🎉 Jovavia PostgreSQL bootstrap completed."