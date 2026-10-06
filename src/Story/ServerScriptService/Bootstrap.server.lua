--!strict
-- Phase 0 smoke test for the Story place. ChapterManager replaces this in Phase 1b.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Strings = require(Shared:WaitForChild("Strings"))

print(
	string.format(
		"[%s] Story place booted. place=%s version=%s skipLobby=%s",
		Strings.GameTitle,
		Config.currentPlace(),
		Config.Version,
		tostring(Config.shouldSkipLobby())
	)
)
