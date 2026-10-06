--!strict
-- Awards the 30 Roblox badges (Shared/Achievements). BadgeService:AwardBadge is only called when
-- a badgeId is filled in and the player does not own the badge yet; the toast always shows the
-- first time in this server. Also keeps the session counters some badges need.
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Achievements = require(Shared:WaitForChild("Achievements"))

local Hud = require(script.Parent.Hud)

local AchievementService = {}

local awarded: { [number]: { [string]: boolean } } = {}
local counters: { [number]: { [string]: number } } = {}

local function owned(userId: number, badgeId: number): boolean
	local ok, has = pcall(function()
		return BadgeService:UserHasBadgeAsync(userId, badgeId)
	end)
	return ok and has == true
end

function AchievementService.award(player: Player, id: string)
	local def = Achievements.ById[id]
	if not def then
		warn("[Achievements] unknown id " .. id)
		return
	end
	local mine = awarded[player.UserId]
	if not mine then
		mine = {}
		awarded[player.UserId] = mine
	end
	if mine[id] then
		return
	end
	mine[id] = true
	Hud.toast({ player }, "achievement", { id = id })
	if def.badgeId ~= 0 then
		task.spawn(function()
			if not owned(player.UserId, def.badgeId) then
				local ok, err = pcall(function()
					BadgeService:AwardBadge(player.UserId, def.badgeId)
				end)
				if not ok then
					warn("[Achievements] AwardBadge failed for " .. id .. ": " .. tostring(err))
				end
			end
		end)
	end
end

--- The ids this player earned in this server (handed back to the lobby after the ending).
function AchievementService.earned(player: Player): { string }
	local out = {}
	local mine: { [string]: boolean } = awarded[player.UserId] or {}
	for id in mine do
		table.insert(out, id)
	end
	return out
end

function AchievementService.awardAll(players: { Player }?, id: string)
	for _, p in players or Players:GetPlayers() do
		AchievementService.award(p, id)
	end
end

function AchievementService.has(player: Player, id: string): boolean
	local mine = awarded[player.UserId]
	return mine ~= nil and mine[id] == true
end

--- Session counter (e.g. revives for HERO_REVIVE). Returns the new value.
function AchievementService.count(player: Player, key: string, delta: number?): number
	local mine = counters[player.UserId]
	if not mine then
		mine = {}
		counters[player.UserId] = mine
	end
	mine[key] = (mine[key] or 0) + (delta or 1)
	return mine[key]
end

function AchievementService.counter(player: Player, key: string): number
	local mine = counters[player.UserId]
	return if mine then mine[key] or 0 else 0
end

function AchievementService.init()
	Players.PlayerRemoving:Connect(function(p)
		awarded[p.UserId] = nil
		counters[p.UserId] = nil
	end)
end

return AchievementService
