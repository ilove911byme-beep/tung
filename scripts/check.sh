#!/bin/bash
# Full check used after every phase: format, lint, strict types, data checks, build.
# Needs rojo, selene, stylua (cloud-setup.sh). Optional: LUAU_LSP and LUAU paths for the type
# check and data checks (built from github.com/JohnnyMorganz/luau-lsp; see README).
set -euo pipefail
cd "$(dirname "$0")/.."
LUAU_LSP=${LUAU_LSP:-/tmp/claude-0/tools/luau-lsp/build/luau-lsp}
LUAU=${LUAU:-/tmp/claude-0/tools/luau-lsp/luau/build/luau}
DEFS=${ROBLOX_DEFS:-/tmp/claude-0/tools/globalTypes.d.luau}

echo "== stylua --check src =="
stylua --check src
echo "== selene src =="
selene src
if [ -x "$LUAU_LSP" ] && [ -f "$DEFS" ]; then
	echo "== luau-lsp analyze (story) =="
	rojo sourcemap story.project.json -o sourcemap.json >/dev/null
	OUT=$("$LUAU_LSP" analyze --platform roblox --sourcemap sourcemap.json --definitions=@roblox="$DEFS" src/Shared src/Story 2>&1 | grep -v '^\[INFO\]\|^\[WARN\]' || true)
	echo "== luau-lsp analyze (lobby) =="
	rojo sourcemap lobby.project.json -o sourcemap.json >/dev/null
	OUT2=$("$LUAU_LSP" analyze --platform roblox --sourcemap sourcemap.json --definitions=@roblox="$DEFS" src/Shared src/Lobby 2>&1 | grep -v '^\[INFO\]\|^\[WARN\]' || true)
	if [ -n "$OUT$OUT2" ]; then echo "$OUT"; echo "$OUT2"; exit 1; fi
else
	echo "(luau-lsp not found, type check skipped)"
fi
if [ -x "$LUAU" ]; then
	echo "== check_data =="
	python3 tools/check_data.py --luau "$LUAU" | tail -3
fi
echo "== rojo build =="
mkdir -p build
rojo build lobby.project.json -o build/Lobby.rbxl
rojo build story.project.json -o build/Story.rbxl
echo "ALL OK"
