--!strict
-- A-FALSINO_MELT: cracks appear, the model squashes to 10 % of its height and a yellow puddle
-- (a flat cylinder) grows underneath. Default 4 s.
local RunService = game:GetService("RunService")

local Debris = require(script.Parent.Debris)

local Melt = {}

export type Params = {
	duration: number?,
	puddleColor: Color3?,
	crackColor: Color3?,
	cracks: number?,
}

type Saved = { part: BasePart, size: Vector3, cframe: CFrame }
type Crack = { part: Part, host: BasePart, localCf: CFrame }

function Melt.run(model: Instance, params: Params?)
	local p: Params = params or {}
	local duration = p.duration or 4
	local parts = Debris.visibleParts(model)
	if #parts == 0 then
		return
	end
	local minV, maxV = Debris.bounds(parts)
	local bottom = minV.Y
	local width = math.max(maxV.X - minV.X, maxV.Z - minV.Z)
	local rng = Random.new()

	local saved: { Saved } = {}
	for _, part in parts do
		table.insert(saved, { part = part, size = part.Size, cframe = part.CFrame })
	end

	-- cracks: thin dark lines on random faces
	local cracks: { Crack } = {}
	for _ = 1, p.cracks or 8 do
		local host = parts[rng:NextInteger(1, #parts)]
		local s = host.Size
		local onX = rng:NextNumber() < 0.5
		local localPos = if onX
			then Vector3.new(0, rng:NextNumber(-0.4, 0.4) * s.Y, -s.Z / 2 - 0.02)
			else Vector3.new(s.X / 2 + 0.02, rng:NextNumber(-0.4, 0.4) * s.Y, 0)
		local localCf = CFrame.new(localPos)
			* CFrame.Angles(0, if onX then 0 else math.pi / 2, rng:NextNumber(-1, 1))
		local crack = Debris.cube(
			Vector3.new(rng:NextNumber(0.6, 1.6), 0.08, 0.05),
			host.CFrame * localCf,
			p.crackColor or Color3.fromRGB(60, 40, 0),
			Enum.Material.SmoothPlastic
		)
		crack.Transparency = 1
		table.insert(cracks, { part = crack, host = host, localCf = localCf })
	end

	local puddle = Instance.new("Part")
	puddle.Shape = Enum.PartType.Cylinder
	puddle.Material = Enum.Material.Neon
	puddle.Color = p.puddleColor or Color3.fromRGB(255, 210, 40)
	puddle.Anchored = true
	puddle.CanCollide = false
	puddle.CanQuery = false
	puddle.CastShadow = false
	puddle.Size = Vector3.new(0.12, 0.05, 0.05)
	local center = (minV + maxV) / 2
	puddle.CFrame = CFrame.new(center.X, bottom + 0.06, center.Z) * CFrame.Angles(0, 0, math.pi / 2)
	puddle.Parent = Debris.container()

	local elapsed = 0
	local finished = Instance.new("BindableEvent")
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt * Debris.timeScale
		local a = math.clamp(elapsed / duration, 0, 1)
		local crackA = math.clamp(elapsed / (duration * 0.25), 0, 1)
		local squash = 1 - 0.9 * (a * a)
		for _, s in saved do
			if s.part.Parent then
				local pos = s.cframe.Position
				local newY = bottom + (pos.Y - bottom) * squash
				s.part.Size = Vector3.new(
					s.size.X * (1 + 0.25 * a),
					s.size.Y * squash,
					s.size.Z * (1 + 0.25 * a)
				)
				s.part.CFrame = CFrame.new(pos.X, newY, pos.Z) * s.cframe.Rotation
			end
		end
		for _, c in cracks do
			c.part.Transparency = 1 - crackA
			c.part.CFrame = c.host.CFrame * c.localCf
		end
		local d = width * 2.2 * math.clamp(a * 1.2, 0, 1)
		puddle.Size = Vector3.new(0.12, math.max(d, 0.05), math.max(d, 0.05))
		if elapsed >= duration then
			connection:Disconnect()
			finished:Fire()
		end
	end)
	finished.Event:Wait()
	finished:Destroy()
	for _, c in cracks do
		c.part:Destroy()
	end
end

return Melt
