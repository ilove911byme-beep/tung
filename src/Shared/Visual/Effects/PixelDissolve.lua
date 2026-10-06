--!strict
-- A-PIXEL_DISSOLVE: the body breaks into 0.4-stud cubes from the bottom up. Each cube flies up
-- at a random speed and turns transparent over 1.5 s; if a light source (target) is near, the
-- cubes are pulled into it. The original parts disappear as the front passes them.
-- Also LastPixel (CS-05 shot 9): one last glowing pixel settles on a spot and goes out.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Debris = require(script.Parent.Debris)

local PixelDissolve = {}

local GIALLINO_YELLOW = Color3.fromRGB(255, 216, 58)
local FADE_TIME = 1.5 -- each cube fades over this (animation library)
local PULL_RANGE = 40

export type Params = {
	duration: number?, -- 6.0 full, 2.0 short (CS-DEAD)
	cubeSize: number?,
	target: BasePart?, -- light source that sucks the pixels in
	keep: { string }?, -- part names that stay (the pointe shoe)
	dropKept: boolean?, -- kept parts fall to the floor afterwards
	color: Color3?,
	maxCubes: number?,
}

type Sample = { part: BasePart, localPos: Vector3, spawnAt: number, color: Color3 }
type Flying = { part: Part, pos: Vector3, vel: Vector3, age: number, color: Color3 }

local function dropToFloor(part: BasePart, model: Instance)
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") or d:IsA("Weld") or d:IsA("WeldConstraint") then
			local joint = d :: any
			if joint.Part0 == part or joint.Part1 == part then
				d:Destroy()
			end
		end
	end
	part.Anchored = true
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model, Debris.container() }
	local hit =
		workspace:Raycast(part.Position + Vector3.new(0, 1, 0), Vector3.new(0, -12, 0), params)
	local floorY = if hit then hit.Position.Y else part.Position.Y - part.Size.Y / 2
	local yaw = part.CFrame.Rotation
	local lying = CFrame.new(part.Position.X, floorY + part.Size.Z / 2, part.Position.Z)
		* yaw
		* CFrame.Angles(math.rad(80), 0, math.rad(12))
	TweenService
		:Create(part, TweenInfo.new(0.55, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
			CFrame = lying,
		})
		:Play()
end

