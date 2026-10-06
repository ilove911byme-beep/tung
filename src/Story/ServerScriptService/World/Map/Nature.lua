--!strict
-- Trees, flowers, tall grass, reeds, mushrooms, Patapim's great hollow tree and the flat
-- Minecraft clouds (map.md sections 3 and 5). Decor is CanCollide / CanQuery / CastShadow off.
-- Positions are deterministic (seeded Random), so every server builds the same valley.
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MapData = require(Shared:WaitForChild("World"):WaitForChild("MapData"))

local Builder = require(script.Parent.Builder)
local Terrain = require(script.Parent.Terrain)

local Nature = {}

-- trees near the village (choppable for the chapter 1 wood task)
local VILLAGE_TREES = {
	{ 60, 57 },
	{ 70, 57 },
	{ 93, 56 },
	{ 107, 75 },
	{ 57, 86 },
	{ 63, 96 },
	{ 75, 107 },
	{ 95, 107 },
	{ 107, 90 },
	{ 88, 112 },
	{ 52, 92 },
	{ 104, 58 },
}

local function blocked(x: number, z: number, margin: number): boolean
	for _, h in MapData.Houses do
		if
			x >= h.x - margin
			and x < h.x + h.w + margin
			and z >= h.z - margin
			and z < h.z + h.d + margin
		then
			return true
		end
	end
	local T = MapData.Tower
	if
		x >= T.x - margin
		and x < T.x + T.w + margin
		and z >= T.z - margin
		and z < T.z + T.d + margin
	then
		return true
	end
	local top = Terrain.topAt(x, z)
	return top ~= "grass" and top ~= "stone"
end

local function tree(
	parent: Instance,
	x: number,
	z: number,
	height: number,
	log: string,
	leafColor: string?
): Model
	local y = Terrain.heightAt(x, z)
	local m = Builder.model(parent, "Tree")
	Builder.box(m, "Trunk", x, y, z, 1, height, 1, log)
	local opts: Builder.Opts = { color = leafColor }
	Builder.box(m, "Leaves", x - 2, y + height - 2, z - 2, 5, 2, 5, "leaves", opts)
	Builder.box(m, "Leaves", x - 1, y + height, z - 1, 3, 1, 3, "leaves", opts)
	Builder.box(m, "Leaves", x, y + height + 1, z, 1, 1, 1, "leaves", opts)
	return m
end

local function patapimTree(parent: Instance)
	local P = MapData.PatapimTree
	local x, z = P.x, P.z
	local y = Terrain.heightAt(x + 1, z + 1)
	local m = Builder.model(parent, "PatapimTree")
	-- 3x3 trunk with the hollow (centre and south cells open for 3 blocks)
	Builder.box(m, "Trunk", x, y, z, 1, 14, 3, "oak_log")
	Builder.box(m, "Trunk", x + 2, y, z, 1, 14, 3, "oak_log")
	Builder.box(m, "Trunk", x + 1, y, z, 1, 14, 1, "oak_log")
	Builder.box(m, "Trunk", x + 1, y + 3, z + 1, 1, 11, 2, "oak_log")
	Builder.box(m, "HollowFloor", x + 1, y, z + 1, 1, 0.3, 2, "dirt")
	local glow = Builder.box(
		m,
		"HollowGlow",
		x + 1.4,
		y + 0.3,
		z + 1.2,
		0.2,
		0.2,
		0.2,
		"torch",
		{ decor = true }
	)
	glow.Color = Color3.fromHex("#FFD83A")
	Builder.light(glow, "#FFD83A", 6, 0.6)
	-- canopy and roots
	Builder.box(m, "Canopy", x - 4, y + 12, z - 4, 11, 4, 11, "leaves", { color = "#244E1A" })
	Builder.box(m, "Canopy", x - 2, y + 16, z - 2, 7, 3, 7, "leaves", { color = "#244E1A" })
	for _, r in { { -2, 1, 2, 1 }, { 3, 1, 2, 1 }, { 1, -2, 1, 2 }, { 1, 3, 1, 2 } } do
		Builder.box(m, "Root", x + r[1], y, z + r[2], r[3], 0.6, r[4], "oak_log")
	end
	return m
end

