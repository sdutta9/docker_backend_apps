#!/bin/bash

# --- Configuration & Arguments ---
TARGET_URL=${1:-"https://your-domain.com"}
# Accepts formats like 30s, 15m, 2h. Defaults to 60s if not provided.
DURATION=${2:-"30m"}

THREADS=2      # Number of CPU threads (Adjust based on your machine)
CONNECTIONS=10 # Concurrent HTTP connections

echo "----------------------------------------------------"
echo " Starting WRK Load Test: $(date)"
echo " Target   : $TARGET_URL"
echo " Duration : $DURATION"
echo " Threads  : $THREADS"
echo " Conns    : $CONNECTIONS"
echo " Using paths from: waf_paths.lua"
echo "----------------------------------------------------"

# Check if wrk is installed
if ! command -v wrk &> /dev/null; then
    echo "Error: 'wrk' is not installed. Please install it first."
    exit 1
fi

# Check if waf_paths.lua exists
if [ ! -f "waf_paths.lua" ]; then
    echo "Error: 'waf_paths.lua' not found in the current directory."
    exit 1
fi

# Run wrk with the Lua script and dynamic duration
wrk -t$THREADS -c$CONNECTIONS -d$DURATION -s waf_paths.lua "$TARGET_URL"

echo "----------------------------------------------------"
echo "Load test complete."