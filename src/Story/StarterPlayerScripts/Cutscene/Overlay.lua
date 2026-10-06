--!strict
-- Screen layers for cutscenes: letterbox bars, black/white fades, GLITCH CUT bursts, film grain,
-- vignette, 4:3 pillarbox (FLASHBACK), continuous glitch (GLITCH grade) and the Skip button.
-- Everything is made of Frames: no uploaded images.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Strings = require(Shared:WaitForChild("Strings"))

local Screen = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Screen"))

local Overlay = {}

local BAR_HEIGHT = 0.11
local GRAIN_DOTS = 90

local gui: ScreenGui? = nil
local topBar: Frame? = nil
local bottomBar: Frame? = nil
local fade: Frame? = nil
local leftBar: Frame? = nil
local rightBar: Frame? = nil
local vignette: Frame? = nil
local grainLayer: Frame? = nil
local glitchLayer: Frame? = nil
local skipButton: TextButton? = nil
local grainOn = false
local glitchOn = false
local pillarboxOn = false
local rng = Random.new()

local function frame(parent: Instance, name: string, color: Color3, z: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.ZIndex = z
	f.Parent = parent
	return f
end

local function edge(
	parent: Frame,
	name: string,
	rotation: number,
	size: UDim2,
	position: UDim2,
	anchor: Vector2
)
	local f = frame(parent, name, Color3.new(0, 0, 0), 2)
	f.Size = size
	f.Position = position
	f.AnchorPoint = anchor
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = f
end

local function pillarWidth(): number
	local g = gui
	if not g then
		return 0
	end
	local size = g.AbsoluteSize
	return math.max(0, (size.X - size.Y * 4 / 3) / 2)
end

function Overlay.init()
	if gui then
		return
	end
	local g = Screen.gui("CutsceneOverlay", 50)
	gui = g

	local top = frame(g, "TopBar", Color3.new(0, 0, 0), 5)
	top.Size = UDim2.fromScale(1, BAR_HEIGHT)
	top.Position = UDim2.fromScale(0, -BAR_HEIGHT)
	topBar = top
	local bottom = frame(g, "BottomBar", Color3.new(0, 0, 0), 5)
	bottom.Size = UDim2.fromScale(1, BAR_HEIGHT)
	bottom.Position = UDim2.fromScale(0, 1)
	bottomBar = bottom

	local left = frame(g, "PillarLeft", Color3.new(0, 0, 0), 4)
	left.Size = UDim2.new(0, 0, 1, 0)
	leftBar = left
	local right = frame(g, "PillarRight", Color3.new(0, 0, 0), 4)
	right.AnchorPoint = Vector2.new(1, 0)
	right.Position = UDim2.fromScale(1, 0)
	right.Size = UDim2.new(0, 0, 1, 0)
	rightBar = right
	g:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if pillarboxOn then
			local w = pillarWidth()
			left.Size = UDim2.new(0, w, 1, 0)
			right.Size = UDim2.new(0, w, 1, 0)
		end
	end)

	local v = frame(g, "Vignette", Color3.new(0, 0, 0), 2)
	v.BackgroundTransparency = 1
	v.Size = UDim2.fromScale(1, 1)
	v.Visible = false
	edge(v, "Top", 90, UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0), Vector2.zero)
	edge(v, "Bottom", 270, UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 1), Vector2.new(0, 1))
	edge(v, "Left", 0, UDim2.fromScale(0.25, 1), UDim2.fromScale(0, 0), Vector2.zero)
	edge(v, "Right", 180, UDim2.fromScale(0.25, 1), UDim2.fromScale(1, 0), Vector2.new(1, 0))
	vignette = v

	local grain = frame(g, "Grain", Color3.new(0, 0, 0), 3)
	grain.BackgroundTransparency = 1
	grain.Size = UDim2.fromScale(1, 1)
	grain.Visible = false
	for i = 1, GRAIN_DOTS do
		local dot = frame(grain, "Dot" .. i, Color3.new(1, 1, 1), 3)
		dot.Size = UDim2.fromOffset(2, 2)
		dot.BackgroundTransparency = 0.75
	end
	grainLayer = grain

	local glitch = frame(g, "Glitch", Color3.new(0, 0, 0), 6)
	glitch.BackgroundTransparency = 1
	glitch.Size = UDim2.fromScale(1, 1)
	glitch.Visible = false
	for i = 1, 14 do
		local block = frame(glitch, "Block" .. i, Color3.new(1, 0, 0), 6)
		block.BackgroundTransparency = 0.35
	end
	glitchLayer = glitch

	local f = frame(g, "Fade", Color3.new(0, 0, 0), 8)
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundTransparency = 1
	fade = f

	local skip = Screen.button(g, "Skip", Strings.Dialogue.Skip, Vector2.new(150, 60))
	skip.AnchorPoint = Vector2.new(1, 1)
	skip.Position = UDim2.new(1, -24, 1, -24)
	skip.ZIndex = 9
	skip.Visible = false
	Screen.autoScale(skip)
	skipButton = skip

	-- animate grain / glitch layers
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		if acc < 0.06 then
			return
		end
		acc = 0
		if grainOn and grainLayer then
			for _, dot in grainLayer:GetChildren() do
				if dot:IsA("Frame") then
					dot.Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber())
					dot.BackgroundColor3 = if rng:NextNumber() < 0.5
						then Color3.new(1, 1, 1)
						else Color3.new(0, 0, 0)
				end
			end
		end
		if glitchOn and glitchLayer then
			local active = rng:NextNumber() < 0.25
			for _, block in glitchLayer:GetChildren() do
				if block:IsA("Frame") then
					block.Visible = active and rng:NextNumber() < 0.4
					block.Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber())
					block.Size =
						UDim2.fromScale(rng:NextNumber(0.02, 0.18), rng:NextNumber(0.005, 0.04))
				end
			end
		end
	end)
