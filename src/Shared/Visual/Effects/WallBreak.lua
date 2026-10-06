--!strict
-- A-WALL_BREAK: the blocks of a wall fly outward from an origin point with gravity, bounce on
-- the floor and fade (or stay as rubble).
local Debris = require(script.Parent.Debris)

local WallBreak = {}

export type Params = {
	origin: Vector3?, -- default: behind the wall center
	force: number?,
	life: number?,
	keepRubble: boolean?,
	floorY: number?,
}

function WallBreak.run(target: Instance, params: Params?)
	local p: Params = params or {}
	local parts = Debris.visibleParts(target)
	if #parts == 0 then
		return
	end
	local minV, maxV = Debris.bounds(parts)
	local origin = p.origin or (minV + maxV) / 2
	local rng = Random.new()
	local force = p.force or 30
	local life = p.life or 2.5
	for _, part in parts do
		local dir = part.Position - origin
		dir = if dir.Magnitude > 1e-3 then dir.Unit else rng:NextUnitVector()
		Debris.add(part, {
			vel = dir * force * rng:NextNumber(0.5, 1.1) + Vector3.new(0, rng:NextNumber(4, 12), 0),
			spin = rng:NextNumber(2, 8),
			spinAxis = rng:NextUnitVector(),
			gravity = 40,
			floorY = p.floorY or (minV.Y + part.Size.Y / 2),
			bounce = 0.25,
			life = life,
			fadeFrom = if p.keepRubble then life + 1 else life * 0.6,
			destroyAtEnd = not p.keepRubble,
		})
	end
end

return WallBreak
