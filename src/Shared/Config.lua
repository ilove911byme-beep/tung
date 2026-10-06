--!strict
-- Central tuning values for both places (Lobby and Story). Nothing story-specific lives here.
local RunService = game:GetService("RunService")

local Config = {}

Config.GameName = "Night in Brainrot Valley"
Config.Version = "0.0.1-phase0"

-- Paste the real PlaceIds here after publishing both places into ONE universe (see README).
-- 0 = not set yet.
Config.PlaceIds = {
	Lobby = 0,
	Story = 0,
}

-- Studio testing: when true (and only inside Studio) the Story place starts Chapter 1 right away
-- without a lobby party. Ignored in live servers, see Config.shouldSkipLobby().
Config.SkipLobby = true

-- Party / queue
Config.Party = {
	MinPlayers = 1,
	MaxPlayers = 6,
	CartCount = 4,
	QueueCountdown = 20, -- seconds, resets when someone joins
	ArrivalTimeout = 30, -- Story place waits this long for all members, then starts with whoever is there
}

-- Revive product (the ONLY monetization). ProductId 0 = placeholder, fill in from Creator Hub.
Config.Revive = {
	ProductId = 0,
	PriceRobux = 45,
	InvulnerableSeconds = 3,
}

-- Health, Downed and Dead rules (screenplay.md "Death and revive")
Config.Health = {
	MaxHealth = 100,
	HeartCount = 10,
	DownedSeconds = 30,
	ReviveHoldSeconds = 3,
	ReviveHealth = 30,
	ProductReviveHealth = 100,
}

-- Votes (dialogue choices, accusation, final choice)
Config.Vote = {
	Seconds = 15,
	-- Tie-break is random, see brief.
}

Config.Inventory = {
	MaxSlots = 4,
}

-- Giallino mood: 100 -> 0. Tier lower bounds, checked from the top down.
Config.Mood = {
	Start = 100,
	Tiers = {
		{ name = "Happy", min = 70 }, -- 100-70
		{ name = "Off", min = 40 }, -- 69-40, Falsino phase
		{ name = "Broken", min = 10 }, -- 39-10, Negatino phase
		{ name = "Hostile", min = 0 }, -- <10, Crudelino phase
	},
}

-- Cutscenes
Config.Cutscene = {
	LetterboxSeconds = 0.4,
	ReturnBlendSeconds = 0.6,
	SyncGraceSeconds = 3, -- server waits for all clients: cutscene length + this
	LeadSeconds = 1.5, -- shared start time is this far in the future (actors load, TTS preloads)
}

-- Text-to-speech. Roblox allows 1 + 6 * concurrent users requests per minute per experience,
-- so every client keeps to its own 6 per minute and falls back to subtitles beyond that.
Config.Voice = {
	RequestsPerMinutePerClient = 6,
	MaxTextLength = 300,
	SubtitleCharsPerSecond = 32,
	SubtitleHoldSeconds = 1.6,
}

-- World (map.md)
Config.World = {
	StudsPerBlock = 4,
	SizeBlocks = 160,
	GroundY = 12, -- in blocks
	WaterY = 10, -- in blocks
	MaxParts = 25000,
}

-- Sound groups created by the Audio helper (Phase 1a)
Config.SoundGroups = { "Music", "Ambience", "SFX", "Voice" }

-- Debug helpers that only ever run inside Studio
Config.Debug = {
	EnableChatCommands = true, -- /cs CS_xx, /fx <Effect>, /tp <spot> (later phases)
	TestStage = true, -- build the Phase 1a test stage when no map exists (Studio only)
	WarnMissingSounds = true, -- warn once per placeholder SoundId (Studio only)
}

--- True only inside Studio and only when Config.SkipLobby is set.
function Config.shouldSkipLobby(): boolean
	return Config.SkipLobby and RunService:IsStudio()
end

--- Which place this server is running. Returns "Lobby", "Story" or "Unknown"
--- (Unknown is normal in an unpublished Studio file where PlaceId is 0).
function Config.currentPlace(): string
	if game.PlaceId == 0 then
		return "Unknown"
	end
	if game.PlaceId == Config.PlaceIds.Lobby then
		return "Lobby"
	end
	if game.PlaceId == Config.PlaceIds.Story then
		return "Story"
	end
	return "Unknown"
end

--- Maps a mood value (0-100) to its tier name.
function Config.moodTier(mood: number): string
	for _, tier in Config.Mood.Tiers do
		if mood >= tier.min then
			return tier.name
		end
	end
	return "Hostile"
end

return Config
