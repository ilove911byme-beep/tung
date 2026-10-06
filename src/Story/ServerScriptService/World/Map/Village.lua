--!strict
-- The village (map.md section 3): Minecraft-style houses (cobblestone foundation row, log
-- corners, plank or brick walls, glass windows with hidden shutters, stepped gable roofs),
-- the tavern, the clock tower with its spiral stairs, the square with the sahur table and the
-- four braziers, well, fountain, notice board, mill, station, rails, bridge, fields, fences and
-- torches, the mine door and the tunnel portal. Interiors carry the gameplay props.
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MapData = require(Shared:WaitForChild("World"):WaitForChild("MapData"))
local NamesList = require(Shared:WaitForChild("StoryData"):WaitForChild("NamesList"))

local Builder = require(script.Parent.Builder)
local Terrain = require(script.Parent.Terrain)

local Village = {}

local S = Builder.S

type Wall = {
	side: string,
	x: number, -- min corner of the wall strip
	z: number,
	alongX: boolean,
	length: number,
}

local function tag(inst: Instance, name: string)
	CollectionService:AddTag(inst, name)
end

--- A torch on a short post (or on a wall when `post` is false). Tagged "Lamp".
local function torch(
	parent: Instance,
	x: number,
	y: number,
	z: number,
	post: boolean?,
	tagName: string?
)
	if post then
		Builder.box(parent, "Post", x - 0.125, y, z - 0.125, 0.25, 1.5, 0.25, "oak_log")
		y += 1.5
	end
	local flame =
		Builder.box(parent, "Torch", x - 0.1, y, z - 0.1, 0.2, 0.45, 0.2, "torch", { decor = true })
	Builder.light(flame, "#FFA040", 12, 1.1, tagName or "Lamp")
	return flame
end

local function door(
	parent: Instance,
	name: string,
	cf: CFrame,
	width: number,
	height: number,
	color: string,
	open: boolean
): Part
	-- cf: center of the closed door; hinge on its local -X edge
	local size = Vector3.new(width * S, height * S, 0.3 * S)
	local hinge = cf * CFrame.new(-size.X / 2, 0, 0)
	local openCf = hinge * CFrame.Angles(0, math.rad(95), 0) * CFrame.new(size.X / 2, 0, 0)
	local p = Builder.part(
		parent,
		name,
		if open then openCf else cf,
		size,
		"oak_planks",
		{ color = color }
	)
	p:SetAttribute("ClosedCFrame", cf)
	p:SetAttribute("OpenCFrame", openCf)
	p:SetAttribute("Open", open)
	tag(p, "Door")
	return p
end

--- Walls of a house: greedy-merged rows with door / window openings.
local function buildWall(
	model: Model,
	house: MapData.House,
	wall: Wall,
	baseY: number,
	wallBlock: string
)
	local H = house.height
	local len = wall.length
	local isDoorSide = wall.side == house.door
	local dw = house.doorWidth or 1
	local dh = house.doorHeight or 2
	local door0 = -1
	if isDoorSide then
		local center = house.doorAt
		local start = if wall.alongX then wall.x else wall.z
		if center then
			door0 = math.floor(center - start - dw / 2 + 0.5)
		else
			door0 = math.floor((len - dw) / 2)
		end
	end
	local windows: { [number]: boolean } = {}
	if len >= 3 then
		local step = if len <= 5 then len else 3
		local i = if len <= 5 then math.floor(len / 2) else 1
		while i < len do
			local nearDoor = isDoorSide and i >= door0 - 1 and i <= door0 + dw
			if not nearDoor then
				windows[i] = true
			end
			i += step
		end
	end
	local function isWindowRow(j: number): boolean
		local r = j % 4
		return j > 0 and j < H - 1 and (r == 1 or r == 2)
	end
	local rects = Builder.greedy2D(len, H, function(i, j)
		if isDoorSide and i >= door0 and i < door0 + dw and j < dh then
			return nil
		end
		if windows[i] and isWindowRow(j) and house.id ~= "Hangar" then
			return "glass"
		end
		if j == 0 then
			return "cobblestone"
		end
		return wallBlock
	end)
	for _, r in rects do
		local x, z, sx, sz
		if wall.alongX then
			x, z, sx, sz = wall.x + r.x, wall.z, r.w, 1
		else
			x, z, sx, sz = wall.x, wall.z + r.x, 1, r.w
		end
		if r.key == "glass" then
			-- thin pane in the middle of the wall + a hidden shutter outside (CS-10 / ch2)
			local inset = 0.4
			if wall.alongX then
				Builder.box(model, "Window", x, baseY + r.z, z + inset, sx, r.d, 0.2, "glass")
			else
				Builder.box(model, "Window", x + inset, baseY + r.z, z, 0.2, r.d, sz, "glass")
			end
			local out = if wall.side == "N"
				then -0.15
				elseif wall.side == "S" then 1.05
				elseif wall.side == "W" then -0.15
				else 1.05
			local shutter
			if wall.alongX then
				shutter = Builder.box(
					model,
					"Shutter",
					x,
					baseY + r.z,
					z + out - 0.05,
					sx,
					r.d,
					0.1,
					"oak_planks",
					{ color = house.doorColor }
				)
			else
				shutter = Builder.box(
					model,
					"Shutter",
					x + out - 0.05,
					baseY + r.z,
					z,
					0.1,
					r.d,
					sz,
					"oak_planks",
					{ color = house.doorColor }
				)
			end
			shutter.Transparency = 1
			shutter.CanCollide = false
			shutter.CanQuery = false
			tag(shutter, "Shutter")
		else
			Builder.box(model, r.key, x, baseY + r.z, z, sx, r.d, sz, r.key)
		end
	end
	if isDoorSide then
		local cx, cz
		if wall.alongX then
			cx, cz = wall.x + door0 + dw / 2, wall.z + 0.5
		else
			cx, cz = wall.x + 0.5, wall.z + door0 + dw / 2
		end
		local yaw = if wall.alongX then 0 else 90
		local cf = CFrame.new(Builder.studs(cx, baseY + dh / 2, cz))
			* CFrame.Angles(0, math.rad(yaw), 0)
		local d = door(model, "Door", cf, dw, dh, house.doorColor, true)
		if house.id == "Tavern" then
			tag(d, "TavernDoor")
		end
		-- torch beside the door, outside
		local ox = if wall.side == "E" then 1.2 elseif wall.side == "W" then -0.2 else 0
		local oz = if wall.side == "S" then 1.2 elseif wall.side == "N" then -0.2 else 0
		local tx = if wall.alongX then cx + dw / 2 + 0.6 else cx - 0.5 + ox
		local tz = if wall.alongX then cz - 0.5 + oz else cz + dw / 2 + 0.6
		torch(model, tx, baseY + 1.6, tz)
	end
