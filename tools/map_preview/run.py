#!/usr/bin/env python3
"""Runs the Story place MapBuilder in the Luau CLI against a small Roblox mock and renders the
result: a top-down map and isometric close-ups (PNG), plus the part count.

Usage: python3 tools/map_preview/run.py --luau /path/to/luau --out DIR [--lobby]
(--lobby builds the Lobby place world instead: the station, the tunnel and the valley.)
"""
import argparse
import json
import math
import os
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
HERE = os.path.dirname(os.path.abspath(__file__))

MOUNTS = [
    ("ReplicatedStorage/Shared", "src/Shared"),
    ("ServerScriptService/World", "src/Story/ServerScriptService/World"),
]


def collect(rel_dir):
    files = []
    base = os.path.join(ROOT, rel_dir)
    for dirpath, _, names in os.walk(base):
        for n in sorted(names):
            if n.endswith(".lua"):
                files.append(os.path.relpath(os.path.join(dirpath, n), ROOT))
    return sorted(files)


LOBBY_MOUNTS = [
    ("ReplicatedStorage/Shared", "src/Shared"),
    ("ServerScriptService", "src/Lobby/ServerScriptService"),
]
LOBBY_FILES = [
    ("ServerScriptService/World", "src/Story/ServerScriptService/World/Map/Builder.lua"),
]


def build_chunk(lobby=False):
    out = []
    with open(os.path.join(HERE, "roblox_mock.luau"), encoding="utf-8") as f:
        out.append("local __mock = (function()\n" + f.read() + "\nend)()")
    for name in ["Vector3", "Vector2", "CFrame", "Color3", "UDim2", "UDim", "Enum", "Random", "Instance",
                 "game", "workspace", "warn", "ColorSequence", "NumberSequence", "NumberRange"]:
        out.append(f"local {name} = __mock.{name}")
    out.append("local math = setmetatable({ noise = __mock.noise }, { __index = math })")
    out.append("local __files = {}")
    out.append("local __cache = {}")
    out.append("local require")
    paths = []
    mounts = LOBBY_MOUNTS if lobby else MOUNTS
    singles = LOBBY_FILES if lobby else []
    for mount, path in singles:
        with open(os.path.join(ROOT, path), encoding="utf-8") as f:
            src = f.read()
        out.append(f"__files[{json.dumps(path)}] = function(script)\n{src}\nend")
        paths.append((mount, os.path.dirname(path), path))
    for mount, rel in mounts:
        for path in collect(rel):
            if path.endswith(".server.lua") or path.endswith(".client.lua"):
                continue
            with open(os.path.join(ROOT, path), encoding="utf-8") as f:
                src = f.read()
            out.append(f"__files[{json.dumps(path)}] = function(script)\n{src}\nend")
            paths.append((mount, rel, path))
    out.append("""
require = function(inst)
	local path = inst:GetAttribute("__path")
	assert(path, "require of a non-module: " .. tostring(inst))
	if __cache[path] == nil then
		__cache[path] = __files[path](inst)
	end
	return __cache[path]
end
local function node(root, parts)
	local cur = root
	for _, p in parts do
		local c = cur:FindFirstChild(p)
		if not c then
			c = Instance.new("Folder")
			c.Name = p
			c.Parent = cur
		end
		cur = c
	end
	return cur
end
""")
    for mount, rel, path in paths:
        service, *sub = mount.split("/")
        inner = os.path.relpath(path, rel)[:-4].split(os.sep)
        is_init = inner[-1] == "init"
        if is_init:
            inner = inner[:-1]
        parent_parts = sub + inner[:-1]
        name = inner[-1] if inner else sub[-1]
        out.append(f"""do
	local parent = node(game:GetService("{service}"), {{{",".join(json.dumps(p) for p in parent_parts)}}})
	local m = parent:FindFirstChild({json.dumps(name)})
	if not m then
		m = Instance.new("ModuleScript")
		m.Name = {json.dumps(name)}
		m.Parent = parent
	end
	m:SetAttribute("__path", {json.dumps(path)})
end""")
    if lobby:
        out.append("""
local SSS = game:GetService("ServerScriptService")
local map = require(SSS.LobbyWorld).build()
local lines = {}
for _, d in map:GetDescendants() do
	if d:IsA("BasePart") then
		local c = d.CFrame
		local s = d.Size
		local col = d.Color or Color3.new(0.8, 0.8, 0.8)
		local r = c.r
		table.insert(lines, string.format("P %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %s %s",
			c.p.X, c.p.Y, c.p.Z, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], s.X, s.Y, s.Z,
			col.R, col.G, col.B, tostring(d.Transparency or 0), d.Name))
	end
end
print(table.concat(lines, "\\n"))
""")
        return "\n".join(out)
    out.append("""
local SSS = game:GetService("ServerScriptService")
local RigFactory = require(SSS.World.RigFactory)
RigFactory.buildAll()
require(SSS.World.Map.Underground).verify = true
local MapBuilder = require(SSS.World.MapBuilder)
local map = MapBuilder.build()
local Builder = require(SSS.World.Map.Builder)
print("PARTS", #map:GetDescendants(), Builder.partCount)
local lines = {}
for _, d in map:GetDescendants() do
	if d:IsA("BasePart") then
		local c = d.CFrame
		local s = d.Size
		local col = d.Color or Color3.new(0.8, 0.8, 0.8)
		local r = c.r
		table.insert(lines, string.format("P %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %s %s",
			c.p.X, c.p.Y, c.p.Z, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], s.X, s.Y, s.Z,
			col.R, col.G, col.B, tostring(d.Transparency or 0), d.Name))
	end
end
for _, n in game:GetService("Workspace"):FindFirstChild("NPCs"):GetChildren() do
	print("NPC", n.Name)
end
print(table.concat(lines, "\\n"))
""")
    return "\n".join(out)


