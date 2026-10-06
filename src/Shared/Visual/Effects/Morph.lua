--!strict
-- Shape and color changes of a whole model:
--   Transform (A-TRANSFORM_NEGATINO): every part tweens to a color, the model stretches
--     vertically (Body size Y) and its lights dim, over `duration`.
--   Wither (CS-14): leaves turn yellow and fall as little cubes, then the whole body dries to
--     a dead-wood color.
--   DirtBurst (A-PATAPIM_RISE): clods of earth burst up around a point and fall back.
local TweenService = game:GetService("TweenService")

local Debris = require(script.Parent.Debris)

local Morph = {}

export type TransformParams = {
	color: Color3?,
	stretch: number?, -- vertical scale of the Body part (1.5 for Negatino)
	glow: number?, -- final PointLight brightness
	duration: number?,
}

function Morph.transform(model: Instance, p: TransformParams?)
	local params: TransformParams = p or {}
	local duration = params.duration or 3
	local info = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local goal: { [string]: any } = {}
			if params.color then
				goal.Color = params.color
			end
			if params.stretch and d.Name == "Body" then
				goal.Size = Vector3.new(d.Size.X, d.Size.Y * params.stretch, d.Size.Z)
				goal.CFrame = d.CFrame * CFrame.new(0, d.Size.Y * (params.stretch - 1) / 2, 0)
			end
			TweenService:Create(d, info, goal):Play()
		elseif d:IsA("Light") then
			local goal: { [string]: any } = {}
			if params.glow then
				goal.Brightness = params.glow
			end
			if params.color then
				goal.Color = params.color
			end
			TweenService:Create(d, info, goal):Play()
		end
	end
	task.wait(duration)
end

export type WitherParams = {
	duration: number?,
	leafColor: Color3?,
	deadColor: Color3?,
	leaves: number?,
}

function Morph.wither(model: Instance, p: WitherParams?)
	local params: WitherParams = p or {}
	local duration = params.duration or 5
	local yellow = params.leafColor or Color3.fromRGB(206, 170, 60)
	local dead = params.deadColor or Color3.fromRGB(96, 78, 58)
	local leafParts: { BasePart } = {}
	local body: { BasePart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 and d.Name ~= "HumanoidRootPart" then
			if string.find(d.Name, "Leaves") or string.find(d.Name, "Moss") then
				table.insert(leafParts, d)
			else
				table.insert(body, d)
			end
		end
	end
	local half = TweenInfo.new(duration * 0.4)
	for _, leaf in leafParts do
		TweenService:Create(leaf, half, { Color = yellow }):Play()
	end
	-- leaves fall in little cubes
	local count = params.leaves or 30
	task.spawn(function()
		for i = 1, count do
			local host = leafParts[((i - 1) % math.max(#leafParts, 1)) + 1]
			if host then
				local offset = Vector3.new(
					(math.random() - 0.5) * host.Size.X,
					(math.random() - 0.5) * host.Size.Y,
					(math.random() - 0.5) * host.Size.Z
				)
				local cube = Debris.cube(
					Vector3.new(0.3, 0.3, 0.3),
					host.CFrame * CFrame.new(offset),
					yellow,
					Enum.Material.Grass
				)
				Debris.add(cube, {
					vel = Vector3.new((math.random() - 0.5) * 2, -1, (math.random() - 0.5) * 2),
					spin = 3,
					gravity = 6,
					life = 3,
					fadeFrom = 2,
				})
			end
			task.wait(duration * 0.6 / count)
		end
	end)
	task.wait(duration * 0.5)
	for _, leaf in leafParts do
		TweenService:Create(leaf, half, { Transparency = 1 }):Play()
	end
	local rest = TweenInfo.new(duration * 0.5)
	for _, part in body do
		TweenService:Create(part, rest, { Color = dead }):Play()
	end
	task.wait(duration * 0.5)
end

export type DirtParams = { at: Vector3?, count: number?, radius: number? }

function Morph.dirtBurst(model: Instance?, p: DirtParams?)
	local params: DirtParams = p or {}
	local center = params.at
	if not center and model then
		local m = if model:IsA("Model")
			then model:GetPivot().Position
			elseif model:IsA("BasePart") then model.Position
			else nil
		center = m
	end
	if not center then
		return
	end
	local radius = params.radius or 2.5
	for _ = 1, params.count or 24 do
		local a = math.random() * math.pi * 2
		local r = math.random() * radius
		local pos = (center :: Vector3) + Vector3.new(math.cos(a) * r, 0.3, math.sin(a) * r)
		local clod = Debris.cube(
			Vector3.new(0.5, 0.5, 0.5),
			CFrame.new(pos),
			Color3.fromRGB(112, 77, 51),
			Enum.Material.Ground
		)
		Debris.add(clod, {
			vel = Vector3.new(math.cos(a) * 6, 12 + math.random() * 10, math.sin(a) * 6),
			spin = 6,
			gravity = 50,
			floorY = (center :: Vector3).Y,
			bounce = 0.2,
			life = 2.5,
			fadeFrom = 1.8,
		})
	end
end

return Morph
