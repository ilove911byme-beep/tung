--!strict
-- After the credits the party goes back to the lobby (brief, lobby / ENDLESS NIGHT meta effect).
-- TeleportData carries the ending, the achievements earned in this run (so the menu can show
-- them even before the badges exist) and everybody's aura for the session board.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local AchievementService = require(script.Parent.AchievementService)
local PartyService = require(script.Parent.PartyService)

local ReturnService = {}

function ReturnService.toLobby()
	local players = Players:GetPlayers()
	if #players == 0 then
		return
	end
	if RunService:IsStudio() or Config.PlaceIds.Lobby == 0 then
		print(
			"[ReturnService] the story is over; the return teleport to the lobby only works in a published game"
		)
		return
	end
	local achievements = {}
	local aura = {}
	for _, p in players do
		achievements[tostring(p.UserId)] = AchievementService.earned(p)
		aura[tostring(p.UserId)] = (p:GetAttribute("Aura") :: number?) or 0
	end
	local data = {
		ending = PartyService.returnData().ending,
		achievements = achievements,
		aura = aura,
	}
	-- a teleport can still fail after TeleportAsync returned: try that player once more
	local retried: { [Player]: boolean } = {}
	TeleportService.TeleportInitFailed:Connect(function(player: Player)
		if retried[player] or not player.Parent then
			return
		end
		retried[player] = true
		task.delay(3, function()
			pcall(function()
				local options = Instance.new("TeleportOptions")
				options:SetTeleportData(data)
				TeleportService:TeleportAsync(Config.PlaceIds.Lobby, { player }, options)
			end)
		end)
	end)
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			local options = Instance.new("TeleportOptions")
			options:SetTeleportData(data)
			TeleportService:TeleportAsync(Config.PlaceIds.Lobby, Players:GetPlayers(), options)
		end)
		if ok then
			return
		end
		warn(
			string.format("[ReturnService] teleport attempt %d failed: %s", attempt, tostring(err))
		)
		task.wait(3)
	end
end

return ReturnService
