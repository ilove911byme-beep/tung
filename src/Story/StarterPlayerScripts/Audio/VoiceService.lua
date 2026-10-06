--!strict
-- Spoken lines. If a line has an uploaded soundId it plays that Sound; otherwise it is spoken
-- with Roblox AudioTextToSpeech (Text <= 300 chars, per-speaker VoiceId / Pitch / Speed from
-- Shared/VoiceSettings). Speakers with a model are 3D (AudioEmitter on the head), the Narrator
-- is 2D (AudioDeviceOutput). Every line is also a subtitle.
-- Rate limit: Roblox allows 1 + 6 * players TTS requests per minute per experience, so each
-- client spends at most Config.Voice.RequestsPerMinutePerClient; generated speech is cached
-- and reused, and if no request is left (or one fails) the line is subtitles only.
-- Villagers hum (npc_hum_*) before each TTS line; Giallino "talks" with blips per letter.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))
local Types = require(Shared:WaitForChild("Types"))
local VoiceLines = require(Shared:WaitForChild("VoiceLines"))
local VoiceSettings = require(Shared:WaitForChild("VoiceSettings"))

local Settings = require(script.Parent.Parent:WaitForChild("Settings"))
local Subtitles = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Subtitles"))

local VoiceService = {}

export type SayOptions = {
	speakerModel: Model?, -- 3D source; nil = 2D
	tokens: { [string]: string }?, -- "[Hiding spot]" etc.
}

type CacheEntry = { tts: AudioTextToSpeech, state: "loading" | "ready" | "failed" }

local cache: { [string]: CacheEntry } = {}
local folder: Folder? = nil
local output2D: AudioDeviceOutput? = nil
local tokensLeft = Config.Voice.RequestsPerMinutePerClient
local lastRefill = os.clock()
local warnedLimit = false
local chanted: { [string]: boolean } = {}
local playing: { Instance } = {}

local BLIP_SPEAKERS = { Giallino = true, Falsino = true, GiallinoTotale = true }

local function refill()
	local now = os.clock()
	local perSecond = Config.Voice.RequestsPerMinutePerClient / 60
	tokensLeft = math.min(
		Config.Voice.RequestsPerMinutePerClient,
		tokensLeft + (now - lastRefill) * perSecond
	)
	lastRefill = now
end

