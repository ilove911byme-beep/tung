--!strict
-- The party in the Story place: members come from the lobby's TeleportData {partyId, members,
-- chosenChapter}. The place waits until every member arrived (max 30 s), then the story starts
-- with whoever is there. In Studio with Config.SkipLobby the story starts right away.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local PartyService = {}

local expected: { [number]: boolean } = {}
local chosenChapter = 1
local returnData: { [string]: any } = {}

local function readJoinData(player: Player)
	local ok, data = pcall(function()
		return player:GetJoinData()
	end)
	if not ok or type(data) ~= "table" then
		return
	end
	local td = (data :: any).TeleportData
	if type(td) ~= "table" then
		return
	end
	if type(td.members) == "table" then
		for _, id in td.members do
			if type(id) == "number" then
				expected[id] = true
			end
		end
	end
	if type(td.chosenChapter) == "number" then
		chosenChapter = math.clamp(math.floor(td.chosenChapter), 1, 6)
	end
end

local function allArrived(): boolean
	for id in expected do
		if not Players:GetPlayerByUserId(id) then
			return false
		end
	end
	return true
end

--- Yields until the party is here (or 30 s passed). Returns the chapter to start from.
function PartyService.waitForParty(): number
	if Config.shouldSkipLobby() then
		while #Players:GetPlayers() == 0 do
			task.wait(0.2)
		end
		task.wait(2)
		return 1
	end
	while #Players:GetPlayers() == 0 do
		task.wait(0.2)
	end
	for _, p in Players:GetPlayers() do
		readJoinData(p)
	end
	local start = os.clock()
	while not allArrived() and os.clock() - start < Config.Party.ArrivalTimeout do
		task.wait(0.5)
		for _, p in Players:GetPlayers() do
			readJoinData(p)
		end
	end
	task.wait(1.5)
	return chosenChapter
end

--- Data handed back to the lobby when the game ends (ending for the menu's meta effect).
function PartyService.setReturnData(key: string, value: any)
	returnData[key] = value
end

function PartyService.returnData(): { [string]: any }
	return returnData
end

function PartyService.init()
	Players.PlayerAdded:Connect(readJoinData)
end

return PartyService
