--!strict
-- Pixel faces on a SurfaceGui on the front of a head (villagers) or on Giallino's screen.
-- Faces change in cutscenes and in gameplay dialogue. A model's face head is the part with the
-- attribute FaceStyle ("screen" or "villager"), set by the RigFactory.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FaceBitmaps = require(script.Parent.FaceBitmaps)

local GRID = 12

type Style = {
	background: Color3,
	backgroundTransparency: number,
	inset: number, -- fraction of the face left as border
	lightInfluence: number,
	colors: { [string]: Color3 },
}

local STYLES: { [string]: Style } = {
	screen = {
		background = Color3.fromRGB(46, 36, 6),
		backgroundTransparency = 0,
		inset = 0.08,
		lightInfluence = 0,
		colors = {
			E = Color3.fromRGB(255, 248, 205),
			W = Color3.fromRGB(255, 255, 255),
			B = Color3.fromRGB(255, 236, 160),
			M = Color3.fromRGB(255, 248, 205),
			G = Color3.fromRGB(90, 255, 90),
			T = Color3.fromRGB(130, 215, 255),
		},
	},
	villager = {
		background = Color3.new(0, 0, 0),
		backgroundTransparency = 1,
		inset = 0.04,
		lightInfluence = 1,
		colors = {
			E = Color3.fromRGB(28, 24, 22),
			W = Color3.fromRGB(250, 250, 250),
			B = Color3.fromRGB(60, 40, 30),
			M = Color3.fromRGB(90, 40, 32),
			G = Color3.fromRGB(70, 200, 70),
			T = Color3.fromRGB(110, 200, 255),
		},
	},
}

local EYE_CHARS = { E = true, W = true, B = true, G = true }

export type Face = {
	model: Model,
	head: BasePart,
	style: Style,
	gui: SurfaceGui,
	background: Frame,
	dimmer: Frame,
	cells: { { Frame } },
	current: string,
	eyeOffset: Vector2,
	flashToken: number,
	tearEmitter: ParticleEmitter?,
}

local FaceController = {}

local faces: { [Model]: Face } = setmetatable({}, { __mode = "k" }) :: any
local animated: { [Face]: boolean } = {}
local animClock = 0
local animConnection: RBXScriptConnection? = nil

local function findHead(model: Model): BasePart?
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("FaceStyle") ~= nil then
			return d
		end
	end
	return nil
end

local function makeTearEmitter(head: BasePart): ParticleEmitter
	local attachment = Instance.new("Attachment")
	attachment.Name = "TearAttachment"
	attachment.Position = Vector3.new(0, -head.Size.Y * 0.05, -head.Size.Z / 2 - 0.05)
	attachment.Parent = head
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Tears"
	emitter.Color = ColorSequence.new(Color3.fromRGB(150, 215, 255))
	emitter.LightEmission = 0.3
	emitter.Size = NumberSequence.new(0.12, 0.05)
	emitter.Transparency = NumberSequence.new(0.1, 1)
	emitter.Lifetime = NumberRange.new(0.6, 0.9)
	emitter.Speed = NumberRange.new(0.3, 0.6)
	emitter.SpreadAngle = Vector2.new(25, 10)
	emitter.Acceleration = Vector3.new(0, -12, 0)
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Rate = 7
	emitter.Enabled = false
	emitter.Parent = attachment
	return emitter
end

--- Creates the face GUI on a head part (idempotent).
function FaceController.attach(model: Model, head: BasePart, styleName: string): Face
	local existing = faces[model]
	if existing then
		return existing
	end
	local style = STYLES[styleName] or STYLES.villager
	local gui = Instance.new("SurfaceGui")
	gui.Name = "PixelFace"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 48
	gui.LightInfluence = style.lightInfluence
	gui.Brightness = if styleName == "screen" then 1.6 else 1
	gui.ResetOnSpawn = false
	gui.Adornee = head

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = style.background
	background.BackgroundTransparency = style.backgroundTransparency
	background.BorderSizePixel = 0
	background.Parent = gui

	local grid = Instance.new("Frame")
	grid.Name = "Grid"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.fromScale(1 - style.inset * 2, 1 - style.inset * 2)
	grid.Position = UDim2.fromScale(style.inset, style.inset)
	grid.Parent = background

	local cells: { { Frame } } = {}
	for r = 1, GRID do
		cells[r] = {}
		for c = 1, GRID do
			local cell = Instance.new("Frame")
			cell.BorderSizePixel = 0
			cell.Size = UDim2.fromScale(1 / GRID, 1 / GRID)
			cell.Position = UDim2.fromScale((c - 1) / GRID, (r - 1) / GRID)
			cell.BackgroundTransparency = 1
			cell.Parent = grid
			cells[r][c] = cell
		end
	end

	local dimmer = Instance.new("Frame")
	dimmer.Name = "Dimmer"
	dimmer.Size = UDim2.fromScale(1, 1)
	dimmer.BackgroundColor3 = Color3.new(0, 0, 0)
	dimmer.BackgroundTransparency = 1
	dimmer.BorderSizePixel = 0
	dimmer.ZIndex = 5
	dimmer.Parent = background

	gui.Parent = head

	local face: Face = {
		model = model,
		head = head,
		style = style,
		gui = gui,
		background = background,
		dimmer = dimmer,
		cells = cells,
		current = "neutral",
		eyeOffset = Vector2.zero,
		flashToken = 0,
		tearEmitter = nil,
	}
	faces[model] = face
	return face
end

