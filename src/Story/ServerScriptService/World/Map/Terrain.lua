--!strict
-- Surface terrain of Brainrot Valley (map.md sections 1, 3, 8). Every (x, z) block column is
-- a list of segments {y0, y1, block} built from a height map (mountains in the west and north,
-- the north-east hill with the mine, Tung Tung's hill, the river, the gorge). Carves cut
-- tunnels and shafts out of the columns. Columns with the same segment list are merged by a
-- greedy 2D pass, so a flat field is a handful of Parts (one per layer) instead of thousands.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MapData = require(Shared:WaitForChild("World"):WaitForChild("MapData"))

local Builder = require(script.Parent.Builder)

local Terrain = {}

type Segment = { y0: number, y1: number, block: string }
type Carve = {
	x0: number,
	x1: number,
	z0: number,
	z1: number,
	y0: number,
	y1: number,
	floor: string?,
}

local N = MapData.Size
local GROUND = MapData.Ground
local BASE = MapData.TerrainBase

local heights: { [number]: number } = {}
local tops: { [number]: string } = {}
local columns: { [number]: { Segment } } = {}

local function idx(x: number, z: number): number
	return z * N + x
end

local function inRect(x: number, z: number, x0: number, x1: number, z0: number, z1: number): boolean
	-- cell (x, z) covers [x, x+1) x [z, z+1); it is inside when its center is
	return x + 0.5 >= x0 and x + 0.5 < x1 and z + 0.5 >= z0 and z + 0.5 < z1
end

local function noise(x: number, z: number, scale: number, seed: number): number
	return math.noise(x / scale, z / scale, seed) -- about -0.5..0.5
end

local function terrace(h: number): number
	if h <= GROUND then
		return h
	end
	return GROUND + 2 * math.floor((h - GROUND) / 2 + 0.5)
end

local function plateauEdge(z: number): number
	if z < 30 then
		return MapData.Plateau.x0 + (z - 18) * 5 / 12
	end
	return 110
end

local function heightAndTop(x: number, z: number): (number, string)
	local h = GROUND
	local top = "grass"
	-- west ridge (x 0-25) and north ridge (z 0-18), terraced like Minecraft hills
	local mountain = 0
	if x < 26 then
		mountain =
			math.max(mountain, (26 - x) * 1.05 + noise(x, z, 9, 1.7) * 7 + noise(x, z, 23, 4.2) * 6)
	end
	if z < 19 then
		mountain = math.max(
			mountain,
			(19 - z) * 1.15 + noise(x, z, 10, 2.3) * 7 + noise(x, z, 27, 8.1) * 6
		)
	end
	if mountain > 0.5 then
		h = terrace(GROUND + mountain)
		if h >= GROUND + 18 then
			top = "stone"
		end
	end
	-- north-east hill with the mine (rises 6 blocks from its border)
	local P = MapData.Plateau
	if z >= P.z0 and z < P.z1 and x >= plateauEdge(z) then
		local d = math.min(x - plateauEdge(z), P.z1 - z, N - x)
		local ph = GROUND + math.min(P.height, math.floor(d * 0.7))
		if ph > h then
			h = ph
		end
	end
	-- Tung Tung's hill: a round dome
	local hill = MapData.TungHill
	local dist = math.sqrt((x + 0.5 - hill.x) ^ 2 + (z + 0.5 - hill.z) ^ 2)
	if dist < hill.radius then
		local k = if dist < 3.5 then 1 else 1 - ((dist - 3.5) / (hill.radius - 3.5)) ^ 2
		h = math.max(h, GROUND + math.floor(hill.height * k + 0.5))
	end
	-- the river and its sand banks
	local R = MapData.River
	if z >= 18 then
		if x >= R.x0 and x < R.x1 then
			return R.bedY, "sand"
		elseif x >= R.x0 - R.bank and x < R.x1 + R.bank then
			return math.min(h, GROUND), "sand"
		end
	end
	-- the gorge in the forest
	local G = MapData.Gorge
	if inRect(x, z, G.x0, G.x1, G.z0, G.z1) then
		return GROUND - G.depth, "gravel"
	end
	-- fields: farmland with a water canal
	local F = MapData.Fields
	if inRect(x, z, F.x0, F.x1, F.z0, F.z1) then
		if z == F.canalZ then
			return GROUND - 1, "dirt"
		end
		return GROUND, "dirt"
	end
	-- the notch in front of the mine door
	if inRect(x, z, 119, 126, 30, 37) then
		return GROUND, "dirt_path"
	end
	-- rail bed from the tunnel to the station
	if inRect(x, z, 22, 52, 79, 82) then
		return math.max(GROUND, if x < 23 then 18 else GROUND), "gravel"
	end
	-- the tunnel portal needs rock above the tunnel
	local T = MapData.Tunnel
	if inRect(x, z, T.x0, T.x1 + 1, T.z0 - 2, T.z1 + 2) then
		h = math.max(h, T.y1 + 2)
	end
	if h == GROUND then
		for _, p in MapData.Paths do
			if inRect(x, z, p[1], p[2], p[3], p[4]) then
				return h, "dirt_path"
			end
		end
		if
			inRect(x, z, MapData.Square.x0, MapData.Square.x1, MapData.Square.z0, MapData.Square.z1)
		then
			return h, "dirt_path"
		end
		local A = MapData.Airstrip
		if inRect(x, z, A.x0, A.x1, A.z0, A.z1) then
			return h, "gravel"
		end
	end
	return h, top
end

local function segmentsFor(h: number, top: string): { Segment }
	local base = math.min(BASE, h - 3)
	local segs: { Segment } = {}
	if h <= GROUND + 6 then
		if h - 4 > base then
			table.insert(segs, { y0 = base, y1 = h - 4, block = "stone" })
		end
		local under = if top == "sand" then "sand" elseif top == "gravel" then "stone" else "dirt"
		table.insert(segs, { y0 = math.max(base, h - 4), y1 = h - 1, block = under })
	else
		table.insert(segs, { y0 = base, y1 = h - 1, block = "stone" })
	end
	table.insert(segs, { y0 = h - 1, y1 = h, block = top })
	return segs
end

local function applyCarve(c: Carve)
	for x = math.floor(c.x0), math.ceil(c.x1) - 1 do
		for z = math.floor(c.z0), math.ceil(c.z1) - 1 do
			if x >= 0 and x < N and z >= 0 and z < N and inRect(x, z, c.x0, c.x1, c.z0, c.z1) then
				local out: { Segment } = {}
				for _, s in columns[idx(x, z)] do
					if s.y1 <= c.y0 or s.y0 >= c.y1 then
						table.insert(out, s)
					else
						if s.y0 < c.y0 then
							table.insert(out, { y0 = s.y0, y1 = c.y0, block = s.block })
						end
						if s.y1 > c.y1 then
							table.insert(out, { y0 = c.y1, y1 = s.y1, block = s.block })
						end
					end
				end
				if c.floor then
					-- the block right under the carve becomes the floor
					for i, s in out do
						if s.y1 == c.y0 then
							if s.y1 - s.y0 > 1 then
								out[i] = { y0 = s.y0, y1 = s.y1 - 1, block = s.block }
								table.insert(
									out,
									i + 1,
									{ y0 = s.y1 - 1, y1 = s.y1, block = c.floor }
								)
							else
								out[i] = { y0 = s.y0, y1 = s.y1, block = c.floor }
							end
							break
						end
					end
				end
				columns[idx(x, z)] = out
			end
		end
	end
end

local CARVES: { Carve } = {
	-- the minecart tunnel in the west ridge (CS-00 / CS-01)
	{
		x0 = MapData.Tunnel.x0 + 2,
		x1 = MapData.Tunnel.x1,
		z0 = MapData.Tunnel.z0,
		z1 = MapData.Tunnel.z1,
		y0 = MapData.Tunnel.y0,
		y1 = MapData.Tunnel.y1,
		floor = "gravel",
	},
	-- the room behind the mine door and the ladder shaft down to the adit
	{ x0 = 120, x1 = 125, z0 = 25, z1 = 30, y0 = 12, y1 = 15, floor = "oak_planks" },
	{ x0 = 121, x1 = 124, z0 = 25, z1 = 27, y0 = BASE, y1 = 12 },
	-- the hole in the cave roof (Bombardiro flies through it, CS-18)
	{
		x0 = MapData.SkyHole.x,
		x1 = MapData.SkyHole.x + MapData.SkyHole.w,
		z0 = MapData.SkyHole.z,
		z1 = MapData.SkyHole.z + MapData.SkyHole.d,
		y0 = BASE,
		y1 = 40,
	},
}

--- Builds the height map, the columns and the merged Parts under `parent`.
function Terrain.build(parent: Instance)
	for x = 0, N - 1 do
		for z = 0, N - 1 do
			local h, top = heightAndTop(x, z)
			heights[idx(x, z)] = h
			tops[idx(x, z)] = top
			columns[idx(x, z)] = segmentsFor(h, top)
		end
	end
	for _, c in CARVES do
		applyCarve(c)
	end
	local signatures: { [number]: string } = {}
	for i, segs in columns do
		local bits = table.create(#segs)
		for k, s in segs do
			bits[k] = string.format("%s:%g:%g", s.block, s.y0, s.y1)
		end
		signatures[i] = table.concat(bits, "|")
	end
	local folder = Builder.folder(parent, "Terrain")
	local rects = Builder.greedy2D(N, N, function(i, j)
		local sig = signatures[idx(i, j)]
		return if sig and sig ~= "" then sig else nil
	end)
	for _, r in rects do
		for _, s in columns[idx(r.x, r.z)] do
			local opts: Builder.Opts? = nil
			if s.block == "grass" then
				opts = { tags = { "Grass" } }
			end
			Builder.box(folder, s.block, r.x, s.y0, r.z, r.w, s.y1 - s.y0, r.d, s.block, opts)
		end
	end
	-- water: the river (one long Part) and the field canal
	local R = MapData.River
	local water = Builder.box(
		folder,
		"River",
		R.x0,
		R.bedY,
		18,
		R.x1 - R.x0,
		MapData.WaterY - R.bedY,
		N - 18,
		"water"
	)
	water.CanQuery = false
	local F = MapData.Fields
	Builder.box(folder, "Canal", F.x0, GROUND - 1, F.canalZ, F.x1 - F.x0, 0.8, 1, "water")
	-- invisible walls a little inside the world edge (behind the slopes)
	local walls = Builder.folder(parent, "Bounds")
	for _, w in { { 0, 0, N, 1 }, { 0, N - 1, N, 1 }, { 0, 0, 1, N }, { N - 1, 0, 1, N } } do
		local p = Builder.box(
			walls,
			"Wall",
			w[1],
			-32,
			w[2],
			w[3],
			160,
			w[4],
			"stone",
			{ noTexture = true }
		)
		p.Transparency = 1
		p.CastShadow = false
	end
end

--- Surface height (top of the highest solid block) of a column, in blocks.
function Terrain.heightAt(x: number, z: number): number
	local h = heights[idx(math.clamp(math.floor(x), 0, N - 1), math.clamp(math.floor(z), 0, N - 1))]
	return h or GROUND
end

function Terrain.topAt(x: number, z: number): string
	return tops[idx(math.clamp(math.floor(x), 0, N - 1), math.clamp(math.floor(z), 0, N - 1))]
		or "grass"
end

return Terrain
