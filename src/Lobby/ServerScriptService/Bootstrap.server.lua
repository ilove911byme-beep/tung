--!strict
-- Phase 0 smoke test for the Lobby place. Replaced by real services in Phase 5.5.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Strings = require(Shared:WaitForChild("Strings"))
local UITheme = require(Shared:WaitForChild("UITheme"))

print(
	string.format(
		"[%s] Lobby place booted. place=%s version=%s tokens=%s",
		Strings.GameTitle,
		Config.currentPlace(),
		Config.Version,
		tostring(UITheme.CornerRadius.Offset)
	)
)
