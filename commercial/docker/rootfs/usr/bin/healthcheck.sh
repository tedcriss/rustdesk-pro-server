#!/bin/sh
# Health check script for RustDesk Pro Server

set -e

# Check if the server is responding
if command -v curl > /dev/null 2>&1; then
    curl -f http://localhost:${SERVER_PORT:-8080}/health || exit 1
elif command -v wget > /dev/null 2>&1; then
    wget -q --spider http://localhost:${SERVER_PORT:-8080}/health || exit 1
else
    # Fallback: check if process is running
    pgrep -f "rustdesk-pro" > /dev/null || exit 1
fi

exit 0
