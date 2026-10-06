--!strict
-- What the lobby knows about each player, session only (no DataStore):
--   * achievements: owned Roblox badges (BadgeService, when a badgeId is filled in) plus the ones
--     earned in the last story run (TeleportData of the return teleport)
--   * the last ending (main menu meta effect after ENDLESS NIGHT) and the aura of that run
--   * the settings and the chapter the player picked in the main menu (sent before riding)
-- Also awards lobby badges (GIALLINO_STARE) and validates the staring contest.
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Achievements = require(Shared:WaitForChild("Achievements"))
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local LobbyProfiles = {}

export type Profile = {
	owned: { [string]: boolean },
	lastEnding: string?,
	aura: number,
	settings: { [string]: any },
	chapter: number,
	joinedAt: number,
}

local profiles: { [Player]: Profile } = {}
local limiter = RateLimiter.new(0.5)
local changed = Instance.new("BindableEvent")
LobbyProfiles.Changed = changed.Event -- (player)

local ENDING_BADGES: { [string]: string } =
	{ dawn = "ENDING_DAWN", endless = "ENDING_ENDLESS_NIGHT", sahur = "ENDING_SAHUR" }
local SETTING_KEYS: { [string]: string } = {
	musicVolume = "number",
	ambienceVolume = "number",
	sfxVolume = "number",
	voiceVolume = "number",
	subtitles = "boolean",
	voices = "boolean",
	cameraShake = "boolean",
	graphics = "string",
}

function LobbyProfiles.get(player: Player): Profile
	local p = profiles[player]
	if not p then
		p = {
			owned = {},
			lastEnding = nil,
			aura = 0,
			settings = {},
			chapter = 1,
			joinedAt = os.clock(),
		}
		profiles[player] = p
	end
	return p
end

local function send(player: Player)
	local p = LobbyProfiles.get(player)
	local list = {}
	for id in p.owned do
		table.insert(list, id)
	end
	Remotes.get(Remotes.Names.LobbyOwned):FireClient(player, list, p.lastEnding)
	changed:Fire(player)
end

--- True when the player owns any ending (replaying single chapters is unlocked then).
function LobbyProfiles.anyEnding(player: Player): boolean
	local owned = LobbyProfiles.get(player).owned
	for _, id in ENDING_BADGES do
		if owned[id] then
			return true
		end
	end
	return false
end

function LobbyProfiles.award(player: Player, id: string)
	local def = Achievements.ById[id]
	local p = LobbyProfiles.get(player)
	if not def or p.owned[id] then
		return
	end
	p.owned[id] = true
	Remotes.get(Remotes.Names.LobbyToast):FireClient(player, id)
	send(player)
	if def.badgeId ~= 0 then
		task.spawn(function()
			local ok, err = pcall(function()
				BadgeService:AwardBadge(player.UserId, def.badgeId)
			end)
			if not ok then
				warn("[LobbyProfiles] AwardBadge failed for " .. id .. ": " .. tostring(err))
			end
		end)
	end
end

local function readJoinData(player: Player)
	local p = LobbyProfiles.get(player)
	local ok, data = pcall(function()
		return player:GetJoinData()
	end)
	local td = if ok and type(data) == "table" then (data :: any).TeleportData else nil
	if type(td) ~= "table" then
		return
	end
	local key = tostring(player.UserId)
	if type(td.ending) == "string" and ENDING_BADGES[td.ending] then
		p.lastEnding = td.ending
		p.owned[ENDING_BADGES[td.ending]] = true
	end
	if type(td.achievements) == "table" and type(td.achievements[key]) == "table" then
		for _, id in td.achievements[key] do
			if type(id) == "string" and Achievements.ById[id] then
				p.owned[id] = true
			end
		end
	end
	if type(td.aura) == "table" and type(td.aura[key]) == "number" then
		p.aura = math.clamp(math.floor(td.aura[key]), -100000, 1000000)
	end
end

local function checkBadges(player: Player)
	local p = LobbyProfiles.get(player)
	for _, def in Achievements.List do
		if def.badgeId ~= 0 and not p.owned[def.id] then
			local ok, has = pcall(function()
				return BadgeService:UserHasBadgeAsync(player.UserId, def.badgeId)
			end)
			if ok and has then
				p.owned[def.id] = true
			end
		end
	end
end

local function onPlayer(player: Player)
	LobbyProfiles.get(player)
	readJoinData(player)
	send(player)
	task.spawn(function()
		checkBadges(player)
		if player.Parent then
			send(player)
		end
	end)
end

function LobbyProfiles.init()
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayer, p)
	end
	Players.PlayerRemoving:Connect(function(p: Player)
		profiles[p] = nil
	end)
	Remotes.get(Remotes.Names.LobbyProfile).OnServerEvent
		:Connect(function(player: Player, settings: unknown, chapter: unknown)
			if not limiter:allow(player) then
				return
			end
			local p = LobbyProfiles.get(player)
			if type(settings) == "table" then
				local clean = {}
				for k, kind in SETTING_KEYS do
					local v = (settings :: any)[k]
					if typeof(v) == kind then
						clean[k] = if kind == "number" then math.clamp(v, 0, 1) else v
					end
				end
				p.settings = clean
			end
			if type(chapter) == "number" then
				local c = math.clamp(math.floor(chapter), 1, 6)
				p.chapter = if c == 1 or LobbyProfiles.anyEnding(player) then c else 1
			end
		end)
	Remotes.get(Remotes.Names.LobbyStare).OnServerEvent:Connect(function(player: Player)
		if not limiter:allow(player) then
			return
		end
		-- the menu shows right after joining: the contest takes 60 s, so it cannot be won sooner
		if os.clock() - LobbyProfiles.get(player).joinedAt >= 58 then
			LobbyProfiles.award(player, "GIALLINO_STARE")
		end
	end)
end

return LobbyProfiles
