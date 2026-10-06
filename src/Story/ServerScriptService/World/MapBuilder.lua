--!strict
-- Builds Brainrot Valley from code (roblox_horror_prompt.md Phase 2, map.md): terrain, the
-- mine, the village, nature, camera anchors, Memory Pages M2-M12, named gameplay points,
-- villager NPCs and the spawn. Everything goes into workspace.Map (built unparented, then
-- parented once). MapBuilder.point(name) gives chapters a point's CFrame (Map.Points or data).
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local World = Shared:WaitForChild("World")
local Anchors = require(World:WaitForChild("Anchors"))
local Config = require(Shared:WaitForChild("Config"))
local MapData = require(World:WaitForChild("MapData"))

local MapFolder = script.Parent:WaitForChild("Map")
local Builder = require(MapFolder:WaitForChild("Builder"))
local Terrain = require(MapFolder:WaitForChild("Terrain"))
local Underground = require(MapFolder:WaitForChild("Underground"))
local Village = require(MapFolder:WaitForChild("Village"))
local Nature = require(MapFolder:WaitForChild("Nature"))

local MapBuilder = {}

local function spotCFrame(s: MapData.Spot): CFrame
	local pos = Builder.studs(s.x, s.y, s.z)
	local r = math.rad(s.yaw or 0)
	return CFrame.lookAt(pos, pos + Vector3.new(math.sin(r), 0, -math.cos(r)))
end

local function points(map: Instance)
	local folder = Builder.folder(map, "Points")
	for name, s in MapData.Points do
		Builder.marker(folder, name, s.x, s.y, s.z, s.yaw)
	end
end

local function memoryPages(map: Instance)
	local folder = Builder.folder(map, "MemoryPages")
	for id, s in MapData.MemoryPages do
		local p = Instance.new("Part")
		p.Name = id
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = true
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 244, 200)
		p.Size = Vector3.new(1.4, 1.8, 0.12)
		p.CFrame = CFrame.new(Builder.studs(s.x, s.y, s.z) + Vector3.new(0, 1.6, 0))
			* CFrame.Angles(math.rad(-15), math.rad(20), 0)
		p.Transparency = 1 -- ClueService shows the pages of the current chapter
		p:SetAttribute("PageId", id)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 226, 140)
		light.Range = 8
		light.Brightness = 0.8
		light.Enabled = false
		light.Parent = p
		CollectionService:AddTag(p, "MemoryPage")
		p.Parent = folder
	end
end

local function npcs()
	local old = workspace:FindFirstChild("NPCs")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "NPCs"
	local models = ServerStorage:FindFirstChild("Models")
	for _, n in MapData.NPCs do
		local template = models and models:FindFirstChild(n.id)
		if template and template:IsA("Model") then
			local m = template:Clone()
			local rootHeight = (m:GetAttribute("RootHeight") :: number?) or 0
			m:PivotTo(
				spotCFrame({ x = n.x, y = n.y, z = n.z, yaw = n.yaw })
					* CFrame.new(0, rootHeight, 0)
			)
			m:SetAttribute("HomeX", n.x)
			m:SetAttribute("HomeY", n.y)
			m:SetAttribute("HomeZ", n.z)
			m:SetAttribute("HomeYaw", n.yaw)
			CollectionService:AddTag(m, "NPC")
			m.Parent = folder
		else
			warn("[MapBuilder] no rig for NPC " .. n.id)
		end
	end
	folder.Parent = workspace
end

local function riverEmitters(map: Instance)
	local folder = Builder.folder(map, "RiverSound")
	local R = MapData.River
	for z = 24, 156, 22 do
		local e = Builder.marker(folder, "RiverEmitter", (R.x0 + R.x1) / 2, MapData.WaterY - 1, z)
		e:SetAttribute("Sound", "amb_water_stream_loop")
		e:SetAttribute("Volume", 0.5)
		e:SetAttribute("MaxDistance", 90)
		CollectionService:AddTag(e, "AmbienceEmitter")
	end
end

local function spawnPoint(map: Instance)
	local St = MapData.Station
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StationSpawn"
	spawn.Size = Vector3.new(6, 0.4, 6)
	spawn.CFrame = CFrame.new(Builder.studs(St.x + 2.5, MapData.Ground + 0.1, St.z + St.d / 2))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = map
	for _, name in { "Baseplate", "SpawnLocation" } do
		local old = workspace:FindFirstChild(name)
		if old and old.Parent == workspace then
			old:Destroy()
		end
	end
end

--- Builds the whole map once. Returns workspace.Map.
function MapBuilder.build(): Instance
	local existing = workspace:FindFirstChild("Map")
	if existing then
		return existing
	end
	local started = os.clock()
	Builder.partCount = 0
	local map = Instance.new("Folder")
	map.Name = "Map"
	Terrain.build(map)
	Underground.build(map)
	Village.build(map)
	Nature.build(map)
	points(map)
	memoryPages(map)
	riverEmitters(map)
	spawnPoint(map)
	map.Parent = workspace
	if not workspace:FindFirstChild("Anchors") then
		Anchors.createParts(workspace)
	end
	npcs()
	local count = 0
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") then
			count += 1
		end
	end
	print(
		string.format(
			"[MapBuilder] built Brainrot Valley: %d parts in %.2f s",
			count,
			os.clock() - started
		)
	)
	if count > Config.World.MaxParts then
		warn(
			string.format(
				"[MapBuilder] %d parts is over the %d budget",
				count,
				Config.World.MaxParts
			)
		)
	end
	return map
end

--- World CFrame of a named point (map.md / MapData.Points). Uses the built marker when it
--- exists (a level designer may move it in Studio).
function MapBuilder.point(name: string): CFrame
	local map = workspace:FindFirstChild("Map")
	local folder = map and map:FindFirstChild("Points")
	local marker = folder and folder:FindFirstChild(name)
	if marker and marker:IsA("BasePart") then
		return marker.CFrame
	end
	local s = MapData.Points[name]
	assert(s, "[MapBuilder] unknown point " .. name)
	return spotCFrame(s) + Vector3.new(0, 1, 0)
end

--- A built instance under workspace.Map by path, e.g. find("Village", "Tavern", "Door").
function MapBuilder.find(...: string): Instance?
	local node: Instance? = workspace:FindFirstChild("Map")
	for _, name in { ... } do
		if not node then
			return nil
		end
		node = node:FindFirstChild(name, true)
	end
	return node
end

--- Opens / closes a door built by the Village (attributes ClosedCFrame / OpenCFrame).
function MapBuilder.setDoor(door: BasePart, open: boolean)
	local cf = door:GetAttribute(if open then "OpenCFrame" else "ClosedCFrame")
	if typeof(cf) == "CFrame" then
		door.CFrame = cf
		door:SetAttribute("Open", open)
	end
end

function MapBuilder.terrainHeight(x: number, z: number): number
	return Terrain.heightAt(x, z)
end

return MapBuilder
