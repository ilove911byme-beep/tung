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
    "CS_07": [("main", "1", 0, 4), ("main", "2", 4, 8), ("main", "3", 8, 12), ("main", "4", 12, 18)],
    "CS_08": [("main", "1", 0, 5), ("main", "2", 5, 9), ("main", "3", 9, 12)],
    "CS_09T": [("main", "1", 0, 5), ("main", "2", 5, 10), ("main", "3", 10, 15), ("main", "4", 15, 20), ("main", "5", 20, 25)],
    "CS_09C": [("main", "1", 0, 5), ("main", "2", 5, 10), ("main", "3", 10, 15), ("main", "4", 15, 20), ("main", "5", 20, 25)],
    "CS_09B": [("main", "1", 0, 5), ("main", "2", 5, 10), ("main", "3", 10, 15), ("main", "4", 15, 20), ("main", "5", 20, 25)],
    "CS_10": [("main", "1", 0, 4), ("main", "2", 4, 8), ("main", "3", 8, 14), ("main", "4", 14, 20), ("main", "5", 20, 26),
              ("main", "6", 26, 30)],
    "CS_11": [("main", "1", 0, 4), ("main", "2", 4, 8), ("main", "3", 8, 14)],
    "CS_12": [("free", "1", 0, 4), ("free", "2", 4, 10), ("free", "3", 10, 16), ("free", "4", 16, 22), ("free", "5", 22, 28),
              ("jailed", "1", 0, 4), ("jailed", "2", 4, 10), ("jailed", "3", 10, 16), ("jailed", "4", 16, 22),
              ("jailed", "5", 22, 28)],
    "CS_13": [("main", "1", 0, 4), ("main", "2", 4, 7), ("main", "3", 7, 10)],
    "CS_14": [("main", "1", 0, 5), ("main", "2", 5, 10), ("main", "3", 10, 17), ("main", "4", 17, 23), ("main", "5", 23, 30)],
    "CS_15": [("main", "1", 0, 4), ("main", "2", 4, 8)],
    "CS_16": [("main", "1", 0, 6), ("main", "2", 6, 12), ("main", "3", 12, 18), ("main", "4", 18, 26), ("main", "5", 26, 33),
              ("main", "6a", 33, 35), ("main", "6b", 35, 37), ("main", "6c", 37, 39), ("main", "6d", 39, 42),
              ("main", "7", 42, 50), ("main", "8", 50, 58), ("main", "9", 58, 68), ("main", "10", 68, 75),
              ("main", "11", 75, 80), ("main", "12", 80, 88), ("main", "13", 88, 95)],
    "CS_17": [("main", "1", 0, 3), ("main", "2", 3, 7), ("main", "3", 7, 11), ("main", "4", 11, 16)],
    "CS_18": [("main", "1", 0, 5), ("main", "2", 5, 9), ("main", "3", 9, 13), ("main", "4", 13, 18), ("main", "5", 18, 22),
              ("main", "6", 22, 26)],
    "CS_19": [("main", "1", 0, 4), ("main", "2", 4, 8)],
    "CS_20": [("main", "1", 0, 5), ("main", "2", 5, 12), ("main", "3", 12, 18), ("main", "4", 18, 24), ("main", "5", 24, 30),
              ("main", "6", 30, 34)],
    "CS_21": [("free", "1", 0, 4), ("free", "2", 4, 9), ("free", "3", 9, 14), ("free", "4", 14, 22), ("free", "5", 22, 28),
              ("free", "6", 28, 34), ("jailed", "1", 0, 8)],
    "CS_22": [("main", "1", 0, 6), ("main", "2", 6, 12), ("main", "3", 12, 20)],
    "CS_E1": [("free", "1", 0, 6), ("free", "2", 6, 10), ("free", "3", 10, 20), ("free", "4", 20, 30), ("free", "5", 30, 38),
              ("free", "6", 38, 46), ("free", "7", 46, 52), ("free", "8", 52, 62), ("free", "9", 62, 70)],
    "CS_E2": [("main", "1", 0, 6), ("main", "2", 6, 10), ("main", "3a", 10, 15), ("main", "3b", 15, 20), ("main", "4", 20, 30)],
    "CS_E3": [("main", "1", 0, 6), ("main", "2", 6, 14), ("main", "3", 14, 20), ("main", "4", 20, 30), ("main", "5", 30, 36),
              ("main", "6", 36, 42), ("main", "7", 42, 48), ("main", "8", 48, 58), ("main", "9", 58, 68), ("main", "10", 68, 80),
              ("main", "11", 80, 88), ("main", "12", 88, 95), ("post", "P", 0, 12)],
    "CS_DOWN": [("main", "1", 0, 2)],
    "CS_DEAD": [("main", "1", 0, 2), ("main", "2", 2, 5)],
    "CS_REVIVE": [("main", "1", 0, 2)],
}

