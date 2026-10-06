--!strict
-- Night threats (brief, gameplay system 9): Glitchlings (pixel shadow cubes with one yellow eye,
-- slow, 10 damage per hit) chase the nearest visible player with PathfindingService; hidden
-- players and players in cutscenes are ignored. Also the scripted "wall" chase used by the big
-- Giallino (Ch4) and the minecart Glitchling wall (Ch5): whoever falls behind it for 3 s is Downed.
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local HealthService = require(script.Parent.HealthService)

local ThreatService = {}

export type Glitchling = { model: Model, humanoid: Humanoid, root: BasePart, alive: boolean }

local glitchlings: { Glitchling } = {}
local folder: Folder? = nil
local hitCooldown: { [Player]: number } = {}

local function container(): Folder
	if folder and folder.Parent then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "Threats"
	f.Parent = workspace
	folder = f
	return f
end

local function buildGlitchling(): (Model, Humanoid, BasePart)
	local model = Instance.new("Model")
	model.Name = "Glitchling"
	model:SetAttribute("CharacterId", "Glitchling")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2.4, 2.4, 2.4)
	root.Color = Color3.fromRGB(20, 18, 26)
	root.Material = Enum.Material.SmoothPlastic
	root.Transparency = 0.1
	root.Parent = model
	local eye = Instance.new("Part")
	eye.Name = "Eye"
	eye.Size = Vector3.new(0.7, 0.7, 0.1)
	eye.Color = Color3.fromRGB(255, 216, 58)
	eye.Material = Enum.Material.Neon
	eye.CanCollide = false
	eye.Massless = true
	eye.CFrame = root.CFrame * CFrame.new(0, 0.3, -1.25)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = eye
	weld.Parent = eye
	eye.Parent = model
	-- a few loose "pixels" orbiting the body
	for i = 1, 4 do
		local px = Instance.new("Part")
		px.Name = "Pixel" .. i
		px.Size = Vector3.new(0.5, 0.5, 0.5)
		px.Color = Color3.fromRGB(35, 30, 45)
		px.CanCollide = false
		px.Massless = true
		px.CFrame = root.CFrame
			* CFrame.new(math.cos(i * 1.6) * 1.6, 0.8 - i * 0.3, math.sin(i * 1.6) * 1.6)
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = px
		w.Parent = px
		px.Parent = model
	end
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 216, 58)
	light.Range = 6
	light.Brightness = 0.8
	light.Parent = eye
	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = 9
	humanoid.HipHeight = 0.2
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model
	model.PrimaryPart = root
	return model, humanoid, root
end

local function targetFor(from: Vector3, range: number): (Player?, BasePart?)
	local best: Player? = nil
	local bestRoot: BasePart? = nil
	local bestDist = range
	for _, p in Players:GetPlayers() do
		if
			p:GetAttribute("LifeState") == "Alive"
			and not p:GetAttribute("HidingIn")
			and not p:GetAttribute("InCutscene")
		then
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local d = (root.Position - from).Magnitude
				if d < bestDist then
					best = p
					bestRoot = root
					bestDist = d
				end
			end
		end
	end
	return best, bestRoot
end

