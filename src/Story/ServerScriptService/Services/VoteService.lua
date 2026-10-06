--!strict
-- Party votes (in-cutscene choices now, dialogue choices in Phase 1b): majority wins, the
-- timer is 15 s, a tie is broken at random, no votes at all = random option.
-- Votes end early when every voter has voted. Players may change their vote until the end.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))
local Remotes = require(Shared:WaitForChild("Remotes"))

export type Option = { id: string, text: string }
export type VoteRequest = {
	options: { Option },
	voters: { Player },
	seconds: number?,
	endsAt: number?, -- server time; overrides seconds
}

type ActiveVote = {
	id: string,
	options: { Option },
	voters: { [Player]: boolean },
	choices: { [Player]: number },
	endsAt: number,
	done: BindableEvent,
	closed: boolean,
}

local VoteService = {}

local active: { [string]: ActiveVote } = {}
local voteCounter = 0
local limiter = RateLimiter.new(0.2)
local rng = Random.new()

local function counts(vote: ActiveVote): { number }
	local out = table.create(#vote.options, 0)
	for _, index in vote.choices do
		out[index] += 1
	end
	return out
end

local function allVoted(vote: ActiveVote): boolean
	for player in vote.voters do
		if player.Parent and vote.choices[player] == nil then
			return false
		end
	end
	return true
end

local function winnerOf(vote: ActiveVote): number
	local c = counts(vote)
	local best = -1
	local tied: { number } = {}
	for i, n in c do
		if n > best then
			best = n
			tied = { i }
		elseif n == best then
			table.insert(tied, i)
		end
	end
	return tied[rng:NextInteger(1, #tied)]
end

local function voterList(vote: ActiveVote): { Player }
	local list = {}
	for player in vote.voters do
		if player.Parent then
			table.insert(list, player)
		end
	end
	return list
end

function VoteService.init()
	Remotes.get(Remotes.Names.VoteCast).OnServerEvent
		:Connect(function(player: Player, voteId: unknown, index: unknown)
			if typeof(voteId) ~= "string" or typeof(index) ~= "number" then
				return
			end
			if not limiter:allow(player) then
				return
			end
			local vote = active[voteId]
			if not vote or vote.closed or not vote.voters[player] then
				return
			end
			local i = math.floor(index)
			if i < 1 or i > #vote.options or i ~= index then
				return
			end
			vote.choices[player] = i
			local update = Remotes.get(Remotes.Names.VoteUpdate)
			for _, p in voterList(vote) do
				update:FireClient(p, vote.id, counts(vote))
			end
			if allVoted(vote) then
				vote.done:Fire()
			end
		end)
	Players.PlayerRemoving:Connect(function(player)
		for _, vote in active do
			vote.voters[player] = nil
			vote.choices[player] = nil
			if not vote.closed and allVoted(vote) then
				vote.done:Fire()
			end
		end
	end)
end

--- Ends every open vote now (party wipe / restart).
function VoteService.cancelAll()
	for _, vote in active do
		if not vote.closed then
			vote.done:Fire()
		end
	end
end

--- Runs a vote and yields until it ends. Returns the winning option index and id.
function VoteService.run(request: VoteRequest): (number, string, { [Player]: string })
	assert(#request.options > 0, "vote without options")
	local now = workspace:GetServerTimeNow()
	local endsAt = request.endsAt or (now + (request.seconds or Config.Vote.Seconds))
	voteCounter += 1
	local vote: ActiveVote = {
		id = "vote" .. voteCounter,
		options = request.options,
		voters = {},
		choices = {},
		endsAt = endsAt,
		done = Instance.new("BindableEvent"),
		closed = false,
	}
	for _, p in request.voters do
		vote.voters[p] = true
	end
	active[vote.id] = vote

	local payload = {}
	for _, o in request.options do
		table.insert(payload, { id = o.id, text = o.text })
	end
	local start = Remotes.get(Remotes.Names.VoteStart)
	for _, p in voterList(vote) do
		start:FireClient(p, vote.id, payload, endsAt)
	end

	local timer = task.delay(math.max(endsAt - now, 0), function()
		vote.done:Fire()
	end)
	if #voterList(vote) > 0 then
		vote.done.Event:Wait()
	end
	task.cancel(timer)
	vote.closed = true
	local winner = winnerOf(vote)
	local finish = Remotes.get(Remotes.Names.VoteEnd)
	for _, p in voterList(vote) do
		finish:FireClient(p, vote.id, winner)
	end
	active[vote.id] = nil
	vote.done:Destroy()
	local byPlayer: { [Player]: string } = {}
	for p, index in vote.choices do
		byPlayer[p] = request.options[index].id
	end
	return winner, request.options[winner].id, byPlayer
end

return VoteService
