--!strict
-- Story place server entry point: builds the rigs, starts every system and hands the story to
-- the ChapterManager. In Studio without a lobby teleport the story starts from
-- Config.Debug.StartChapter (or waits for /chapter when the test stage is used).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))

local SSS = script.Parent
local Services = SSS:WaitForChild("Services")
local Systems = SSS:WaitForChild("Systems")
local CutsceneService = require(Services:WaitForChild("CutsceneService"))
local VoteService = require(Services:WaitForChild("VoteService"))
local RigFactory = require(SSS:WaitForChild("World"):WaitForChild("RigFactory"))
local MapBuilder = require(SSS:WaitForChild("World"):WaitForChild("MapBuilder"))

local AchievementService = require(Systems:WaitForChild("AchievementService"))
local AtmosphereService = require(Systems:WaitForChild("AtmosphereService"))
local ClueService = require(Systems:WaitForChild("ClueService"))
local HealthService = require(Systems:WaitForChild("HealthService"))
local HidingService = require(Systems:WaitForChild("HidingService"))
local Hud = require(Systems:WaitForChild("Hud"))
local InventoryService = require(Systems:WaitForChild("InventoryService"))
local PartyService = require(Systems:WaitForChild("PartyService"))
local QTEService = require(Systems:WaitForChild("QTEService"))
local StoryFlags = require(Systems:WaitForChild("StoryFlags"))

local ChapterManager = require(SSS:WaitForChild("Story"):WaitForChild("ChapterManager"))

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

Remotes.init()
RigFactory.buildAll()
if not (RunService:IsStudio() and Config.Debug.TestStage) then
	MapBuilder.build()
end
VoteService.init()
CutsceneService.init()
StoryFlags.init()
AchievementService.init()
Hud.init()
AtmosphereService.init()
HealthService.init()
InventoryService.init()
QTEService.init()
HidingService.init()
ClueService.init()
PartyService.init()

local usingTestStage = false
if RunService:IsStudio() then
	local Dev = SSS:WaitForChild("Dev")
	usingTestStage = require(Dev:WaitForChild("TestStage")).buildIfNeeded()
	require(Dev:WaitForChild("DebugCommands")).init()
end

print(
	string.format(
		"[%s] Story place booted. place=%s version=%s skipLobby=%s",
		Strings.GameTitle,
		Config.currentPlace(),
		Config.Version,
		tostring(Config.shouldSkipLobby())
	)
)

-- Start the story once the party is here (PartyService knows who is expected).
task.spawn(function()
	if usingTestStage then
		return -- the test stage has no map: chapters start with /chapter
	end
	local chapter = PartyService.waitForParty()
	if #Players:GetPlayers() == 0 then
		return
	end
	ChapterManager.run(math.max(chapter, 1))
end)
