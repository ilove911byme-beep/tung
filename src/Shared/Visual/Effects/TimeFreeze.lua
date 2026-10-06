--!strict
-- TimeFreeze: particles and effect pieces stop mid-air, then resume (Lirili's time stop).
-- freeze() also scatters frozen motes (water drops and dust) around a point, like the lab in
-- CS-16. resume() lets everything move again and the motes fall.
local Debris = require(script.Parent.Debris)

local TimeFreeze = {}

export type Params = {
	root: Instance?, -- emitters under this are frozen (default workspace)
	center: Vector3?, -- spawn frozen motes here
	radius: number?,
	motes: number?,
}

export type Handle = {
	resume: (self: Handle) -> (),
}

function TimeFreeze.freeze(params: Params?): Handle
	local p: Params = params or {}
	local root = p.root or workspace
	local frozen: { [ParticleEmitter]: number } = {}
	for _, d in root:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			frozen[d] = d.TimeScale
			d.TimeScale = 0
		end
	end
	Debris.timeScale = 0

	local motes: { Part } = {}
	if p.center then
		local rng = Random.new()
		local radius = p.radius or 10
		for i = 1, p.motes or 40 do
			local isDrop = i % 3 == 0
			local pos = p.center
				+ Vector3.new(
					rng:NextNumber(-radius, radius),
					rng:NextNumber(0.5, radius * 0.6),
					rng:NextNumber(-radius, radius)
				)
			local mote = Debris.cube(
				if isDrop then Vector3.new(0.12, 0.3, 0.12) else Vector3.new(0.1, 0.1, 0.1),
				CFrame.new(pos),
				if isDrop then Color3.fromRGB(150, 200, 255) else Color3.fromRGB(220, 210, 190),
				if isDrop then Enum.Material.Glass else Enum.Material.SmoothPlastic
			)
			mote.Transparency = if isDrop then 0.3 else 0.2
			table.insert(motes, mote)
		end
	end

	local handle = {}
	function handle.resume(_self: Handle)
		for emitter, scale in frozen do
			if emitter.Parent then
				emitter.TimeScale = scale
			end
		end
		Debris.timeScale = 1
		for _, mote in motes do
			if mote.Parent then
				Debris.add(mote, { gravity = 30, life = 1.2, fadeFrom = 0.6 })
			end
		end
	end
	return handle :: Handle
end

return TimeFreeze
