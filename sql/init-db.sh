#!/usr/bin/env bash
set -e

SA_PASSWORD="${MSSQL_SA_PASSWORD:-YourStrong@Passw0rd!}"
SERVER="${SQL_HOST:-localhost}"
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"

echo "Waiting for SQL Server ($SERVER) to be ready..."
for i in {1..60}; do
  if $SQLCMD -S "$SERVER" -U sa -P "$SA_PASSWORD" -C -Q "SELECT 1" > /dev/null 2>&1; then
    echo "SQL Server is UP and responding."
    break
  fi
  echo "SQL Server is not ready yet (attempt $i/60). Sleeping 2s..."
  sleep 2
done

echo "Executing 01_schema.sql..."
$SQLCMD -S "$SERVER" -U sa -P "$SA_PASSWORD" -C -i /sql/01_schema.sql

echo "Executing 02_seed.sql..."
$SQLCMD -S "$SERVER" -U sa -P "$SA_PASSWORD" -C -i /sql/02_seed.sql

echo "Executing 03_indexes.sql..."
$SQLCMD -S "$SERVER" -U sa -P "$SA_PASSWORD" -C -i /sql/03_indexes.sql

echo "Database initialization and seeding completed successfully!"
