--!strict
-- Ambience by zone and time of day (Shared/World/AmbienceZones) with crossfaded layers,
-- random one-shots (owl at night, cave_eerie in the mine) and 3D loops on Parts tagged
-- "AmbienceEmitter" (river water, tavern fireplace). Day/night comes from the workspace
-- attribute TimeOfDay ("Day"/"Night") when the server sets it, else from Lighting.ClockTime.
-- Minecart rides: player attribute InMinecart. Rain: workspace attribute Rain.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local AmbienceZones = require(Shared:WaitForChild("World"):WaitForChild("AmbienceZones"))
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))

local AmbienceDirector = {}

local FADE = 1.5
local TICK = 0.5

local layers: { [string]: Sound } = {} -- sound name -> playing loop
local emitters: { [Instance]: Sound } = {}
local nextOneShot: { [string]: number } = {}
local currentZone = ""
local rng = Random.new()

local function isNight(): boolean
	local attr = workspace:GetAttribute("TimeOfDay")
	if attr == "Day" then
		return false
	elseif attr == "Night" then
		return true
	end
	local t = Lighting.ClockTime
	return t < 6.2 or t >= 18.4
end

local function inZone(zone: AmbienceZones.Zone, blockPos: Vector3): boolean
	if zone.min and zone.max then
		local mn, mx = zone.min, zone.max
		return blockPos.X >= mn[1]
			and blockPos.X <= mx[1]
			and blockPos.Y >= mn[2]
			and blockPos.Y <= mx[2]
			and blockPos.Z >= mn[3]
			and blockPos.Z <= mx[3]
	end
	if zone.center and zone.radius then
		local dx = blockPos.X - zone.center[1]
		local dz = blockPos.Z - zone.center[2]
		return dx * dx + dz * dz <= zone.radius * zone.radius
			and blockPos.Y <= (zone.maxY or math.huge)
	end
	return true -- fallback zone
end

local function zoneAt(position: Vector3): AmbienceZones.Zone
	local blockPos = position / Config.World.StudsPerBlock
	for _, zone in AmbienceZones do
		if inZone(zone, blockPos) then
			return zone
		end
	end
	return AmbienceZones[#AmbienceZones]
end

local function setLayers(wanted: { [string]: number })
	for name, sound in layers do
		if not wanted[name] then
			Audio.stop(sound, FADE)
			layers[name] = nil
		end
	end
	for name, volume in wanted do
		local sound = layers[name]
		if sound then
			Audio.fadeTo(sound, volume, FADE)
		else
			local newSound =
				Audio.loop(name, nil, { volume = volume, fadeIn = FADE, group = "Ambience" })
			if newSound then
				layers[name] = newSound
			end
		end
	end
end

local function listenerPosition(): Vector3?
	local camera = workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	-- in cutscenes the camera is the ear
	if Players.LocalPlayer:GetAttribute("InCutscene") and camera then
		return camera.CFrame.Position
	end
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return if camera then camera.CFrame.Position else nil
end

local function tick()
	local pos = listenerPosition()
	if not pos then
		return
	end
	local zone = zoneAt(pos)
	local night = isNight()
	local wanted: { [string]: number } = {}
	local layerList: { AmbienceZones.Layer } = if night then zone.night else zone.day
	for _, layer in layerList do
		wanted[layer.sound] = layer.volume
	end
	if zone.rain and workspace:GetAttribute("Rain") == true then
		wanted.amb_rain_loop = 0.5
	end
	if Players.LocalPlayer:GetAttribute("InMinecart") == true then
		wanted.amb_minecart_loop = 0.6
	end
	setLayers(wanted)

	local key = zone.id .. (if night then "N" else "D")
	if key ~= currentZone then
		currentZone = key
		table.clear(nextOneShot)
	end
	local now = os.clock()
	local shots: { AmbienceZones.OneShot } = (
		if night then zone.nightOneShots else zone.dayOneShots
	) or {}
	for i, shot in shots do
		local id = key .. i
		local due = nextOneShot[id]
		if not due then
			nextOneShot[id] = now + rng:NextNumber(shot.min, shot.max)
		elseif now >= due then
			Audio.play(
				shot.sounds[rng:NextInteger(1, #shot.sounds)],
				nil,
				{ volume = shot.volume, group = "Ambience" }
			)
			nextOneShot[id] = now + rng:NextNumber(shot.min, shot.max)
		end
	end
end

local function addEmitter(part: Instance)
	if emitters[part] or not part:IsA("BasePart") then
		return
	end
	local name = part:GetAttribute("Sound")
	if typeof(name) ~= "string" then
		return
	end
	local volume = part:GetAttribute("Volume")
	local maxDistance = part:GetAttribute("MaxDistance")
	local sound = Audio.loop(name, part, {
		volume = if typeof(volume) == "number" then volume else 0.5,
		rollOffMax = if typeof(maxDistance) == "number" then maxDistance else 80,
		rollOffMin = 6,
		group = "Ambience",
	})
	if sound then
		emitters[part] = sound
	end
end

local function removeEmitter(part: Instance)
	local sound = emitters[part]
	if sound then
		sound:Destroy()
		emitters[part] = nil
	end
end

function AmbienceDirector.init()
	for _, part in CollectionService:GetTagged("AmbienceEmitter") do
		addEmitter(part)
	end
	CollectionService:GetInstanceAddedSignal("AmbienceEmitter"):Connect(addEmitter)
	CollectionService:GetInstanceRemovedSignal("AmbienceEmitter"):Connect(removeEmitter)
	task.spawn(function()
		while true do
			tick()
			task.wait(TICK)
		end
	end)
end

function AmbienceDirector.zoneId(): string
	return currentZone
end

return AmbienceDirector
