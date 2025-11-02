#!/bin/bash
# Wrapper script to run the CRM backend as a daemon
# This script handles environment setup and ensures dependencies are available

# Don't exit on error - let LaunchAgent handle restarts
set +e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Load environment variables from .env file
if [ -f .env ]; then
    set -a
    source ./.env
    set +a
fi

# Ensure DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    # Construct DATABASE_URL from individual components if not set
    POSTGRES_USER="${POSTGRES_USER:-crm_user}"
    POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-crm_password}"
    POSTGRES_DB="${POSTGRES_DB:-personal_crm}"
    POSTGRES_PORT="${POSTGRES_PORT:-5432}"
    export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:${POSTGRES_PORT}/${POSTGRES_DB}?sslmode=disable"
fi

# Ensure Docker is running (required for PostgreSQL)
# Try to start Docker Desktop if it's not running
if ! docker ps >/dev/null 2>&1; then
    echo "Docker is not running. Attempting to start Docker services..."
    # Try to start Docker Desktop (macOS)
    if command -v open >/dev/null 2>&1; then
        open -a Docker 2>/dev/null || true
        # Wait for Docker to start (up to 30 seconds)
        for i in {1..30}; do
            if docker ps >/dev/null 2>&1; then
                break
            fi
            sleep 1
        done
    fi
    # Start Docker Compose services if Docker is now available
    if docker ps >/dev/null 2>&1; then
        cd "$PROJECT_ROOT/infra" && docker compose up -d
        # Wait a moment for database to be ready
        sleep 3
    else
        echo "Warning: Could not start Docker. Backend may fail to connect to database."
    fi
fi

# Ensure backend binary exists
if [ ! -f "$PROJECT_ROOT/backend/bin/crm-api" ]; then
    echo "Backend binary not found. Building..."
    cd "$PROJECT_ROOT/backend"
    go build -o bin/crm-api cmd/crm-api/main.go
fi

# Set up log directory
LOG_DIR="$HOME/Library/Logs/Personal-CRM"
mkdir -p "$LOG_DIR"

# Run the backend (output goes to log files)
cd "$PROJECT_ROOT"
exec "$PROJECT_ROOT/backend/bin/crm-api" >> "$LOG_DIR/backend.log" 2>> "$LOG_DIR/backend.error.log"

