--!strict
-- The loading screen (CS-00 shot 4, the teleport to the Story place, joining): black screen, a
-- small yellow cube that "loads" pixel by pixel in the middle, a ring of blocks as the progress
-- bar and the blinking text "Connecting to Brainrot Valley…". At 100 % the text shows
-- "Hi, <DisplayName>. :)" for one frame only (screenplay P-1), then the screen closes.
-- Client only. build() returns a ScreenGui (also usable as the TeleportGui).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Strings = require(script.Parent.Parent:WaitForChild("Strings"))
local UITheme = require(script.Parent.Parent:WaitForChild("UITheme"))

local LoadingScreen = {}

export type Handle = {
	gui: ScreenGui,
	setProgress: (number) -> (),
	finish: (greet: boolean?) -> (),
	destroy: () -> (),
}

local RING = 16 -- blocks around the cube
local GRID = 4 -- the cube fills in 4 x 4 pixels

function LoadingScreen.build(): (ScreenGui, (number) -> (), TextLabel)
	local gui = Instance.new("ScreenGui")
	gui.Name = "LoadingScreen"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = UITheme.Colors.Black
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local holder = Instance.new("Frame")
	holder.Name = "Center"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.45)
	holder.Size = UDim2.fromOffset(220, 220)
	holder.BackgroundTransparency = 1
	holder.Parent = bg
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Parent = holder
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(260, 260)
	sizeLimit.MinSize = Vector2.new(120, 120)
	sizeLimit.Parent = holder
	-- the cube: GRID x GRID pixels that light up as the progress grows
	local pixels: { Frame } = {}
	for j = 0, GRID - 1 do
		for i = 0, GRID - 1 do
			local px = Instance.new("Frame")
			px.Name = "Pixel"
			px.AnchorPoint = Vector2.new(0.5, 0.5)
			px.Size = UDim2.fromScale(0.3 / GRID * 0.92, 0.3 / GRID * 0.92)
			px.Position =
				UDim2.fromScale(0.35 + (i + 0.5) * 0.3 / GRID, 0.35 + (j + 0.5) * 0.3 / GRID)
			px.BackgroundColor3 = UITheme.Colors.Giallino
			px.BackgroundTransparency = 1
			px.BorderSizePixel = 0
			px.Parent = holder
			table.insert(pixels, px)
		end
	end
	-- shuffle the fill order once (deterministic)
	local order = {}
	for k = 1, #pixels do
		order[k] = k
	end
	local rng = Random.new(67)
	for k = #order, 2, -1 do
		local m = rng:NextInteger(1, k)
		order[k], order[m] = order[m], order[k]
	end
	-- the ring of blocks
	local ring: { Frame } = {}
	for k = 0, RING - 1 do
		local a = k / RING * math.pi * 2 - math.pi / 2
		local b = Instance.new("Frame")
		b.Name = "Ring"
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Size = UDim2.fromScale(0.07, 0.07)
		b.Position = UDim2.fromScale(0.5 + math.cos(a) * 0.42, 0.5 + math.sin(a) * 0.42)
		b.BackgroundColor3 = UITheme.Colors.PanelLight
		b.BorderSizePixel = 0
		b.Parent = holder
		table.insert(ring, b)
	end
	local text = Instance.new("TextLabel")
	text.Name = "Status"
	text.AnchorPoint = Vector2.new(0.5, 0)
	text.Position = UDim2.fromScale(0.5, 0.66)
	text.Size = UDim2.new(0.9, 0, 0, 40)
	text.BackgroundTransparency = 1
	text.Font = UITheme.Fonts.Body
	text.TextColor3 = UITheme.Colors.Text
	text.TextScaled = true
	text.Text = Strings.Loading.Connecting
	text.Parent = bg
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 28
	limit.Parent = text
	local function setProgress(p: number)
		p = math.clamp(p, 0, 1)
		local lit = math.floor(p * #pixels + 0.5)
		for k, idx in order do
			pixels[idx].BackgroundTransparency = if k <= lit then 0 else 1
		end
		local ringLit = math.floor(p * RING + 0.5)
		for k, b in ring do
			b.BackgroundColor3 = if k <= ringLit
				then UITheme.Colors.Giallino
				else UITheme.Colors.PanelLight
		end
	end
	setProgress(0)
	return gui, setProgress, text
end

--- Shows the loading screen. finish() runs it to 100 %, greets for one frame and removes it.
function LoadingScreen.show(): Handle
	local player = Players.LocalPlayer
	local gui, setProgress, text = LoadingScreen.build()
	gui.Parent = player:WaitForChild("PlayerGui")
	local alive = true
	local started = os.clock()
	local blink = RunService.RenderStepped:Connect(function()
		text.TextTransparency = 0.25 + 0.25 * math.sin((os.clock() - started) * 5)
	end)
	local handle: Handle
	handle = {
		gui = gui,
		setProgress = setProgress,
		finish = function(greet: boolean?)
			if not alive then
				return
			end
			setProgress(1)
			if greet ~= false then
				-- one frame only, like a glitch (screenplay P-1)
				text.Text = (string.gsub(Strings.Loading.Hello, "%[Name%]", player.DisplayName))
				RunService.RenderStepped:Wait()
				RunService.RenderStepped:Wait()
				text.Text = Strings.Loading.Connecting
			end
			task.wait(0.3)
			handle.destroy()
		end,
		destroy = function()
			alive = false
			blink:Disconnect()
			gui:Destroy()
		end,
	}
	return handle
end

--- Plays the whole loading animation over `duration` seconds (CS-00 shot 4). `stare` = the
--- cube is already fully loaded and looks straight at you (CS-E2).
function LoadingScreen.play(duration: number, greet: boolean?, stare: boolean?)
	local h = LoadingScreen.show()
	if stare then
		h.setProgress(1)
		local center = h.gui:FindFirstChild("Center", true)
		if center then
			for _, spec in
				{
					{ 0.44, 0.44 },
					{ 0.56, 0.44 },
					{ 0.42, 0.56 },
					{ 0.46, 0.585 },
					{ 0.5, 0.59 },
					{ 0.54, 0.585 },
					{ 0.58, 0.56 },
				}
			do
				local px = Instance.new("Frame")
				px.AnchorPoint = Vector2.new(0.5, 0.5)
				px.Size = UDim2.fromScale(0.045, 0.045)
				px.Position = UDim2.fromScale(spec[1], spec[2])
				px.BackgroundColor3 = Color3.fromRGB(30, 22, 6)
				px.BorderSizePixel = 0
				px.ZIndex = 5
				px.Parent = center
			end
		end
		task.wait(duration)
		h.destroy()
		return
	end
	local start = os.clock()
	while os.clock() - start < duration do
		local p = (os.clock() - start) / duration
		h.setProgress(p * p * (3 - 2 * p))
		task.wait()
	end
	h.finish(greet)
end

return LoadingScreen