def render(parts, out_dir, lobby=False):
    from PIL import Image, ImageDraw
    os.makedirs(out_dir, exist_ok=True)
    S = 4
    # top-down: lower parts first so the top surface wins
    scale = 2  # pixels per stud / 2 -> 1280 px for 640 studs
    img = Image.new("RGB", (640 * scale // 1, 640 * scale // 1), (30, 30, 40))
    d = ImageDraw.Draw(img)
    def corners(p):
        (px, py, pz, r, sx, sy, sz) = p["px"], p["py"], p["pz"], p["r"], p["sx"], p["sy"], p["sz"]
        cs = []
        for dx in (-0.5, 0.5):
            for dy in (-0.5, 0.5):
                for dz in (-0.5, 0.5):
                    lx, ly, lz = dx * sx, dy * sy, dz * sz
                    cs.append((px + r[0] * lx + r[1] * ly + r[2] * lz,
                               py + r[3] * lx + r[4] * ly + r[5] * lz,
                               pz + r[6] * lx + r[7] * ly + r[8] * lz))
        return cs
    above = [p for p in parts if p["t"] < 0.99 and p["py"] > 0 and p["sy"] < 400]
    for p in sorted(above, key=lambda p: p["py"] + p["sy"] / 2):
        cs = corners(p)
        xs = [c[0] for c in cs]
        zs = [c[2] for c in cs]
        top = max(c[1] for c in cs)
        shade = max(0.55, min(1.25, 0.75 + (top - 48) / 120))
        col = tuple(int(min(255, v * 255 * shade)) for v in p["col"])
        d.rectangle([min(xs) * scale / 1, min(zs) * scale / 1, max(xs) * scale / 1, max(zs) * scale / 1], fill=col)
    img.save(os.path.join(out_dir, "map_top.png"))

    # isometric views of areas (studs): (name, cx, cz, radius, yaw deg)
    views = [("iso_lobby_station", 22 * S, 30 * S, 22 * S, 160), ("iso_lobby_tunnel", 50 * S, 22 * S, 22 * S, 200),
             ("iso_lobby_valley", 180 * S, 12 * S, 60 * S, 120)] if lobby else [("iso_village", 80 * S, 80 * S, 36 * S, 45), ("iso_square", 80 * S, 76 * S, 16 * S, 45),
             ("iso_station", 40 * S, 80 * S, 22 * S, 135), ("iso_forest", 35 * S, 128 * S, 24 * S, 45),
             ("iso_mine", 130 * S, 35 * S, 30 * S, 45), ("iso_tower", 80 * S, 66 * S, 10 * S, 225)]
    for name, cx, cz, rad, yaw in views:
        W, H = 1400, 1000
        img = Image.new("RGB", (W, H), (78, 128, 50) if lobby else (140, 190, 235))
        d = ImageDraw.Draw(img)
        a = math.radians(yaw)
        ca, sa = math.cos(a), math.sin(a)
        k = (W * 0.42) / rad
        def proj(x, y, z):
            rx = (x - cx) * ca - (z - cz) * sa
            rz = (x - cx) * sa + (z - cz) * ca
            sxp = W / 2 + rx * k
            syp = H * 0.6 + (rz * 0.5 - (y - 48) * 0.85) * k
            return sxp, syp, rz + y * 0.01
        faces = []
        under = name == "iso_mine"
        for p in parts:
            if p["t"] >= 0.99 or p["sy"] > 300 or (lobby and p["name"] == "Ground"):
                continue
            if abs(p["px"] - cx) > rad * 1.6 or abs(p["pz"] - cz) > rad * 1.6:
                continue
            if under and p["py"] > 4 * S:
                continue
            if not under and p["py"] < 0:
                continue
            cs = corners(p)
            idx = [(0, 1, 3, 2), (4, 5, 7, 6), (0, 1, 5, 4), (2, 3, 7, 6), (0, 2, 6, 4), (1, 3, 7, 5)]
            center = [sum(c[i] for c in cs) / 8 for i in range(3)]
            for f in idx:
                pts = [cs[i] for i in f]
                fc = [sum(q[i] for q in pts) / 4 for i in range(3)]
                n = [fc[i] - center[i] for i in range(3)]
                # visible if facing the viewer: viewer direction (from scene to camera)
                vx, vy, vz = -sa, 0.85, -ca
                vdir = (sa * 0 - 0, 1, 0)
                facing = n[1] > 1e-6 or ((n[0] * sa + n[2] * ca) > 1e-6)
                if not facing:
                    continue
                shade = 1.0 if n[1] > 1e-6 else (0.8 if abs(n[0]) > abs(n[2]) else 0.65)
                col = tuple(int(min(255, v * 255 * shade)) for v in p["col"])
                pp = [proj(*q) for q in pts]
                depth = sum(q[2] for q in pp) / 4 + (0.02 if n[1] > 0 else 0)
                faces.append((depth, [(q[0], q[1]) for q in pp], col))
        faces.sort(key=lambda f: f[0])
        for _, poly, col in faces:
            d.polygon(poly, fill=col, outline=tuple(max(0, c - 25) for c in col))
        img.save(os.path.join(out_dir, name + ".png"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--luau", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--lobby", action="store_true")
    args = ap.parse_args()
    chunk = build_chunk(args.lobby)
    with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False) as f:
        f.write(chunk)
        path = f.name
    res = subprocess.run([args.luau, path], capture_output=True, text=True)
    if res.returncode != 0:
        print(res.stdout[-3000:])
        print(res.stderr[-3000:])
        sys.exit(1)
    parts = []
    for line in res.stdout.splitlines():
        if line.startswith("P "):
            b = line.split(" ")
            v = [float(x) for x in b[1:19]]
            parts.append({"px": v[0], "py": v[1], "pz": v[2], "r": v[3:12], "sx": v[12], "sy": v[13],
                          "sz": v[14], "col": v[15:18], "t": float(b[19]), "name": b[20] if len(b) > 20 else ""})
        else:
            print(line)
    print(f"{len(parts)} parts")
    render(parts, args.out, args.lobby)
    print("rendered to", args.out)


if __name__ == "__main__":
    main()
