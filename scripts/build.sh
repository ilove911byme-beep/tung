#!/bin/bash
# Runs the cloud-setup checks and builds both places into build/.
# Usage: ./scripts/build.sh
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p build

echo "== stylua --check src =="
stylua --check src

echo "== selene src =="
selene src

echo "== rojo build =="
rojo build lobby.project.json -o build/Lobby.rbxl
rojo build story.project.json -o build/Story.rbxl

ls -l build/*.rbxl
echo "OK"
