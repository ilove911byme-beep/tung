--!strict
-- Server side of the cutscene system. The server picks a shared start time (server clock),
-- every client plays the cutscene locally from the same data and reports when it has finished;
-- the server waits for all of them (at most cutscene length + SyncGraceSeconds).
-- Cutscenes are split into segments: a segment can end in a party vote (CS-02, CS-23) whose
-- winner picks the next segment. Skipping needs a skip vote from every player and is not
-- allowed for lock cutscenes the first time they play in this server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Anchors = require(Shared:WaitForChild("World"):WaitForChild("Anchors"))
local Config = require(Shared:WaitForChild("Config"))
local CutsceneLibrary = require(Shared:WaitForChild("CutsceneLibrary"))
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Types = require(Shared:WaitForChild("Types"))

local VoteService = require(script.Parent.VoteService)

export type PlayOptions = {
	players: { Player }?,
	entry: string?, -- start at another segment (variants)
	tokens: { [Player]: { [string]: string } }?, -- per-player text tokens, e.g. ["Hiding spot"]
}

export type Result = { choice: string?, skipped: boolean }

type SavedCharacter = { root: BasePart, anchored: boolean }

type Run = {
	runId: string,
	data: Types.Cutscene,
	participants: { [Player]: boolean },
	skipVotes: { [Player]: boolean },
	finished: { [Player]: boolean },
	segment: string,
	inVote: boolean,
	skipRequested: boolean,
	saved: { [Player]: SavedCharacter },
	runtime: Folder,
}

local CutsceneService = {}

-- Fired as (cutsceneId, optionId, effects, voters) when an in-cutscene vote ends.
-- StoryFlags / Achievements (Phase 1b) listen to this.
local choiceEvent = Instance.new("BindableEvent")
CutsceneService.ChoiceMade = choiceEvent.Event

local current: Run? = nil
local runCounter = 0
local playedOnce: { [string]: boolean } = {}
local skipLimiter = RateLimiter.new(0.4)
local finishLimiter = RateLimiter.new(0.1)

local function participantList(run: Run): { Player }
	local list = {}
	for player in run.participants do
		if player.Parent then
			table.insert(list, player)
		end
	end
	return list
end

local function skipAllowed(run: Run): boolean
	return (not run.data.noSkip or playedOnce[run.data.id] == true) and not run.inVote
end

