#!/usr/bin/env bash

# Wait for Postgres to start

dbhost=$(printenv DB_HOST)
dbuser=$(printenv DB_USER)
dbpass=$(printenv DB_PASSWORD)
export PGPASSWORD=$dbpass

until psql -h $dbhost -U $dbuser -c '\l' >> /dev/null 2>&1; do
  echo "Postgres is unavailable - sleeping"
  sleep 1
done

echo "Postgres is up"