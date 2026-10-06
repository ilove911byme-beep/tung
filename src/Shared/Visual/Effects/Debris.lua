--!strict
-- Tiny kinematic simulator for effect pieces (pixels, shards, blocks). Pieces are anchored
-- Parts moved by code, so the result is the same on every client and no physics ownership is
-- involved. TimeFreeze sets Debris.timeScale = 0 to stop everything mid-air.
local RunService = game:GetService("RunService")

export type Body = {
	part: BasePart,
	pos: Vector3,
	vel: Vector3,
	rot: CFrame,
	spinAxis: Vector3,
	spin: number, -- radians per second
	gravity: number,
	floorY: number?,
	bounce: number,
	age: number,
	life: number,
	fadeFrom: number, -- age when fading starts
	baseTransparency: number,
	destroyAtEnd: boolean,
	onUpdate: ((Body, number) -> ())?,
	onDone: ((Body) -> ())?,
}

export type BodyOptions = {
	vel: Vector3?,
	spin: number?,
	spinAxis: Vector3?,
	gravity: number?,
	floorY: number?,
	bounce: number?,
	life: number?,
	fadeFrom: number?,
	destroyAtEnd: boolean?,
	onUpdate: ((Body, number) -> ())?,
	onDone: ((Body) -> ())?,
}

local Debris = {}
Debris.timeScale = 1

local bodies: { Body } = {}
local connection: RBXScriptConnection? = nil

local function step(dt: number)
	local scaled = dt * Debris.timeScale
	if scaled <= 0 then
		return
	end
	local parts: { BasePart } = {}
	local cframes: { CFrame } = {}
	local i = 1
	while i <= #bodies do
		local b = bodies[i]
		b.age += scaled
		if not b.part.Parent then
			table.remove(bodies, i)
			continue
		end
		b.vel += Vector3.new(0, -b.gravity * scaled, 0)
		b.pos += b.vel * scaled
		local floorY = b.floorY
		if floorY and b.pos.Y < floorY then
			b.pos = Vector3.new(b.pos.X, floorY, b.pos.Z)
			b.vel = Vector3.new(b.vel.X * 0.6, -b.vel.Y * b.bounce, b.vel.Z * 0.6)
			b.spin *= 0.6
		end
		if b.spin ~= 0 then
			b.rot = CFrame.fromAxisAngle(b.spinAxis, b.spin * scaled) * b.rot
		end
		if b.onUpdate then
			b.onUpdate(b, scaled)
		end
		if b.age >= b.fadeFrom then
			local a = math.clamp((b.age - b.fadeFrom) / math.max(b.life - b.fadeFrom, 1e-3), 0, 1)
			b.part.Transparency = b.baseTransparency + (1 - b.baseTransparency) * a
		end
		table.insert(parts, b.part)
		table.insert(cframes, CFrame.new(b.pos) * b.rot)
		if b.age >= b.life then
			table.remove(bodies, i)
			if b.onDone then
				b.onDone(b)
			end
			if b.destroyAtEnd then
				b.part:Destroy()
			end
		else
			i += 1
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function ensureLoop()
	if connection then
		return
	end
	connection = RunService.Heartbeat:Connect(step)
end

--- Starts simulating an anchored part.
function Debris.add(part: BasePart, opts: BodyOptions?): Body
	local o: BodyOptions = opts or {}
	part.Anchored = true
	local life = o.life or 1.5
	local body: Body = {
		part = part,
		pos = part.Position,
		vel = o.vel or Vector3.zero,
		rot = part.CFrame.Rotation,
		spinAxis = if o.spinAxis and o.spinAxis.Magnitude > 0
			then o.spinAxis.Unit
			else Vector3.yAxis,
		spin = o.spin or 0,
		gravity = o.gravity or 0,
		floorY = o.floorY,
		bounce = o.bounce or 0.3,
		age = 0,
		life = life,
		fadeFrom = o.fadeFrom or 0,
		baseTransparency = part.Transparency,
		destroyAtEnd = if o.destroyAtEnd == nil then true else o.destroyAtEnd,
		onUpdate = o.onUpdate,
		onDone = o.onDone,
	}
	table.insert(bodies, body)
	ensureLoop()
	return body
end

--- Folder in workspace for effect parts (client-local when created on a client).
function Debris.container(): Folder
	local folder = workspace:FindFirstChild("Effects")
	if folder and folder:IsA("Folder") then
		return folder
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = "Effects"
	newFolder.Parent = workspace
	return newFolder
end

--- A small anchored, non-colliding effect cube.
function Debris.cube(size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = Debris.container()
	return p
end

--- Visible BaseParts of a model (skips the root and fully transparent parts).
function Debris.visibleParts(model: Instance, skip: { [string]: boolean }?): { BasePart }
	local out: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if
			d:IsA("BasePart")
			and d.Name ~= "HumanoidRootPart"
			and d.Transparency < 1
			and not (skip and skip[d.Name])
		then
			table.insert(out, d)
		end
	end
	if model:IsA("BasePart") and model.Transparency < 1 then
		table.insert(out, model)
	end
	return out
end

--- World-space bounding box (min, max) of a list of parts.
function Debris.bounds(parts: { BasePart }): (Vector3, Vector3)
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in parts do
		local half = p.Size / 2
		local cf = p.CFrame
		-- extents of the rotated box
		local ext = Vector3.new(
			math.abs(cf.RightVector.X) * half.X
				+ math.abs(cf.UpVector.X) * half.Y
				+ math.abs(cf.LookVector.X) * half.Z,
			math.abs(cf.RightVector.Y) * half.X
				+ math.abs(cf.UpVector.Y) * half.Y
				+ math.abs(cf.LookVector.Y) * half.Z,
			math.abs(cf.RightVector.Z) * half.X
				+ math.abs(cf.UpVector.Z) * half.Y
				+ math.abs(cf.LookVector.Z) * half.Z
		)
		minV = minV:Min(p.Position - ext)
		maxV = maxV:Max(p.Position + ext)
	end
	return minV, maxV
end

--- Random point inside a part, in the part's local space.
function Debris.randomLocalPoint(part: BasePart, rng: Random): Vector3
	local s = part.Size
	return Vector3.new(
		rng:NextNumber(-0.5, 0.5) * s.X,
		rng:NextNumber(-0.5, 0.5) * s.Y,
		rng:NextNumber(-0.5, 0.5) * s.Z
	)
end

return Debris
