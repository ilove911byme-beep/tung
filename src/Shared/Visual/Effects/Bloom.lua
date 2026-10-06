--!strict
-- A-PATAPIM_BLOOM: new green leaves (Parts) appear on the branches, scale 0 -> 1 over 4 s.
-- Branch parts are the model's parts named "Branch*"; without them, the upper half is used.
local RunService = game:GetService("RunService")

local Debris = require(script.Parent.Debris)
local PoseMath = require(script.Parent.Parent.PoseMath)

local Bloom = {}

export type Params = {
	count: number?,
	duration: number?,
	color: Color3?,
	size: number?,
}

type Leaf = { part: Part, host: BasePart, localCf: CFrame, startAt: number, size: Vector3 }

function Bloom.run(model: Instance, params: Params?)
	local p: Params = params or {}
	local duration = p.duration or 4
	local count = p.count or 24
	local hosts: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and string.sub(d.Name, 1, 6) == "Branch" then
			table.insert(hosts, d)
		end
	end
	if #hosts == 0 then
		local parts = Debris.visibleParts(model)
		if #parts == 0 then
			return
		end
		local minV, maxV = Debris.bounds(parts)
		local midY = (minV.Y + maxV.Y) / 2
		for _, part in parts do
			if part.Position.Y >= midY then
				table.insert(hosts, part)
			end
		end
		if #hosts == 0 then
			hosts = parts
		end
	end
	local rng = Random.new()
	local leaves: { Leaf } = {}
	local baseSize = p.size or 0.7
	for i = 1, count do
		local host = hosts[rng:NextInteger(1, #hosts)]
		local s = host.Size
		-- a point on the surface of the host
		local localPos = Vector3.new(
			rng:NextNumber(-0.5, 0.5) * s.X,
			rng:NextNumber(0, 0.5) * s.Y,
			rng:NextNumber(-0.5, 0.5) * s.Z
		)
		local axis = rng:NextInteger(1, 3)
		local sign = if rng:NextNumber() < 0.5 then -1 else 1
		if axis == 1 then
			localPos = Vector3.new(sign * s.X / 2, localPos.Y, localPos.Z)
		elseif axis == 2 then
			localPos = Vector3.new(localPos.X, s.Y / 2, localPos.Z)
		else
			localPos = Vector3.new(localPos.X, localPos.Y, sign * s.Z / 2)
		end
		local leafSize = Vector3.new(baseSize, baseSize * 0.35, baseSize) * rng:NextNumber(0.7, 1.3)
		local part = Debris.cube(
			Vector3.new(0.05, 0.05, 0.05),
			host.CFrame * CFrame.new(localPos),
			p.color or Color3.fromRGB(70, 160, 60),
			Enum.Material.Grass
		)
		part.Parent = model
		table.insert(leaves, {
			part = part,
			host = host,
			localCf = CFrame.new(localPos)
				* CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6.28), 0),
			startAt = (i - 1) / count * duration * 0.75,
			size = leafSize,
		})
	end
	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt * Debris.timeScale
		for _, leaf in leaves do
			local a = PoseMath.ease(
				"BackOut",
				math.clamp((elapsed - leaf.startAt) / (duration * 0.25), 0, 1)
			)
			leaf.part.Size = (leaf.size * math.max(a, 0.02)):Max(Vector3.new(0.05, 0.05, 0.05))
			leaf.part.CFrame = leaf.host.CFrame * leaf.localCf
		end
		if elapsed >= duration then
			connection:Disconnect()
		end
	end)
end

return Bloom
