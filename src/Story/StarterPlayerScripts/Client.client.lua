--!strict
-- Story place client entry point (Phase 1a: cutscene, animation, voice and audio stack).
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))

local Root = script.Parent
local Settings = require(Root:WaitForChild("Settings"))
local MusicDirector = require(Root:WaitForChild("Audio"):WaitForChild("MusicDirector"))
local AmbienceDirector = require(Root:WaitForChild("Audio"):WaitForChild("AmbienceDirector"))
local Footsteps = require(Root:WaitForChild("Audio"):WaitForChild("Footsteps"))
local VoiceService = require(Root:WaitForChild("Audio"):WaitForChild("VoiceService"))
local VoteUI = require(Root:WaitForChild("UI"):WaitForChild("VoteUI"))
local CutsceneEngine = require(Root:WaitForChild("Cutscene"):WaitForChild("CutsceneEngine"))

Audio.init()
local function applyVolumes()
	local s = Settings.get()
	Audio.setGroupVolume("Music", s.musicVolume)
	Audio.setGroupVolume("Ambience", s.ambienceVolume)
	Audio.setGroupVolume("SFX", s.sfxVolume)
	Audio.setGroupVolume("Voice", s.voiceVolume)
end
applyVolumes()
Settings.Changed:Connect(applyVolumes)

MusicDirector.init()
AmbienceDirector.init()
Footsteps.init()
VoiceService.init()
VoteUI.init()
CutsceneEngine.init()

if RunService:IsStudio() then
	require(Root:WaitForChild("Dev"):WaitForChild("DebugClient")).init()
end
