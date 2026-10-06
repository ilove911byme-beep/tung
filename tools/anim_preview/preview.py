#!/usr/bin/env python3
"""Animation preview for the code-only PoseAnimator (no Roblox Studio needed).

It bundles the pure Luau modules (PoseMath, PoseMixer, RigSpecs, Shared/Animations/A_*.lua),
runs a timeline with the Luau CLI using the SAME mixing code as the game, then draws the rig
(forward kinematics with the RigSpecs skeleton) from the front and the side into a PNG grid.

Usage:
  python3 tools/anim_preview/preview.py --luau /path/to/luau --out out.png \
      --rig Ballerina --play 0:A-BALLERINA_DANCE --times 0,0.5,1,1.5,2,3,4,5
  python3 tools/anim_preview/preview.py --luau ... --scene cs05   (built-in CS-05 timeline)

--play takes start:ID[:speed] and may be repeated; --stop takes time:ID.
"""
import argparse
import json
import math
import os
import re
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SHARED = os.path.join(ROOT, "src", "Shared")

PURE_MODULES = {
    "PoseMath": os.path.join(SHARED, "Visual", "PoseMath.lua"),
    "PoseMixer": os.path.join(SHARED, "Visual", "PoseMixer.lua"),
    "RigSpecs": os.path.join(SHARED, "RigSpecs.lua"),
}

RUNNER = r"""
local PoseMath = __mod_PoseMath
local PoseMixer = __mod_PoseMixer
local RigSpecs = __mod_RigSpecs

local function enc(v)
	local t = type(v)
	if t == "number" then
		if v ~= v then return "0" end
		return string.format("%.5g", v)
	elseif t == "string" then
		return '"' .. v:gsub('[%c"\\]', function(c) return string.format("\\u%04x", string.byte(c)) end) .. '"'
	elseif t == "boolean" then
		return tostring(v)
	elseif t == "table" then
		if #v > 0 or next(v) == nil then
			local parts = {}
			for _, x in ipairs(v) do table.insert(parts, enc(x)) end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local parts = {}
		for k, x in pairs(v) do table.insert(parts, enc(tostring(k)) .. ":" .. enc(x)) end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "null"
end

local cache = {}
local function loader(id)
	if cache[id] then return cache[id] end
	local data = __anims[id]
	assert(data, "unknown animation " .. id)
	local tracks = {}
	for joint, keys in pairs(data.tracks) do
		tracks[joint] = PoseMath.normalizeTrack(keys)
	end
	local loaded = { data = data, tracks = tracks, scale = data.scale }
	cache[id] = loaded
	return loaded
end

local spec = __spec
local clockNow = 0
local names = {}
for _, j in ipairs(RigSpecs.skeleton.joints) do table.insert(names, j.name) end
table.insert(names, "Root")
local mixer = PoseMixer.new(names, loader, function() return clockNow end)

table.sort(spec.events, function(a, b) return a.t < b.t end)
local nextEvent = 1
local frames = {}
local wanted = spec.times
local wi = 1
local dt = 1 / 60
local t = 0
local lastEffects = {}
while wi <= #wanted do
	clockNow = t
	while nextEvent <= #spec.events and spec.events[nextEvent].t <= t + 1e-9 do
		local e = spec.events[nextEvent]
		if e.op == "play" then
			mixer:play(e.id, { startClock = e.t, speed = e.speed, fade = e.fade })
		else
			mixer:stop(e.id)
		end
		nextEvent += 1
	end
	local poses, effects = mixer:step()
	for _, ef in ipairs(effects) do table.insert(lastEffects, { t = t, kind = ef.kind }) end
	if t + 1e-9 >= wanted[wi] then
		local out = {}
		for name, p in pairs(poses) do
			out[name] = { p.rot[1], p.rot[2], p.rot[3], p.pos[1], p.pos[2], p.pos[3] }
		end
		table.insert(frames, { t = wanted[wi], poses = out, scale = mixer.scale })
		wi += 1
	else
		t += dt
		if t > wanted[wi] then t = wanted[wi] end
	end
end
print(enc({ frames = frames, skeleton = RigSpecs.skeleton, characters = RigSpecs.characters, effects = lastEffects }))
"""


def strip_module(src, name):
    src = re.sub(r"^--!strict\s*$", "", src, flags=re.M)

    def repl(m):
        mod = m.group(1)
        if mod not in PURE_MODULES:
            raise SystemExit(f"{name}: requires non-pure module {mod}")
        return f"__mod_{mod}"

    src = re.sub(r"require\(script\.Parent(?:\.Parent)?(?:\.Visual)?\.(\w+)\)", repl, src)
    return src


