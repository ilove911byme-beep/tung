#!/bin/bash
# Paste this into: claude.ai/code -> environment settings -> Setup script
# Installs Rojo (Roblox project builder), Selene (linter) and StyLua (formatter) from crates.io.
command -v rojo   >/dev/null || cargo install --locked rojo
command -v selene >/dev/null || cargo install --locked selene
command -v stylua >/dev/null || cargo install --locked stylua
