--!strict
-- Dialogue with party votes (brief, gameplay system 4): lines are shown to everyone in the
-- dialogue box (speaker name + portrait color + typewriter + voice), choices are voted on by the
-- party (majority, 15 s, random on tie). Dialogue data lives in Shared/Dialogues.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local VoiceLines = require(Shared:WaitForChild("VoiceLines"))

local VoteService =
	require(script.Parent.Parent:WaitForChild("Services"):WaitForChild("VoteService"))

export type Choice = {
	id: string,
	text: string,
	next: string?,
	effects: { [string]: any }?,
	requires: string?, -- name of a condition the chapter registered
}

export type Node = {
	lines: { string }?,
	choices: { Choice }?,
	next: string?,
	effects: { [string]: any }?,
}

export type Dialogue = { id: string, start: string, nodes: { [string]: Node } }

export type Result = { choices: { string }, effects: { { [string]: any } } }

local DialogueService = {}

local dialogueFolder = Shared:WaitForChild("Dialogues")
local conditions: { [string]: () -> boolean } = {}
local effectHandler: ((effects: { [string]: any }, voters: { Player }) -> ())? = nil

function DialogueService.setCondition(name: string, fn: () -> boolean)
	conditions[name] = fn
end

export type EffectHandler = (effects: { [string]: any }, voters: { Player }) -> ()

function DialogueService.setEffectHandler(fn: EffectHandler)
	effectHandler = fn
end

local function lineTime(lineId: string): number
	local line = VoiceLines.get(lineId)
	if not line then
		return 1
	end
	local chars = utf8.len(line.text) or #line.text
	return chars / Config.Voice.SubtitleCharsPerSecond + 1.3
end

--- Shows one line to everyone (outside a full dialogue) and waits until it is read.
function DialogueService.say(lineId: string, players: { Player }?, tokens: { [string]: string }?)
	local remote = Remotes.get(Remotes.Names.DialogueLine)
	for _, p in players or Players:GetPlayers() do
		remote:FireClient(p, lineId, tokens)
	end
	task.wait(lineTime(lineId))
end

function DialogueService.close(players: { Player }?)
	local remote = Remotes.get(Remotes.Names.DialogueEnd)
	for _, p in players or Players:GetPlayers() do
		remote:FireClient(p)
	end
end

function DialogueService.get(id: string): Dialogue
	local module = dialogueFolder:FindFirstChild(id)
	assert(module and module:IsA("ModuleScript"), "unknown dialogue " .. id)
	return (require :: any)(module) :: Dialogue
end

--- Runs a dialogue for the party and yields until it ends.
function DialogueService.run(id: string, players: { Player }?): Result
	local dialogue = DialogueService.get(id)
	local list = players or Players:GetPlayers()
	local result: Result = { choices = {}, effects = {} }
	local nodeId: string? = dialogue.start
	local guard = 0
	while nodeId and guard < 64 do
		guard += 1
		local node = dialogue.nodes[nodeId]
		assert(node, id .. ": missing node " .. nodeId)
		local lines: { string } = node.lines or {}
		for _, lineId in lines do
			DialogueService.say(lineId, list)
		end
		if node.effects then
			table.insert(result.effects, node.effects)
			if effectHandler then
				effectHandler(node.effects, list)
			end
		end
		local nextId = node.next
		local choices = node.choices
		if choices then
			local visible: { Choice } = {}
			for _, c in choices do
				local cond = c.requires and conditions[c.requires]
				if not c.requires or (cond and cond()) then
					table.insert(visible, c)
				end
			end
			if #visible > 0 then
				local options = {}
				for _, c in visible do
					table.insert(options, { id = c.id, text = c.text })
				end
				local _, chosenId = VoteService.run({
					options = options,
					voters = list,
					seconds = Config.Vote.Seconds,
				})
				for _, c in visible do
					if c.id == chosenId then
						table.insert(result.choices, c.id)
						if c.effects then
							table.insert(result.effects, c.effects)
							if effectHandler then
								effectHandler(c.effects, list)
							end
						end
						nextId = c.next
					end
				end
			end
		end
		nodeId = nextId
	end
	DialogueService.close(list)
	return result
end

return DialogueService
