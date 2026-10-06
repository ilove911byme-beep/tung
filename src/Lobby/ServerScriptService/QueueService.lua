--!strict
-- The party queue (brief, lobby B/C): 4 minecarts on the sidings = 4 queues of 1-6 riders.
-- Step in (Seat or the "Get in" prompt) to join, jump out to leave. The first rider owns the
-- cart: Public / Friends only and "Start now". A 20 s countdown restarts whenever somebody
-- joins. When it ends the safety bar locks, the riders see CS-00 (the carts roll into the
-- tunnel), the real cart rolls in for everybody else, and the party is teleported to a reserved
-- server of the Story place with TeleportData {partyId, members, chosenChapter, settings}.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CutsceneLibrary = require(Shared:WaitForChild("CutsceneLibrary"))
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))

local Builder = require(script.Parent:WaitForChild("World"):WaitForChild("Builder"))
local LobbyProfiles = require(script.Parent:WaitForChild("LobbyProfiles"))
local LobbyWorld = require(script.Parent:WaitForChild("LobbyWorld"))

local QueueService = {}

type Cart = {
	index: number,
	model: Model,
	base: BasePart,
	bar: BasePart,
	barOpen: CFrame,
	seats: { Seat },
	riders: { Player },
	owner: Player?,
	friendsOnly: boolean,
	endsAt: number?,
	launching: boolean,
	home: CFrame,
	label: TextLabel,
}

local S = Builder.S
local G = LobbyWorld.Ground
local carts: { Cart } = {}
local limiter = RateLimiter.new(0.3)

local function humanoidOf(p: Player): Humanoid?
	local character = p.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function buildCart(index: number, parent: Instance): Cart
	local z = LobbyWorld.CartZ[index]
	local center = Builder.studs(LobbyWorld.CartX, G, z + 0.5)
	local model = Instance.new("Model")
	model.Name = "QueueCart" .. index
	local function part(
		name: string,
		size: Vector3,
		offset: Vector3,
		color: string,
		mat: Enum.Material?
	): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.CFrame = CFrame.new(center + offset)
		p.Color = Color3.fromHex(color)
		p.Material = mat or Enum.Material.Metal
		p.TopSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local base = part("Base", Vector3.new(3 * S, 0.6, 2 * S), Vector3.new(0, 1.2, 0), "#5A5A60")
	part("WallN", Vector3.new(3 * S, 2.6, 0.4), Vector3.new(0, 2.6, -S + 0.2), "#6A6A70")
	part("WallS", Vector3.new(3 * S, 2.6, 0.4), Vector3.new(0, 2.6, S - 0.2), "#6A6A70")
	part("WallW", Vector3.new(0.4, 2.6, 2 * S), Vector3.new(-1.5 * S + 0.2, 2.6, 0), "#6A6A70")
	part("WallE", Vector3.new(0.4, 2.6, 2 * S), Vector3.new(1.5 * S - 0.2, 2.6, 0), "#6A6A70")
	for _, dx in { -1.1, 1.1 } do
		for _, dz in { -0.7, 0.7 } do
			local wheel = part(
				"Wheel",
				Vector3.new(0.6, 1.4, 1.4),
				Vector3.new(dx * S, 0.7, dz * S),
				"#2A2A2E"
			)
			wheel.Shape = Enum.PartType.Cylinder
			wheel.CFrame = CFrame.new(center + Vector3.new(dx * S, 0.7, dz * S))
				* CFrame.Angles(0, math.rad(90), 0)
		end
	end
	local bar =
		part("SafetyBar", Vector3.new(3 * S - 0.8, 0.3, 0.3), Vector3.new(0, 5.2, 0), "#E8C040")
	bar.CanCollide = false
	local seats: { Seat } = {}
	for _, dx in { -1, 0, 1 } do
		for _, dz in { -0.45, 0.45 } do
			local seat = Instance.new("Seat")
			seat.Name = "Seat"
			seat.Anchored = true
			seat.Size = Vector3.new(2, 0.4, 2)
			seat.CFrame = CFrame.new(center + Vector3.new(dx * S, 1.7, dz * S))
				* CFrame.Angles(0, math.rad(-90), 0)
			seat.Color = Color3.fromHex("#7A5A34")
			seat.Material = Enum.Material.Wood
			seat.Parent = model
			table.insert(seats, seat)
		end
	end
	model.PrimaryPart = base
	-- the queue label
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 70)
	gui.StudsOffset = Vector3.new(0, 7, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 120
	gui.Parent = base
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0.5, 0)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromHex("#FF9A3C")
	title.TextStrokeTransparency = 0.4
	title.Text = string.format(Strings.Queue.Cart, index)
	title.Parent = gui
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, 0.5)
	label.Size = UDim2.new(1, 0, 0.5, 0)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromHex("#F4EFE6")
	label.TextStrokeTransparency = 0.4
	label.Parent = gui
	model.Parent = parent
	return {
		index = index,
		model = model,
		base = base,
		bar = bar,
		barOpen = bar.CFrame,
		seats = seats,
		riders = {},
		owner = nil,
		friendsOnly = false,
		endsAt = nil,
		launching = false,
		home = model:GetPivot(),
		label = label,
	}
