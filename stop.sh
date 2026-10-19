#!/usr/bin/env bash

# ==============================================================================
# MessLedger Stop Script
# Shuts down the backend server and Flutter process.
# ==============================================================================

echo "Stopping MessLedger..."

# Stop backend and flutter
pkill -f "app\.main" 2>/dev/null || true
pkill -f "uvicorn" 2>/dev/null || true
pkill -f "flutter" 2>/dev/null || true

# Free port 8000 if still held
fuser -k 8000/tcp 2>/dev/null || true

echo "MessLedger has been stopped."
