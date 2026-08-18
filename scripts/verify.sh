#!/usr/bin/env bash
set -euo pipefail
base_url="${HONCHO_URL:-http://localhost:8000}"

echo "1/4 API health"
curl --fail --silent --show-error "$base_url/health"
echo

echo "2/4 Database + migrations via workspace create"
workspace="smoke-$(date +%s)"
response=$(curl --fail --silent --show-error -X POST "$base_url/v3/workspaces" \
  -H 'Content-Type: application/json' \
  -d "{\"name\":\"$workspace\"}")
printf '%s\n' "$response"
printf '%s' "$response" | python3 -c 'import json,sys; assert json.load(sys.stdin).get("id"), "workspace response has no id"'

echo "3/4 pgvector extension"
docker compose exec -T database psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Atc \
  "SELECT extname FROM pg_extension WHERE extname = 'vector';" | grep -qx vector

echo "4/4 service state"
docker compose ps

echo "PASS: API, PostgreSQL migrations, and pgvector are healthy."
