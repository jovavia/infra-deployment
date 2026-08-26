#!/bin/sh
set -eu

echo "Generating PgBouncer userlist..."

eval "cat <<EOF
$(cat /etc/pgbouncer/userlist.template)
EOF" > /tmp/userlist.txt

echo "Generating PgBouncer configuration..."

eval "cat <<EOF
$(cat /etc/pgbouncer/pgbouncer.ini.template)
EOF" > /tmp/pgbouncer.ini

echo "Starting PgBouncer..."

exec pgbouncer /tmp/pgbouncer.ini