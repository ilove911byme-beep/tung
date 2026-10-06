--!strict
-- All RemoteEvents in one place. The server creates them (Remotes.init()), clients wait for them.
-- c->s = sent by clients (always validated on the server), s->c = sent by the server.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

Remotes.Names = {
	CutsceneStart = "CutsceneStart", -- s->c (runId, cutsceneId, segment, startTime, info)
	CutsceneSegment = "CutsceneSegment", -- s->c (runId, segment, startTime, jumpedBySkip)
	CutsceneEnd = "CutsceneEnd", -- s->c (runId, skipped)
	CutsceneFinished = "CutsceneFinished", -- c->s (runId, segment)
	CutsceneSkip = "CutsceneSkip", -- c->s (runId)
	CutsceneSkipState = "CutsceneSkipState", -- s->c (runId, votes, needed, allowed)
	VoteStart = "VoteStart", -- s->c (voteId, options, endsAt)
	VoteCast = "VoteCast", -- c->s (voteId, optionIndex)
	VoteUpdate = "VoteUpdate", -- s->c (voteId, counts)
	VoteEnd = "VoteEnd", -- s->c (voteId, winnerIndex)
	MusicState = "MusicState", -- s->c (state)
	DebugFx = "DebugFx", -- s->c (effectName) Studio only
} :: { [string]: string }

local FOLDER = "Remotes"

function Remotes.init()
	assert(RunService:IsServer(), "Remotes.init is server only")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER
		folder.Parent = ReplicatedStorage
	end
	for _, name in Remotes.Names do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
end

function Remotes.get(name: string): RemoteEvent
	local folder = ReplicatedStorage:WaitForChild(FOLDER)
	local remote = folder:WaitForChild(name, 30)
	assert(remote and remote:IsA("RemoteEvent"), "missing remote " .. name)
	return remote
end

return Remotes
