--!strict
-- Story place server entry point. Phase 1a: cutscene and animation stack.
-- ChapterManager takes over the story flow in Phase 1b.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))

local Services = script.Parent:WaitForChild("Services")
local CutsceneService = require(Services:WaitForChild("CutsceneService"))
local VoteService = require(Services:WaitForChild("VoteService"))
local RigFactory = require(script.Parent:WaitForChild("World"):WaitForChild("RigFactory"))

Remotes.init()
RigFactory.buildAll()
VoteService.init()
CutsceneService.init()

if RunService:IsStudio() then
	local Dev = script.Parent:WaitForChild("Dev")
	require(Dev:WaitForChild("TestStage")).buildIfNeeded()
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
