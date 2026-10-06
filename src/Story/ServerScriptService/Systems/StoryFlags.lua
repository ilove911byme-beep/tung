--!strict
-- One server table every chapter reads and writes (brief, gameplay system 6). Checkpoints take a
-- snapshot so a party wipe can roll the flags back to the moment of the checkpoint.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

export type Flags = {
	chapter: number,
	giallinoMood: number,
	cluesFound: { [string]: boolean },
	riddleCorrect: boolean,
	spottedFalsino: boolean,
	sawTungRunning: boolean,
	jailed: string?, -- "TungTung" | "Cappuccino" | "Bombardiro" | nil
	hidingSpots: { [string]: string }, -- tostring(userId) -> spot name (CS-10)
	neverDark: boolean,
	untouchable: boolean,
	perfectRide: boolean,
	gears: number,
	glowingLantern: boolean,
	memoryPages: { [string]: boolean },
	patapimGone: boolean,
	bombardiroDown: boolean,
	finalChoice: string?,
	ending: string?,
	tungTalks: number,
	startedAt: number,
}

local StoryFlags = {}

local function defaults(): Flags
	return {
		chapter = 1,
		giallinoMood = Config.Mood.Start,
		cluesFound = {},
		riddleCorrect = false,
		spottedFalsino = false,
		sawTungRunning = false,
		jailed = nil,
		hidingSpots = {},
		neverDark = true,
		untouchable = true,
		perfectRide = true,
		gears = 0,
		glowingLantern = false,
		memoryPages = {},
		patapimGone = false,
		bombardiroDown = false,
		finalChoice = nil,
		ending = nil,
		tungTalks = 0,
		startedAt = os.clock(),
	}
end

local flags: Flags = defaults()
local changed = Instance.new("BindableEvent")
StoryFlags.Changed = changed.Event -- (key)

local function deepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value :: any do
		out[k] = deepCopy(v)
	end
	return out :: any
end

function StoryFlags.get(): Flags
	return flags
end

function StoryFlags.set(key: string, value: any)
	(flags :: any)[key] = value
	changed:Fire(key)
end

--- Lowers (or raises) Giallino's mood and mirrors it on every player for the client effects.
function StoryFlags.addMood(delta: number)
	flags.giallinoMood = math.clamp(flags.giallinoMood + delta, 0, 100)
	for _, p in Players:GetPlayers() do
		p:SetAttribute("GiallinoMood", flags.giallinoMood)
	end
	changed:Fire("giallinoMood")
end

function StoryFlags.moodTier(): string
	return Config.moodTier(flags.giallinoMood)
end

function StoryFlags.snapshot(): Flags
	return deepCopy(flags)
end

function StoryFlags.restore(snapshot: Flags)
	local startedAt = flags.startedAt
	flags = deepCopy(snapshot)
	flags.startedAt = startedAt -- the speedrun timer keeps running
	for _, p in Players:GetPlayers() do
		p:SetAttribute("GiallinoMood", flags.giallinoMood)
	end
	changed:Fire("*")
end

function StoryFlags.reset()
	flags = defaults()
	changed:Fire("*")
end

--- Number of real clues found (C1..C7).
function StoryFlags.realClues(): number
	local n = 0
	for id in flags.cluesFound do
		if string.sub(id, 1, 1) == "C" then
			n += 1
		end
	end
	return n
end

function StoryFlags.init()
	Players.PlayerAdded:Connect(function(p)
		p:SetAttribute("GiallinoMood", flags.giallinoMood)
	end)
	for _, p in Players:GetPlayers() do
		p:SetAttribute("GiallinoMood", flags.giallinoMood)
	end
end

return StoryFlags