end

local function roof(
	model: Model,
	x: number,
	y: number,
	z: number,
	w: number,
	d: number,
	color: string
)
	local alongX = w >= d
	local short = if alongX then d else w
	local layers = math.ceil((short + 2) / 2)
	for i = 0, layers - 1 do
		local extent = short + 2 - 2 * i
		if extent <= 0 then
			break
		end
		if alongX then
			Builder.box(
				model,
				"Roof",
				x - 1,
				y + i,
				z - 1 + i,
				w + 2,
				1,
				extent,
				"oak_planks",
				{ color = color }
			)
		else
			Builder.box(
				model,
				"Roof",
				x - 1 + i,
				y + i,
				z - 1,
				extent,
				1,
				d + 2,
				"oak_planks",
				{ color = color }
			)
		end
	end
end

--- A complete house from MapData. Returns its model and floor height.
local function house(parent: Instance, h: MapData.House): (Model, number)
	local model = Builder.model(parent, h.id)
	local baseY = Terrain.heightAt(h.x + h.w / 2, h.z + h.d / 2)
	local wallBlock = h.wall or "oak_planks"
	-- floor and corner logs
	Builder.box(model, "Floor", h.x + 1, baseY, h.z + 1, h.w - 2, 0.1, h.d - 2, "oak_planks")
	for _, c in
		{
			{ h.x, h.z },
			{ h.x + h.w - 1, h.z },
			{ h.x, h.z + h.d - 1 },
			{ h.x + h.w - 1, h.z + h.d - 1 },
		}
	do
		Builder.box(model, "Corner", c[1], baseY, c[2], 1, h.height, 1, h.trim or "oak_log")
	end
	local walls: { Wall } = {
		{ side = "N", x = h.x + 1, z = h.z, alongX = true, length = h.w - 2 },
		{ side = "S", x = h.x + 1, z = h.z + h.d - 1, alongX = true, length = h.w - 2 },
		{ side = "W", x = h.x, z = h.z + 1, alongX = false, length = h.d - 2 },
		{ side = "E", x = h.x + h.w - 1, z = h.z + 1, alongX = false, length = h.d - 2 },
	}
	for _, wall in walls do
		buildWall(model, h, wall, baseY, wallBlock)
	end
	roof(model, h.x, baseY + h.height, h.z, h.w, h.d, h.roof)
	-- a lamp under the roof
	local lamp = Builder.box(
		model,
		"Lamp",
		h.x + h.w / 2 - 0.2,
		baseY + h.height - 0.8,
		h.z + h.d / 2 - 0.2,
		0.4,
		0.5,
		0.4,
		"torch",
		{ decor = true }
	)
	Builder.light(lamp, "#FFC070", 16, 0.9, if h.id == "Tavern" then "TavernLamp" else "Lamp")
	return model, baseY
end

------------------------------------------------------------------ furniture helpers

local function bed(model: Instance, x: number, y: number, z: number, alongX: boolean)
	local sx, sz = if alongX then 2 else 1, if alongX then 1 else 2
	Builder.box(model, "BedFrame", x, y, z, sx, 0.5, sz, "oak_planks")
	Builder.box(model, "Blanket", x, y + 0.5, z, sx, 0.15, sz, "wool_red")
	local pillowX = if alongX then x else x
	Builder.box(
		model,
		"Pillow",
		pillowX,
		y + 0.5,
		z,
		if alongX then 0.5 else 1,
		0.25,
		if alongX then 1 else 0.5,
		"white"
	)
end

local function hidingSpot(
	parent: Instance,
	name: string,
	x: number,
	y: number,
	z: number,
	spotName: string
)
	local m = Builder.marker(parent, name, x, y, z, 0, { SpotName = spotName })
	m.Size = Vector3.new(2, 5, 2)
	m.CFrame = CFrame.new(Builder.studs(x, y, z) + Vector3.new(0, 3, 0))
	tag(m, "HidingSpot")
	return m
end

local function barrel(model: Instance, x: number, y: number, z: number)
	Builder.part(
		model,
		"Barrel",
		CFrame.new(Builder.studs(x + 0.5, y + 0.5, z + 0.5)) * CFrame.Angles(0, 0, math.rad(90)),
		Vector3.new(S, S * 0.9, S * 0.9),
		"oak_log",
		{ shape = "Cylinder" }
	)
end