local function broadcastSkipState(run: Run)
	local list = participantList(run)
	local votes = 0
	for p in run.skipVotes do
		if run.participants[p] then
			votes += 1
		end
	end
	local remote = Remotes.get(Remotes.Names.CutsceneSkipState)
	for _, p in list do
		remote:FireClient(p, run.runId, votes, #list, skipAllowed(run))
	end
	if #list > 0 and votes >= #list and skipAllowed(run) then
		run.skipRequested = true
	end
end

local function allFinished(run: Run): boolean
	for _, p in participantList(run) do
		if not run.finished[p] then
			return false
		end
	end
	return true
end

local function rootHeight(humanoid: Humanoid, root: BasePart): number
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		return root.Size.Y / 2 + 2
	end
	return humanoid.HipHeight + root.Size.Y / 2
end

local function placePlayers(run: Run, list: { Player })
	local spec = run.data.players
	local mode = if spec then spec.mode else "keep"
	if mode == "keep" then
		return
	end
	for i, player in list do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and root and root:IsA("BasePart") then
			run.saved[player] = { root = root, anchored = root.Anchored }
			if spec and mode == "slots" and spec.anchor and spec.slots then
				local slot = spec.slots[((i - 1) % #spec.slots) + 1]
				local cf = Anchors.get(spec.anchor)
					* CFrame.new(slot + Vector3.new(0, rootHeight(humanoid, root), 0))
					* CFrame.Angles(0, math.rad(spec.yaw or 0), 0)
				root.AssemblyLinearVelocity = Vector3.zero
				if character then
					character:PivotTo(cf)
				end
			end
			root.Anchored = true
		end
	end
end

local function restorePlayers(run: Run)
	for player, saved in run.saved do
		if saved.root.Parent then
			saved.root.Anchored = saved.anchored
		end
		if player.Parent then
			player:SetAttribute("InCutscene", nil)
		end
	end
	for player in run.participants do
		if player.Parent then
			player:SetAttribute("InCutscene", nil)
		end
	end
end

local function firstAnchor(data: Types.Cutscene): string?
	if data.players and data.players.anchor then
		return data.players.anchor
	end
	for _, actor in data.actors do
		if actor.at.anchor then
			return actor.at.anchor
		end
	end
	return nil
end

local function buildRuntime(runId: string, data: Types.Cutscene): Folder
	local root = ReplicatedStorage:FindFirstChild("CutsceneRuntime")
	if not root then
		local newRoot = Instance.new("Folder")
		newRoot.Name = "CutsceneRuntime"
		newRoot.Parent = ReplicatedStorage
		root = newRoot
	end
	assert(root, "CutsceneRuntime folder")
	local folder = Instance.new("Folder")
	folder.Name = runId
	local models = ServerStorage:FindFirstChild("Models")
	local copied: { [string]: boolean } = {}
	for _, actor in data.actors do
		if not copied[actor.model] then
			copied[actor.model] = true
			local template = models and models:FindFirstChild(actor.model)
			if template then
				template:Clone().Parent = folder
			else
				warn(
					string.format(
						"[CutsceneService] %s: model '%s' not in ServerStorage.Models",
						data.id,
						actor.model
					)
				)
			end
		end
	end
	folder.Parent = root
	return folder
end

local function nextVoteSegment(data: Types.Cutscene, from: string?): string?
	local key = from
	local guard = 0
	while key and guard < 32 do
		local seg = data.segments[key]
		if seg.vote then
			return key
		end
		key = seg.next
		guard += 1
	end
	return nil
end

function CutsceneService.init()
	Remotes.get(Remotes.Names.CutsceneFinished).OnServerEvent
		:Connect(function(player: Player, runId: unknown, segment: unknown)
			local run = current
			if not run or runId ~= run.runId or segment ~= run.segment then
				return
			end
			if not run.participants[player] or not finishLimiter:allow(player) then
				return
			end
			run.finished[player] = true
		end)
	Remotes.get(Remotes.Names.CutsceneSkip).OnServerEvent
		:Connect(function(player: Player, runId: unknown)
			local run = current
			if not run or runId ~= run.runId or not run.participants[player] then
				return
			end
			if not skipLimiter:allow(player) or not skipAllowed(run) then
				return
			end
			if run.skipVotes[player] then
				run.skipVotes[player] = nil
			else
				run.skipVotes[player] = true
			end
			broadcastSkipState(run)
		end)
	Players.PlayerRemoving:Connect(function(player)
		local run = current
		if run and run.participants[player] then
			run.participants[player] = nil
			run.skipVotes[player] = nil
			run.saved[player] = nil
			broadcastSkipState(run)
		end
	end)
end

function CutsceneService.isPlaying(): boolean
	return current ~= nil
end

--- Plays a cutscene for the party and yields until it is over.
function CutsceneService.play(id: string, opts: PlayOptions?): Result
	local o: PlayOptions = opts or {}
	local data = CutsceneLibrary.get(id)
	if not data then
		warn("[CutsceneService] unknown cutscene " .. id)
		return { choice = nil, skipped = false }
	end
	while current do
		task.wait(0.25)
	end
	runCounter += 1
	local runId = string.format("%s_%d", data.id, runCounter)
	local list = o.players or Players:GetPlayers()
	local run: Run = {
		runId = runId,
		data = data,
		participants = {},
		skipVotes = {},
		finished = {},
		segment = o.entry or data.entry,
		inVote = false,
		skipRequested = false,
		saved = {},
		runtime = buildRuntime(runId, data),
	}
	current = run
	for _, p in list do
		run.participants[p] = true
		p:SetAttribute("InCutscene", true) -- HealthAndDeath ignores damage while this is set
	end
	placePlayers(run, list)

	local anchorName = firstAnchor(data)
	if anchorName then
		local pos = Anchors.get(anchorName).Position
		for _, p in list do
			task.spawn(function()
				pcall(function()
					p:RequestStreamAroundAsync(pos, 2)
				end)
			end)
		end
	end

	local result: Result = { choice = nil, skipped = false }
	local segKey = run.segment
	local segStart = workspace:GetServerTimeNow() + Config.Cutscene.LeadSeconds
	local startRemote = Remotes.get(Remotes.Names.CutsceneStart)
	for _, p in list do
		local tokens = if o.tokens then o.tokens[p] else nil
		startRemote:FireClient(p, runId, data.id, segKey, segStart, {
			skippable = skipAllowed(run),
			tokens = tokens or {},
		})
	end

	while true do
		local seg = data.segments[segKey]
		run.segment = segKey
		run.finished = {}
		local nextKey: string? = seg.next
		local jumped = false
		if seg.vote then
			run.inVote = true
			broadcastSkipState(run)
			local options = {}
			for _, option in seg.vote.options do
				table.insert(options, { id = option.id, text = option.text })
			end
			local _, optionId = VoteService.run({
				options = options,
				voters = participantList(run),
				endsAt = segStart + (seg.vote.seconds or Config.Vote.Seconds),
			})
			run.inVote = false
			result.choice = optionId
			for _, option in seg.vote.options do
				if option.id == optionId then
					nextKey = option.next
					choiceEvent:Fire(data.id, optionId, option.effects or {}, participantList(run))
					print(string.format("[CutsceneService] %s choice: %s", data.id, optionId))
				end
			end
		else
			local isLast = nextKey == nil
			local segEnd = segStart + seg.length
			local deadline = segEnd + (if isLast then Config.Cutscene.SyncGraceSeconds else 0)
			while workspace:GetServerTimeNow() < deadline do
				if run.skipRequested then
					break
				end
				if isLast and workspace:GetServerTimeNow() >= segEnd and allFinished(run) then
					break
				end
				task.wait(0.05)
			end
			if run.skipRequested then
				run.skipRequested = false
				run.skipVotes = {}
				result.skipped = true
				jumped = true
				nextKey = nextVoteSegment(data, seg.next)
				broadcastSkipState(run)
			end
		end
		if not nextKey then
			break
		end
		segKey = nextKey
		segStart = workspace:GetServerTimeNow() + 0.15
		run.segment = segKey
		local segRemote = Remotes.get(Remotes.Names.CutsceneSegment)
		for _, p in participantList(run) do
			segRemote:FireClient(p, runId, segKey, segStart, jumped)
		end
	end

	local endRemote = Remotes.get(Remotes.Names.CutsceneEnd)
	for _, p in participantList(run) do
		endRemote:FireClient(p, runId, result.skipped)
	end
	restorePlayers(run)
	playedOnce[data.id] = true
	current = nil
	local runtime = run.runtime
	task.delay(5, function()
		runtime:Destroy()
	end)
	return result
end

return CutsceneService