end

local function stateFor(cart: Cart, p: Player): { [string]: any }
	return {
		count = #cart.riders,
		max = #cart.seats,
		endsAt = cart.endsAt,
		owner = cart.owner == p,
		friendsOnly = cart.friendsOnly,
		launching = cart.launching,
	}
end

local function pushState(cart: Cart)
	local remote = Remotes.get(Remotes.Names.LobbyCartState)
	for _, p in cart.riders do
		remote:FireClient(p, cart.index, stateFor(cart, p))
	end
end

local function eject(seat: Seat)
	local occupant = seat.Occupant
	local weld = seat:FindFirstChild("SeatWeld")
	if weld then
		weld:Destroy()
	end
	if occupant then
		occupant.Sit = false
		occupant.Jump = true
	end
end

local function isFriend(a: Player, b: Player): boolean
	local ok, result = pcall(function()
		return a:IsFriendsWithAsync(b.UserId)
	end)
	return ok and result == true
end

local function refresh(cart: Cart)
	local before: { [Player]: boolean } = {}
	for _, p in cart.riders do
		before[p] = true
	end
	local now: { Player } = {}
	for _, seat in cart.seats do
		local h = seat.Occupant
		local p = h and Players:GetPlayerFromCharacter(h.Parent)
		if p then
			local newcomer = not before[p]
			local owner = cart.owner
			local refused = newcomer
				and (
					cart.launching
					or (cart.friendsOnly and owner ~= nil and owner ~= p and not isFriend(owner, p))
				)
			if refused then
				eject(seat)
			else
				table.insert(now, p)
			end
		end
	end
	-- keep the join order (the owner stays first)
	table.sort(now, function(a, b)
		local ia = table.find(cart.riders, a) or math.huge
		local ib = table.find(cart.riders, b) or math.huge
		return ia < ib
	end)
	local joined = false
	for _, p in now do
		if not before[p] then
			joined = true
		end
	end
	local leftRemote = Remotes.get(Remotes.Names.LobbyCartState)
	for p in before do
		if not table.find(now, p) and p.Parent then
			leftRemote:FireClient(p, cart.index, nil)
		end
	end
	cart.riders = now
	cart.owner = now[1]
	if #now == 0 then
		cart.endsAt = nil
		cart.friendsOnly = false
	elseif joined and not cart.launching then
		cart.endsAt = workspace:GetServerTimeNow() + Config.Party.QueueCountdown
	end
	pushState(cart)
end

local function resetCart(cart: Cart)
	cart.model:PivotTo(cart.home)
	cart.bar.CFrame = cart.barOpen
	cart.launching = false
	for _, p in cart.riders do
		local h = humanoidOf(p)
		if h then
			h.JumpHeight = 7.2
			h.JumpPower = 50
		end
	end
	for _, seat in cart.seats do
		eject(seat)
	end
	refresh(cart)
end

local function teleportParty(riders: { Player }): boolean
	if RunService:IsStudio() or Config.PlaceIds.Story == 0 then
		warn("[QueueService] " .. Strings.Lobby.StudioNoTeleport)
		return false
	end
	local owner = riders[1]
	local members = {}
	local settings = {}
	for _, p in riders do
		table.insert(members, p.UserId)
		settings[tostring(p.UserId)] = LobbyProfiles.get(p).settings
	end
	local data = {
		partyId = string.format(
			"%d-%d-%d",
			if owner then owner.UserId else 0,
			os.time(),
			math.random(1, 999999)
		),
		members = members,
		chosenChapter = if owner then LobbyProfiles.get(owner).chapter else 1,
		settings = settings,
	}
	for attempt = 1, 2 do
		local ok, err = pcall(function()
			local code = TeleportService:ReserveServer(Config.PlaceIds.Story)
			local options = Instance.new("TeleportOptions")
			options.ReservedServerAccessCode = code
			options:SetTeleportData(data)
			TeleportService:TeleportAsync(Config.PlaceIds.Story, riders, options)
		end)
		if ok then
			return true
		end
		warn(string.format("[QueueService] teleport attempt %d failed: %s", attempt, tostring(err)))
		task.wait(2)
	end
	return false
end