--- Returns the model's face, creating it from the FaceStyle attribute if needed.
function FaceController.get(model: Model): Face?
	local face = faces[model]
	if face then
		return face
	end
	local head = findHead(model)
	if not head then
		return nil
	end
	return FaceController.attach(model, head, tostring(head:GetAttribute("FaceStyle")))
end

local function paint(face: Face, bitmap: { string })
	local ox = math.round(face.eyeOffset.X)
	local oy = math.round(face.eyeOffset.Y)
	-- clear
	for r = 1, GRID do
		for c = 1, GRID do
			face.cells[r][c].BackgroundTransparency = 1
		end
	end
	for r = 1, GRID do
		local row = bitmap[r]
		for c = 1, GRID do
			local ch = string.sub(row, c, c)
			if ch ~= "." then
				local rr, cc = r, c
				if EYE_CHARS[ch] then
					rr += oy
					cc += ox
				end
				if rr >= 1 and rr <= GRID and cc >= 1 and cc <= GRID then
					local cell = face.cells[rr][cc]
					cell.BackgroundColor3 = face.style.colors[ch] or Color3.new(1, 0, 1)
					cell.BackgroundTransparency = 0
				end
			end
		end
	end
end

local function paintStatic(face: Face)
	local rng = Random.new()
	for r = 1, GRID do
		for c = 1, GRID do
			local cell = face.cells[r][c]
			local v = rng:NextNumber()
			if v < 0.55 then
				local g = rng:NextNumber(0.25, 1)
				cell.BackgroundColor3 = Color3.new(g, g, g * 0.85)
				cell.BackgroundTransparency = 0
			else
				cell.BackgroundTransparency = 1
			end
		end
	end
	face.background.BackgroundColor3 =
		Color3.fromRGB(rng:NextInteger(10, 50), rng:NextInteger(10, 40), 10)
end

-- tear pixels running down below each eye
local TEAR_COLUMNS = { 3, 10 }

local function paintTears(face: Face, clock: number)
	paint(face, FaceBitmaps.sad)
	local step = math.floor(clock / 0.14)
	for i, col in TEAR_COLUMNS do
		local phase = (step + (i - 1) * 2) % 5
		local row = 7 + phase
		local c = col + math.round(face.eyeOffset.X)
		for _, rr in { row, row - 1 } do
			if rr >= 7 and rr <= GRID and c >= 1 and c <= GRID then
				local cell = face.cells[rr][c]
				cell.BackgroundColor3 = face.style.colors.T
				cell.BackgroundTransparency = if rr == row then 0 else 0.45
			end
		end
	end
end

local function ensureAnimLoop()
	if animConnection then
		return
	end
	animConnection = RunService.Heartbeat:Connect(function(dt: number)
		animClock += dt
		for face in animated do
			if not face.gui.Parent then
				animated[face] = nil
			elseif face.current == "screen_static" then
				paintStatic(face)
			elseif face.current == "crying" then
				paintTears(face, animClock)
			end
		end
	end)
end

local function render(face: Face)
	face.background.BackgroundColor3 = face.style.background
	if face.current == "off" then
		face.background.BackgroundColor3 = Color3.new(0.02, 0.02, 0.02)
	end
	local isAnimated = face.current == "screen_static" or face.current == "crying"
	if isAnimated then
		animated[face] = true
		ensureAnimLoop()
		if face.current == "crying" then
			paintTears(face, animClock)
		else
			paintStatic(face)
		end
	else
		animated[face] = nil
		paint(face, FaceBitmaps[face.current] or FaceBitmaps.neutral)
	end
	-- falling drops while crying
	if face.current == "crying" then
		if not face.tearEmitter then
			face.tearEmitter = makeTearEmitter(face.head)
		end
	end
	if face.tearEmitter then
		face.tearEmitter.Enabled = face.current == "crying"
	end
end

--- Sets an expression. Unknown ids fall back to neutral.
function FaceController.set(model: Model, faceId: string)
	local face = FaceController.get(model)
	if not face then
		return
	end
	face.flashToken += 1
	face.current = faceId
	render(face)
end

--- Shows an expression for `seconds` (e.g. one frame of screen_static), then goes back.
function FaceController.flash(model: Model, faceId: string, seconds: number)
	local face = FaceController.get(model)
	if not face then
		return
	end
	local previous = face.current
	face.flashToken += 1
	local token = face.flashToken
	face.current = faceId
	render(face)
	task.delay(math.max(seconds, 1 / 60), function()
		if face.flashToken == token and face.gui.Parent then
			face.current = previous
			render(face)
		end
	end)
end

function FaceController.current(model: Model): string?
	local face = faces[model]
	return face and face.current
end

--- 0 = full brightness, 1 = black. Tweened over `time` seconds.
function FaceController.setDim(model: Model, dim: number, time: number?)
	local face = FaceController.get(model)
	if not face then
		return
	end
	local goal = { BackgroundTransparency = 1 - math.clamp(dim, 0, 1) }
	if time and time > 0 then
		TweenService:Create(face.dimmer, TweenInfo.new(time, Enum.EasingStyle.Sine), goal):Play()
	else
		face.dimmer.BackgroundTransparency = goal.BackgroundTransparency
	end
end

--- Moves the eyes (and brows) by whole pixels, e.g. Vector2.new(0, 1) = one pixel lower.
function FaceController.setEyeOffset(model: Model, offset: Vector2)
	local face = FaceController.get(model)
	if not face then
		return
	end
	face.eyeOffset = offset
	render(face)
end

return FaceController
