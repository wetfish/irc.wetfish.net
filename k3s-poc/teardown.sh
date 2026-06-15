#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; NC='\033[0m'
info() { echo -e "${GREEN}[+]${NC} $*"; }

info "Deleting k3d clusters..."
k3d cluster delete dc-us 2>/dev/null || true
k3d cluster delete dc-eu 2>/dev/null || true

info "Removing Docker network..."
docker network rm irc-net 2>/dev/null || true

info "Cleanup complete."
