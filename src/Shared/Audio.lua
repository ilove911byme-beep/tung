--!strict
-- Audio helper: Audio.play(name, parent?), Audio.loop(name, parent?), Audio.stop(sound, fade?).
-- Names are keys of SoundIds; "step_grass" picks one of step_grass_1.._4 at random.
-- Sounds go to the SoundGroups Music / Ambience / SFX (Voice is used by VoiceService), whose
-- volumes are the Settings sliders. Placeholder ids ("rbxassetid://0") are skipped: the call
-- returns nil and Studio warns once per name.
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(script.Parent.Config)
local SoundIds = require(script.Parent.SoundIds)

local Audio = {}

export type PlayOptions = {
	volume: number?,
	speed: number?,
	group: string?,
	looped: boolean?,
	timePosition: number?,
	rollOffMax: number?, -- 3D sounds (parent is a part): audible up to this many studs
	rollOffMin: number?,
	fadeIn: number?,
}

local PLACEHOLDER = "rbxassetid://0"
local warned: { [string]: boolean } = {}
local rng = Random.new()

local function groupFor(name: string): string
	if
		string.sub(name, 1, 6) == "music_"
		or name == "dusk_piano_theme"
		or name == "ending_dawn"
	then
		return "Music"
	end
	if
		string.sub(name, 1, 4) == "amb_"
		or string.sub(name, 1, 9) == "ambience_"
		or string.sub(name, 1, 10) == "cave_eerie"
		or name == "owl_hoot"
	then
		return "Ambience"
	end
	return "SFX"
end

--- SoundGroup by name, created on first use.
function Audio.group(name: string): SoundGroup
	local existing = SoundService:FindFirstChild(name)
	if existing and existing:IsA("SoundGroup") then
		return existing
	end
	local g = Instance.new("SoundGroup")
	g.Name = name
	g.Volume = 1
	g.Parent = SoundService
	return g
end

function Audio.setGroupVolume(name: string, volume: number)
	Audio.group(name).Volume = math.clamp(volume, 0, 2)
end

function Audio.init()
	for _, name in Config.SoundGroups do
		Audio.group(name)
	end
end

--- Resolves "step_grass" -> "step_grass_3" (random) when only numbered variants exist.
function Audio.resolve(name: string): string?
	if SoundIds[name] then
		return name
	end
	local variants = {}
	for i = 1, 9 do
		local v = name .. "_" .. i
		if SoundIds[v] then
			table.insert(variants, v)
		else
			break
		end
	end
	if #variants == 0 then
		return nil
	end
	return variants[rng:NextInteger(1, #variants)]
end

function Audio.isPlaceholder(name: string): boolean
	local resolved = Audio.resolve(name)
	return resolved == nil or SoundIds[resolved] == PLACEHOLDER
end

--- Creates (but does not play) a Sound. nil if the id is missing or still a placeholder.
function Audio.create(name: string, parent: Instance?, opts: PlayOptions?): Sound?
	local o: PlayOptions = opts or {}
	local resolved = Audio.resolve(name)
	if not resolved then
		warn("[Audio] unknown sound " .. name)
		return nil
	end
	local id = SoundIds[resolved]
	if id == PLACEHOLDER then
		if Config.Debug.WarnMissingSounds and RunService:IsStudio() and not warned[resolved] then
			warned[resolved] = true
			print(string.format("[Audio] '%s' has no SoundId yet (placeholder), skipped", resolved))
		end
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = resolved
	sound.SoundId = id
	sound.Volume = o.volume or 0.6
	sound.PlaybackSpeed = o.speed or 1
	sound.Looped = if o.looped ~= nil
		then o.looped
		else (string.find(resolved, "_loop", 1, true) ~= nil)
	sound.SoundGroup = Audio.group(o.group or groupFor(resolved))
	if o.timePosition then
		sound.TimePosition = o.timePosition
	end
	if parent and parent:IsA("BasePart") or parent and parent:IsA("Attachment") then
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = o.rollOffMin or 8
		sound.RollOffMaxDistance = o.rollOffMax or 80
	end
	sound.Parent = parent or SoundService
	return sound
end

--- Plays a one-shot (destroyed when it ends). 3D if parent is a Part or Attachment.
function Audio.play(name: string, parent: Instance?, opts: PlayOptions?): Sound?
	local o: PlayOptions = opts or {}
	local sound = Audio.create(name, parent, {
		volume = o.volume,
		speed = o.speed,
		group = o.group,
		looped = false,
		rollOffMax = o.rollOffMax,
		rollOffMin = o.rollOffMin,
		timePosition = o.timePosition,
	})
	if not sound then
		return nil
	end
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
	return sound
end

--- Plays a looping sound (optionally fading in). Stop it with Audio.stop.
function Audio.loop(name: string, parent: Instance?, opts: PlayOptions?): Sound?
	local o: PlayOptions = opts or {}
	local target = o.volume or 0.5
	local sound = Audio.create(name, parent, {
		volume = target,
		speed = o.speed,
		group = o.group,
		looped = true,
		rollOffMax = o.rollOffMax,
		rollOffMin = o.rollOffMin,
	})
	if not sound then
		return nil
	end
	if o.fadeIn and o.fadeIn > 0 then
		sound.Volume = 0
		sound:Play()
		TweenService:Create(sound, TweenInfo.new(o.fadeIn), { Volume = target }):Play()
	else
		sound:Play()
	end
	return sound
end

--- Stops a sound, optionally fading out first, then destroys it.
function Audio.stop(sound: Sound?, fade: number?)
	if not sound then
		return
	end
	if fade and fade > 0 then
		local tween = TweenService:Create(sound, TweenInfo.new(fade), { Volume = 0 })
		tween.Completed:Once(function()
			sound:Destroy()
		end)
		tween:Play()
	else
		sound:Destroy()
	end
end

--- Tweens a sound's volume.
function Audio.fadeTo(sound: Sound?, volume: number, time: number)
	if sound then
		TweenService:Create(sound, TweenInfo.new(time), { Volume = volume }):Play()
	end
end

return Audio
