#!/bin/bash
# Start backend server detached from terminal

set -a
source ./.env
set +a

# Override POSTGRES_PORT to use Docker container port (5433) instead of local PostgreSQL (5432)
export POSTGRES_PORT=5433
export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5433/${POSTGRES_DB}?sslmode=disable"

cd backend
# Start process with nohup, redirect output, run in background, and disown it
nohup go run cmd/crm-api/main.go > ../logs/backend-dev.log 2>&1 &
BACKEND_PID=$!
disown $BACKEND_PID 2>/dev/null || true
sleep 2
# Get the actual PID - try multiple patterns
ACTUAL_PID=$(pgrep -f "go run.*crm-api" | head -1)
if [ -z "$ACTUAL_PID" ]; then
    ACTUAL_PID=$(pgrep -f "crm-api" | head -1)
fi
if [ -n "$ACTUAL_PID" ]; then
    echo $ACTUAL_PID > ../logs/backend-dev.pid
    echo "Backend started with PID: $ACTUAL_PID (detached from terminal)"
else
    echo "Warning: Could not determine PID, but process may be running"
    echo "Check logs/backend-dev.log for details"
fi