local function voiceFolder(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "VoiceCache"
	f.Parent = SoundService
	folder = f
	return f
end

--- Makes sure 3D audio has a listener (camera) wired to a device output, and creates the 2D
--- output used by the Narrator.
local function ensureOutputs()
	local camera = workspace.CurrentCamera
	local hasListener = false
	local character = Players.LocalPlayer.Character
	for _, root in { camera, character, SoundService } do
		if root and root:FindFirstChildWhichIsA("AudioListener", true) then
			hasListener = true
			break
		end
	end
	if not hasListener and camera then
		local listener = Instance.new("AudioListener")
		listener.Name = "VoiceListener"
		listener.Parent = camera
		local device = Instance.new("AudioDeviceOutput")
		device.Name = "ListenerOutput"
		device.Parent = SoundService
		local wire = Instance.new("Wire")
		wire.SourceInstance = listener
		wire.TargetInstance = device
		wire.Parent = device
	end
	if not output2D then
		local device = Instance.new("AudioDeviceOutput")
		device.Name = "Voice2DOutput"
		device.Parent = SoundService
		output2D = device
	end
end

function VoiceService.personalize(text: string, tokens: { [string]: string }?): string
	local name = Players.LocalPlayer.DisplayName
	local out = string.gsub(text, "%[DisplayName%]", name)
	out = string.gsub(out, "%[Name%]", name)
	if tokens then
		for key, value in tokens do
			out = string.gsub(out, "%[" .. string.gsub(key, "%p", "%%%0") .. "%]", value)
		end
	end
	return out
end

local function cacheKey(settings: Types.VoiceSettings, text: string): string
	return string.format("%s|%g|%g|%s", settings.voiceId, settings.pitch, settings.speed, text)
end

local function startLoad(speaker: Types.SpeakerId, text: string): CacheEntry?
	local settings = VoiceSettings[speaker]
	if not settings then
		return nil
	end
	local clipped = string.sub(text, 1, Config.Voice.MaxTextLength)
	local key = cacheKey(settings, clipped)
	local entry = cache[key]
	if entry then
		return entry
	end
	refill()
	if tokensLeft < 1 then
		if RunService:IsStudio() and not warnedLimit then
			warnedLimit = true
			print("[VoiceService] TTS budget used up for this minute, lines fall back to subtitles")
		end
		return nil
	end
	tokensLeft -= 1
	local tts = Instance.new("AudioTextToSpeech")
	tts.Name = speaker
	tts.Text = clipped
	tts.VoiceId = settings.voiceId
	tts.Pitch = math.clamp(settings.pitch, -12, 12)
	tts.Speed = math.clamp(settings.speed, 0.5, 2)
	tts.Volume = settings.volume
	tts.Parent = voiceFolder()
	local newEntry: CacheEntry = { tts = tts, state = "loading" }
	cache[key] = newEntry
	task.spawn(function()
		local ok, status = pcall(function()
			return tts:LoadAsync()
		end)
		if ok and status == Enum.AssetFetchStatus.Success then
			newEntry.state = "ready"
		else
			newEntry.state = "failed"
			if RunService:IsStudio() then
				print(
					string.format(
						"[VoiceService] TTS failed for %s (%s), subtitles only",
						speaker,
						tostring(status)
					)
				)
			end
		end
	end)
	return newEntry
end

--- Starts generating speech for lines ahead of time (cutscenes call this at the start).
function VoiceService.preload(lineIds: { string }, tokens: { [string]: string }?)
	if not Settings.get().voices then
		return
	end
	for _, id in lineIds do
		local line = VoiceLines.get(id)
		if line and not line.soundId then
			startLoad(line.speaker, VoiceService.personalize(line.text, tokens))
		end
	end
end

local function headOf(model: Model?): BasePart?
	if not model then
		return nil
	end
	local head = model:FindFirstChild("Head") or model.PrimaryPart
	if head and head:IsA("BasePart") then
		return head
	end
	return nil
end

local function humKind(line: Types.VoiceLine, text: string): string?
	if line.hum == "none" then
		return nil
	end
	if line.hum then
		return line.hum
	end
	local lower = string.lower(text)
	if string.sub(text, -1) == "?" then
		return "question"
	elseif string.sub(lower, 1, 2) == "no" then
		return "no"
	elseif string.find(lower, "haha", 1, true) or string.find(lower, "yay", 1, true) then
		return "happy"
	end
	return "neutral"
end

local function playTts(entry: CacheEntry, head: BasePart?)
	local tts = entry.tts
	local target: Instance? = nil
	local emitter: AudioEmitter? = nil
	if head then
		local e = Instance.new("AudioEmitter")
		e.Name = "VoiceEmitter"
		e:SetDistanceAttenuation({ [0] = 1, [40] = 0.85, [90] = 0.4, [160] = 0 })
		e.Parent = head
		emitter = e
		target = e
	else
		target = output2D
	end
	if not target then
		return
	end
	local wire = Instance.new("Wire")
	wire.SourceInstance = tts
	wire.TargetInstance = target
	wire.Parent = tts
	tts.Volume = (VoiceSettings[tts.Name :: any] and VoiceSettings[tts.Name :: any].volume or 1)
		* Settings.get().voiceVolume
	tts.TimePosition = 0
	tts:Play()
	table.insert(playing, tts)
	local connection: RBXScriptConnection
	connection = tts.Ended:Connect(function()
		connection:Disconnect()
		wire:Destroy()
		if emitter then
			emitter:Destroy()
		end
	end)
end

local function blipper(speaker: string): ((number) -> ())?
	if not BLIP_SPEAKERS[speaker] then
		return nil
	end
	return function(index: number)
		if index % 2 ~= 1 then
			return
		end
		local mood = Players.LocalPlayer:GetAttribute("GiallinoMood")
		local broken = typeof(mood) == "number" and mood < 40
		Audio.play(
			if broken then "giallino_blip_broken" else "giallino_blip",
			nil,
			{ volume = 0.25 }
		)
	end
end

--- Says a line: subtitle + voice. Returns how long the subtitle stays up.
function VoiceService.say(lineId: string, opts: SayOptions?): number
	local o: SayOptions = opts or {}
	local line = VoiceLines.get(lineId)
	if not line then
		warn("[VoiceService] unknown line " .. lineId)
		return 0
	end
	local text = VoiceService.personalize(line.text, o.tokens)
	local duration = Subtitles.show(line.speaker, text, blipper(line.speaker))
	if not Settings.get().voices then
		return duration
	end
	local head = headOf(o.speakerModel)
	if line.soundId then
		local sound = Instance.new("Sound")
		sound.SoundId = line.soundId
		sound.Volume = Settings.get().voiceVolume
		sound.SoundGroup = Audio.group("Voice")
		sound.Parent = head or SoundService
		sound.Ended:Once(function()
			sound:Destroy()
		end)
		sound:Play()
		table.insert(playing, sound)
		return duration
	end
	local settings = VoiceSettings[line.speaker]
	local hum = if settings and settings.villager then humKind(line, text) else nil
	local entry = startLoad(line.speaker, text)
	task.spawn(function()
		if hum then
			Audio.play("npc_hum_" .. hum, head, { volume = 0.5 })
			task.wait(0.35)
		end
		if not entry then
			return
		end
		local waited = 0
		while entry.state == "loading" and waited < 1.5 do
			waited += task.wait(0.05)
		end
		if entry.state == "ready" then
			playTts(entry, head)
		end
	end)
	return duration
end

--- Intro chant the first time a character appears in gameplay (not in cutscenes).
function VoiceService.playIntroChant(speaker: Types.SpeakerId, model: Model?)
	if chanted[speaker] then
		return
	end
	chanted[speaker] = true
	local line = VoiceLines.chant(speaker)
	if line then
		VoiceService.say(line.id, { speakerModel = model })
	end
end

--- Stops every voice (cutscene skipped / ended).
function VoiceService.stopAll()
	for _, inst in playing do
		if inst.Parent then
			if inst:IsA("AudioTextToSpeech") then
				inst:Pause()
			elseif inst:IsA("Sound") then
				inst:Stop()
			end
		end
	end
	table.clear(playing)
	Subtitles.clear()
end

function VoiceService.init()
	ensureOutputs()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(ensureOutputs)
end

return VoiceService