--- Runs the dissolve on a model. Returns when the dissolve is complete.
function PixelDissolve.run(model: Instance, params: Params?)
	local p: Params = params or {}
	local duration = p.duration or 6
	local cubeSize = p.cubeSize or 0.4
	local maxCubes = p.maxCubes or (if duration < 3 then 220 else 480)
	local yellow = p.color or GIALLINO_YELLOW
	local keep: { [string]: boolean } = {}
	local keepList = p.keep
	if keepList then
		for _, name in keepList do
			keep[name] = true
		end
	end

	local parts = Debris.visibleParts(model, keep)
	if #parts == 0 then
		return
	end
	local minV, maxV = Debris.bounds(parts)
	local height = math.max(maxV.Y - minV.Y, 0.1)
	local sweep = math.max(duration - FADE_TIME, 0.3)
	local rng = Random.new()

	-- how many cubes each part gets, by volume
	local totalVolume = 0
	for _, part in parts do
		totalVolume += part.Size.X * part.Size.Y * part.Size.Z
	end
	local samples: { Sample } = {}
	for _, part in parts do
		local volume = part.Size.X * part.Size.Y * part.Size.Z
		local count = math.clamp(math.round(maxCubes * volume / totalVolume), 3, 60)
		for _ = 1, count do
			local localPos = Debris.randomLocalPoint(part, rng)
			local worldY = (part.CFrame * localPos).Y
			local spawnAt = (worldY - minV.Y) / height * sweep + rng:NextNumber(-0.08, 0.08)
			table.insert(
				samples,
				{ part = part, localPos = localPos, spawnAt = spawnAt, color = part.Color }
			)
		end
	end
	table.sort(samples, function(a, b)
		return a.spawnAt < b.spawnAt
	end)

	local original: { [BasePart]: number } = {}
	local guis: { [BasePart]: { Instance } } = {}
	for _, part in parts do
		original[part] = part.Transparency
		local list: { Instance } = {}
		for _, d in part:GetDescendants() do
			if
				d:IsA("SurfaceGui")
				or d:IsA("Decal")
				or d:IsA("ParticleEmitter")
				or d:IsA("BillboardGui")
			then
				table.insert(list, d)
			end
		end
		guis[part] = list
	end

	local flying: { Flying } = {}
	local nextSample = 1
	local elapsed = 0
	local done = false
	local finished = Instance.new("BindableEvent")
	local size = Vector3.new(cubeSize, cubeSize, cubeSize)

	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt * Debris.timeScale
		local scaledDt = dt * Debris.timeScale
		-- spawn cubes the front has reached
		while nextSample <= #samples and samples[nextSample].spawnAt <= elapsed do
			local s = samples[nextSample]
			nextSample += 1
			if s.part.Parent then
				local pos = (s.part.CFrame * s.localPos)
				local cube = Debris.cube(size, CFrame.new(pos), s.color, Enum.Material.Neon)
				table.insert(flying, {
					part = cube,
					pos = pos,
					vel = Vector3.new(
						rng:NextNumber(-0.6, 0.6),
						rng:NextNumber(2, 5),
						rng:NextNumber(-0.6, 0.6)
					),
					age = 0,
					color = s.color,
				})
			end
		end
		-- hide parts as the front passes them
		local frontY = minV.Y + math.clamp(elapsed / sweep, 0, 1) * height
		for part, base in original do
			local half = part.Size.Y / 2
			local bottom = part.Position.Y - half
			local a = math.clamp((frontY - bottom) / math.max(part.Size.Y, 0.05), 0, 1)
			part.Transparency = base + (1 - base) * a
			if a > 0.6 then
				for _, g in guis[part] do
					if g:IsA("SurfaceGui") or g:IsA("BillboardGui") then
						(g :: any).Enabled = false
					elseif g:IsA("ParticleEmitter") then
						g.Enabled = false
					elseif g:IsA("Decal") then
						g.Transparency = 1
					end
				end
			end
		end
		-- move cubes
		local target = p.target
		local targetPos = if target and target.Parent then target.Position else nil
		local moved: { BasePart } = {}
		local cframes: { CFrame } = {}
		local i = 1
		while i <= #flying do
			local f = flying[i]
			f.age += scaledDt
			f.pos += f.vel * scaledDt
			local a = math.clamp(f.age / FADE_TIME, 0, 1)
			local shown = f.pos
			if targetPos and (targetPos - f.pos).Magnitude < PULL_RANGE then
				local pull = a * a
				shown = f.pos:Lerp(targetPos, pull)
			end
			f.part.Color = f.color:Lerp(yellow, math.min(a * 2, 1))
			f.part.Transparency = a
			table.insert(moved, f.part)
			table.insert(cframes, CFrame.new(shown) * CFrame.Angles(f.age * 3, f.age * 2, 0))
			if f.age >= FADE_TIME then
				f.part:Destroy()
				table.remove(flying, i)
			else
				i += 1
			end
		end
		if #moved > 0 then
			workspace:BulkMoveTo(moved, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		end
		if not done and elapsed >= duration and nextSample > #samples and #flying == 0 then
			done = true
			connection:Disconnect()
			finished:Fire()
		end
	end)

	finished.Event:Wait()
	finished:Destroy()
	for part in original do
		part.Transparency = 1
	end
	if p.dropKept then
		for name in keep do
			local kept = model:FindFirstChild(name, true)
			if kept and kept:IsA("BasePart") then
				dropToFloor(kept, model)
			end
		end
	end
end

--- One last glowing pixel drifts down onto `at` and goes out (CS-05 shot 9).
function PixelDissolve.lastPixel(at: Vector3, duration: number?)
	local total = duration or 2.4
	local start = at + Vector3.new(0.4, 3, 0.2)
	local cube = Debris.cube(
		Vector3.new(0.4, 0.4, 0.4),
		CFrame.new(start),
		GIALLINO_YELLOW,
		Enum.Material.Neon
	)
	local light = Instance.new("PointLight")
	light.Color = GIALLINO_YELLOW
	light.Range = 4
	light.Brightness = 1.2
	light.Parent = cube
	local landAt = total * 0.55
	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt * Debris.timeScale
		local cf: CFrame
		if elapsed < landAt then
			local a = elapsed / landAt
			local e = 1 - (1 - a) * (1 - a)
			local sway = math.sin(elapsed * 5) * 0.25 * (1 - a)
			cf = CFrame.new(start:Lerp(at + Vector3.new(0, 0.25, 0), e) + Vector3.new(sway, 0, 0))
		else
			local a = math.clamp((elapsed - landAt) / (total - landAt), 0, 1)
			cf = CFrame.new(at + Vector3.new(0, 0.25, 0))
			cube.Transparency = a
			light.Brightness = 1.2 * (1 - a)
		end
		cube.CFrame = cf
		if elapsed >= total then
			connection:Disconnect()
			cube:Destroy()
		end
	end)
end

return PixelDissolve
