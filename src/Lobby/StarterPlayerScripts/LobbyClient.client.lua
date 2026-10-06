--!strict
-- Lobby place client entry point: audio (music, voices, subtitles), the cutscene engine for
-- CS-00, the world effects, NPC faces / idles, then the main menu, the lobby HUD, emotes, the
-- launch into the story and the little teasers.
local StarterGui = game:GetService("StarterGui")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Root = script.Parent
local Settings = require(Root:WaitForChild("Settings"))
local AudioFolder = Root:WaitForChild("Audio")
local MusicDirector = require(AudioFolder:WaitForChild("MusicDirector"))
local Footsteps = require(AudioFolder:WaitForChild("Footsteps"))
local VoiceService = require(AudioFolder:WaitForChild("VoiceService"))
local CutsceneEngine = require(Root:WaitForChild("Cutscene"):WaitForChild("CutsceneEngine"))
local WorldFx = require(Root:WaitForChild("Gameplay"):WaitForChild("WorldFx"))
local MapClient = require(Root:WaitForChild("Gameplay"):WaitForChild("MapClient"))

local Lobby = Root:WaitForChild("Lobby")
local Profile = require(Lobby:WaitForChild("Profile"))
local Emotes = require(Lobby:WaitForChild("Emotes"))
local Launch = require(Lobby:WaitForChild("Launch"))
local LobbyHud = require(Lobby:WaitForChild("LobbyHud"))
local Teasers = require(Lobby:WaitForChild("Teasers"))
local MainMenu = require(Lobby:WaitForChild("MainMenu"))

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

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
Footsteps.init()
VoiceService.init()
CutsceneEngine.init()
WorldFx.init()
MapClient.init()

Remotes.get(Remotes.Names.LobbyLine).OnClientEvent:Connect(function(lineId: string)
	VoiceService.say(lineId)
end)

Profile.init()
Emotes.init()
Launch.init()
LobbyHud.init()
Teasers.init()
MainMenu.init()
MusicDirector.setState("lobby")
