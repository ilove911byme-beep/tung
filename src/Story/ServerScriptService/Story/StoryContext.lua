--!strict
-- The API chapter scripts use. Everything a step creates can be tracked so a party wipe or the
-- end of a chapter removes it again. Story text never lives here: objectives come from
-- Shared/StoryData/Objectives, lines from Shared/VoiceLines, dialogues from Shared/Dialogues.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Anchors = require(Shared:WaitForChild("World"):WaitForChild("Anchors"))
local Objectives = require(Shared:WaitForChild("StoryData"):WaitForChild("Objectives"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local SSS = script.Parent.Parent
local Services = SSS:WaitForChild("Services")
local Systems = SSS:WaitForChild("Systems")
local CutsceneService = require(Services:WaitForChild("CutsceneService"))
local VoteService = require(Services:WaitForChild("VoteService"))
local AchievementService = require(Systems:WaitForChild("AchievementService"))
local AtmosphereService = require(Systems:WaitForChild("AtmosphereService"))
local AuraService = require(Systems:WaitForChild("AuraService"))
local BossFramework = require(Systems:WaitForChild("BossFramework"))
local ClueService = require(Systems:WaitForChild("ClueService"))
local DialogueService = require(Systems:WaitForChild("DialogueService"))
local HealthService = require(Systems:WaitForChild("HealthService"))
local HidingService = require(Systems:WaitForChild("HidingService"))
local Hud = require(Systems:WaitForChild("Hud"))
local InventoryService = require(Systems:WaitForChild("InventoryService"))
local ParkourService = require(Systems:WaitForChild("ParkourService"))
local QTEService = require(Systems:WaitForChild("QTEService"))
local StoryFlags = require(Systems:WaitForChild("StoryFlags"))
local ThreatService = require(Systems:WaitForChild("ThreatService"))

local StoryContext = {}
StoryContext.__index = StoryContext

export type Context = typeof(setmetatable(
	{} :: {
		tracked: { Instance | () -> () },
		checkpoint: CFrame,
		flags: typeof(StoryFlags),
		inv: typeof(InventoryService),
		health: typeof(HealthService),
		clues: typeof(ClueService),
		qte: typeof(QTEService),
		hiding: typeof(HidingService),
		threats: typeof(ThreatService),
		atmosphere: typeof(AtmosphereService),
		achievements: typeof(AchievementService),
		aura: typeof(AuraService),
		dialogues: typeof(DialogueService),
		cutscenes: typeof(CutsceneService),
		parkour: typeof(ParkourService),
		boss: typeof(BossFramework),
		hud: typeof(Hud),
		votes: typeof(VoteService),
	},
	StoryContext
))

function StoryContext.new(): Context
	return setmetatable({
		tracked = {},
		checkpoint = CFrame.new(0, 60, 0),
		flags = StoryFlags,
		inv = InventoryService,
		health = HealthService,
		clues = ClueService,
		qte = QTEService,
		hiding = HidingService,
		threats = ThreatService,
		atmosphere = AtmosphereService,
		achievements = AchievementService,
		aura = AuraService,
		dialogues = DialogueService,
		cutscenes = CutsceneService,
		parkour = ParkourService,
		boss = BossFramework,
		hud = Hud,
		votes = VoteService,
	}, StoryContext)
end

function StoryContext.players(_self: Context): { Player }
	return Players:GetPlayers()
end

function StoryContext.alive(_self: Context): { Player }
	return HealthService.alivePlayers()
end

--- Remember something to remove on wipe / chapter end (an Instance or a cleanup function).
function StoryContext.track<T>(self: Context, thing: T): T
	table.insert(self.tracked, thing :: any)
	return thing
end

function StoryContext.cleanup(self: Context)
	for i = #self.tracked, 1, -1 do
		local thing = self.tracked[i]
		if typeof(thing) == "Instance" then
			thing:Destroy()
		elseif type(thing) == "function" then
			pcall(thing)
		end
	end
	table.clear(self.tracked)
end

function StoryContext.anchor(_self: Context, name: string): CFrame
	return Anchors.get(name)
end

--- Plays a cutscene (yields). Per-player tokens ([Hiding spot]) are filled from the flags.
function StoryContext.cutscene(_self: Context, id: string, entry: string?): CutsceneService.Result
	local tokens: { [Player]: { [string]: string } } = {}
	local spots = StoryFlags.get().hidingSpots
	for _, p in Players:GetPlayers() do
		tokens[p] = { ["Hiding spot"] = spots[tostring(p.UserId)] or "In the inn" }
	end
	return CutsceneService.play(id, { entry = entry, tokens = tokens })
end

function StoryContext.objective(_self: Context, id: string, ...: any)
	local text = Objectives[id]
	assert(text, "unknown objective " .. id)
	Hud.objective(if select("#", ...) > 0 then string.format(text, ...) else text)
end

function StoryContext.clearObjective(_self: Context)
	Hud.objective("")
end

function StoryContext.timer(_self: Context, seconds: number): number
	local endsAt = workspace:GetServerTimeNow() + seconds
	Hud.timer(endsAt)
	return endsAt
end

function StoryContext.clearTimer(_self: Context)
	Hud.timer(0)
end

function StoryContext.wait(_self: Context, seconds: number)
	task.wait(seconds)
end

--- Polls until fn() is true (or the timeout passes). Returns whether fn() became true.
function StoryContext.waitUntil(
	_self: Context,
	fn: () -> boolean,
	timeout: number?,
	interval: number?
): boolean
	local start = os.clock()
	while not fn() do
		if timeout and os.clock() - start >= timeout then
			return false
		end
		task.wait(interval or 0.2)
	end
	return true
end

function StoryContext.music(_self: Context, state: string)
	local remote = Remotes.get(Remotes.Names.MusicState)
	for _, p in Players:GetPlayers() do
		remote:FireClient(p, state)
	end
end

function StoryContext.preset(_self: Context, name: string, time: number?)
	AtmosphereService.preset(name, time)
end

function StoryContext.glitch(_self: Context, kind: string, params: { [string]: any }?)
	AtmosphereService.glitch(kind, params)
end

--- Moves the party next to a CFrame (or anchor), spread in a row.
function StoryContext.teleport(self: Context, at: CFrame | string, spacing: number?)
	local cf = if typeof(at) == "string" then self:anchor(at) else at
	for i, p in Players:GetPlayers() do
		local character = p.Character
		if character then
			local offset = ((i - 1) - (#Players:GetPlayers() - 1) / 2) * (spacing or 3)
			character:PivotTo(cf * CFrame.new(offset, 3, 0))
		end
	end
end

export type PromptOptions = {
	hold: number?,
	distance: number?,
	objectText: string?,
	key: Enum.KeyCode?,
}

--- A ProximityPrompt that calls handler(player) for alive players. Tracked.
function StoryContext.prompt(
	self: Context,
	parent: Instance,
	actionText: string,
	opts: PromptOptions?,
	handler: (Player) -> ()
): ProximityPrompt
	local o: PromptOptions = opts or {}
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = o.objectText or ""
	prompt.HoldDuration = o.hold or 0
	prompt.MaxActivationDistance = o.distance or 9
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = o.key or Enum.KeyCode.E
	prompt.Parent = parent
	prompt.Triggered:Connect(function(player: Player)
		if
			player:GetAttribute("LifeState") == "Alive" and not player:GetAttribute("InCutscene")
		then
			handler(player)
		end
	end)
	self:track(prompt)
	return prompt
end

--- Yields until someone uses the prompt; returns who did. The prompt is removed afterwards.
function StoryContext.waitPrompt(
	self: Context,
	parent: Instance,
	actionText: string,
	opts: PromptOptions?
): Player
	local done = Instance.new("BindableEvent")
	local who: Player? = nil
	local prompt = self:prompt(parent, actionText, opts, function(player)
		if not who then
			who = player
			done:Fire()
		end
	end)
	done.Event:Wait()
	prompt:Destroy()
	done:Destroy()
	return who :: Player
end

function StoryContext.say(_self: Context, lineId: string)
	DialogueService.say(lineId)
end

function StoryContext.dialogue(_self: Context, id: string): DialogueService.Result
	return DialogueService.run(id)
end

export type VoteOption = { id: string, text: string }

function StoryContext.vote(_self: Context, options: { VoteOption }, seconds: number?): string
	local _, id =
		VoteService.run({ options = options, voters = Players:GetPlayers(), seconds = seconds })
	return id
end

function StoryContext.award(_self: Context, id: string, players: { Player }?)
	AchievementService.awardAll(players, id)
end

function StoryContext.auraAll(_self: Context, amount: number)
	AuraService.addAll(amount)
end

--- A villager NPC placed by the map (workspace.NPCs, attribute CharacterId).
function StoryContext.npc(_self: Context, id: string): Model?
	for _, m in CollectionService:GetTagged("NPC") do
		if m:IsA("Model") and m:GetAttribute("CharacterId") == id then
			return m
		end
	end
	return nil
end

--- A tagged map instance (MapBuilder tags interactables with "Story_<name>").
function StoryContext.find(_self: Context, name: string): Instance?
	local list = CollectionService:GetTagged("Story_" .. name)
	return list[1]
end

function StoryContext.findAll(_self: Context, name: string): { Instance }
	return CollectionService:GetTagged("Story_" .. name)
end

--- A Part to hang prompts on (the instance itself, its PrimaryPart or first BasePart).
function StoryContext.part(self: Context, name: string): BasePart
	local inst = self:find(name)
	assert(inst, "map instance Story_" .. name .. " is missing")
	if inst:IsA("BasePart") then
		return inst
	end
	if inst:IsA("Model") and inst.PrimaryPart then
		return inst.PrimaryPart
	end
	local p = inst:FindFirstChildWhichIsA("BasePart", true)
	assert(p, "map instance Story_" .. name .. " has no parts")
	return p
end

function StoryContext.giallinoSay(_self: Context, text: string)
	Hud.giallinoSay(text)
end

return StoryContext
