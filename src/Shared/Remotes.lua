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
	-- HUD
	Objective = "Objective", -- s->c (text or "")
	Timer = "Timer", -- s->c (endsAt or 0)
	Toast = "Toast", -- s->c (kind, data)  kind: achievement | aura | info
	BossCard = "BossCard", -- s->c (title, subtitle, signatureSound)
	MemoryPage = "MemoryPage", -- s->c (pageId)
	-- inventory
	InventoryUpdate = "InventoryUpdate", -- s->c (slots)
	UseItem = "UseItem", -- c->s (slotIndex)
	-- health / death
	DeathScreen = "DeathScreen", -- s->c (show, solo)
	DeathChoice = "DeathChoice", -- c->s ("revive" | "spectate" | "retry")
	-- QTE
	QTEStart = "QTEStart", -- s->c (qteId, spec)
	QTEResult = "QTEResult", -- c->s (qteId, success)
	QTETap = "QTETap", -- c->s (qteId) party bar taps
	QTEProgress = "QTEProgress", -- s->c (qteId, progress 0..1)
	QTEEnd = "QTEEnd", -- s->c (qteId, success)
	-- dialogue
	DialogueLine = "DialogueLine", -- s->c (lineId, tokens)
	DialogueEnd = "DialogueEnd", -- s->c ()
	-- journal
	JournalUpdate = "JournalUpdate", -- s->c (state)
	JournalRead = "JournalRead", -- c->s ("names")
	-- world
	WorldFx = "WorldFx", -- s->c (kind, params)
	GiallinoSay = "GiallinoSay", -- s->c (text) companion line outside cutscenes
	-- lobby
	LobbyCart = "LobbyCart", -- c->s (action: "leave" | "public" | "friends" | "start", arg)
	LobbyCartState = "LobbyCartState", -- s->c (cartIndex, state) the local rider's cart panel
	LobbyLaunch = "LobbyLaunch", -- s->c (cartIndex, startTime, riderUserIds) roll into the tunnel
	LobbyProfile = "LobbyProfile", -- c->s (settings, chosenChapter) sent before riding
	LobbyOwned = "LobbyOwned", -- s->c (ownedAchievementIds, lastEnding)
	LobbyStare = "LobbyStare", -- c->s () the staring contest with the menu Giallino is won
	LobbyEmote = "LobbyEmote", -- c->s (emoteId or "")
	LobbyLine = "LobbyLine", -- s->c (lineId) a lobby NPC speaks to this player
	LobbyToast = "LobbyToast", -- s->c (achievementId) unlocked in the lobby
	LobbyAura = "LobbyAura", -- s->c ({ {name, aura} }) the session aura board
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