def bundle(spec):
    out = []
    order = ["PoseMath", "PoseMixer", "RigSpecs"]
    for name in order:
        with open(PURE_MODULES[name], encoding="utf-8") as f:
            src = strip_module(f.read(), name)
        out.append(f"local __mod_{name} = (function()\n{src}\nend)()\n")
    anim_dir = os.path.join(SHARED, "Animations")
    out.append("local __anims = {}\n")
    for fn in sorted(os.listdir(anim_dir)):
        if fn.endswith(".lua"):
            with open(os.path.join(anim_dir, fn), encoding="utf-8") as f:
                src = strip_module(f.read(), fn)
            aid = fn[:-4].replace("_", "-", 1)
            out.append(f'__anims["{aid}"] = (function()\n{src}\nend)()\n')
    out.append("local __spec = " + lua_literal(spec) + "\n")
    out.append(RUNNER)
    return "\n".join(out)


def lua_literal(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(float(v))
    if isinstance(v, str):
        return json.dumps(v)
    if v is None:
        return "nil"
    if isinstance(v, list):
        return "{" + ",".join(lua_literal(x) for x in v) + "}"
    if isinstance(v, dict):
        return "{" + ",".join(f"[{json.dumps(k)}]={lua_literal(x)}" for k, x in v.items()) + "}"
    raise TypeError(v)


# ---------------------------------------------------------------- kinematics
def rot_x(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def mat(rot=(0, 0, 0), pos=(0, 0, 0)):
    m = np.eye(4)
    r = [math.radians(x) for x in rot]
    m[:3, :3] = rot_x(r[0]) @ rot_y(r[1]) @ rot_z(r[2])  # CFrame.Angles order
    m[:3, 3] = pos
    return m


def trans(p):
    return mat((0, 0, 0), p)


def solve_rig(skel, chars, rig, pose):
    """World matrices of all parts for one frame. Returns list of (name, matrix, size, color)."""
    ch = chars[rig]
    colors = ch["colors"]
    root_off = pose.get("Root", [0] * 6)
    if ch["kind"] == "cube":
        s = ch.get("cubeSize", 4)
        m = trans((0, 3, 0)) @ mat(root_off[0:3], root_off[3:6])
        return [("Body", m, [s, s, s], colors.get("*", "#FFD83A"))]
    world = {"HumanoidRootPart": trans((0, skel["rootHeight"], 0)) @ mat(root_off[0:3], root_off[3:6])}
    pending = list(skel["joints"])
    while pending:
        progressed = False
        for j in list(pending):
            if j["part0"] in world:
                p = pose.get(j["name"], [0] * 6)
                c0 = trans(j["c0"]) @ mat(p[0:3], p[3:6])
                world[j["part1"]] = world[j["part0"]] @ c0 @ np.linalg.inv(trans(j["c1"]))
                pending.remove(j)
                progressed = True
        if not progressed:
            break
    out = []
    for name, m in world.items():
        if name == "HumanoidRootPart":
            continue
        size = skel["parts"][name]["size"]
        out.append((name, m, size, colors.get(name, colors.get("*", "#CCCCCC"))))
    for acc in ch.get("accessories", []) or []:
        host = world.get(acc["part"])
        if host is not None:
            out.append((acc["name"], host @ trans(acc["offset"]), acc["size"], acc["color"]))
    return out


def corners(m, size):
    hx, hy, hz = [s / 2 for s in size]
    pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                pts.append((m @ np.array([sx * hx, sy * hy, sz * hz, 1]))[:3])
    return np.array(pts)


def hull(points):
    pts = sorted(set(map(tuple, points)))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def draw_view(draw, parts, view, ox, oy, scale):
    # view "front": camera in front of the rig (rig faces -Z) -> screen x = -world x, depth = z
    # view "side": camera on the rig's right (+X) -> screen x = -world z (forward = right), depth = -x
    items = []
    for name, m, size, color in parts:
        c = corners(m, size)
        if name == "prop" and view == "front":
            continue  # props stand in front of the rig; only draw them from the side
        if view == "front":
            pts2 = [(-p[0], p[1]) for p in c]
            closeness = -np.mean(c[:, 2])  # camera on the -Z side
        else:
            pts2 = [(-p[2], p[1]) for p in c]
            closeness = np.mean(c[:, 0])  # camera on the +X side
        items.append((closeness, name, pts2, color))
    items.sort(key=lambda x: x[0])  # far first, near last
    for _, name, pts2, color in items:
        poly = [(ox + x * scale, oy - y * scale) for x, y in hull(pts2)]
        rgb = hex_rgb(color)
        draw.polygon(poly, fill=rgb, outline=(30, 30, 30))
    draw.line([(ox - 4 * scale, oy), (ox + 4 * scale, oy)], fill=(90, 90, 90))


def render(result, rig, out_path, title, props=None):
    frames = result["frames"]
    skel, chars = result["skeleton"], result["characters"]
    scale = 34
    cell_w, cell_h = 9 * scale, 8 * scale
    cols = min(len(frames), 6)
    rows_per = 2  # front + side
    nrows = math.ceil(len(frames) / cols)
    img = Image.new("RGB", (cols * cell_w, nrows * rows_per * cell_h + 30), (236, 236, 240))
    d = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 15)
    except OSError:
        font = ImageFont.load_default()
    d.text((8, 6), title, fill=(0, 0, 0), font=font)
    for i, fr in enumerate(frames):
        r, c = divmod(i, cols)
        parts = solve_rig(skel, chars, rig, fr["poses"])
        for prop in props or []:
            if prop.get("from", -1e9) <= fr["t"] <= prop.get("to", 1e9):
                parts.append(("prop", trans(prop["pos"]), prop["size"], prop["color"]))
        for k, view in enumerate(("front", "side")):
            ox = c * cell_w + cell_w / 2
            oy = 30 + (r * rows_per + k) * cell_h + cell_h - 20
            draw_view(d, parts, view, ox, oy, scale)
            d.text((c * cell_w + 6, 30 + (r * rows_per + k) * cell_h + 4), f"t={fr['t']:.2f} {view}", fill=(0, 0, 0), font=font)
    img.save(out_path)
    return out_path


SCENES = {
    # CS-05 Ballerina timeline (cutscene seconds), as in Shared/Cutscenes/CS_05.lua
    "cs05": {
        "rig": "Ballerina",
        "events": [
            {"t": 0.0, "op": "play", "id": "A-BALLERINA_DANCE"},
            {"t": 5.3, "op": "play", "id": "A-BALLERINA_DANCE", "speed": 0.8},
            {"t": 12.0, "op": "play", "id": "A-BALLERINA_SLOW_STOP"},
            {"t": 21.0, "op": "play", "id": "A-KNEEL_SOFT"},
            {"t": 22.5, "op": "play", "id": "A-STROKE_SOFT"},
            {"t": 26.0, "op": "stop", "id": "A-STROKE_SOFT"},
            {"t": 31.2, "op": "play", "id": "A-REACH_OUT"},
        ],
        "times": [0, 0.75, 1.5, 2.6, 3.5, 5.2, 12.0, 12.5, 13.0, 14.0, 15.0, 21.0, 21.75, 22.5, 24.0, 26.5, 31.2, 32.2, 33.2, 36.0],
        # Giallino hovering in front of her (CS_05 shots 3-7), for checking the hand contact
        "props": [{"pos": [0, 2.3, -3.3], "size": [4, 4, 4], "color": "#FFD83A", "from": 14.5, "to": 31.0}],
    },
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--luau", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--rig", default="Ballerina")
    ap.add_argument("--play", action="append", default=[])
    ap.add_argument("--stop", action="append", default=[])
    ap.add_argument("--times", default="")
    ap.add_argument("--scene", default="")
    ap.add_argument("--title", default="")
    args = ap.parse_args()

    props = []
    if args.scene:
        spec = dict(SCENES[args.scene])
        rig = spec.pop("rig")
        props = spec.pop("props", [])
    else:
        rig = args.rig
        events = []
        for p in args.play:
            bits = p.split(":")
            e = {"t": float(bits[0]), "op": "play", "id": bits[1]}
            if len(bits) > 2:
                e["speed"] = float(bits[2])
            events.append(e)
        for s in args.stop:
            t, i = s.split(":")
            events.append({"t": float(t), "op": "stop", "id": i})
        spec = {"events": events, "times": [float(x) for x in args.times.split(",") if x]}
    code = bundle(spec)
    with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False) as f:
        f.write(code)
        path = f.name
    proc = subprocess.run([args.luau, path], capture_output=True, text=True)
    if proc.returncode != 0:
        sys.stderr.write(proc.stdout + proc.stderr)
        sys.stderr.write(f"\n(bundle kept at {path})\n")
        raise SystemExit(1)
    result = json.loads(proc.stdout.strip().splitlines()[-1])
    for e in result.get("effects", []):
        print(f"effect {e['kind']} fired at t={e['t']:.2f}")
    render(result, rig, args.out, args.title or (args.scene or ",".join(args.play)), props)
    print("wrote", args.out)


if __name__ == "__main__":
    main()
