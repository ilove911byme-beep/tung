--!strict
-- A-ROOTS_BRIDGE: roots (block beams) grow out of the ground one by one and stretch across a
-- gap, each in 0.4 s. The roots collide, so players can run over the bridge.
local RunService = game:GetService("RunService")

local Debris = require(script.Parent.Debris)
local PoseMath = require(script.Parent.Parent.PoseMath)

local RootsBridge = {}

export type Params = {
	from: Vector3, -- start edge (ground level)
	to: Vector3, -- far edge
	count: number?,
	width: number?, -- total bridge width (studs)
	thickness: number?,
	growTime: number?, -- per root (0.4 in the animation library)
	stagger: number?,
	color: Color3?,
	parent: Instance?,
}

type Root = { part: Part, a: Vector3, b: Vector3, startAt: number }

function RootsBridge.run(params: Params): Model
	local count = params.count or 6
	local width = params.width or 6
	local thickness = params.thickness or 1
	local growTime = params.growTime or 0.4
	local stagger = params.stagger or 0.4
	local model = Instance.new("Model")
	model.Name = "RootsBridge"
	model.Parent = params.parent or Debris.container()

	local along = params.to - params.from
	local flat = Vector3.new(along.X, 0, along.Z)
	local side = if flat.Magnitude > 1e-3 then flat.Unit:Cross(Vector3.yAxis) else Vector3.xAxis
	local rng = Random.new()
	local roots: { Root } = {}
	for i = 1, count do
		local lateral = (i - (count + 1) / 2) / math.max(count - 1, 1) * width
		local jitter = Vector3.new(0, rng:NextNumber(-0.25, 0.1), 0)
		local a = params.from + side * lateral + Vector3.new(0, -thickness * 0.5, 0) + jitter
		local b = params.to
			+ side * (lateral + rng:NextNumber(-0.4, 0.4))
			+ Vector3.new(0, -thickness * 0.5, 0)
			+ jitter
		local part = Instance.new("Part")
		part.Name = "Root" .. i
		part.Material = Enum.Material.Wood
		part.Color = params.color or Color3.fromRGB(92, 62, 36)
		part.Anchored = true
		part.CanCollide = false
		part.Size = Vector3.new(thickness, thickness, 0.05)
		part.CFrame = CFrame.lookAt(a, b)
		part.Parent = model
		table.insert(roots, { part = part, a = a, b = b, startAt = (i - 1) * stagger })
	end

	local elapsed = 0
	local total = (count - 1) * stagger + growTime
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt * Debris.timeScale
		for _, r in roots do
			local a = PoseMath.ease("QuadOut", math.clamp((elapsed - r.startAt) / growTime, 0, 1))
			local length = (r.b - r.a).Magnitude * a
			if length > 0.05 then
				local dir = (r.b - r.a).Unit
				-- rises out of the ground first, then lies flat
				local rise = (1 - a) * 1.2
				local mid = r.a + dir * (length / 2) - Vector3.new(0, rise, 0)
				r.part.Size = Vector3.new(thickness, thickness, length)
				r.part.CFrame = CFrame.lookAt(mid, mid + dir)
				r.part.CanCollide = a >= 1
			end
		end
		if elapsed >= total then
			connection:Disconnect()
		end
	end)
	return model
end

return RootsBridge
