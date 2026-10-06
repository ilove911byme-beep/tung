--!strict
-- A-PIXEL_ASSEMBLE / A-GIALLINO_ASSEMBLE: pixels fly in (on a spiral) and become the model.
-- The model's parts are hidden at the start and fade in while the last pixels arrive.
local RunService = game:GetService("RunService")

local Debris = require(script.Parent.Debris)

local PixelAssemble = {}

export type Params = {
	duration: number?, -- 2.5 for Giallino, 2.0 for players (CS-REVIVE)
	count: number?, -- number of pixels (A-GIALLINO_ASSEMBLE: 30)
	from: Vector3?, -- where the pixels come from (e.g. the lantern); nil = all around
	spiral: boolean?,
	cubeSize: number?,
	color: Color3?,
	flash: boolean?, -- golden flash at the end (CS-REVIVE)
}

type Pixel = {
	part: Part,
	target: BasePart,
	localPos: Vector3,
	start: Vector3,
	delay: number,
	travel: number,
}

function PixelAssemble.run(model: Instance, params: Params?)
	local p: Params = params or {}
	local duration = p.duration or 2.5
	local cubeSize = p.cubeSize or 0.4
	local color = p.color or Color3.fromRGB(255, 216, 58)
	local parts = Debris.visibleParts(model)
	if #parts == 0 then
		return
	end
	local rng = Random.new()
	local original: { [BasePart]: number } = {}
	local totalVolume = 0
	for _, part in parts do
		original[part] = part.Transparency
		part.Transparency = 1
		totalVolume += part.Size.X * part.Size.Y * part.Size.Z
	end
	-- faces / name tags stay hidden until the body appears
	local guis: { [Instance]: boolean } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			local gui = d :: any
			guis[d] = gui.Enabled
			gui.Enabled = false
		end
	end
	local guisShown = false
	local minV, maxV = Debris.bounds(parts)
	local center = (minV + maxV) / 2
	local count = p.count or math.clamp(math.round(totalVolume / (cubeSize ^ 3) * 0.05), 20, 220)

	local pixels: { Pixel } = {}
	for _ = 1, count do
		-- weighted random part
		local pick = rng:NextNumber(0, totalVolume)
		local chosen = parts[1]
		for _, part in parts do
			pick -= part.Size.X * part.Size.Y * part.Size.Z
			if pick <= 0 then
				chosen = part
				break
			end
		end
		local start: Vector3
		if p.from then
			start = p.from + rng:NextUnitVector() * rng:NextNumber(0.2, 1.5)
		else
			start = center + rng:NextUnitVector() * rng:NextNumber(5, 8)
		end
		local delay = rng:NextNumber(0, duration * 0.35)
		local cube = Debris.cube(
			Vector3.new(cubeSize, cubeSize, cubeSize),
			CFrame.new(start),
			color,
			Enum.Material.Neon
		)
		cube.Transparency = 1
		table.insert(pixels, {
			part = cube,
			target = chosen,
			localPos = Debris.randomLocalPoint(chosen, rng),
			start = start,
			delay = delay,
			travel = duration * 0.55,
		})
	end

	local elapsed = 0
	local finished = Instance.new("BindableEvent")
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt * Debris.timeScale
		local moved: { BasePart } = {}
		local cframes: { CFrame } = {}
		for _, px in pixels do
			if px.part.Parent then
				local a = math.clamp((elapsed - px.delay) / px.travel, 0, 1)
				local goal = px.target.CFrame * px.localPos
				local pos: Vector3
				if p.spiral ~= false then
					local e = 1 - (1 - a) ^ 3
					local offset = px.start - goal
					local radius = offset.Magnitude * (1 - e)
					local angle = (1 - e) * math.pi * 3
					local flat = Vector3.new(offset.X, 0, offset.Z)
					local dir = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.xAxis
					local rotated = CFrame.fromAxisAngle(Vector3.yAxis, angle)
						:VectorToWorldSpace(dir)
					pos = goal + rotated * radius + Vector3.new(0, offset.Y * (1 - e), 0)
				else
					pos = px.start:Lerp(goal, a * a)
				end
				px.part.Transparency = if a <= 0 then 1 elseif a >= 1 then 1 else 0.1
				table.insert(moved, px.part)
				table.insert(cframes, CFrame.new(pos))
				if a >= 1 then
					px.part:Destroy()
				end
			end
		end
		if #moved > 0 then
			workspace:BulkMoveTo(moved, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		end
		-- reveal the body during the last 35 %
		local reveal = math.clamp((elapsed - duration * 0.65) / (duration * 0.35), 0, 1)
		for part, base in original do
			part.Transparency = 1 - (1 - base) * reveal
		end
		if reveal > 0.5 and not guisShown then
			guisShown = true
			for gui, enabled in guis do
				(gui :: any).Enabled = enabled
			end
		end
		if elapsed >= duration then
			connection:Disconnect()
			finished:Fire()
		end
	end)
	finished.Event:Wait()
	finished:Destroy()
	for _, px in pixels do
		if px.part.Parent then
			px.part:Destroy()
		end
	end
	for part, base in original do
		part.Transparency = base
	end
	if not guisShown then
		for gui, enabled in guis do
			(gui :: any).Enabled = enabled
		end
	end
	if p.flash then
		local flash = Debris.cube(
			maxV - minV + Vector3.new(1, 1, 1),
			CFrame.new(center),
			Color3.fromRGB(255, 220, 120)
		)
		flash.Transparency = 0.4
		Debris.add(flash, { life = 0.4, fadeFrom = 0 })
	end
end

return PixelAssemble