local function tavern(model: Model, baseY: number)
	-- fireplace on the west wall (fire for chapter 2, M4 hides behind it)
	local fp = Builder.model(model, "Fireplace")
	Builder.box(fp, "Hearth", 62.5, baseY, 77.5, 1.2, 3, 3, "cobblestone")
	Builder.box(fp, "Chimney", 62.5, baseY + 3, 78, 1, 6, 2, "cobblestone")
	local fire =
		Builder.box(fp, "FirePlace", 63.4, baseY, 78.4, 0.8, 0.6, 1.2, "torch", { decor = true })
	fire.Color = Color3.fromHex("#FF7A20")
	local flame = Instance.new("Fire")
	flame.Size = 4
	flame.Heat = 6
	flame.Parent = fire
	Builder.light(fire, "#FF8A3A", 18, 1.6)
	fire:SetAttribute("Sound", "amb_fireplace_loop")
	fire:SetAttribute("Volume", 0.6)
	fire:SetAttribute("MaxDistance", 40)
	tag(fire, "AmbienceEmitter")
	tag(fire, "Fireplace")
	Builder.box(fp, "Logs", 63.6, baseY, 76.6, 0.8, 0.5, 0.8, "oak_log")
	-- ramp to the upper floor along the north wall, the upper floor around the stair hole
	local ramp = Instance.new("WedgePart")
	ramp.Name = "StairRamp"
	ramp.Anchored = true
	ramp.Size = Vector3.new(1.5 * S, 4 * S, 6 * S)
	ramp.CFrame = CFrame.new(Builder.studs(66.5, baseY + 2, 76.25))
		* CFrame.Angles(0, math.rad(-90), 0)
	ramp.Material = Enum.Material.WoodPlanks
	ramp.Color = Color3.fromHex("#9C7646")
	ramp:SetAttribute("Block", "oak_planks")
	ramp.Parent = model
	Builder.partCount += 1
	Builder.box(model, "UpperFloor", 62.5, baseY + 3.75, 77, 7, 0.25, 7.5, "oak_planks")
	Builder.box(model, "UpperFloor", 62.5, baseY + 3.75, 75.5, 1, 0.25, 1.5, "oak_planks")
	-- tables and stools
	for i, t in { { 65, 80.5 }, { 67.5, 80.5 } } do
		Builder.box(model, "Table" .. i, t[1], baseY, t[2], 1.2, 0.9, 1.2, "oak_planks")
		Builder.box(model, "Stool", t[1] - 0.8, baseY, t[2] + 0.3, 0.5, 0.5, 0.5, "oak_log")
		Builder.box(model, "Stool", t[1] + 1.5, baseY, t[2] + 0.3, 0.5, 0.5, 0.5, "oak_log")
	end
	-- crates to drag to the door (chapter 2 barricade)
	for i = 1, 3 do
		local p = MapData.Points["Crate" .. i]
		local crate = Builder.box(
			model,
			"Crate" .. i,
			p.x - 0.4,
			baseY,
			p.z + 1,
			0.8,
			0.8,
			0.8,
			"oak_planks",
			{ color = "#8A6436" }
		)
		tag(crate, "Crate")
	end
	-- hiding spots: wardrobes, beds, barrels
	local hide = Builder.folder(model, "HidingSpots")
	for i, w in { { 63, 84 }, { 64.5, 84 } } do
		Builder.box(
			model,
			"Wardrobe" .. i,
			w[1] - 0.5,
			baseY,
			w[2] - 0.5,
			1.2,
			2.5,
			1,
			"oak_planks",
			{ color = "#6A4A2A" }
		)
		hidingSpot(hide, "Wardrobe" .. i, w[1], baseY, w[2], "In the wardrobe")
	end
	for i, b in { { 66, 82.9 }, { 68, 82.9 } } do
		bed(model, b[1] - 0.5, baseY, b[2] - 0.5, false)
		hidingSpot(hide, "Bed" .. i, b[1], baseY, b[2], "Under the bed")
	end
	bed(model, 63, baseY + 4, 82, true)
	hidingSpot(hide, "Bed3", 64, baseY + 4, 82.5, "Under the bed")
	for i, b in { { 68.4, 77.2 }, { 68.4, 79.4 } } do
		barrel(model, b[1], baseY, b[2])
		barrel(model, b[1], baseY, b[2] + 1)
		barrel(model, b[1], baseY + 1, b[2])
		hidingSpot(hide, "Barrels" .. i, b[1] - 0.6, baseY, b[2] + 0.5, "Behind the barrels")
	end
	-- red wool banners on the east facade and the tavern sign
	for _, z in { 76, 82 } do
		Builder.box(model, "Banner", 70.55, baseY + 4.5, z, 0.1, 2.5, 1, "wool_red")
	end
	Builder.sign(
		model,
		"TavernSign",
		CFrame.new(Builder.studs(70.8, baseY + 2.6, 82.6)) * CFrame.Angles(0, math.rad(-90), 0),
		Vector3.new(2.4 * S, 0.7 * S, 0.15 * S),
		"Sleepy Sahur"
	)
end

local function ballerinaHouse(model: Model, baseY: number)
	-- pink curtains, the mirror (M5), her bed, the loose floorboards (clue 4)
	Builder.box(
		model,
		"Mirror",
		93.8,
		baseY + 1,
		73.55,
		1.4,
		2.2,
		0.1,
		"glass",
		{ color = "#DDEEFF", transparency = 0.2 }
	)
	Builder.box(model, "MirrorFrame", 93.7, baseY + 0.9, 73.5, 1.6, 2.4, 0.05, "pink")
	for _, z in { 75.05, 76.55 } do
		Builder.box(model, "Curtain", 97.35, baseY + 1, z, 0.1, 2, 0.4, "pink")
	end
	bed(model, 95.4, baseY, 73.6, true)
	local boards = Builder.folder(model, "Floorboards")
	for i = 0, 4 do
		local b = Builder.box(
			boards,
			"Floorboard",
			92.5 + i,
			baseY + 0.1,
			76.6,
			1,
			0.05,
			0.8,
			"oak_planks",
			{ color = "#8C6A3E" }
		)
		b:SetAttribute("Index", i + 1)
		tag(b, "Floorboard")
	end
end

