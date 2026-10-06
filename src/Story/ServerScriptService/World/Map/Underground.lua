--!strict
-- The abandoned mine (map.md section 4, chapter 5), Y -2 .. -30 under the north-east hill.
-- Built as a voxel block of stone: rooms, the minecart loop, corridors, ladder shafts and the
-- maze are carved out as air, then only the stone blocks touching air are kept and merged by a
-- greedy 3D pass (walls stay single Parts, ore blocks break them up like in Minecraft).
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MapData = require(Shared:WaitForChild("World"):WaitForChild("MapData"))

local Builder = require(script.Parent.Builder)

local Underground = {}

-- tools/map_preview sets this to flood-fill the carved air and report unreachable rooms
Underground.verify = false

local X0, X1 = 94, 160
local Z0, Z1 = 4, 62
local Y0, Y1 = -30, MapData.TerrainBase
local W, D, H = X1 - X0, Z1 - Z0, Y1 - Y0

local grid: { [number]: string } = {}

local function idx(x: number, y: number, z: number): number
	return ((y - Y0) * D + (z - Z0)) * W + (x - X0)
end

local function inside(x: number, y: number, z: number): boolean
	return x >= X0 and x < X1 and y >= Y0 and y < Y1 and z >= Z0 and z < Z1
end

--- Sets every cell of a box (min corner + size, blocks) to `block` (nil = air).
local function fill(
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	block: string?
)
	for cx = math.floor(x), math.floor(x + sx) - 1 do
		for cy = math.floor(y), math.floor(y + sy) - 1 do
			for cz = math.floor(z), math.floor(z + sz) - 1 do
				if inside(cx, cy, cz) then
					grid[idx(cx, cy, cz)] = block :: any
				end
			end
		end
	end
end

local function carve(x: number, y: number, z: number, sx: number, sy: number, sz: number)
	fill(x, y, z, sx, sy, sz, nil)
end

local function isAir(x: number, y: number, z: number): boolean
	return inside(x, y, z) and grid[idx(x, y, z)] == nil
end

local function room(r: { x: number, z: number, w: number, d: number, y: number, h: number })
	carve(r.x, r.y, r.z, r.w, r.h, r.d)
end

-- the track legs: 3 wide, 4 high, centered on the path cells
local function trackLeg(a: { number }, b: { number }, y: number)
	local xa, xb = math.min(a[1], b[1]), math.max(a[1], b[1])
	local za, zb = math.min(a[2], b[2]), math.max(a[2], b[2])
	carve(xa - 1, y, za - 1, xb - xa + 3, 4, zb - za + 3)
end

