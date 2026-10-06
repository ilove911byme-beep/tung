--!strict
-- Lobby place server entry point: rigs (for the cameos and the CS-00 actors), the station world,
-- player profiles, the minecart queue and the living lobby.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))

local RigFactory = require(script.Parent:WaitForChild("World"):WaitForChild("RigFactory"))
local LobbyLife = require(script.Parent:WaitForChild("LobbyLife"))
local LobbyProfiles = require(script.Parent:WaitForChild("LobbyProfiles"))
local LobbyWorld = require(script.Parent:WaitForChild("LobbyWorld"))
local QueueService = require(script.Parent:WaitForChild("QueueService"))

Remotes.init()
Players.CharacterAutoLoads = true
RigFactory.buildAll()
local world = LobbyWorld.build()
LobbyProfiles.init()
QueueService.init(world)
LobbyLife.init(world)

print(
	string.format(
		"[%s] Lobby place booted. place=%s version=%s",
		Strings.GameTitle,
		Config.currentPlace(),
		Config.Version
	)
)