local function rollPath(cart: Cart): { Vector3 }
	local z = LobbyWorld.CartZ[cart.index] + 0.5
	return {
		Builder.studs(LobbyWorld.CartX, G, z),
		Builder.studs(34, G, z),
		Builder.studs(40, G, LobbyWorld.RailZ + 0.5),
		Builder.studs(96, G, LobbyWorld.RailZ + 0.5),
	}
end

local function launch(cart: Cart)
	if cart.launching or #cart.riders == 0 then
		return
	end
	cart.launching = true
	cart.endsAt = nil
	local riders = table.clone(cart.riders)
	for _, p in riders do
		local h = humanoidOf(p)
		if h then
			h.JumpHeight = 0
			h.JumpPower = 0
		end
	end
	cart.bar.CFrame = cart.barOpen * CFrame.new(0, -1.2, 0)
	pushState(cart)
	local data = CutsceneLibrary.get("CS_00")
	local length = if data then data.segments.main.length else 14
	local startTime = workspace:GetServerTimeNow() + Config.Cutscene.LeadSeconds
	local ids = {}
	for _, p in riders do
		table.insert(ids, p.UserId)
	end
	local remote = Remotes.get(Remotes.Names.LobbyLaunch)
	for _, p in riders do
		remote:FireClient(p, cart.index, startTime, ids)
	end
	-- the real cart rolls into the tunnel for everybody watching from the platform
	task.spawn(function()
		task.wait(Config.Cutscene.LeadSeconds + 0.4)
		local path = rollPath(cart)
		local offset = cart.home.Position - path[1]
		for i = 1, #path - 1 do
			local a, b = path[i], path[i + 1]
			local duration = (b - a).Magnitude / (if i == 1 then 10 else 22)
			local t0 = os.clock()
			while cart.launching do
				local k = math.clamp((os.clock() - t0) / duration, 0, 1)
				local p = a:Lerp(b, k) + offset
				local dir = (b - a).Unit
				cart.model:PivotTo(CFrame.lookAt(p, p + dir) * CFrame.Angles(0, math.rad(90), 0))
				if k >= 1 then
					break
				end
				task.wait()
			end
		end
	end)
	task.wait(Config.Cutscene.LeadSeconds + length + 0.5)
	local ok = teleportParty(riders)
	if not ok then
		local failRemote = Remotes.get(Remotes.Names.LobbyCartState)
		for _, p in riders do
			if p.Parent then
				failRemote:FireClient(p, cart.index, { failed = true })
			end
		end
		task.wait(1)
		resetCart(cart)
	end
end

function QueueService.init(parent: Instance)
	for i = 1, Config.Party.CartCount do
		local cart = buildCart(i, parent)
		carts[i] = cart
		for _, seat in cart.seats do
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				refresh(cart)
			end)
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = Strings.Prompts.Ride
		prompt.ObjectText = string.format(Strings.Queue.Cart, i)
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = cart.base
		prompt.Triggered:Connect(function(player: Player)
			if cart.launching then
				return
			end
			local h = humanoidOf(player)
			if not h or h.Sit then
				return
			end
			for _, seat in cart.seats do
				if not seat.Occupant then
					seat:Sit(h)
					return
				end
			end
		end)
	end
	Remotes.get(Remotes.Names.LobbyCart).OnServerEvent
		:Connect(function(player: Player, action: unknown)
			if not limiter:allow(player) or type(action) ~= "string" then
				return
			end
			for _, cart in carts do
				if table.find(cart.riders, player) then
					if action == "leave" and not cart.launching then
						for _, seat in cart.seats do
							local h = seat.Occupant
							if h and h.Parent == player.Character then
								eject(seat)
							end
						end
					elseif cart.owner == player and not cart.launching then
						if action == "friends" or action == "public" then
							cart.friendsOnly = action == "friends"
							pushState(cart)
						elseif action == "start" then
							task.spawn(launch, cart)
						end
					end
				end
			end
		end)
	Players.PlayerRemoving:Connect(function()
		task.defer(function()
			for _, cart in carts do
				refresh(cart)
			end
		end)
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = workspace:GetServerTimeNow()
			for _, cart in carts do
				local n, max = #cart.riders, #cart.seats
				if cart.launching then
					cart.label.Text = Strings.Queue.Locked
				elseif cart.endsAt then
					local left = math.max(0, math.ceil(cart.endsAt - now))
					cart.label.Text = string.format(Strings.Queue.Status, n, max, left)
					if now >= cart.endsAt and n >= Config.Party.MinPlayers then
						task.spawn(launch, cart)
					end
				else
					cart.label.Text = string.format(Strings.Queue.Waiting, n, max)
				end
			end
		end
	end)
end

return QueueService