local function maze()
	local M = MapData.Caves.Maze
	local cols, rows = 4, 5
	local rng = Random.new(67)
	local visited: { [number]: boolean } = {}
	local function cellPos(i: number, j: number): (number, number)
		return M.x + 1 + i * 3, M.z + 1 + j * 3
	end
	local function open(i: number, j: number)
		local x, z = cellPos(i, j)
		carve(x, M.y, z, 2, M.h, 2)
	end
	local stack = { { 0, rows - 1 } }
	visited[(rows - 1) * cols] = true
	open(0, rows - 1)
	while #stack > 0 do
		local top = stack[#stack]
		local i, j = top[1], top[2]
		local options = {}
		for _, dir in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local ni, nj = i + dir[1], j + dir[2]
			if ni >= 0 and ni < cols and nj >= 0 and nj < rows and not visited[nj * cols + ni] then
				table.insert(options, { ni, nj })
			end
		end
		if #options == 0 then
			table.remove(stack)
		else
			local pick = options[rng:NextInteger(1, #options)]
			local ni, nj = pick[1], pick[2]
			visited[nj * cols + ni] = true
			open(ni, nj)
			-- knock down the wall between the two cells
			local x1, z1 = cellPos(i, j)
			local x2, z2 = cellPos(ni, nj)
			carve(
				math.min(x1, x2),
				M.y,
				math.min(z1, z2),
				math.abs(x2 - x1) + 2,
				M.h,
				math.abs(z2 - z1) + 2
			)
			table.insert(stack, pick)
		end
	end
end

local ORES = {
	{ block = "coal_ore", chance = 0.035 },
	{ block = "iron_ore", chance = 0.018 },
	{ block = "gold_ore", chance = 0.006 },
	{ block = "glowstone_ore", chance = 0.01 },
}

local function ladder(parent: Instance, x: number, z: number, yBottom: number, yTop: number)
	local truss = Instance.new("TrussPart")
	truss.Name = "Ladder"
	truss.Anchored = true
	truss.Size = Vector3.new(2, (yTop - yBottom) * Builder.S, 2)
	truss.CFrame = CFrame.new(Builder.studs(x, (yBottom + yTop) / 2, z))
	truss.Color = Color3.fromHex("#7A5A34")
	truss.Material = Enum.Material.Wood
	truss:SetAttribute("Block", "oak_planks")
	truss.Parent = parent
	Builder.partCount += 1
end

local function torch(parent: Instance, x: number, y: number, z: number)
	local p =
		Builder.box(parent, "Torch", x - 0.1, y, z - 0.1, 0.2, 0.5, 0.2, "torch", { decor = true })
	Builder.light(p, "#FFA040", 12, 1.1, "MineTorch")
end

local function buildTrack(parent: Instance)
	local T = MapData.Track
	local folder = Builder.folder(parent, "Track")
	local legs: { { { number } } } = {}
	for i = 1, #T.path - 1 do
		table.insert(legs, { T.path[i], T.path[i + 1] })
	end
	for _, f in T.forks do
		table.insert(legs, { T.path[f.at], f.to })
	end
	for _, leg in legs do
		local a, b = leg[1], leg[2]
		local pa = Vector3.new(a[1] + 0.5, T.y + 0.1, a[2] + 0.5)
		local pb = Vector3.new(b[1] + 0.5, T.y + 0.1, b[2] + 0.5)
		local dir = (pb - pa).Unit
		local right = dir:Cross(Vector3.yAxis)
		for _, side in { -0.35, 0.35 } do
			Builder.slab(
				folder,
				"Rail",
				pa + right * side,
				pb + right * side,
				0.08,
				0.1,
				"rail",
				0,
				0,
				{ query = false }
			)
		end
		local length = (pb - pa).Magnitude
		for k = 0, math.floor(length / 2) do
			local c = pa + dir * (k * 2)
			Builder.slab(
				folder,
				"Sleeper",
				c - dir * 0.15,
				c + dir * 0.15,
				1.1,
				0.06,
				"oak_planks",
				0,
				-0.04,
				{ query = false }
			)
		end
		-- torches on the tunnel wall every 8 blocks
		for k = 1, math.floor(length / 8) do
			local c = pa + dir * (k * 8) + right * 1.45
			torch(folder, c.X, T.y + 2, c.Z)
		end
	end
	for _, f in T.forks do
		local e = f.to
		Builder.box(folder, "DeadEnd", e[1] - 0.5, T.y, e[2] - 0.5, 2, 3, 2, "cobblestone")
	end
	-- low beams (duck under them, CS minecart QTE)
	for i, b in T.beams do
		local beam =
			Builder.box(folder, "LowBeam" .. i, b[1] - 1, T.y + 1.6, b[2] - 1, 3, 0.5, 3, "oak_log")
		CollectionService:AddTag(beam, "LowBeam")
	end
end

local function buildLab(parent: Instance)
	local L = MapData.Caves.Lab
	local folder = Builder.folder(parent, "LiriliLab")
	Builder.box(folder, "Floor", L.x, L.y - 0.2, L.z, L.w, 0.2, L.d, "oak_planks")
	-- the big clock mechanism she froze beside
	local mech = Builder.model(folder, "ClockMechanism")
	Builder.box(mech, "Frame", L.x + 4, L.y, L.z + 1, 4, 5, 1, "oak_log")
	for i, g in { { 5, 3.2, 1.2 }, { 6.6, 2, 0.9 }, { 5.6, 1, 0.7 } } do
		local gear = Builder.part(
			mech,
			"Gear" .. i,
			CFrame.new(Builder.studs(L.x + g[1], L.y + g[2], L.z + 2.1))
				* CFrame.Angles(0, math.rad(90), 0),
			Vector3.new(0.6, g[3] * 2 * Builder.S, g[3] * 2 * Builder.S),
			"iron",
			{ shape = "Cylinder", color = "#E0B040" }
		)
		gear:SetAttribute("Spin", 0) -- frozen until CS-22 / CS-E1
	end
	-- workbenches, candles, clocks on the walls
	for i, wb in { { L.x + 1, L.z + 6 }, { L.x + 9, L.z + 6 } } do
		Builder.box(folder, "Workbench" .. i, wb[1], L.y, wb[2], 2, 1, 1, "oak_planks")
		local candle = Builder.box(
			folder,
			"Candle" .. i,
			wb[1] + 0.4,
			L.y + 1,
			wb[2] + 0.4,
			0.2,
			0.4,
			0.2,
			"white",
			{ decor = true }
		)
		Builder.light(candle, "#FFC870", 10, 0.9, "Lamp")
	end
	for i = 0, 3 do
		local clock = Builder.part(
			folder,
			"WallClock",
			CFrame.new(Builder.studs(L.x + 2 + i * 2.6, L.y + 3.5, L.z + 0.06))
				* CFrame.Angles(0, math.rad(90), 0),
			Vector3.new(0.2, 3, 3),
			"white",
			{ shape = "Cylinder", decor = true }
		)
		clock.Color = Color3.fromHex("#E8D8A8")
	end
end

local function buildLevers(parent: Instance)
	local folder = Builder.folder(parent, "LeverRoom")
	for i = 1, 4 do
		local p = MapData.Points["Lever" .. i]
		local lever = Builder.model(folder, "Lever" .. i)
		Builder.box(lever, "Base", p.x - 0.15, p.y - 0.2, p.z - 0.3, 0.3, 0.6, 0.6, "cobblestone")
		local handle = Builder.part(
			lever,
			"Handle",
			CFrame.new(Builder.studs(p.x + 0.3, p.y + 0.35, p.z))
				* CFrame.Angles(0, 0, math.rad(-35)),
			Vector3.new(0.3, 2.2, 0.3),
			"oak_log"
		)
		handle:SetAttribute("Index", i)
		CollectionService:AddTag(lever, "Lever")
	end
	-- spike plates that slide out of the floor on a wrong order (hidden at first)
	local L = MapData.Caves.Levers
	for i = 0, 5 do
		local spike = Builder.box(
			folder,
			"Spikes",
			L.x + 1 + i,
			L.y,
			L.z + 3,
			1,
			0.8,
			2,
			"iron",
			{ color = "#9A9AA8" }
		)
		spike.Transparency = 1
		spike.CanCollide = false
		spike:SetAttribute("Index", i + 1)
		CollectionService:AddTag(spike, "Spikes")
	end
	-- two steps up to the corridor from the lab
	Builder.box(folder, "Step", 128, L.y, 47, 3, 1, 1, "cobblestone")
end

local function buildLava(parent: Instance)
	local folder = Builder.folder(parent, "LavaLake")
	local L = MapData.Caves.Lava
	local lava =
		Builder.box(folder, "Lava", L.x, L.y, L.z, L.w, MapData.LavaLevel - L.y, L.d, "lava")
	CollectionService:AddTag(lava, "Lava")
	CollectionService:AddTag(lava, "AmbienceEmitter")
	lava:SetAttribute("Sound", "amb_lava_loop")
	lava:SetAttribute("Volume", 0.6)
	lava:SetAttribute("MaxDistance", 120)
	-- start and gear platforms, the hidden safe ledge along the north wall
	Builder.box(folder, "StartPlatform", 115, L.y, 46, 3, 4, 8, "stone")
	Builder.box(folder, "GearPlatform", L.x, L.y, 46, 3, 4, 6, "stone")
	local ledge = Builder.box(folder, "SecretLedge", 101, L.y, L.z, 14, 4, 1, "stone")
	ledge:SetAttribute("Secret", true)
end

local function buildCave(parent: Instance)
	local folder = Builder.folder(parent, "CrudelinoCave")
	local C = MapData.Caves.Cave
	-- stone columns (Crudelino breaks them in phase 1)
	local rng = Random.new(1717)
	for i, c in { { 129, 14 }, { 139, 14 }, { 129, 25 }, { 139, 25 }, { 134, 12 }, { 134, 27 } } do
		local col = Builder.box(
			folder,
			"Column" .. i,
			c[1],
			C.y,
			c[2],
			2,
			C.h,
			2,
			if i % 2 == 0 then "cobblestone" else "stone"
		)
		CollectionService:AddTag(col, "CaveColumn")
	end
	-- stalactites (the fallback fight when Bombardiro is jailed)
	for i = 1, 3 do
		local p = MapData.Points["Stalactite" .. i]
		local s = Builder.box(
			folder,
			"Stalactite" .. i,
			p.x - 0.5,
			p.y - 3,
			p.z - 0.5,
			1,
			2.5,
			1,
			"stone"
		)
		CollectionService:AddTag(s, "Stalactite")
	end
	-- loose rocks to knock the stalactites down
	for _ = 1, 8 do
		local x = C.x + 2 + rng:NextNumber() * (C.w - 4)
		local z = C.z + 2 + rng:NextNumber() * (C.d - 4)
		local rock = Builder.box(folder, "Rock", x, C.y, z, 0.5, 0.4, 0.5, "cobblestone")
		CollectionService:AddTag(rock, "Rock")
	end
end

--- Carves and builds the whole mine under `parent`.
function Underground.build(parent: Instance)
	local folder = Builder.folder(parent, "Underground")
	for i = 0, W * D * H - 1 do
		grid[i] = "stone"
	end
	local C = MapData.Caves
	for _, r in { C.Adit, C.Lab, C.Levers, C.Lava, C.Cave } do
		room(r)
	end
	maze()
	local T = MapData.Track
	for i = 1, #T.path - 1 do
		trackLeg(T.path[i], T.path[i + 1], T.y)
	end
	for _, f in T.forks do
		trackLeg(T.path[f.at], f.to, T.y)
	end
	-- shafts and corridors (see MapData.Points for where they lead)
	carve(121, -2, 25, 3, Y1 + 2, 2) -- surface -> adit
	carve(146, -12, 51, 2, 14, 2) -- track end -> lab level
	carve(145, -12, 42, 3, 4, 11) -- -> lab east wall
	carve(128, -12, 40, 6, 4, 3) -- lab west -> levers
	carve(128, -12, 40, 3, 4, 8)
	carve(118, -14, 50, 6, 4, 3) -- levers -> lava cave
	carve(140, -12, 25, 3, 4, 10) -- lab north -> maze
	carve(140, -12, 25, 6, 4, 3)
	carve(144, -16, 25, 2, 4, 2)
	carve(140, -16, 19, 5, 3, 2) -- maze -> cave wall
	local S = MapData.SkyHole
	carve(S.x, C.Cave.y + C.Cave.h, S.z, S.w, Y1 - (C.Cave.y + C.Cave.h), S.d)

	-- ores on the cave walls (deterministic)
	local rng = Random.new(5)
	local glowCount = 0
	local shell: { [number]: boolean } = {}
	for x = X0, X1 - 1 do
		for y = Y0, Y1 - 1 do
			for z = Z0, Z1 - 1 do
				local i = idx(x, y, z)
				if grid[i] ~= nil then
					if
						isAir(x + 1, y, z)
						or isAir(x - 1, y, z)
						or isAir(x, y + 1, z)
						or isAir(x, y - 1, z)
						or isAir(x, y, z + 1)
						or isAir(x, y, z - 1)
					then
						shell[i] = true
						local roll = rng:NextNumber()
						local acc = 0
						for _, ore in ORES do
							acc += ore.chance
							if roll < acc then
								if ore.block ~= "glowstone_ore" or glowCount < 40 then
									grid[i] = ore.block
									if ore.block == "glowstone_ore" then
										glowCount += 1
									end
								end
								break
							end
						end
					end
				end
			end
		end
	end
	-- floors: gravel in the adit and along the track
	for x = X0, X1 - 1 do
		for z = Z0, Z1 - 1 do
			local i = idx(x, T.y - 1, z)
			if shell[i] and isAir(x, T.y, z) then
				grid[i] = "gravel"
			end
		end
	end

	-- greedy 3D merge of the shell blocks
	local walls = Builder.folder(folder, "Walls")
	local used: { [number]: boolean } = {}
	for y = Y0, Y1 - 1 do
		for z = Z0, Z1 - 1 do
			for x = X0, X1 - 1 do
				local i = idx(x, y, z)
				local block = grid[i]
				if shell[i] and not used[i] and block then
					local function ok(cx: number, cy: number, cz: number): boolean
						if not inside(cx, cy, cz) then
							return false
						end
						local n = idx(cx, cy, cz)
						return shell[n] == true and not used[n] and grid[n] == block
					end
					local sx = 1
					while ok(x + sx, y, z) do
						sx += 1
					end
					local sz = 1
					local grow = true
					while grow do
						for dx = 0, sx - 1 do
							if not ok(x + dx, y, z + sz) then
								grow = false
								break
							end
						end
						if grow then
							sz += 1
						end
					end
					local sy = 1
					grow = true
					while grow do
						for dz = 0, sz - 1 do
							for dx = 0, sx - 1 do
								if not ok(x + dx, y + sy, z + dz) then
									grow = false
									break
								end
							end
							if not grow then
								break
							end
						end
						if grow then
							sy += 1
						end
					end
					for dy = 0, sy - 1 do
						for dz = 0, sz - 1 do
							for dx = 0, sx - 1 do
								used[idx(x + dx, y + dy, z + dz)] = true
							end
						end
					end
					Builder.box(walls, block, x, y, z, sx, sy, sz, block)
				end
			end
		end
	end

	-- ladders between the levels
	ladder(folder, 122.5, 25.5, -2, 15)
	ladder(folder, 147, 52.5, -12, 2)
	ladder(folder, 145, 25.5, -16, -8)
	ladder(folder, 117.5, 51.5, -20, -10)
	ladder(folder, 142.5, 20, C.Cave.y, -13)

	buildTrack(folder)
	buildLab(folder)
	buildLevers(folder)
	buildLava(folder)
	buildCave(folder)

	-- adit dressing: support frames, cobwebs, torches
	local A = C.Adit
	for i = 0, 2 do
		local z = A.z + 2 + i * 3.5
		Builder.box(folder, "Support", A.x, A.y, z, 1, A.h, 1, "oak_log")
		Builder.box(folder, "Support", A.x + A.w - 1, A.y, z, 1, A.h, 1, "oak_log")
		Builder.box(folder, "Beam", A.x, A.y + A.h - 1, z, A.w, 1, 1, "oak_planks")
	end
	for _, c in { { A.x + 1, A.z + 1 }, { A.x + A.w - 2, A.z + A.d - 2 } } do
		Builder.box(
			folder,
			"Cobweb",
			c[1],
			A.y + A.h - 2,
			c[2],
			1,
			1,
			1,
			"cobweb",
			{ decor = true }
		)
	end
	torch(folder, A.x + 1.2, A.y + 2, A.z + 5)
	torch(folder, A.x + A.w - 1.2, A.y + 2, A.z + 5)

	if Underground.verify then
		local seen: { [number]: boolean } = {}
		local queue = { { 122, -2, 30 } }
		seen[idx(122, -2, 30)] = true
		local head = 1
		while head <= #queue do
			local c = queue[head]
			head += 1
			for _, d in
				{ { 1, 0, 0 }, { -1, 0, 0 }, { 0, 1, 0 }, { 0, -1, 0 }, { 0, 0, 1 }, { 0, 0, -1 } }
			do
				local nx, ny, nz = c[1] + d[1], c[2] + d[2], c[3] + d[3]
				if isAir(nx, ny, nz) and not seen[idx(nx, ny, nz)] then
					seen[idx(nx, ny, nz)] = true
					table.insert(queue, { nx, ny, nz })
				end
			end
		end
		for name, p in MapData.Points do
			if p.y < Y1 and inside(math.floor(p.x), math.floor(p.y), math.floor(p.z)) then
				local ok = seen[idx(math.floor(p.x), math.floor(p.y), math.floor(p.z))] == true
				print(
					string.format(
						"[Underground] %-16s %s",
						name,
						if ok then "reachable" else "NOT REACHABLE"
					)
				)
			end
		end
	end
	table.clear(grid)
	return folder
end

return Underground