local function brain(g: Glitchling)
	local path =
		PathfindingService:CreatePath({ AgentRadius = 1.5, AgentHeight = 3, AgentCanJump = true })
	local lastPath = 0
	while g.alive and g.model.Parent do
		local player, root = targetFor(g.root.Position, 140)
		if player and root then
			local dist = (root.Position - g.root.Position).Magnitude
			if dist < 3.6 then
				local now = os.clock()
				if (hitCooldown[player] or 0) < now then
					hitCooldown[player] = now + 1
					HealthService.damage(player, 10, "glitchling")
				end
			end
			if dist > 24 and os.clock() - lastPath > 1.5 then
				lastPath = os.clock()
				local ok = pcall(function()
					path:ComputeAsync(g.root.Position, root.Position)
				end)
				local points = if ok and path.Status == Enum.PathStatus.Success
					then path:GetWaypoints()
					else {}
				if #points >= 2 then
					g.humanoid:MoveTo(points[math.min(3, #points)].Position)
				else
					g.humanoid:MoveTo(root.Position)
				end
			elseif dist <= 24 then
				g.humanoid:MoveTo(root.Position)
			end
		else
			g.humanoid:MoveTo(g.root.Position)
		end
		task.wait(0.25)
	end
end

--- Spawns a Glitchling at a CFrame. It starts hunting right away.
function ThreatService.spawnGlitchling(at: CFrame): Glitchling
	local model, humanoid, root = buildGlitchling()
	model:PivotTo(at + Vector3.new(0, 1.4, 0))
	model.Parent = container()
	root:SetNetworkOwner(nil)
	local g: Glitchling = { model = model, humanoid = humanoid, root = root, alive = true }
	table.insert(glitchlings, g)
	task.spawn(brain, g)
	return g
end

--- Spawns n Glitchlings around a center (radius in studs).
function ThreatService.wave(n: number, center: CFrame, radius: number): { Glitchling }
	local out = {}
	for i = 1, n do
		local angle = (i / n) * math.pi * 2
		table.insert(
			out,
			ThreatService.spawnGlitchling(
				center * CFrame.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			)
		)
	end
	return out
end

function ThreatService.remove(g: Glitchling)
	g.alive = false
	g.model:Destroy()
end

function ThreatService.clear()
	for _, g in glitchlings do
		g.alive = false
		if g.model.Parent then
			g.model:Destroy()
		end
	end
	table.clear(glitchlings)
end

function ThreatService.count(): number
	local n = 0
	for _, g in glitchlings do
		if g.alive and g.model.Parent then
			n += 1
		end
	end
	return n
end

--- Distance from a position to the closest live Glitchling (for heartbeat effects).
function ThreatService.nearest(pos: Vector3): number
	local best = math.huge
	for _, g in glitchlings do
		if g.alive and g.model.Parent then
			best = math.min(best, (g.root.Position - pos).Magnitude)
		end
	end
	return best
end

export type ChaseOptions = {
	path: { Vector3 }, -- waypoints the chaser follows
	speed: number, -- studs per second
	model: Model?, -- something visible that moves along the path (pivot)
	lagSeconds: number?, -- falling behind the chaser this long = Downed (3 s)
	players: { Player },
	lookAhead: boolean?,
}

--- A scripted chase: the chaser moves along the path; a player whose progress along the path is
--- behind the chaser for `lagSeconds` goes Downed. Yields until the chaser reaches the end.
function ThreatService.chase(opts: ChaseOptions)
	local points = opts.path
	local lengths = { 0 }
	for i = 2, #points do
		lengths[i] = lengths[i - 1] + (points[i] - points[i - 1]).Magnitude
	end
	local total = lengths[#points]
	local function progressOf(pos: Vector3): number
		local best, bestD = 0, math.huge
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			local ab = b - a
			local t = math.clamp((pos - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
			local d = (a + ab * t - pos).Magnitude
			if d < bestD then
				bestD = d
				best = lengths[i] + ab.Magnitude * t
			end
		end
		return best
	end
	local function pointAt(dist: number): (Vector3, Vector3)
		for i = 1, #points - 1 do
			if dist <= lengths[i + 1] then
				local a, b = points[i], points[i + 1]
				local t = (dist - lengths[i]) / math.max(lengths[i + 1] - lengths[i], 1e-6)
				return a:Lerp(b, t), (b - a).Unit
			end
		end
		return points[#points], (points[#points] - points[#points - 1]).Unit
	end
	local behindSince: { [Player]: number } = {}
	local start = os.clock()
	local lag = opts.lagSeconds or 3
	while true do
		task.wait(0.1)
		local dist = math.min((os.clock() - start) * opts.speed, total)
		local pos, dir = pointAt(dist)
		if opts.model and opts.model.Parent then
			opts.model:PivotTo(CFrame.lookAt(pos, pos + dir))
		end
		for _, p in opts.players do
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") and p:GetAttribute("LifeState") == "Alive" then
				if progressOf(root.Position) < dist then
					behindSince[p] = behindSince[p] or os.clock()
					if os.clock() - (behindSince[p] :: number) >= lag then
						HealthService.down(p)
						behindSince[p] = nil
					end
				else
					behindSince[p] = nil
				end
			end
		end
		if dist >= total then
			break
		end
	end
end

return ThreatService
