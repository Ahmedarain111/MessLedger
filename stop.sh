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
pkill -f "dart.*flutter" 2>/dev/null || true

# Free ports 8000 (backend) and 3000 (frontend) if still held
fuser -k 8000/tcp 2>/dev/null || true
fuser -k 3000/tcp 2>/dev/null || true

echo "MessLedger backend and frontend have been stopped."