local function bakery(model: Model, baseY: number)
	Builder.box(model, "Oven", 94.5, baseY, 85.5, 1, 2, 2, "cobblestone")
	local glow = Builder.box(
		model,
		"OvenFire",
		94.4,
		baseY + 0.3,
		86,
		0.2,
		0.6,
		1,
		"torch",
		{ decor = true }
	)
	Builder.light(glow, "#FF8A3A", 10, 1)
	Builder.box(model, "Counter", 91, baseY, 88, 1, 1, 3, "oak_planks")
	Builder.box(model, "BreadShelf", 91, baseY, 91.9, 3, 1.5, 0.6, "oak_planks")
	for i = 0, 2 do
		Builder.box(
			model,
			"Bread",
			91.2 + i,
			baseY + 1.5,
			92,
			0.6,
			0.25,
			0.35,
			"hay",
			{ decor = true }
		)
	end
end

local function shop(model: Model, baseY: number)
	Builder.box(model, "Counter", 67.5, baseY, 90.5, 4, 1, 0.8, "oak_planks", { color = "#C8A030" })
	for i = 0, 4 do
		Builder.box(
			model,
			"Banana",
			67.8 + i * 0.7,
			baseY + 1,
			90.7,
			0.5,
			0.2,
			0.25,
			"flower_yellow",
			{ decor = true }
		)
	end
	for i = 0, 2 do
		local l = Builder.box(
			model,
			"LanternForSale",
			70.5 + i * 0.6,
			baseY + 1,
			93.5,
			0.35,
			0.45,
			0.35,
			"torch",
			{ decor = true }
		)
		Builder.light(l, "#FFD070", 6, 0.6, "Lamp")
	end
end

local function workshop(model: Model, baseY: number)
	Builder.box(model, "Workbench", 89, baseY, 62, 2, 1, 1, "oak_planks")
	local box = Builder.box(
		model,
		"MusicBox",
		87.6,
		baseY,
		61.7,
		0.8,
		0.6,
		0.6,
		"oak_planks",
		{ color = "#6A3A8A" }
	)
	tag(box, "MusicBox")
	Builder.sign(
		model,
		"CodeBoard",
		CFrame.new(Builder.studs(86.6, baseY + 1.8, 64)) * CFrame.Angles(0, math.rad(-90), 0),
		Vector3.new(1.8 * S, 1.2 * S, 0.1 * S),
		"3 . 1 . 2"
	)
	for i = 0, 3 do
		Builder.part(
			model,
			"WallClock",
			CFrame.new(Builder.studs(87.5 + i * 1.3, baseY + 2.8, 61.6))
				* CFrame.Angles(0, math.rad(90), 0),
			Vector3.new(0.15, 1.2 * S * 0.5, 1.2 * S * 0.5),
			"white",
			{ shape = "Cylinder", color = "#E8D8A8", decor = true }
		)
	end
end

local function barn(model: Model, baseY: number)
	for i, p in { { 105, 65.5 }, { 106, 65.5 }, { 105, 66.5 }, { 105, 65.5 } } do
		Builder.box(model, "Hay", p[1], baseY + (if i == 4 then 1 else 0), p[2], 1, 1, 1, "hay")
	end
	-- the cell (fence bars) where an accused villager is locked away
	for i = 0, 3 do
		Builder.box(model, "Bar", 102.5, baseY, 66.5 + i * 0.9, 0.15, 3, 0.15, "oak_log")
	end
end

local function cameo(model: Model, h: MapData.House, baseY: number)
	bed(model, h.x + 1, baseY, h.z + 1, true)
	Builder.box(model, "Table", h.x + h.w - 2, baseY, h.z + h.d - 2, 1, 0.9, 1, "oak_planks")
end

local function tungHut(model: Model, baseY: number)
	-- the board of names (M6 lies beside it)
	local text = table.concat(NamesList.base, "\n")
	Builder.sign(
		model,
		"NameBoard",
		CFrame.new(Builder.studs(82.1, baseY + 1.6, 126)) * CFrame.Angles(0, math.rad(-90), 0),
		Vector3.new(2.2 * S, 1.6 * S, 0.15 * S),
		text
	)
end

local function hangar(model: Model, baseY: number)
	Builder.sign(
		model,
		"CaveMap",
		CFrame.new(Builder.studs(119.6, baseY + 1.8, 86)) * CFrame.Angles(0, math.rad(-90), 0),
		Vector3.new(2.6 * S, 1.8 * S, 0.1 * S),
		"MINE  ~  LAB  ~  LAVA  ~  ???"
	)
	Builder.box(model, "Crates", 127, baseY, 83, 1.5, 1, 1.5, "oak_planks")
	Builder.box(model, "Crates", 127.2, baseY + 1, 83.2, 1, 1, 1, "oak_planks")
end

local function mill(model: Model, baseY: number)
	local M = { x = 99, z = 99, w = 5 }
	local hub = CFrame.new(Builder.studs(M.x + M.w / 2, baseY + 6, M.z + 5.4))
	local wings = Builder.model(model, "Wings")
	local center = Builder.part(wings, "Hub", hub, Vector3.new(S, S, S * 0.6), "oak_log")
	for i = 0, 3 do
		Builder.part(
			wings,
			"Blade",
			hub * CFrame.Angles(0, 0, math.rad(i * 90)) * CFrame.new(0, 2.6 * S, 0),
			Vector3.new(0.9 * S, 4.4 * S, 0.15 * S),
			"white",
			{ color = "#E8E0D0" }
		)
	end
	wings.PrimaryPart = center
	wings:SetAttribute("SpinAxis", "Z")
	wings:SetAttribute("SpinSpeed", 18) -- degrees per second, driven by the client
	tag(wings, "Spin")
end

------------------------------------------------------------------ landmarks