local function decor(parent: Instance, rng: Random)
	local folder = Builder.folder(parent, "Decor")
	local placed = 0
	local tries = 0
	while placed < 520 and tries < 6000 do
		tries += 1
		local x = rng:NextInteger(26, 150)
		local z = rng:NextInteger(20, 158)
		if not blocked(x, z, 1) and Terrain.topAt(x, z) == "grass" then
			local y = Terrain.heightAt(x, z)
			local roll = rng:NextNumber()
			local fx = x + rng:NextNumber() * 0.6
			local fz = z + rng:NextNumber() * 0.6
			if roll < 0.7 then
				Builder.box(
					folder,
					"TallGrass",
					fx,
					y,
					fz,
					0.35,
					0.6,
					0.35,
					"tall_grass",
					{ decor = true }
				)
			elseif roll < 0.85 then
				Builder.box(
					folder,
					"Flower",
					fx,
					y,
					fz,
					0.2,
					0.45,
					0.2,
					"flower_red",
					{ decor = true }
				)
			else
				Builder.box(
					folder,
					"Flower",
					fx,
					y,
					fz,
					0.2,
					0.45,
					0.2,
					"flower_yellow",
					{ decor = true }
				)
			end
			placed += 1
		end
	end
	-- reeds on the river banks
	local R = MapData.River
	for z = 20, 158, 3 do
		for _, x in { R.x0 - 0.6, R.x1 + 0.2 } do
			if
				rng:NextNumber() < 0.6
				and not (z >= MapData.Bridge.z0 - 1 and z < MapData.Bridge.z1 + 1)
			then
				Builder.box(
					folder,
					"Reed",
					x,
					MapData.Ground,
					z + rng:NextNumber(),
					0.2,
					1.1,
					0.2,
					"reed",
					{ decor = true }
				)
			end
		end
	end
end

local function forest(parent: Instance, rng: Random)
	local F = MapData.Forest
	local G = MapData.Gorge
	local P = MapData.PatapimTree
	local folder = Builder.folder(parent, "PatapimForest")
	for gx = F.x0 + 1, F.x1 - 2, 4 do
		for gz = F.z0 + 1, F.z1 - 2, 4 do
			local x = gx + rng:NextInteger(0, 2)
			local z = gz + rng:NextInteger(0, 2)
			local nearTree = math.abs(x - P.x) < 7 and math.abs(z - P.z) < 8
			local inGorge = z >= G.z0 - 2 and z < G.z1 + 2 and x >= G.x0 - 1 and x < G.x1 + 1
			if not nearTree and not inGorge and rng:NextNumber() < 0.85 then
				local pale = rng:NextNumber() < 0.4
				tree(
					folder,
					x,
					z,
					rng:NextInteger(5, 8),
					if pale then "pale_log" else "oak_log",
					if pale then "#3E7A2E" else "#244E1A"
				)
			end
		end
	end
	-- undergrowth: ferns and mushrooms
	for _ = 1, 140 do
		local x = rng:NextInteger(F.x0, F.x1 - 1) + rng:NextNumber()
		local z = rng:NextInteger(F.z0, F.z1 - 1) + rng:NextNumber()
		if Terrain.topAt(x, z) == "grass" then
			local y = Terrain.heightAt(x, z)
			if rng:NextNumber() < 0.7 then
				Builder.box(folder, "Fern", x, y, z, 0.6, 0.5, 0.6, "fern", { decor = true })
			else
				Builder.box(
					folder,
					"Mushroom",
					x,
					y,
					z,
					0.3,
					0.3,
					0.3,
					"mushroom",
					{ decor = true }
				)
			end
		end
	end
	-- fallen trunks (scenery; the chapter 4 parkour adds its own)
	local logs: { { x: number, z: number, alongX: boolean } } = {
		{ x = 44, z = 112, alongX = true },
		{ x = 30, z = 118, alongX = false },
		{ x = 48, z = 130, alongX = true },
		{ x = 22, z = 126, alongX = false },
	}
	for i, l in logs do
		local x, z, alongX = l.x, l.z, l.alongX
		Builder.box(
			folder,
			"FallenLog" .. i,
			x,
			Terrain.heightAt(x, z),
			z,
			if alongX then 6 else 1,
			1,
			if alongX then 1 else 6,
			"oak_log"
		)
	end
	patapimTree(folder)
end

local function clouds(parent: Instance, rng: Random)
	local folder = Builder.folder(parent, "Clouds")
	for i = 1, 26 do
		local w = rng:NextInteger(8, 22)
		local d = rng:NextInteger(5, 12)
		local x = rng:NextInteger(-30, 180)
		local z = rng:NextInteger(-10, 170)
		local c = Builder.box(folder, "Cloud" .. i, x, 60, z, w, 1, d, "cloud", { decor = true })
		CollectionService:AddTag(c, "Cloud")
	end
end

function Nature.build(parent: Instance)
	local folder = Builder.folder(parent, "Nature")
	local rng = Random.new(2024)
	local village = Builder.folder(folder, "VillageTrees")
	for i, t in VILLAGE_TREES do
		local m = tree(village, t[1], t[2], 4 + (i % 3), "oak_log")
		m.Name = "WoodTree" .. i
		m:SetAttribute("Wood", 3)
		CollectionService:AddTag(m, "WoodTree")
	end
	forest(folder, rng)
	decor(folder, rng)
	clouds(folder, rng)
	return folder
end

return Nature
