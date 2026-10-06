--!strict
-- Clues, Memory Pages and Tung Tung's list of names (brief, gameplay system 5). The Journal is
-- shared by the party: the server keeps the state and sends it to every client.
--  * real clues lower Giallino's mood by 8; fake clues stay "?" until their debunking clue is found
--  * Memory Pages: glowing pickups (Parts tagged "MemoryPage", attribute PageId); the Narrator
--    reads each one; all 12 -> ARCHIVIST
--  * reading the names in the Journal -> SAY_THEIR_NAMES
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))
local Clues = require(Shared:WaitForChild("StoryData"):WaitForChild("Clues"))
local MemoryPages = require(Shared:WaitForChild("StoryData"):WaitForChild("MemoryPages"))
local NamesList = require(Shared:WaitForChild("StoryData"):WaitForChild("NamesList"))
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))

local AchievementService = require(script.Parent.AchievementService)
local AuraService = require(script.Parent.AuraService)
local Hud = require(script.Parent.Hud)
local StoryFlags = require(script.Parent.StoryFlags)

local ClueService = {}

local clueById: { [string]: Clues.Clue } = {}
for _, c in Clues do
	clueById[c.id] = c
end

local names: { string } = table.clone(NamesList.base)
local namesUnlocked = false
local readLimiter = RateLimiter.new(1)
local foundEvent = Instance.new("BindableEvent")
ClueService.ClueFound = foundEvent.Event -- (clueId)

local function state(): { [string]: any }
	local flags = StoryFlags.get()
	return {
		clues = flags.cluesFound,
		memories = flags.memoryPages,
		names = if namesUnlocked then names else {},
	}
end

function ClueService.broadcast()
	local remote = Remotes.get(Remotes.Names.JournalUpdate)
	local s = state()
	for _, p in Players:GetPlayers() do
		remote:FireClient(p, s)
	end
end

function ClueService.has(id: string): boolean
	return StoryFlags.get().cluesFound[id] == true
end

--- A clue was found by the party.
function ClueService.found(id: string, finder: Player?)
	local clue = clueById[id]
	assert(clue, "unknown clue " .. id)
	local flags = StoryFlags.get()
	if flags.cluesFound[id] then
		return
	end
	flags.cluesFound[id] = true
	if not clue.fake then
		StoryFlags.addMood(-8)
	end
	Audio.play("clue_found", nil, { volume = 0.6 })
	Hud.toast(nil, "info", { text = string.format(Strings.Hud.NewClue, clue.title) })
	if finder then
		AuraService.add(finder, 100)
	end
	ClueService.broadcast()
	foundEvent:Fire(id)
end

function ClueService.unlockNames()
	namesUnlocked = true
	ClueService.broadcast()
end

function ClueService.addName(name: string)
	if not table.find(names, name) then
		table.insert(names, name)
	end
	ClueService.broadcast()
end

function ClueService.memoryPage(pageId: string, finder: Player?)
	local flags = StoryFlags.get()
	if flags.memoryPages[pageId] then
		return
	end
	flags.memoryPages[pageId] = true
	Audio.play("xp_orb_pickup", nil, { volume = 0.6 })
	Hud.memoryPage(pageId)
	local n = 0
	for _ in flags.memoryPages do
		n += 1
	end
	Hud.toast(nil, "info", { text = string.format(Strings.Hud.PageFound, n) })
	if pageId == "M6" then
		ClueService.unlockNames()
	end
	if n >= #MemoryPages then
		AchievementService.awardAll(nil, "ARCHIVIST")
	end
	if finder then
		AuraService.add(finder, 100)
	end
	ClueService.broadcast()
end

--- Shows / hides page pickups for the current chapter (pages of later chapters stay hidden).
function ClueService.refreshPages(chapter: number)
	local flags = StoryFlags.get()
	for _, part in CollectionService:GetTagged("MemoryPage") do
		if part:IsA("BasePart") then
			local id = part:GetAttribute("PageId") :: string?
			local page = nil
			for _, pg in MemoryPages do
				if pg.id == id then
					page = pg
				end
			end
			local visible = page ~= nil
				and page.chapter <= chapter
				and not flags.memoryPages[id :: string]
			part.Transparency = if visible then 0.15 else 1
			local prompt = part:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Enabled = visible
			end
			local light = part:FindFirstChildOfClass("PointLight")
			if light then
				light.Enabled = visible
			end
		end
	end
end

local function setupPage(part: Instance)
	if not part:IsA("BasePart") or part:FindFirstChildOfClass("ProximityPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Strings.Prompts.Pickup
	prompt.ObjectText = Strings.Hud.Memory
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player: Player)
		local id = part:GetAttribute("PageId")
		if typeof(id) == "string" and player:GetAttribute("LifeState") == "Alive" then
			ClueService.memoryPage(id, player)
			part.Transparency = 1
			prompt.Enabled = false
		end
	end)
end

function ClueService.init()
	for _, part in CollectionService:GetTagged("MemoryPage") do
		setupPage(part)
	end
	CollectionService:GetInstanceAddedSignal("MemoryPage"):Connect(setupPage)
	Remotes.get(Remotes.Names.JournalRead).OnServerEvent
		:Connect(function(player: Player, what: unknown)
			if what == "names" and namesUnlocked and readLimiter:allow(player) then
				AchievementService.award(player, "SAY_THEIR_NAMES")
			end
		end)
	Players.PlayerAdded:Connect(function(p)
		task.wait(3)
		Remotes.get(Remotes.Names.JournalUpdate):FireClient(p, state())
	end)
	StoryFlags.Changed:Connect(function(key)
		if key == "*" then
			ClueService.broadcast()
		end
	end)
end

function ClueService.namesUnlocked(): boolean
	return namesUnlocked
end

return ClueService
