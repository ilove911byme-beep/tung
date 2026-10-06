--!strict
-- A-SHATTER: the model bursts into spinning shards (default 40) that fly out and fade.
local Debris = require(script.Parent.Debris)

local Shatter = {}

export type Params = {
	pieces: number?,
	color: Color3?, -- nil = colors of the original parts
	speed: number?,
	life: number?,
	gravity: number?,
}

function Shatter.run(model: Instance, params: Params?)
	local p: Params = params or {}
	local parts = Debris.visibleParts(model)
	if #parts == 0 then
		return
	end
	local minV, maxV = Debris.bounds(parts)
	local center = (minV + maxV) / 2
	local extent = maxV - minV
	local rng = Random.new()
	local pieces = p.pieces or 40
	local speed = p.speed or 16
	local life = p.life or 1.5
	for _, part in parts do
		part.Transparency = 1
		for _, d in part:GetDescendants() do
			if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
				(d :: any).Enabled = false
			end
		end
	end
	for _ = 1, pieces do
		local source = parts[rng:NextInteger(1, #parts)]
		local local3 = Vector3.new(
			rng:NextNumber(-0.5, 0.5),
			rng:NextNumber(-0.5, 0.5),
			rng:NextNumber(-0.5, 0.5)
		)
		local pos = center + local3 * extent
		local s = rng:NextNumber(0.25, 0.8)
		local shard = Debris.cube(
			Vector3.new(s, s * rng:NextNumber(0.4, 1), s * rng:NextNumber(0.2, 0.6)),
			CFrame.new(pos) * CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), 0),
			p.color or source.Color,
			Enum.Material.Neon
		)
		local dir = (pos - center)
		dir = if dir.Magnitude > 1e-3 then dir.Unit else rng:NextUnitVector()
		Debris.add(shard, {
			vel = dir * speed * rng:NextNumber(0.5, 1) + Vector3.new(0, rng:NextNumber(2, 8), 0),
			spin = rng:NextNumber(4, 12),
			spinAxis = rng:NextUnitVector(),
			gravity = p.gravity or 25,
			life = life,
			fadeFrom = life * 0.3,
		})
	end
end

return Shatter
