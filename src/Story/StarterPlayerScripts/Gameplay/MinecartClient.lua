--!strict
-- The minecart ride of chapter 5 (screenplay 5-2). The server only publishes the start time
-- (workspace attributes CartRideStart, CartRiders) and every rider's seat (player attribute
-- CartSeat); each client draws all carts locally along Shared/World/TrackPath from the shared
-- server clock and drives its own character in its cart (the character's position replicates
-- as usual). A failed QTE sets CartFlipUntil: the cart tips over, the rider is thrown on the
-- rails and runs until the cart comes back for them. A wall of Glitchlings rolls behind.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TrackPath = require(Shared:WaitForChild("World"):WaitForChild("TrackPath"))

local MinecartClient = {}

local player = Players.LocalPlayer
local carts: { [Player]: Model } = {}
local wall: Model? = nil
local folder: Folder? = nil
local driving = false
local thrown = false

local function rideFolder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local nf = Instance.new("Folder")
	nf.Name = "MinecartsLocal"
	nf.Parent = workspace
	folder = nf
	return nf
end

local function template(name: string): Model?
	local templates = ReplicatedStorage:FindFirstChild("RigTemplates")
	local t = templates and templates:FindFirstChild(name)
	return if t and t:IsA("Model") then t else nil
end

local function newCart(): Model
	local t = template("Minecart")
	local m: Model
	if t then
		m = t:Clone()
	else
		m = Instance.new("Model")
		local base = Instance.new("Part")
		base.Name = "Base"
		base.Size = Vector3.new(3.6, 1.8, 5.2)
		base.Color = Color3.fromRGB(90, 90, 96)
		base.Material = Enum.Material.Metal
		base.Parent = m
		m.PrimaryPart = base
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
		end
	end
	m.Parent = rideFolder()
	return m
end

local function newWall(): Model
	local m = Instance.new("Model")
	m.Name = "GlitchlingWall"
	local rng = Random.new(67)
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Size = Vector3.new(12, 15, 2)
	core.Color = Color3.fromRGB(12, 8, 14)
	core.Material = Enum.Material.SmoothPlastic
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.Parent = m
	m.PrimaryPart = core
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 40, 40)
	glow.Range = 18
	glow.Brightness = 1.4
	glow.Parent = core
	for i = 1, 26 do
		local c = Instance.new("Part")
		c.Name = "Glitchling" .. i
		local s = rng:NextNumber(0.8, 2.2)
		c.Size = Vector3.new(s, s, s)
		c.Color = if rng:NextNumber() < 0.2
			then Color3.fromRGB(200, 30, 40)
			else Color3.fromRGB(25, 20, 30)
		c.Material = if c.Color.R > 0.5 then Enum.Material.Neon else Enum.Material.SmoothPlastic
		c.Anchored = true
		c.CanCollide = false
		c.CanQuery = false
		c:SetAttribute(
			"Offset",
			Vector3.new(rng:NextNumber(-5.5, 5.5), rng:NextNumber(-7, 7), rng:NextNumber(-1, 3))
		)
		c:SetAttribute("Phase", rng:NextNumber(0, 6.28))
		c.Parent = m
	end
	m.Parent = rideFolder()
	return m
end

local function humanoidOf(p: Player): (Humanoid?, BasePart?)
	local character = p.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return humanoid, if root and root:IsA("BasePart") then root else nil
end

local function release()
	if driving then
		driving = false
		local humanoid = humanoidOf(player)
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
end

local function clearAll()
	release()
	thrown = false
	for p, m in carts do
		m:Destroy()
		carts[p] = nil
	end
	if wall then
		wall:Destroy()
		wall = nil
	end
end

local function cartCf(dist: number, flipped: boolean): CFrame
	local pos, dir = TrackPath.at(dist)
	local cf = CFrame.lookAt(pos, pos + dir) * CFrame.new(0, 1.2, 0)
	if flipped then
		cf = cf * CFrame.new(1.6, -0.6, 0) * CFrame.Angles(0, 0, math.rad(100))
	end
	return cf
end

local function update()
	local start = workspace:GetAttribute("CartRideStart")
	if typeof(start) ~= "number" then
		if next(carts) or wall then
			clearAll()
		end
		return
	end
	local riders = (workspace:GetAttribute("CartRiders") :: number?) or 1
	local now = workspace:GetServerTimeNow()
	local elapsed = now - start
	local seen: { [Player]: boolean } = {}
	local last = math.huge
	for _, p in Players:GetPlayers() do
		local seat = p:GetAttribute("CartSeat")
		if typeof(seat) == "number" then
			seen[p] = true
			local m = carts[p]
			if not m then
				m = newCart()
				carts[p] = m
			end
			local dist = TrackPath.seatDistance(seat, riders, elapsed)
			last = math.min(last, dist)
			local flipUntil = (p:GetAttribute("CartFlipUntil") :: number?) or 0
			local flipped = flipUntil > now
			local cf = cartCf(dist, flipped)
			-- a little rattle on the rails
			local rattle = if elapsed > 0 and not flipped
				then CFrame.Angles(
					math.sin(now * 23 + seat) * 0.012,
					0,
					math.sin(now * 17 + seat) * 0.02
				)
				else CFrame.identity
			m:PivotTo(cf * rattle)
			if p == player then
				local humanoid, root = humanoidOf(p)
				local alive = p:GetAttribute("LifeState") == "Alive"
				if humanoid and root and alive and not flipped then
					if not driving then
						driving = true
						humanoid.PlatformStand = true
					end
					thrown = false
					root.CFrame = cf * rattle * CFrame.new(0, 2.6, 0.3)
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
				elseif humanoid and root and flipped and not thrown then
					-- thrown out beside the rails: run after the carts
					thrown = true
					release()
					root.CFrame = cartCf(dist, false) * CFrame.new(0, 3, 4)
				elseif not alive then
					release()
				end
			end
		end
	end
	for p, m in carts do
		if not seen[p] then
			m:Destroy()
			carts[p] = nil
			if p == player then
				release()
			end
		end
	end
	-- the Glitchling wall rolls a few blocks behind the last cart
	if last < math.huge and elapsed > 0 then
		local w = wall or newWall()
		wall = w
		local wcf = cartCf(math.max(last - 5 - math.max(0, 1.5 - elapsed) * 3, 0), false)
		w:PivotTo(wcf * CFrame.new(0, 5, 0))
		for _, c in w:GetChildren() do
			local off = c:GetAttribute("Offset")
			local ph = (c:GetAttribute("Phase") :: number?) or 0
			if c:IsA("BasePart") and typeof(off) == "Vector3" then
				c.CFrame = wcf
					* CFrame.new(
						off
							+ Vector3.new(
								0,
								5 + math.sin(now * 6 + ph) * 0.4,
								math.sin(now * 4 + ph) * 0.6
							)
					)
					* CFrame.Angles(now * 2 + ph, now * 1.3, 0)
			end
		end
	end
end

function MinecartClient.init()
	RunService.RenderStepped:Connect(update)
end

return MinecartClient