end

function Overlay.letterbox(show: boolean, time: number?)
	local t = time or Config.Cutscene.LetterboxSeconds
	local top, bottom = topBar, bottomBar
	if not top or not bottom then
		return
	end
	local info = TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService
		:Create(top, info, { Position = UDim2.fromScale(0, if show then 0 else -BAR_HEIGHT) })
		:Play()
	TweenService
		:Create(bottom, info, { Position = UDim2.fromScale(0, if show then 1 - BAR_HEIGHT else 1) })
		:Play()
end

--- Sets the fade layer directly: opacity 0 = clear, 1 = solid color.
function Overlay.setFade(color: Color3, opacity: number)
	local f = fade
	if f then
		f.BackgroundColor3 = color
		f.BackgroundTransparency = 1 - math.clamp(opacity, 0, 1)
	end
end

function Overlay.fadeTo(color: Color3, opacity: number, time: number)
	local f = fade
	if f then
		f.BackgroundColor3 = color
		TweenService
			:Create(
				f,
				TweenInfo.new(time),
				{ BackgroundTransparency = 1 - math.clamp(opacity, 0, 1) }
			)
			:Play()
	end
end

function Overlay.fadeOpacity(): number
	local f = fade
	return if f then 1 - f.BackgroundTransparency else 0
end

--- GLITCH CUT: ~0.2 s of noise blocks and color tears.
function Overlay.glitchBurst(duration: number?)
	local layer = glitchLayer
	if not layer then
		return
	end
	local total = duration or 0.2
	layer.Visible = true
	local start = os.clock()
	task.spawn(function()
		while os.clock() - start < total do
			for _, block in layer:GetChildren() do
				if block:IsA("Frame") then
					block.Visible = true
					block.BackgroundColor3 = if rng:NextNumber() < 0.5
						then Color3.fromRGB(255, 40, 40)
						else Color3.fromRGB(40, 255, 255)
					block.Position = UDim2.fromScale(rng:NextNumber(-0.1, 1), rng:NextNumber())
					block.Size =
						UDim2.fromScale(rng:NextNumber(0.1, 0.9), rng:NextNumber(0.01, 0.08))
				end
			end
			RunService.RenderStepped:Wait()
		end
		for _, block in layer:GetChildren() do
			if block:IsA("Frame") then
				block.Visible = false
				block.BackgroundColor3 = Color3.new(1, 0, 0)
			end
		end
		layer.Visible = glitchOn
	end)
end

function Overlay.setGrain(on: boolean)
	grainOn = on
	if grainLayer then
		grainLayer.Visible = on
	end
end

function Overlay.setVignette(on: boolean, color: Color3?)
	local v = vignette
	if v then
		v.Visible = on
		for _, edgeFrame in v:GetChildren() do
			if edgeFrame:IsA("Frame") then
				edgeFrame.BackgroundColor3 = color or Color3.new(0, 0, 0)
			end
		end
	end
end

function Overlay.setGlitch(on: boolean)
	glitchOn = on
	if glitchLayer then
		glitchLayer.Visible = on
	end
end

function Overlay.setPillarbox(on: boolean, time: number?)
	pillarboxOn = on
	local left, right = leftBar, rightBar
	if not left or not right then
		return
	end
	local w = if on then pillarWidth() else 0
	local info = TweenInfo.new(time or 0.5)
	TweenService:Create(left, info, { Size = UDim2.new(0, w, 1, 0) }):Play()
	TweenService:Create(right, info, { Size = UDim2.new(0, w, 1, 0) }):Play()
end

--- Skip button: hidden when not allowed, shows "Skip n/m" once someone voted.
function Overlay.setSkip(visible: boolean, votes: number?, needed: number?)
	local button = skipButton
	if not button then
		return
	end
	button.Visible = visible
	if votes and needed and votes > 0 then
		button.Text = string.format(Strings.Dialogue.SkipVotes, votes, needed)
	else
		button.Text = Strings.Dialogue.Skip
	end
end

function Overlay.onSkip(callback: () -> ())
	local button = skipButton
	if button then
		button.Activated:Connect(callback)
	end
end

function Overlay.reset()
	Overlay.setGrain(false)
	Overlay.setVignette(false)
	Overlay.setGlitch(false)
	Overlay.setPillarbox(false, 0)
	Overlay.setSkip(false)
	if fade then
		fade.BackgroundTransparency = 1
	end
end

return Overlay