EFFECTS = ["PixelDissolve", "PixelAssemble", "LastPixel", "Shatter", "Melt", "Grow", "Shrink",
           "WallBreak", "RootsBridge", "Bloom", "TimeFreeze", "TimeResume", "DropItem", "ShowPart",
           "HidePart", "Transform", "Wither", "DirtBurst"]

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
    # dialogues
    parts.append("local __dialogues = {}")
    ddir = os.path.join(SHARED, "Dialogues")
    for fn in sorted(os.listdir(ddir)):
        if fn.endswith(".lua"):
            parts.append(f'__dialogues["{fn[:-4]}"] = {module_expr(load(os.path.join(ddir, fn)), {})}')
    expected = "{" + ",".join(
        f'["{cs}"]=' + "{" + ",".join(f'{{seg="{s}",n="{n}",t0={a},t1={b}}}' for s, n, a, b in rows) + "}"
        for cs, rows in EXPECTED.items()) + "}"
    parts.append(f"local __expected = {expected}")
    parts.append("local __effects = {" + ",".join(f'["{e}"]=true' for e in EFFECTS) + "}")
    parts.append(load(os.path.join(os.path.dirname(__file__), "check_data_runner.luau")))
    return "\n".join(parts)


def read(*parts):
    with open(os.path.join(ROOT, *parts), encoding="utf-8") as fh:
        return fh.read()


