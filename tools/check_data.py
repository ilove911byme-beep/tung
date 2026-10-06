#!/usr/bin/env python3
"""Offline checks for the data modules and the pure animation code (no Roblox Studio needed).

Bundles the Shared modules that do not need Roblox (with tiny shims for Vector3 / Vector2 /
Color3 used inside data tables) and runs them with the Luau CLI:
  * every cutscene loads; shot times are ordered and fit their segment
  * shot times match the storyboard tables in cutscenes.md (EXPECTED below)
  * every referenced voice line, animation, sound, anchor, rig model and effect exists
  * voice lines are <= 300 characters and every speaker has TTS settings
  * PoseMath / PoseMixer unit tests (easing, angle wrap, speed change, layering, continueYaw)

Usage: python3 tools/check_data.py --luau /path/to/luau
"""
import argparse
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SHARED = os.path.join(ROOT, "src", "Shared")

# cutscenes.md shot tables: (segment, shot n, t0, t1)
EXPECTED = {
    "CS_02": [
        ("main", "1", 0, 4), ("main", "2", 4, 9), ("main", "3", 9, 13), ("main", "4", 13, 18),
        ("main", "5", 18, 23), ("choice", "6", 0, 15), ("yes", "7a", 0, 4.5), ("no", "7b", 0, 5.5),
    ],
    "CS_05": [
        ("main", "1", 0, 5), ("main", "2", 5, 12), ("main", "3", 12, 17), ("main", "4", 17, 21),
        ("main", "5", 21, 26), ("main", "6", 26, 29), ("main", "7", 29, 31), ("main", "8", 31, 40),
        ("main", "9", 40, 43), ("main", "10", 43, 48),
    ],
    "CS_00": [("main", "1", 0, 3), ("main", "2", 3, 7), ("main", "3", 7, 10), ("main", "4", 10, 14)],
    "CS_01": [("main", "1", 0, 4), ("main", "2", 4, 14), ("main", "3", 14, 19), ("main", "4", 19, 23),
              ("main", "5", 23, 27), ("main", "6", 27, 32)],
    "CS_03": [("main", "1", 0, 5), ("main", "2", 5, 9), ("main", "3", 9, 13), ("main", "4", 13, 17),
              ("main", "5", 17, 20)],
    "CS_04": [("main", "1", 0, 5), ("main", "2", 5, 8), ("main", "3", 8, 11), ("main", "4", 11, 15),
              ("main", "5", 15, 20), ("main", "6", 20, 23), ("main", "7", 23, 26)],
    "CS_04A": [("main", "1", 0, 3), ("main", "2", 3, 6), ("main", "3", 6, 7), ("main", "4", 7, 10)],
    "CS_06": [("main", "1", 0, 4), ("main", "2", 4, 9), ("main", "3", 9, 13), ("main", "4", 13, 18),
              ("main", "5", 18, 22), ("main", "6", 22, 30), ("main", "7", 30, 38)],
    "CS_DOWN": [("main", "1", 0, 2)],
    "CS_DEAD": [("main", "1", 0, 2), ("main", "2", 2, 5)],
    "CS_REVIVE": [("main", "1", 0, 2)],
}

EFFECTS = ["PixelDissolve", "PixelAssemble", "LastPixel", "Shatter", "Melt", "Grow", "Shrink",
           "WallBreak", "RootsBridge", "Bloom", "TimeFreeze", "TimeResume", "DropItem", "ShowPart",
           "HidePart"]

SHIMS = r"""
Vector3 = { new = function(x, y, z) return { X = x, Y = y, Z = z } end }
Vector2 = { new = function(x, y) return { X = x, Y = y } end }
Color3 = {
	new = function(r, g, b) return { R = r, G = g, B = b } end,
	fromRGB = function(r, g, b) return { R = r / 255, G = g / 255, B = b / 255 } end,
	fromHex = function(h) return { hex = h } end,
}
"""


def load(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def module_expr(src, mapping):
    src = re.sub(r"^--!strict\s*$", "", src, flags=re.M)
    for pattern, replacement in mapping.items():
        src = re.sub(pattern, replacement, src)
    return f"(function()\n{src}\nend)()"


def build():
    parts = [SHIMS]
    m_types = {r"require\(script\.Parent\.Parent\.Types\)": "__Types", r"require\(script\.Parent\.Types\)": "__Types",
               r"require\(script\.Parent\.Parent\.CutsceneKit\)": "__CutsceneKit"}
    parts.append("local __Types = {}")
    parts.append("local __CutsceneKit = " + module_expr(load(os.path.join(SHARED, "CutsceneKit.lua")), m_types))
    parts.append("local __PoseMath = " + module_expr(load(os.path.join(SHARED, "Visual", "PoseMath.lua")), {}))
    parts.append("local __PoseMixer = " + module_expr(load(os.path.join(SHARED, "Visual", "PoseMixer.lua")),
                                                      {r"require\(script\.Parent\.PoseMath\)": "__PoseMath"}))
    parts.append("local __SoundIds = " + module_expr(load(os.path.join(SHARED, "SoundIds.lua")), {}))
    parts.append("local __RigSpecs = " + module_expr(load(os.path.join(SHARED, "RigSpecs.lua")), {}))
    parts.append("local __VoiceSettings = " + module_expr(load(os.path.join(SHARED, "VoiceSettings.lua")), m_types))
    anchors_src = load(os.path.join(SHARED, "World", "Anchors.lua"))
    parts.append("local __Anchors = " + module_expr(anchors_src, {r"require\(script\.Parent\.Parent\.Config\)": "{ World = { StudsPerBlock = 4 } }"}))
    # voice lines
    parts.append("local __lines = {}")
    vdir = os.path.join(SHARED, "VoiceLines")
    for fn in sorted(os.listdir(vdir)):
        if fn.endswith(".lua") and fn != "init.lua":
            parts.append(f"for _, l in ipairs({module_expr(load(os.path.join(vdir, fn)), m_types)}) do table.insert(__lines, l) end")
    # animations
    parts.append("local __anims = {}")
    adir = os.path.join(SHARED, "Animations")
    for fn in sorted(os.listdir(adir)):
        if fn.endswith(".lua"):
            parts.append(f'__anims["{fn[:-4]}"] = {module_expr(load(os.path.join(adir, fn)), {})}')
    # cutscenes
    parts.append("local __cutscenes = {}")
    cdir = os.path.join(SHARED, "Cutscenes")
    for fn in sorted(os.listdir(cdir)):
        if fn.endswith(".lua"):
            parts.append(f'__cutscenes["{fn[:-4]}"] = {module_expr(load(os.path.join(cdir, fn)), m_types)}')
    expected = "{" + ",".join(
        f'["{cs}"]=' + "{" + ",".join(f'{{seg="{s}",n="{n}",t0={a},t1={b}}}' for s, n, a, b in rows) + "}"
        for cs, rows in EXPECTED.items()) + "}"
    parts.append(f"local __expected = {expected}")
    parts.append("local __effects = {" + ",".join(f'["{e}"]=true' for e in EFFECTS) + "}")
    parts.append(load(os.path.join(os.path.dirname(__file__), "check_data_runner.luau")))
    return "\n".join(parts)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--luau", required=True)
    args = ap.parse_args()
    code = build()
    with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False) as f:
        f.write(code)
        path = f.name
    proc = subprocess.run([args.luau, path], capture_output=True, text=True)
    sys.stdout.write(proc.stdout)
    sys.stderr.write(proc.stderr)
    if proc.returncode != 0 or "FAIL" in proc.stdout:
        sys.stderr.write(f"\n(bundle kept at {path})\n")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
