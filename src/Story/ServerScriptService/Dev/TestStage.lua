--!strict
-- Studio-only test stage for Phase 1a (replaced by the MapBuilder in Phase 2). It builds just
-- enough of the village AT THE REAL map.md COORDINATES for CS-02 and CS-05: the station with
-- rails and the lantern, the tavern's east wall with the window (and a room behind it with a
-- fireplace), the square, a strip of river, footstep test patches and a test dummy. Anchors
-- come from Shared/World/Anchors, so the cutscene data does not change when the real map comes.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Anchors = require(Shared:WaitForChild("World"):WaitForChild("Anchors"))
local Config = require(Shared:WaitForChild("Config"))

local TestStage = {}

local GROUND = Config.World.GroundY * Config.World.StudsPerBlock -- 48 studs

local function block(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material,
	blockName: string?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if blockName then
		p:SetAttribute("Block", blockName) -- footsteps read this (map.md palette names)
	end
	p.Parent = parent
	return p
end

local rgb = Color3.fromRGB
local GRASS = rgb(76, 128, 48)
local PATH = rgb(140, 112, 70)
local PLANKS = rgb(156, 118, 70)
local LOG = rgb(96, 68, 40)
local COBBLE = rgb(118, 118, 118)
local STONE = rgb(112, 112, 112)

local function buildStation(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Station"
	folder.Parent = parent
	local c = Anchors.get("Anchor_Station").Position -- (208, 48, 320)
	block(
		folder,
		"Floor",
		Vector3.new(24, 0.2, 40),
		c + Vector3.new(0, -0.02, 0),
		PLANKS,
		Enum.Material.WoodPlanks,
		"oak_planks"
	)
	for _, dx in { -11, 11 } do
		for _, dz in { -19, 19 } do
			block(
				folder,
				"Post",
				Vector3.new(1.6, 14, 1.6),
				c + Vector3.new(dx, 7, dz),
				LOG,
				Enum.Material.Wood,
				"oak_log"
			)
		end
	end
	block(
		folder,
		"Roof",
		Vector3.new(26, 1, 42),
		c + Vector3.new(0, 14.5, 0),
		PLANKS,
		Enum.Material.WoodPlanks,
		"oak_planks"
	)
	-- rails from the tunnel (x 88) to the station (x 208) on z = 320
	for _, dz in { -2, 2 } do
		block(
			folder,
			"Rail",
			Vector3.new(120, 0.3, 0.3),
			Vector3.new(148, GROUND + 0.35, 320 + dz),
			rgb(150, 150, 155),
			Enum.Material.Metal
		)
	end
	for x = 90, 206, 4 do
		block(
			folder,
			"Sleeper",
			Vector3.new(1, 0.25, 6),
			Vector3.new(x, GROUND + 0.12, 320),
			LOG,
			Enum.Material.Wood,
			"oak_log"
		)
	end
	-- the lantern Giallino comes out of: 10 studs in front of the players (Anchor_Station local -Z)
	local lanternBase = (Anchors.get("Anchor_Station") * CFrame.new(0, 0, -10)).Position
	block(
		folder,
		"LanternPost",
		Vector3.new(0.8, 6, 0.8),
		lanternBase + Vector3.new(0, 3, 0),
		LOG,
		Enum.Material.Wood
	)
	local lantern = block(
		folder,
		"Lantern",
		Vector3.new(1.4, 1.4, 1.4),
		lanternBase + Vector3.new(0, 6.6, 0),
		rgb(60, 50, 30),
		Enum.Material.Glass
	)
	lantern.Transparency = 0.3
end

local function buildTavern(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Tavern"
	folder.Parent = parent
	local w = Anchors.get("Anchor_Tavern_Window").Position -- (282, 54, 320)
	local x = w.X
	local top = GROUND + 16
	local function wall(name: string, z0: number, z1: number, y0: number, y1: number)
		block(
			folder,
			name,
			Vector3.new(1, y1 - y0, z1 - z0),
			Vector3.new(x, (y0 + y1) / 2, (z0 + z1) / 2),
			PLANKS,
			Enum.Material.WoodPlanks
		)
	end
	-- east wall: window 8 wide x 6 tall centered on the anchor, a door further south
	wall("WallNorth", 298, w.Z - 4, GROUND, top)
	wall("WallUnderWindow", w.Z - 4, w.Z + 4, GROUND, w.Y - 3)
	wall("WallOverWindow", w.Z - 4, w.Z + 4, w.Y + 3, top)
	wall("WallMid", w.Z + 4, 330, GROUND, top)
	wall("WallOverDoor", 330, 334, GROUND + 8, top)
	wall("WallSouth", 334, 342, GROUND, top)
	local glass = block(
		folder,
		"WindowGlass",
		Vector3.new(0.2, 6, 8),
		w,
		rgb(200, 230, 255),
		Enum.Material.Glass
	)
	glass.Transparency = 0.7
	glass.CanCollide = true
	block(folder, "WindowBarV", Vector3.new(0.4, 6, 0.3), w, LOG, Enum.Material.Wood)
	block(folder, "WindowBarH", Vector3.new(0.4, 0.3, 8), w, LOG, Enum.Material.Wood)
	-- the room behind the window
	block(
		folder,
		"Floor",
		Vector3.new(36, 0.2, 44),
		Vector3.new(x - 18, GROUND - 0.02, 320),
		PLANKS,
		Enum.Material.WoodPlanks,
		"oak_planks"
	)
	block(
		folder,
		"WallBack",
		Vector3.new(1, 16, 44),
		Vector3.new(x - 36, GROUND + 8, 320),
		PLANKS,
		Enum.Material.WoodPlanks
	)
	block(
		folder,
		"WallSideN",
		Vector3.new(36, 16, 1),
		Vector3.new(x - 18, GROUND + 8, 298),
		PLANKS,
		Enum.Material.WoodPlanks
	)
	block(
		folder,
		"WallSideS",
		Vector3.new(36, 16, 1),
		Vector3.new(x - 18, GROUND + 8, 342),
		PLANKS,
		Enum.Material.WoodPlanks
	)
	block(
		folder,
		"Ceiling",
		Vector3.new(37, 1, 45),
		Vector3.new(x - 18, top + 0.5, 320),
		PLANKS,
		Enum.Material.WoodPlanks
	)
	block(
		folder,
		"Fireplace",
		Vector3.new(3, 8, 6),
		Vector3.new(x - 34.5, GROUND + 4, 320),
		COBBLE,
		Enum.Material.Cobblestone,
		"cobblestone"
	)
	local fire = block(
		folder,
		"Fire",
		Vector3.new(1.2, 1.4, 3),
		Vector3.new(x - 32.6, GROUND + 0.8, 320),
		rgb(255, 140, 40),
		Enum.Material.Neon
	)
	fire.CanCollide = false
	local fireLight = Instance.new("PointLight")
	fireLight.Color = rgb(255, 160, 80)
	fireLight.Range = 18
	fireLight.Brightness = 2
	fireLight.Parent = fire
	fire:SetAttribute("Sound", "amb_fireplace_loop")
	fire:SetAttribute("Volume", 0.6)
	fire:SetAttribute("MaxDistance", 40)
	CollectionService:AddTag(fire, "AmbienceEmitter")
end

local function buildSquare(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Square"
	folder.Parent = parent
	local c = Anchors.get("Anchor_Square_Center").Position -- (320, 48, 320)
	block(
		folder,
		"Path",
		Vector3.new(60, 0.1, 60),
		c + Vector3.new(0, 0.03, 0),
		PATH,
		Enum.Material.Ground,
		"dirt_path"
	)
	-- brazier spots for Chapter 4 (map.md): (74,74) (86,74) (74,86) (86,86) blocks
	for _, b in { { 74, 74 }, { 86, 74 }, { 74, 86 }, { 86, 86 } } do
		block(
			folder,
			"Brazier",
			Vector3.new(4, 4, 4),
			Vector3.new(b[1] * 4, GROUND + 2, b[2] * 4),
			COBBLE,
			Enum.Material.Cobblestone,
			"cobblestone"
		)
	end
end

local function buildRiverStrip(parent: Instance)
	-- map.md: river X 112-116 blocks
	local water = block(
		parent,
		"RiverStrip",
		Vector3.new(16, 1, 120),
		Vector3.new(456, GROUND - 0.4, 320),
		rgb(48, 82, 160),
		Enum.Material.Glass
	)
	water.Transparency = 0.35
	water.CanCollide = false
	water:SetAttribute("Sound", "amb_water_stream_loop")
	water:SetAttribute("Volume", 0.55)
	water:SetAttribute("MaxDistance", 80) -- 20 blocks
	CollectionService:AddTag(water, "AmbienceEmitter")
end

local function buildFootstepPatches(parent: Instance)
	type Patch = { block: string, color: Color3, material: Enum.Material }
	local patches: { Patch } = {
		{ block = "stone", color = STONE, material = Enum.Material.Slate },
		{ block = "oak_planks", color = PLANKS, material = Enum.Material.WoodPlanks },
		{ block = "gravel", color = rgb(110, 104, 100), material = Enum.Material.Pebble },
		{ block = "sand", color = rgb(216, 200, 150), material = Enum.Material.Sand },
	}
	for i, patch in patches do
		local position = Vector3.new(160 + i * 10, GROUND + 0.02, 360)
		block(
			parent,
			"Steps_" .. patch.block,
			Vector3.new(8, 0.2, 8),
			position,
			patch.color,
			patch.material,
			patch.block
		)
	end
end

--- Builds the stage unless a real map (workspace.Map) or a previous stage exists.
function TestStage.buildIfNeeded()
	if not RunService:IsStudio() or not Config.Debug.TestStage then
		return
	end
	if workspace:FindFirstChild("Map") or workspace:FindFirstChild("TestStage") then
		return
	end
	local stage = Instance.new("Folder")
	stage.Name = "TestStage"
	block(
		stage,
		"Baseplate",
		Vector3.new(340, 2, 230),
		Vector3.new(300, GROUND - 1, 320),
		GRASS,
		Enum.Material.Grass,
		"grass"
	)
	buildStation(stage)
	buildTavern(stage)
	buildSquare(stage)
	buildRiverStrip(stage)
	buildFootstepPatches(stage)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "TestSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(196, GROUND + 0.5, 336)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = stage

	local models = ServerStorage:FindFirstChild("Models")
	local dummyTemplate = models and models:FindFirstChild("Dummy")
	if dummyTemplate and dummyTemplate:IsA("Model") then
		local dummy = dummyTemplate:Clone()
		dummy:PivotTo(CFrame.new(220, GROUND + 3.2, 350) * CFrame.Angles(0, math.rad(-90), 0))
		dummy.Parent = stage
	end
	stage.Parent = workspace
	if not workspace:FindFirstChild("Anchors") then
		Anchors.createParts(workspace)
	end
	-- remove the default Studio baseplate / spawn so players spawn on the stage
	for _, name in { "Baseplate", "SpawnLocation" } do
		local old = workspace:FindFirstChild(name)
		if old and old.Parent == workspace then
			old:Destroy()
		end
	end
	print("[TestStage] built. Chat: /cs CS_02, /cs CS_05, /cs list, /fx <Effect>")
end

return TestStage
