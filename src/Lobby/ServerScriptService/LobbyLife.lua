--!strict
-- The living lobby (brief, <memes>): the cameo villagers on the platform with their intro chants
-- and lobby lines, the station speaker, the emote wheel (the server keeps the emote as a player
-- attribute; every client animates it), "6 7" on the emote stage (+67 aura, Udin cheers) and the
-- session Aura board (the aura of the last story run + lobby fun).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))

local Builder = require(script.Parent:WaitForChild("World"):WaitForChild("Builder"))
local LobbyProfiles = require(script.Parent:WaitForChild("LobbyProfiles"))
local LobbyWorld = require(script.Parent:WaitForChild("LobbyWorld"))

local LobbyLife = {}

local EMOTES = {
	["A-EMOTE_67"] = true,
	["A-EMOTE_AURA"] = true,
	["A-EMOTE_BRAINROT"] = true,
	["A-EMOTE_BAT"] = true,
}
local EMOTE_SECONDS = 10
local SPEAKER_EVERY = 120

type Cameo = { id: string, x: number, z: number, yaw: number, line: string? }
local CAMEOS: { Cameo } = {
	{ id = "TrippiTroppi", x = 16, z = 44.5, yaw = 180, line = "LOBBY_TRIPPI_BOARD" },
	{ id = "UdinDinDinDun", x = 43, z = 49, yaw = 270, line = "LOBBY_UDIN_67" },
	{ id = "BonecaAmbalabu", x = 9, z = 45, yaw = 135 },
	{ id = "LaVacaSaturno", x = 27, z = 45.5, yaw = 200 },
	{ id = "FrigoCamelo", x = 9.5, z = 38.5, yaw = 90 },
	{ id = "GlorboFruttodrillo", x = 31, z = 40, yaw = 250 },
}

local limiter = RateLimiter.new(0.4)
local heard: { [Player]: { [string]: boolean } } = {}
local stageBonus: { [Player]: boolean } = {}
local emoteToken: { [Player]: number } = {}

local function say(player: Player, lineId: string)
	Remotes.get(Remotes.Names.LobbyLine):FireClient(player, lineId)
end

local function placeCameo(c: Cameo, parent: Instance)
	local models = ServerStorage:FindFirstChild("Models")
	local template = models and models:FindFirstChild(c.id)
	if not template or not template:IsA("Model") then
		return
	end
	local m = template:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("BillboardGui") then
			d.Enabled = false
		end
	end
	local pos = Builder.studs(c.x, LobbyWorld.Ground, c.z)
	local r = math.rad(c.yaw)
	local h = (m:GetAttribute("RootHeight") :: number?) or 0
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m:PivotTo(
		CFrame.lookAt(pos, pos + Vector3.new(math.sin(r), 0, -math.cos(r))) * CFrame.new(0, h, 0)
	)
	m.Parent = parent
	CollectionService:AddTag(m, "NPC")
	CollectionService:AddTag(m, "Faced")
	local head = m:FindFirstChild("Head") or m.PrimaryPart
	if not head then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Strings.Prompts.Talk
	prompt.ObjectText = (m:GetAttribute("DisplayName") :: string?) or c.id
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = head
	prompt.Triggered:Connect(function(player: Player)
		if not limiter:allow(player) then
			return
		end
		local mine = heard[player] or {}
		heard[player] = mine
		local chant = "CHANT_" .. string.upper(c.id)
		if not mine[chant] then
			mine[chant] = true
			say(player, chant)
		elseif c.line then
			say(player, c.line)
		else
			say(player, chant)
		end
	end)
end