local function tower(parent: Instance)
	local T = MapData.Tower
	local model = Builder.model(parent, "ClockTower")
	local y0 = MapData.Ground
	local top = y0 + T.height -- 42
	local function ring(yA: number, yB: number, block: string)
		Builder.box(model, block, T.x, yA, T.z, T.w, yB - yA, 1, block)
		Builder.box(model, block, T.x, yA, T.z + T.d - 1, 3, yB - yA, 1, block)
		Builder.box(model, block, T.x + 4, yA, T.z + T.d - 1, 3, yB - yA, 1, block)
		Builder.box(model, block, T.x, yA, T.z + 1, 1, yB - yA, T.d - 2, block)
		Builder.box(model, block, T.x + T.w - 1, yA, T.z + 1, 1, yB - yA, T.d - 2, block)
	end
	-- the south wall has the door column (x + 3) open at the bottom only
	ring(y0, y0 + 2, "cobblestone")
	Builder.box(model, "cobblestone", T.x, y0 + 2, T.z + T.d - 1, T.w, 2, 1, "cobblestone")
	Builder.box(model, "cobblestone", T.x, y0 + 2, T.z, T.w, 2, 1, "cobblestone")
	Builder.box(model, "cobblestone", T.x, y0 + 2, T.z + 1, 1, 2, T.d - 2, "cobblestone")
	Builder.box(model, "cobblestone", T.x + T.w - 1, y0 + 2, T.z + 1, 1, 2, T.d - 2, "cobblestone")
	Builder.box(model, "bricks", T.x, y0 + 4, T.z + T.d - 1, T.w, 18, 1, "bricks")
	Builder.box(model, "bricks", T.x, y0 + 4, T.z, T.w, 18, 1, "bricks")
	Builder.box(model, "bricks", T.x, y0 + 4, T.z + 1, 1, 18, T.d - 2, "bricks")
	Builder.box(model, "bricks", T.x + T.w - 1, y0 + 4, T.z + 1, 1, 18, T.d - 2, "bricks")
	-- bell chamber (planks) with arches on the east, west and north sides
	local yb = y0 + 22 -- 34
	Builder.box(model, "oak_planks", T.x, yb, T.z + T.d - 1, T.w, 6, 1, "oak_planks")
	for _, side in { "N", "E", "W" } do
		if side == "N" then
			Builder.box(model, "Pillar", T.x, yb, T.z, 2, 6, 1, "oak_log")
			Builder.box(model, "Pillar", T.x + T.w - 2, yb, T.z, 2, 6, 1, "oak_log")
			Builder.box(model, "Lintel", T.x + 2, yb + 4, T.z, T.w - 4, 2, 1, "oak_planks")
			Builder.box(model, "Sill", T.x + 2, yb, T.z, T.w - 4, 1, 1, "oak_planks")
		else
			local x = if side == "E" then T.x + T.w - 1 else T.x
			Builder.box(model, "Pillar", x, yb, T.z + 1, 1, 6, 1, "oak_log")
			Builder.box(model, "Pillar", x, yb, T.z + T.d - 2, 1, 6, 1, "oak_log")
			Builder.box(model, "Lintel", x, yb + 4, T.z + 2, 1, 2, T.d - 4, "oak_planks")
			Builder.box(model, "Sill", x, yb, T.z + 2, 1, 1, T.d - 4, "oak_planks")
		end
	end
	-- roof platform (M12 on top) with a parapet
	Builder.box(
		model,
		"RoofSlab",
		T.x,
		top - 2,
		T.z,
		T.w,
		2,
		T.d,
		"oak_planks",
		{ color = "#7A5230" }
	)
	for _, p in
		{
			{ T.x, T.z, T.w, 1 },
			{ T.x, T.z + T.d - 1, T.w, 1 },
			{ T.x, T.z + 1, 1, T.d - 2 },
			{ T.x + T.w - 1, T.z + 1, 1, T.d - 2 },
		}
	do
		Builder.box(model, "Parapet", p[1], top, p[2], p[3], 1, p[4], "cobblestone")
	end
	Builder.box(
		model,
		"Hatch",
		T.x + 5,
		top - 2,
		T.z + 1,
		1,
		2,
		1,
		"oak_planks",
		{ transparency = 1, collide = false }
	)
	-- floors inside: ground and the bell chamber floor (hole above the last stairs)
	Builder.box(model, "Floor", T.x + 1, y0, T.z + 1, T.w - 2, 0.1, T.d - 2, "oak_planks")
	Builder.box(
		model,
		"ChamberFloor",
		T.x + 2,
		yb - 0.25,
		T.z + 1,
		T.w - 3,
		0.25,
		T.d - 2,
		"oak_planks"
	)
	-- spiral stairs around the inside walls: 44 half-block steps from the door to the chamber
	local ringCells = {
		{ 4, 4 },
		{ 4, 3 },
		{ 4, 2 },
		{ 4, 1 },
		{ 4, 0 },
		{ 3, 0 },
		{ 2, 0 },
		{ 1, 0 },
		{ 0, 0 },
		{ 0, 1 },
		{ 0, 2 },
		{ 0, 3 },
		{ 0, 4 },
		{ 1, 4 },
		{ 2, 4 },
		{ 3, 4 },
	}
	local stairs = Builder.folder(model, "Stairs")
	for i = 1, 44 do
		local c = ringCells[((i - 1) % #ringCells) + 1]
		local step = Builder.box(
			stairs,
			"Step" .. i,
			T.x + 1 + c[1],
			y0 + i * 0.5 - 0.5,
			T.z + 1 + c[2],
			1,
			0.5,
			1,
			"oak_planks"
		)
		step:SetAttribute("Index", i)
		tag(step, "TowerStair")
	end
	-- the ladder from the chamber to the roof
	local truss = Instance.new("TrussPart")
	truss.Name = "RoofLadder"
	truss.Anchored = true
	truss.Size = Vector3.new(2, (top - yb) * S, 2)
	truss.CFrame = CFrame.new(Builder.studs(T.x + 5.5, (yb + top) / 2, T.z + 1.5))
	truss.Color = Color3.fromHex("#7A5A34")
	truss.Parent = model
	-- outside ladder on the east face up to the balcony (rooftop parkour, M7)
	local outer = truss:Clone()
	outer.Name = "BalconyLadder"
	outer.Size = Vector3.new(2, 12 * S, 2)
	outer.CFrame = CFrame.new(Builder.studs(T.x + T.w + 0.25, yb - 6, T.z + 4.5))
	outer.Parent = model
	Builder.box(model, "Balcony", T.x + T.w, yb - 0.25, T.z + 2.5, 2, 0.25, 2, "oak_planks")
	Builder.partCount += 2
	-- clock face on the south wall with stopped hands, the bell, the gear mechanism
	local faceCf = CFrame.new(Builder.studs(80, 36, T.z + T.d + 0.08))
		* CFrame.Angles(0, math.rad(90), 0)
	local clock = Builder.model(model, "ClockFace")
	Builder.part(
		clock,
		"Dial",
		faceCf,
		Vector3.new(0.2 * S, 4.6 * S, 4.6 * S),
		"white",
		{ shape = "Cylinder", color = "#F0E6C8" }
	)
	local handBase = CFrame.new(Builder.studs(80, 36, T.z + T.d + 0.16))
	local hour = Builder.part(
		clock,
		"HourHand",
		handBase * CFrame.Angles(0, 0, math.rad(-60)) * CFrame.new(0, 0.6 * S, 0),
		Vector3.new(0.3 * S, 1.2 * S, 0.1 * S),
		"black"
	)
	local minute = Builder.part(
		clock,
		"MinuteHand",
		handBase * CFrame.Angles(0, 0, math.rad(20)) * CFrame.new(0, 0.9 * S, 0),
		Vector3.new(0.2 * S, 1.8 * S, 0.1 * S),
		"black"
	)
	hour:SetAttribute("Pivot", handBase)
	minute:SetAttribute("Pivot", handBase)
	tag(clock, "ClockFace")
	local bell = Builder.part(
		model,
		"Bell",
		CFrame.new(Builder.studs(80, yb + 3.2, 66)),
		Vector3.new(1.4 * S, 1.6 * S, 1.4 * S),
		"gold_ore",
		{ color = "#C8A040", material = "Metal", noTexture = true }
	)
	tag(bell, "Bell")
	local mech = Builder.model(model, "Mechanism")
	Builder.box(mech, "Frame", T.x + 1.2, yb, T.z + 1, 4.6, 2.2, 0.6, "oak_log")
	for i = 1, 3 do
		local p = MapData.Points["GearSocket" .. i]
		local socket = Builder.part(
			mech,
			"GearSocket" .. i,
			CFrame.new(Builder.studs(p.x, p.y + 0.6, T.z + 1.65))
				* CFrame.Angles(0, math.rad(90), 0),
			Vector3.new(0.2 * S, 1.1 * S, 1.1 * S),
			"black",
			{ shape = "Cylinder" }
		)
		socket:SetAttribute("Index", i)
		tag(socket, "GearSocket")
	end
	-- tower door (Tung Tung holds it in CS-21)
	local doorCf = CFrame.new(Builder.studs(80, y0 + 1, T.z + T.d - 0.5))
	local d = door(model, "TowerDoor", doorCf, 1, 2, "#5A3418", true)
	tag(d, "TowerDoor")
	torch(model, T.x + 2.4, y0 + 1.8, T.z + T.d + 0.2)
	torch(model, T.x + 4.6, y0 + 1.8, T.z + T.d + 0.2)
	local inside =
		Builder.box(model, "Lamp", 79.8, y0 + 20, 65.8, 0.4, 0.4, 0.4, "torch", { decor = true })
	Builder.light(inside, "#FFC070", 20, 0.8, "Lamp")
	return model
end

local function square(parent: Instance)
	local model = Builder.model(parent, "Square")
	local g = MapData.Ground
	-- the long sahur table: 2 x 12 blocks with 16 chairs; some chairs carry name signs
	local table_ = Builder.model(model, "SahurTable")
	Builder.box(table_, "Top", 79, g + 0.8, 74, 2, 0.2, 12, "oak_planks")
	for _, leg in
		{ { 79, 74 }, { 80.75, 74 }, { 79, 85.75 }, { 80.75, 85.75 }, { 79, 80 }, { 80.75, 80 } }
	do
		Builder.box(table_, "Leg", leg[1], g, leg[2], 0.25, 0.8, 0.25, "oak_log")
	end
	local names = NamesList.base
	for i = 0, 7 do
		for _, side in { -1, 1 } do
			local x = if side < 0 then 78.1 else 81.3
			local z = 74.4 + i * 1.5
			Builder.box(table_, "Chair", x, g, z, 0.6, 0.5, 0.6, "oak_planks")
			Builder.box(
				table_,
				"ChairBack",
				if side < 0 then x else x + 0.5,
				g + 0.5,
				z,
				0.1,
				0.7,
				0.6,
				"oak_planks"
			)
			local nameIndex = i + 1
			if side < 0 and nameIndex <= #names then
				local sign = Builder.sign(
					table_,
					"NameSign",
					CFrame.new(Builder.studs(x - 0.06, g + 1.0, z + 0.3))
						* CFrame.Angles(0, math.rad(-90), 0),
					Vector3.new(0.6 * S, 0.3 * S, 0.05 * S),
					names[nameIndex]
				)
				sign.CanCollide = false
			end
		end
	end
	-- four braziers for the Negatino fight (unlit)
	for i, b in MapData.Braziers do
		local m = Builder.model(model, "Brazier" .. i)
		Builder.box(m, "Base", b.x - 0.5, g, b.z - 0.5, 1, 1, 1, "cobblestone")
		local bowl = Builder.box(
			m,
			"Bowl",
			b.x - 0.6,
			g + 1,
			b.z - 0.6,
			1.2,
			0.3,
			1.2,
			"iron",
			{ color = "#4A4A4A" }
		)
		local fire = Instance.new("Fire")
		fire.Size = 6
		fire.Heat = 9
		fire.Enabled = false
		fire.Parent = bowl
		local light = Builder.light(bowl, "#FF8A2A", 28, 2)
		light.Enabled = false
		m:SetAttribute("Index", i)
		m:SetAttribute("Lit", false)
		tag(m, "Brazier")
	end
	return model
end

local function wellAndFountain(parent: Instance)
	local g = MapData.Ground
	local W = MapData.Well
	local well = Builder.model(parent, "Well")
	for _, p in { { 0, 0, 3, 1 }, { 0, 2, 3, 1 }, { 0, 1, 1, 1 }, { 2, 1, 1, 1 } } do
		Builder.box(well, "Rim", W.x + p[1], g, W.z + p[2], p[3], 1, p[4], "cobblestone")
	end
	Builder.box(well, "Water", W.x + 1, g - 2, W.z + 1, 1, 2.6, 1, "water")
	for _, p in { { 0, 0 }, { 2.75, 0 }, { 0, 2.75 }, { 2.75, 2.75 } } do
		Builder.box(well, "Post", W.x + p[1], g + 1, W.z + p[2], 0.25, 2, 0.25, "oak_log")
	end
	roof(well, W.x, g + 3, W.z, 3, 3, "#6A4A2A")
	local sign = Builder.sign(
		well,
		"CoordSign",
		CFrame.new(Builder.studs(84, g + 1.4, W.z - 0.1)),
		Vector3.new(1.4 * S, 0.7 * S, 0.1 * S),
		"X 135  Z 20  Y -25"
	)
	sign:SetAttribute("Clue", "C2")
	local F = MapData.Fountain
	local fountain = Builder.model(parent, "Fountain")
	for _, p in { { 0, 0, 5, 1 }, { 0, 4, 5, 1 }, { 0, 1, 1, 3 }, { 4, 1, 1, 3 } } do
		Builder.box(fountain, "Basin", F.x + p[1], g, F.z + p[2], p[3], 1, p[4], "cobblestone")
	end
	Builder.box(fountain, "Water", F.x + 1, g, F.z + 1, 3, 0.8, 3, "water")
	Builder.box(fountain, "Pillar", F.x + 2, g, F.z + 2, 1, 2.5, 1, "mossy_cobblestone")
	-- notice board
	local N = MapData.NoticeBoard
	local board = Builder.model(parent, "NoticeBoard")
	Builder.box(board, "Post", N.x - 1.5, g, N.z, 0.25, 2.5, 0.25, "oak_log")
	Builder.box(board, "Post", N.x + 1.25, g, N.z, 0.25, 2.5, 0.25, "oak_log")
	Builder.sign(
		board,
		"Board",
		CFrame.new(Builder.studs(N.x, g + 1.8, N.z + 0.3)),
		Vector3.new(3 * S, 1.2 * S, 0.1 * S),
		"LOST: Lirili Larila\nNIGHT CURFEW"
	)
end

local function station(parent: Instance)
	local St = MapData.Station
	local g = MapData.Ground
	local model = Builder.model(parent, "Station")
	Builder.box(model, "Platform", St.x, g, St.z, St.w, 0.25, St.d, "cobblestone")
	for _, c in
		{
			{ St.x, St.z },
			{ St.x + St.w - 1, St.z },
			{ St.x, St.z + St.d - 1 },
			{ St.x + St.w - 1, St.z + St.d - 1 },
		}
	do
		Builder.box(model, "Pillar", c[1], g, c[2], 1, 4, 1, "oak_log")
	end
	roof(model, St.x, g + 4, St.z, St.w, St.d, "#5A3A22")
	Builder.box(model, "Bench", St.x + 4, g + 0.25, St.z + 3, 1, 0.5, 4, "oak_planks")
	Builder.sign(
		model,
		"StationSign",
		CFrame.new(Builder.studs(St.x + St.w - 0.4, g + 3, St.z + St.d / 2))
			* CFrame.Angles(0, math.rad(-90), 0),
		Vector3.new(4 * S, 0.8 * S, 0.15 * S),
		"Last Stop -> Brainrot Valley"
	)
	torch(model, St.x + St.w - 0.5, g + 2.2, St.z + 1.5)
	torch(model, St.x + St.w - 0.5, g + 2.2, St.z + St.d - 1.5)
end

local function railsAndTunnel(parent: Instance)
	local g = MapData.Ground
	local R = MapData.Rails
	local model = Builder.model(parent, "Rails")
	for _, side in { -0.35, 0.35 } do
		Builder.box(model, "Rail", R.x0, g, R.z + side - 0.04, R.x1 - R.x0, 0.1, 0.08, "rail")
	end
	for x = R.x0, R.x1 - 1, 1.5 do
		Builder.box(
			model,
			"Sleeper",
			x,
			g,
			R.z - 0.55,
			0.3,
			0.06,
			1.1,
			"oak_planks",
			{ query = false }
		)
	end
	-- fences with torches along the rails outside the tunnel
	for _, z in { 78.6, 82.4 } do
		Builder.box(model, "FenceRail", 24, g + 0.8, z - 0.05, 24, 0.12, 0.1, "oak_planks")
		for x = 24, 48, 6 do
			torch(model, x, g, z, true)
		end
	end
	-- the tunnel portal (cobblestone arch)
	local T = MapData.Tunnel
	Builder.box(model, "Portal", T.x1, T.y0, T.z0 - 1, 0.5, T.y1 - T.y0 + 1, 1, "cobblestone")
	Builder.box(model, "Portal", T.x1, T.y0, T.z1, 0.5, T.y1 - T.y0 + 1, 1, "cobblestone")
	Builder.box(model, "Portal", T.x1, T.y1, T.z0 - 1, 0.5, 1, T.z1 - T.z0 + 2, "cobblestone")
	torch(model, T.x1 + 0.6, T.y0 + 2, T.z0 - 0.5)
	torch(model, T.x1 + 0.6, T.y0 + 2, T.z1 + 0.5)
	Builder.box(model, "TunnelEnd", T.x0 + 1, T.y0, T.z0, 1, T.y1 - T.y0, T.z1 - T.z0, "black")
end

local function bridge(parent: Instance)
	local B = MapData.Bridge
	local g = MapData.Ground
	local model = Builder.model(parent, "Bridge")
	Builder.box(model, "Deck", B.x0, g - 0.25, B.z0, B.x1 - B.x0, 0.5, B.z1 - B.z0, "oak_planks")
	for _, z in { B.z0, B.z1 - 0.15 } do
		Builder.box(model, "Railing", B.x0, g + 0.9, z, B.x1 - B.x0, 0.12, 0.15, "oak_planks")
		for x = B.x0, B.x1, 3 do
			Builder.box(model, "Post", x, g, z, 0.15, 1, 0.15, "oak_log")
		end
	end
	for _, x in { 112, 116 } do
		Builder.box(
			model,
			"Pier",
			x - 0.5,
			MapData.River.bedY,
			B.z0 + 1,
			1,
			g - MapData.River.bedY - 0.25,
			1,
			"cobblestone"
		)
	end
end

local function fields(parent: Instance)
	local F = MapData.Fields
	local g = MapData.Ground
	local model = Builder.model(parent, "Fields")
	for z = F.z0, F.z1 - 1 do
		if z ~= F.canalZ then
			Builder.box(
				model,
				"Wheat",
				F.x0,
				g,
				z + 0.15,
				F.x1 - F.x0,
				0.6,
				0.7,
				"wheat",
				{ decor = true }
			)
		end
	end
	for i, h in { { 56.5, 98 }, { 56.5, 99 }, { 56.5, 100 }, { 57.5, 98 } } do
		Builder.box(model, "HayBale", h[1], g + (if i == 4 then 1 else 0), h[2], 1, 1, 1, "hay")
	end
	-- fence around the fields
	for _, z in { F.z0 - 0.6, F.z1 + 0.4 } do
		Builder.box(model, "Fence", F.x0, g + 0.7, z, F.x1 - F.x0, 0.12, 0.12, "oak_planks")
		for x = F.x0, F.x1, 2.5 do
			Builder.box(model, "FencePost", x, g, z - 0.06, 0.25, 1.1, 0.25, "oak_log")
		end
	end
end

local function lamps(parent: Instance)
	local folder = Builder.folder(parent, "Lamps")
	local g = MapData.Ground
	local spots = {
		{ 58, 78.3 },
		{ 64, 78.3 },
		{ 88.5, 79.3 },
		{ 96, 79.3 },
		{ 104, 79.3 },
		{ 78.3, 58 },
		{ 82.7, 60 },
		{ 78.3, 92 },
		{ 82.7, 100 },
		{ 78.3, 108 },
		{ 82.7, 114 },
		{ 72, 72 },
		{ 88, 72 },
		{ 72, 88 },
		{ 88, 88 },
		{ 76, 95 },
		{ 90, 95.5 },
		{ 121, 37 },
		{ 124.5, 37 },
	}
	for _, p in spots do
		torch(folder, p[1], g, p[2], true)
	end
end

local function mineEntrance(parent: Instance)
	local g = MapData.Ground
	local model = Builder.model(parent, "MineEntrance")
	local M = MapData.MineDoor
	Builder.box(model, "FrameL", M.x - 2, g, M.z - 0.5, 1, 3.5, 1, "oak_log")
	Builder.box(model, "FrameR", M.x + 1, g, M.z - 0.5, 1, 3.5, 1, "oak_log")
	Builder.box(model, "FrameTop", M.x - 2, g + 3, M.z - 0.5, 4, 0.75, 1, "oak_log")
	local doorCf = CFrame.new(Builder.studs(M.x, g + 1.4, M.z))
	local d = door(model, "MineDoor", doorCf, 2, 2.8, "#9A9AA8", false)
	d.Material = Enum.Material.Metal
	CollectionService:RemoveTag(d, "Door")
	tag(d, "MineDoor")
	local keypad = Builder.box(
		model,
		"Keypad",
		M.x + 1.4,
		g + 1,
		M.z + 0.4,
		0.4,
		0.5,
		0.15,
		"iron",
		{ color = "#2A2A30" }
	)
	tag(keypad, "MineKeypad")
	Builder.sign(
		model,
		"MineSign",
		CFrame.new(Builder.studs(M.x, g + 4.2, M.z + 0.55)),
		Vector3.new(3 * S, 0.6 * S, 0.1 * S),
		"MINE - KEEP OUT"
	)
	torch(model, M.x - 2.3, g + 2, M.z + 0.7)
	torch(model, M.x + 2.3, g + 2, M.z + 0.7)
end

--- Builds every village structure under `parent`.
function Village.build(parent: Instance)
	local folder = Builder.folder(parent, "Village")
	for _, h in MapData.Houses do
		local model, baseY = house(folder, h)
		if h.id == "Tavern" then
			tavern(model, baseY)
		elseif h.id == "BallerinaHouse" then
			ballerinaHouse(model, baseY)
		elseif h.id == "Bakery" then
			bakery(model, baseY)
		elseif h.id == "Shop" then
			shop(model, baseY)
		elseif h.id == "LiriliWorkshop" then
			workshop(model, baseY)
		elseif h.id == "Barn" then
			barn(model, baseY)
		elseif h.id == "TungHut" then
			tungHut(model, baseY)
		elseif h.id == "Hangar" then
			hangar(model, baseY)
		elseif h.id == "Mill" then
			mill(model, baseY)
		else
			cameo(model, h, baseY)
		end
	end
	tower(folder)
	square(folder)
	wellAndFountain(folder)
	station(folder)
	railsAndTunnel(folder)
	bridge(folder)
	fields(folder)
	lamps(folder)
	mineEntrance(folder)
	return folder
end

return Village