def check_story():
    """Every id a chapter / system script names (lines, objectives, cutscenes and their entries,
    achievements, presets, sounds, items, map points, world effects, models) must exist."""
    voice = set()
    for name in os.listdir(os.path.join(SHARED, "VoiceLines")):
        voice |= set(re.findall(r'id = "([A-Za-z0-9_]+)"', read("src", "Shared", "VoiceLines", name)))
    objectives = set(re.findall(r'^\s*([A-Z0-9_]+) = "', read("src", "Shared", "StoryData", "Objectives.lua"), re.M))
    achievements = set(re.findall(r'a\(\s*"([A-Z0-9_]+)"', read("src", "Shared", "Achievements.lua")))
    presets = set(re.findall(r'^\t([a-z_]+) = \{', read("src", "Story", "ServerScriptService", "Systems", "AtmosphereService.lua"), re.M))
    sounds = set(re.findall(r'^\s*([a-z0-9_]+) = P', read("src", "Shared", "SoundIds.lua"), re.M))
    items = set(re.findall(r'^\t([a-z_]+) = \{', read("src", "Shared", "StoryData", "Items.lua"), re.M))
    mapdata = read("src", "Shared", "World", "MapData.lua")
    points = set(re.findall(r'^\t([A-Za-z0-9]+) = \{ x = ', mapdata, re.M))
    anchors = set(re.findall(r'^\t(Anchor_[A-Za-z_]+) = ', read("src", "Shared", "World", "Anchors.lua"), re.M))
    fx = read("src", "Story", "StarterPlayerScripts", "Gameplay", "WorldFx.lua")
    fx_kinds = set(re.findall(r'^\t([a-zA-Z]+) = ', fx.split("local HANDLERS")[1], re.M))
    models = set(re.findall(r'^\t([A-Za-z]+) = \{\n\t\tkind = ', read("src", "Shared", "RigSpecs.lua"), re.M))
    cutscenes = {}
    for name in os.listdir(os.path.join(SHARED, "Cutscenes")):
        if name.endswith(".lua"):
            cutscenes[name[:-4]] = read("src", "Shared", "Cutscenes", name)
    errors = []
    base = os.path.join(ROOT, "src", "Story", "ServerScriptService")
    for dirpath, _, files in os.walk(base):
        for name in files:
            if not name.endswith(".lua") or "Dev" in dirpath:
                continue
            src = read(os.path.relpath(os.path.join(dirpath, name), ROOT))
            where = name

            def need(kind, value, pool):
                if value not in pool:
                    errors.append(f"FAIL story {where}: unknown {kind} {value}")

            for v in re.findall(r':say\(\s*"([A-Za-z0-9_]+)"', src):
                need("line", v, voice)
            for v in re.findall(r'task\.spawn\(ctx\.say, ctx, "([A-Za-z0-9_]+)"', src):
                need("line", v, voice)
            for v in re.findall(r':objective\(\s*"([A-Za-z0-9_]+)"', src):
                need("objective", v, objectives)
            for v in re.findall(r':award\(\s*"([A-Za-z0-9_]+)"', src):
                need("achievement", v, achievements)
            for v in re.findall(r':preset\(\s*"([a-z_]+)"', src):
                need("preset", v, presets)
            for v in re.findall(r'(?:ctx:sfx|:telegraph\([^,]+,[^,]+),?\s*"([a-z0-9_]+)"', src):
                need("sound", v, sounds)
            for v in re.findall(r'ctx:sfx\(\s*"([a-z0-9_]+)"', src):
                need("sound", v, sounds)
            for v in re.findall(r'inv\.(?:add|remove|has|count|onUse)\([^"]*"([a-z_]+)"', src):
                need("item", v, items)
            for v in re.findall(r':(?:point|ground)\(\s*"([A-Za-z0-9]+)"(?!\s*\.\.)', src):
                need("map point", v, points)
            for v in re.findall(r'\bpoint = "([A-Za-z0-9]+)"', src):
                need("map point", v, points)
            for v in re.findall(r'\banchor = "(Anchor_[A-Za-z_]+)"', src):
                need("anchor", v, anchors)
            for v in re.findall(r'(?:ctx:glitch|Hud\.worldFx)\(\s*"([a-zA-Z]+)"', src):
                need("world effect", v, fx_kinds)
            for v in re.findall(r'worldFxFor\([^,]+,\s*"([a-zA-Z]+)"', src):
                need("world effect", v, fx_kinds)
            for v in re.findall(r'\b(?:model|animated)\(\s*"([A-Za-z]+)"', src):
                need("model", v, models)
            for cs, entry in re.findall(r':cutscene\(\s*"(CS_[A-Z0-9]+)"(?:,\s*"([a-zA-Z]+)")?', src):
                if cs not in cutscenes:
                    errors.append(f"FAIL story {where}: unknown cutscene {cs}")
                elif entry and not re.search(r'\b' + entry + r' = \{', cutscenes[cs]):
                    errors.append(f"FAIL story {where}: cutscene {cs} has no entry {entry}")
            # entries chosen with if/else inside :cutscene(...)
            for cs, rest in re.findall(r':cutscene\(\s*"(CS_[A-Z0-9]+)",\s*(if [^\n]+)', src):
                for entry in re.findall(r'(?:then|else)\s+"([a-zA-Z]+)"', rest):
                    if cs in cutscenes and not re.search(r'\b' + entry + r' = \{', cutscenes[cs]):
                        errors.append(f"FAIL story {where}: cutscene {cs} has no entry {entry}")
    # lobby scripts: voice lines and animations named in them
    anims = {n[:-4].replace("A_", "A-", 1) for n in os.listdir(os.path.join(SHARED, "Animations")) if n.endswith(".lua")}
    for dirpath, _, files in os.walk(os.path.join(ROOT, "src", "Lobby")):
        for name in files:
            if name.endswith(".lua"):
                src = read(os.path.relpath(os.path.join(dirpath, name), ROOT))
                for v in re.findall(r'"((?:LOBBY|CHANT)_[A-Z0-9_]+)"', src):
                    if v not in voice:
                        errors.append(f"FAIL lobby {name}: unknown line {v}")
                for v in re.findall(r'"(A-[A-Z0-9_]+)"', src):
                    if v not in anims:
                        errors.append(f"FAIL lobby {name}: unknown animation {v}")
    for e in errors:
        print(e)
    print(f"story scripts checked, {len(errors)} problems")
    return not errors


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--luau", required=True)
    args = ap.parse_args()
    if not check_story():
        raise SystemExit(1)
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