local function onStage(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	local c =
		Builder.studs(LobbyWorld.EmoteStage.X, LobbyWorld.EmoteStage.Y, LobbyWorld.EmoteStage.Z)
	return Vector3.new(root.Position.X - c.X, 0, root.Position.Z - c.Z).Magnitude < 3.5 * Builder.S
end

local board: SurfaceGui? = nil

local function refreshBoard()
	local gui = board
	if not gui then
		return
	end
	local list = gui:FindFirstChild("List")
	if not list then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local rows = {}
	for _, p in Players:GetPlayers() do
		table.insert(rows, { name = p.DisplayName, aura = LobbyProfiles.get(p).aura })
	end
	table.sort(rows, function(a, b)
		return a.aura > b.aura
	end)
	if #rows == 0 or rows[1].aura == 0 then
		local empty = Instance.new("TextLabel")
		empty.BackgroundTransparency = 1
		empty.Size = UDim2.new(1, 0, 0, 40)
		empty.Font = Enum.Font.FredokaOne
		empty.TextScaled = true
		empty.TextColor3 = Color3.fromHex("#9AA0B4")
		empty.Text = Strings.Lobby.AuraEmpty
		empty.Parent = list
	end
	for i, row in rows do
		if i > 8 or row.aura == 0 then
			break
		end
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 40)
		label.LayoutOrder = i
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = if i == 1 then Color3.fromHex("#FFC83A") else Color3.fromHex("#F4EFE6")
		label.Text = string.format("%d. %s  %d", i, row.name, row.aura)
		label.Parent = list
	end
	local ranking = {}
	for _, row in rows do
		table.insert(ranking, { row.name, row.aura })
	end
	Remotes.get(Remotes.Names.LobbyAura):FireAllClients(ranking)
end

local function buildBoard()
	for _, part in CollectionService:GetTagged("AuraBoard") do
		if part:IsA("BasePart") then
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Left -- the board stands on the east side, facing west
			gui.CanvasSize = Vector2.new(360, 240)
			gui.LightInfluence = 0.4
			local title = Instance.new("TextLabel")
			title.BackgroundTransparency = 1
			title.Size = UDim2.new(1, 0, 0, 50)
			title.Font = Enum.Font.Creepster
			title.TextScaled = true
			title.TextColor3 = Color3.fromHex("#FF9A3C")
			title.Text = Strings.Lobby.AuraBoard
			title.Parent = gui
			local list = Instance.new("Frame")
			list.Name = "List"
			list.BackgroundTransparency = 1
			list.Position = UDim2.fromOffset(16, 56)
			list.Size = UDim2.new(1, -32, 1, -64)
			list.Parent = gui
			local layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = list
			gui.Parent = part
			board = gui
		end
	end
end

function LobbyLife.init(parent: Instance)
	local npcs = Instance.new("Folder")
	npcs.Name = "NPCs"
	npcs.Parent = parent
	for _, c in CAMEOS do
		placeCameo(c, npcs)
	end
	buildBoard()
	refreshBoard()
	LobbyProfiles.Changed:Connect(refreshBoard)
	Players.PlayerAdded:Connect(function(p: Player)
		task.delay(6, function()
			if p.Parent then
				say(p, "LOBBY_SPEAKER")
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(p: Player)
		heard[p] = nil
		stageBonus[p] = nil
		emoteToken[p] = nil
		task.defer(refreshBoard)
	end)
	task.spawn(function()
		while true do
			task.wait(SPEAKER_EVERY)
			for _, p in Players:GetPlayers() do
				say(p, "LOBBY_SPEAKER")
			end
		end
	end)
	Remotes.get(Remotes.Names.LobbyEmote).OnServerEvent
		:Connect(function(player: Player, id: unknown)
			if not limiter:allow(player) then
				return
			end
			if id == "" or id == nil then
				player:SetAttribute("Emote", nil)
				return
			end
			if type(id) ~= "string" or not EMOTES[id] then
				return
			end
			player:SetAttribute("Emote", id)
			local token = (emoteToken[player] or 0) + 1
			emoteToken[player] = token
			task.delay(EMOTE_SECONDS, function()
				if emoteToken[player] == token and player.Parent then
					player:SetAttribute("Emote", nil)
				end
			end)
			if id == "A-EMOTE_67" and onStage(player) and not stageBonus[player] then
				stageBonus[player] = true
				LobbyProfiles.get(player).aura += 67
				say(player, "LOBBY_UDIN_67")
				refreshBoard()
			end
		end)
end

return LobbyLife
