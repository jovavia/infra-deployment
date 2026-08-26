#!/bin/sh
set -eu

echo "Generating PgBouncer configuration..."

eval "cat <<EOF
$(cat /etc/pgbouncer/pgbouncer.ini.template)
EOF" > /tmp/pgbouncer.ini

echo "===== PgBouncer Config ====="
cat /tmp/pgbouncer.ini
echo "============================"

exec pgbouncer /tmp/pgbouncer.ini