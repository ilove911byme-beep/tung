--!strict
-- The main menu (brief, lobby A): the camera flies slowly along a spline over the night valley
-- (blur, vignette, letterbox), the title "NIGHT IN BRAINROT VALLEY" glitches every ~20 s, a
-- little sun sits by the title and a small Giallino floats beside it following the mouse with
-- its eyes. Buttons slide in: PLAY · CHAPTERS · ENDINGS · ACHIEVEMENTS · SETTINGS · CREDITS.
-- PLAY swoops the camera down to the station and hands over control.
-- Meta effect: after the ENDLESS NIGHT ending the sun is Giallino once, and it winks.
-- Secret: staring at the menu for 60 s without moving the mouse = GIALLINO_STARE.
-- Landscape: buttons on the left, pages on the right; portrait phones stack everything.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Achievements = require(Shared:WaitForChild("Achievements"))
local Audio = require(Shared:WaitForChild("Audio"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local UITheme = require(Shared:WaitForChild("UITheme"))

local Client = script.Parent.Parent
local Settings = require(Client:WaitForChild("Settings"))
local Screen = require(Client:WaitForChild("UI"):WaitForChild("Screen"))
local MusicDirector = require(Client:WaitForChild("Audio"):WaitForChild("MusicDirector"))
local LobbyHud = require(script.Parent:WaitForChild("LobbyHud"))
local Profile = require(script.Parent:WaitForChild("Profile"))

local MainMenu = {}

local S = 4
local PATH: { Vector3 } = {
	Vector3.new(112, 34, -14) * S,
	Vector3.new(146, 29, 4) * S,
	Vector3.new(176, 25, 30) * S,
	Vector3.new(214, 31, 36) * S,
	Vector3.new(230, 36, 0) * S,
	Vector3.new(196, 40, -30) * S,
	Vector3.new(150, 38, -34) * S,
}
local LOOK = Vector3.new(205, 22, 14) * S
local SPAWN_VIEW = CFrame.lookAt(Vector3.new(20, 16, 47) * S, Vector3.new(20, 13, 32) * S)
local LAP_SECONDS = 90
local STARE_SECONDS = 60
local GLITCH_EVERY = 20

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local open = false
local camConn: RBXScriptConnection? = nil
local blur: BlurEffect? = nil
local pageHost: Frame? = nil
local buttonsFrame: Frame? = nil
local titleFrame: Frame? = nil
local giallinoFace: Frame? = nil
local currentPage: string? = nil
local metaShown = false
local stareSent = false

------------------------------------------------------------------ helpers

local function catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local t2, t3 = t * t, t * t * t
	return 0.5
		* (
			(2 * p1)
			+ (-p0 + p2) * t
			+ (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
			+ (-p0 + 3 * p1 - 3 * p2 + p3) * t3
		)
end

local function pathAt(u: number): Vector3
	local n = #PATH
	local x = (u % 1) * n
	local i = math.floor(x)
	local t = x - i
	local function p(k: number): Vector3
		return PATH[((k % n) + n) % n + 1]
	end
	return catmull(p(i - 1), p(i), p(i + 1), p(i + 2), t)
end

local function viewScale(): number
	local camera = workspace.CurrentCamera
	local v = if camera then camera.ViewportSize else UITheme.ReferenceResolution
	local ref = UITheme.ReferenceResolution
	local portrait = v.Y > v.X
	local s = if portrait then v.X / 560 else math.min(v.X / ref.X, v.Y / ref.Y)
	return math.clamp(s, 0.62, 1.5)
end

local function isPortrait(): boolean
	local camera = workspace.CurrentCamera
	return camera ~= nil and camera.ViewportSize.Y > camera.ViewportSize.X
end

local function text(
	parent: Instance,
	t: string,
	size: UDim2,
	pos: UDim2,
	font: Enum.Font?,
	color: Color3?
): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Font = font or UITheme.Fonts.Body
	l.TextColor3 = color or UITheme.Colors.Text
	l.TextScaled = true
	l.TextWrapped = true
	l.Text = t
	l.Parent = parent
	return l
end

local function sounds(button: GuiButton)
	button.MouseEnter:Connect(function()
		Audio.play("vote_tick", nil, { volume = 0.4, group = "SFX" })
	end)
	button.Activated:Connect(function()
		Audio.play("item_pickup", nil, { volume = 0.5, group = "SFX" })
	end)
end

local function block(parent: Instance, color: string, pos: UDim2, size: UDim2): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.fromHex(color)
	f.BorderSizePixel = 0
	f.Position = pos
	f.Size = size
	f.Parent = parent
	return f
end

------------------------------------------------------------------ camera, blur, frame

local function startCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local t0 = os.clock()
	camConn = RunService.RenderStepped:Connect(function()
		local u = (os.clock() - t0) / LAP_SECONDS
		local pos = pathAt(u)
		local ahead = pathAt(u + 0.02)
		local look = ahead:Lerp(LOOK, 0.55)
		camera.CFrame = CFrame.lookAt(pos, look)
		camera.FieldOfView = 60
	end)
	local b = Instance.new("BlurEffect")
	b.Name = "MenuBlur"
	b.Size = 6
	b.Parent = Lighting
	blur = b
end

local function stopCamera(swoop: boolean)
	local conn = camConn
	if conn then
		conn:Disconnect()
		camConn = nil
	end
	local camera = workspace.CurrentCamera
	local b = blur
	if b then
		TweenService:Create(b, TweenInfo.new(1.6), { Size = 0 }):Play()
		task.delay(1.7, function()
			b:Destroy()
		end)
		blur = nil
	end
	if not camera then
		return
	end
	if swoop then
		local from = camera.CFrame
		local mid = CFrame.lookAt(Vector3.new(60, 40, 40) * S, Vector3.new(20, 12, 30) * S)
		local t0 = os.clock()
		local duration = 2.6
		while os.clock() - t0 < duration do
			local a = TweenService:GetValue(
				(os.clock() - t0) / duration,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut
			)
			local p1 = from:Lerp(mid, a)
			local p2 = mid:Lerp(SPAWN_VIEW, a)
			camera.CFrame = p1:Lerp(p2, a)
			RunService.RenderStepped:Wait()
		end
	end
	camera.CameraType = Enum.CameraType.Custom
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

type Edge = { size: UDim2, pos: UDim2, rot: number }

local function vignette(parent: Instance)
	local edges: { Edge } = {
		{ size = UDim2.fromScale(1, 0.22), pos = UDim2.fromScale(0, 0), rot = 90 },
		{ size = UDim2.fromScale(1, 0.22), pos = UDim2.fromScale(0, 0.78), rot = 270 },
		{ size = UDim2.fromScale(0.18, 1), pos = UDim2.fromScale(0, 0), rot = 0 },
		{ size = UDim2.fromScale(0.18, 1), pos = UDim2.fromScale(0.82, 0), rot = 180 },
	}
	for _, e in edges do
		local f = Instance.new("Frame")
		f.Size = e.size
		f.Position = e.pos
		f.BackgroundColor3 = UITheme.Colors.Black
		f.BorderSizePixel = 0
		local g = Instance.new("UIGradient")
		g.Rotation = e.rot
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = f
		f.Parent = parent
	end
	-- slight letterbox
	block(parent, "#000000", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.045))
	block(parent, "#000000", UDim2.fromScale(0, 0.955), UDim2.fromScale(1, 0.045))
end

------------------------------------------------------------------ title, sun, Giallino

local function pixelFace(parent: Frame, wink: boolean): (Frame, Frame)
	local eyeL = block(parent, "#1E1606", UDim2.fromScale(0.24, 0.3), UDim2.fromScale(0.14, 0.2))
	local eyeR = block(parent, "#1E1606", UDim2.fromScale(0.62, 0.3), UDim2.fromScale(0.14, 0.2))
	for i, x in { 0.28, 0.36, 0.44, 0.52, 0.6, 0.68 } do
		local y = if i == 1 or i == 6 then 0.62 else 0.68
		block(parent, "#1E1606", UDim2.fromScale(x - 0.03, y), UDim2.fromScale(0.08, 0.07))
	end
	if wink then
		task.delay(1.6, function()
			eyeR.Size = UDim2.fromScale(0.14, 0.05)
			eyeR.Position = UDim2.fromScale(0.62, 0.38)
			Audio.play("giallino_blip_3", nil, { volume = 0.6, group = "SFX" })
			task.wait(0.35)
			eyeR.Size = UDim2.fromScale(0.14, 0.2)
			eyeR.Position = UDim2.fromScale(0.62, 0.3)
		end)
	end
	return eyeL, eyeR
end

local function buildSun(parent: Instance): Frame
	local sun = Instance.new("Frame")
	sun.Name = "Sun"
	sun.Size = UDim2.fromOffset(72, 72)
	sun.Position = UDim2.fromOffset(0, 14)
	sun.BackgroundTransparency = 1
	sun.Parent = parent
	local core = block(sun, "#FFB030", UDim2.fromScale(0.2, 0.2), UDim2.fromScale(0.6, 0.6))
	core.Name = "Core"
	for _, r in
		{
			{ 0.44, 0, 0.12, 0.14 },
			{ 0.44, 0.86, 0.12, 0.14 },
			{ 0, 0.44, 0.14, 0.12 },
			{ 0.86, 0.44, 0.14, 0.12 },
			{ 0.08, 0.08, 0.1, 0.1 },
			{ 0.82, 0.08, 0.1, 0.1 },
			{ 0.08, 0.82, 0.1, 0.1 },
			{ 0.82, 0.82, 0.1, 0.1 },
		}
	do
		block(sun, "#FF9A3C", UDim2.fromScale(r[1], r[2]), UDim2.fromScale(r[3], r[4]))
	end
	-- after ENDLESS NIGHT the sun is Giallino, once, and it winks
	if Profile.lastEnding() == "endless" and not metaShown then
		metaShown = true
		for _, c in sun:GetChildren() do
			if c:IsA("Frame") and c ~= core then
				c.Visible = false
			end
		end
		core.BackgroundColor3 = UITheme.Colors.Giallino
		core.Position = UDim2.fromScale(0.05, 0.05)
		core.Size = UDim2.fromScale(0.9, 0.9)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.12, 0)
		corner.Parent = core
		pixelFace(core, true)
	end
	return sun
end

local function buildTitle(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Title"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(820, 110)
	frame.Parent = parent
	buildSun(frame)
	local glow = text(
		frame,
		Strings.GameTitle,
		UDim2.new(1, -190, 1, 0),
		UDim2.fromOffset(84, 2),
		UITheme.Fonts.Title,
		UITheme.Colors.Orange
	)
	glow.TextTransparency = 0.75
	local glowStroke = Instance.new("UIStroke")
	glowStroke.Color = UITheme.Colors.Orange
	glowStroke.Thickness = 6
	glowStroke.Transparency = 0.8
	glowStroke.Parent = glow
	local title = text(
		frame,
		Strings.GameTitle,
		UDim2.new(1, -190, 1, 0),
		UDim2.fromOffset(84, 0),
		UITheme.Fonts.Title,
		UITheme.Colors.Orange
	)
	title.Name = "Text"
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 20, 0)
	stroke.Thickness = 1.5
	stroke.Parent = title
	-- the floating Giallino beside the title
	local g = Instance.new("Frame")
	g.Name = "Giallino"
	g.Size = UDim2.fromOffset(84, 84)
	g.AnchorPoint = Vector2.new(1, 0)
	g.Position = UDim2.new(1, -8, 0, 12)
	g.BackgroundColor3 = UITheme.Colors.Giallino
	g.BorderSizePixel = 0
	g.Parent = frame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.12, 0)
	corner.Parent = g
	local glowLight = Instance.new("UIStroke")
	glowLight.Color = UITheme.Colors.Giallino
	glowLight.Thickness = 4
	glowLight.Transparency = 0.6
	glowLight.Parent = g
	giallinoFace = g
	local eyeL, eyeR = pixelFace(g, false)
	local baseL, baseR = eyeL.Position, eyeR.Position
	local nextBlink = os.clock() + 3
	RunService.RenderStepped:Connect(function()
		if not g.Parent then
			return
		end
		local t = os.clock()
		g.Position = UDim2.new(1, -8, 0, 12 + math.sin(t * 2) * 6)
		g.Rotation = math.sin(t * 1.3) * 4
		-- eyes follow the mouse
		local mouse = UserInputService:GetMouseLocation()
		local center = g.AbsolutePosition + g.AbsoluteSize / 2
		local d = mouse - center
		local m = math.max(d.Magnitude, 1)
		local off = d / m * math.min(m / 400, 1)
		local dx, dy = off.X * 0.06, off.Y * 0.06
		eyeL.Position = UDim2.fromScale(baseL.X.Scale + dx, baseL.Y.Scale + dy)
		eyeR.Position = UDim2.fromScale(baseR.X.Scale + dx, baseR.Y.Scale + dy)
		if t > nextBlink then
			nextBlink = t + math.random(25, 50) / 10
			eyeL.Size = UDim2.fromScale(0.14, 0.04)
			eyeR.Size = UDim2.fromScale(0.14, 0.04)
			task.delay(0.12, function()
				eyeL.Size = UDim2.fromScale(0.14, 0.2)
				eyeR.Size = UDim2.fromScale(0.14, 0.2)
			end)
		end
	end)
	-- the glitch: letters swap for 0.3 s, a burst, Giallino's face flashes red for one frame
	task.spawn(function()
		local chars = "#%&?!01<>/\\"
		while frame.Parent do
			task.wait(GLITCH_EVERY + math.random() * 4)
			if not open then
				continue
			end
			Audio.play("glitch_burst", nil, { volume = 0.5, group = "SFX" })
			g.BackgroundColor3 = UITheme.Colors.Danger
			RunService.RenderStepped:Wait()
			g.BackgroundColor3 = UITheme.Colors.Giallino
			local t0 = os.clock()
			while os.clock() - t0 < 0.3 do
				local out = {}
				for i = 1, #Strings.GameTitle do
					local c = string.sub(Strings.GameTitle, i, i)
					if c ~= " " and math.random() < 0.3 then
						local k = math.random(1, #chars)
						c = string.sub(chars, k, k)
					end
					out[i] = c
				end
				title.Text = table.concat(out)
				title.Position = UDim2.fromOffset(84 + math.random(-4, 4), math.random(-3, 3))
				task.wait(0.05)
			end
			title.Text = Strings.GameTitle
			title.Position = UDim2.fromOffset(84, 0)
		end
	end)
	return frame
end

------------------------------------------------------------------ pages

local function clearPage(): Frame?
	local host = pageHost
	if not host then
		return nil
	end
	for _, c in host:GetChildren() do
		if not c:IsA("UICorner") and not c:IsA("UIStroke") then
			c:Destroy()
		end
	end
	return host
end

local function pageTitle(host: Frame, t: string)
	local l = text(
		host,
		t,
		UDim2.new(1, -140, 0, 46),
		UDim2.fromOffset(20, 12),
		UITheme.Fonts.Title,
		UITheme.Colors.Orange
	)
	l.TextXAlignment = Enum.TextXAlignment.Left
end

local function scroller(host: Frame, top: number): ScrollingFrame
	local sf = Instance.new("ScrollingFrame")
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.Position = UDim2.fromOffset(16, top)
	sf.Size = UDim2.new(1, -32, 1, -top - 16)
	sf.CanvasSize = UDim2.new()
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.ScrollBarThickness = 8
	sf.ScrollBarImageColor3 = UITheme.Colors.Orange
	sf.Parent = host
	return sf
end

local CHAPTER_SCENES: { [number]: { { string } } } = {
	-- {color, x, y, w, h} in scale of the thumbnail (a blocky "photo" of the location)
	[1] = {
		{ "#F4A86A", "0", "0", "1", "0.6" },
		{ "#5E9E4E", "0", "0.6", "1", "0.4" },
		{ "#5A5A60", "0.3", "0.5", "0.4", "0.18" },
	},
	[2] = {
		{ "#141428", "0", "0", "1", "0.65" },
		{ "#2E4A2A", "0", "0.65", "1", "0.35" },
		{ "#7A5A34", "0.25", "0.3", "0.5", "0.4" },
		{ "#FFC060", "0.42", "0.42", "0.14", "0.12" },
	},
	[3] = {
		{ "#8EC8F0", "0", "0", "1", "0.6" },
		{ "#5E9E4E", "0", "0.6", "1", "0.4" },
		{ "#C8A070", "0.1", "0.35", "0.3", "0.3" },
		{ "#B07A48", "0.55", "0.3", "0.35", "0.35" },
	},
	[4] = {
		{ "#0A0A18", "0", "0", "1", "0.65" },
		{ "#3A3A3A", "0", "0.65", "1", "0.35" },
		{ "#FF8020", "0.15", "0.5", "0.1", "0.15" },
		{ "#FF8020", "0.75", "0.5", "0.1", "0.15" },
		{ "#4A6CFF", "0.42", "0.2", "0.16", "0.18" },
	},
	[5] = {
		{ "#1A1A1E", "0", "0", "1", "1" },
		{ "#6E6E6E", "0", "0.7", "1", "0.3" },
		{ "#E07018", "0", "0.85", "0.5", "0.15" },
		{ "#5A5A60", "0.55", "0.55", "0.3", "0.15" },
	},
	[6] = {
		{ "#2A1A3A", "0", "0", "1", "0.7" },
		{ "#3A4A3A", "0", "0.7", "1", "0.3" },
		{ "#767676", "0.4", "0.15", "0.2", "0.6" },
		{ "#FFB030", "0.1", "0.08", "0.2", "0.22" },
	},
}

local function padlock(parent: Instance)
	local body = block(parent, "#9AA0B4", UDim2.fromScale(0.42, 0.45), UDim2.fromScale(0.16, 0.16))
	body.ZIndex = 5
	local arc = Instance.new("Frame")
	arc.BackgroundTransparency = 1
	arc.Position = UDim2.fromScale(0.445, 0.33)
	arc.Size = UDim2.fromScale(0.11, 0.16)
	arc.ZIndex = 5
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromHex("#9AA0B4")
	stroke.Thickness = 4
	stroke.Parent = arc
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = arc
	arc.Parent = parent
end

local function chaptersPage(host: Frame, s: number)
	pageTitle(host, Strings.Menu.Chapters)
	local hint = text(
		host,
		Strings.Menu.ChaptersHint,
		UDim2.new(1, -40, 0, 26),
		UDim2.fromOffset(20, 60),
		nil,
		UITheme.Colors.TextDim
	)
	hint.TextXAlignment = Enum.TextXAlignment.Left
	local sf = scroller(host, 94)
	local grid = Instance.new("UIGridLayout")
	local portrait = isPortrait()
	grid.CellSize = UDim2.new(if portrait then 0.48 else 0.31, 0, 0, math.floor(170 * s))
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = sf
	for n = 1, 6 do
		local unlocked = n == 1 or Profile.anyEnding()
		local card = Instance.new("TextButton")
		card.Text = ""
		card.AutoButtonColor = false
		card.LayoutOrder = n
		card.BackgroundColor3 = UITheme.Colors.PanelLight
		card.Parent = sf
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UITheme.CornerRadius
		corner.Parent = card
		local stroke = Instance.new("UIStroke")
		stroke.Color = UITheme.Colors.Orange
		stroke.Thickness = 2
		stroke.Transparency = if Profile.chapter() == n then 0 else 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = card
		local thumb = Instance.new("Frame")
		thumb.Position = UDim2.fromScale(0.05, 0.06)
		thumb.Size = UDim2.fromScale(0.9, 0.58)
		thumb.ClipsDescendants = true
		thumb.BorderSizePixel = 0
		thumb.Parent = card
		for _, r in CHAPTER_SCENES[n] do
			block(
				thumb,
				r[1],
				UDim2.fromScale(tonumber(r[2]) or 0, tonumber(r[3]) or 0),
				UDim2.fromScale(tonumber(r[4]) or 0, tonumber(r[5]) or 0)
			)
		end
		local name = text(
			card,
			string.format(Strings.ChapterLabel, n) .. "\n" .. (Strings.Chapters[n] or ""),
			UDim2.fromScale(0.9, 0.3),
			UDim2.fromScale(0.05, 0.67)
		)
		if not unlocked then
			local dim = block(card, "#000000", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
			dim.BackgroundTransparency = 0.45
			dim.ZIndex = 4
			local c2 = Instance.new("UICorner")
			c2.CornerRadius = UITheme.CornerRadius
			c2.Parent = dim
			padlock(card)
			name.TextColor3 = UITheme.Colors.TextDim
		end
		sounds(card)
		card.Activated:Connect(function()
			if unlocked then
				Profile.setChapter(n)
				for _, other in sf:GetChildren() do
					local st = other:FindFirstChildOfClass("UIStroke")
					if other:IsA("TextButton") and st then
						st.Transparency = if other == card then 0 else 1
					end
				end
			end
		end)
	end
end

local function endingsPage(host: Frame, s: number)
	pageTitle(host, Strings.Menu.Endings)
	local hint = text(
		host,
		Strings.Menu.EndingsHint,
		UDim2.new(1, -40, 0, 26),
		UDim2.fromOffset(20, 60),
		nil,
		UITheme.Colors.TextDim
	)
	hint.TextXAlignment = Enum.TextXAlignment.Left
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromOffset(16, 100)
	row.Size = UDim2.new(1, -32, 0, math.floor(260 * s))
	row.Parent = host
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0.03, 0)
	layout.Parent = row
	local list = {
		{ "dawn", Strings.Endings.Dawn, "#F4A86A" },
		{ "endless", Strings.Endings.EndlessNight, "#1A1A3A" },
		{ "sahur", Strings.Endings.Sahur, "#F0D090" },
	}
	for _, e in list do
		local owned = Profile.ownsEnding(e[1])
		local tile = Screen.panel(row, "Ending")
		tile.Size = UDim2.fromScale(0.3, 1)
		tile.BackgroundColor3 = if owned then Color3.fromHex(e[3]) else UITheme.Colors.PanelLight
		-- a blocky silhouette: a figure under a sun
		local fig = block(
			tile,
			if owned then "#2A1A10" else "#0A0A10",
			UDim2.fromScale(0.4, 0.3),
			UDim2.fromScale(0.2, 0.42)
		)
		fig.BackgroundTransparency = if owned then 0.2 else 0
		block(
			tile,
			if owned then "#2A1A10" else "#0A0A10",
			UDim2.fromScale(0.42, 0.18),
			UDim2.fromScale(0.16, 0.14)
		)
		local caption = text(
			tile,
			if owned then e[2] else Strings.Menu.Unknown,
			UDim2.fromScale(0.9, 0.18),
			UDim2.fromScale(0.05, 0.78),
			UITheme.Fonts.Title,
			if owned then UITheme.Colors.Text else UITheme.Colors.TextDim
		)
		caption.TextStrokeTransparency = 0.6
	end
end

local function achievementsPage(host: Frame, s: number)
	pageTitle(host, Strings.Achievements.PageTitle)
	local sf = scroller(host, 66)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = sf
	for i, def in Achievements.List do
		local owned = Profile.owns(def.id)
		local hidden = def.hidden and not owned
		local row = Screen.panel(sf, "Row")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, -12, 0, math.floor(64 * s))
		row.BackgroundColor3 = UITheme.Colors.PanelLight
		local bar = block(row, "#000000", UDim2.fromScale(0, 0), UDim2.new(0, 6, 1, 0))
		bar.BackgroundColor3 = UITheme.Rarity[def.rarity]
		local name = text(
			row,
			(if hidden then Strings.Achievements.Hidden else def.name)
				.. "  ·  "
				.. (Strings.Rarity[def.rarity] or def.rarity),
			UDim2.new(0.8, -20, 0.5, 0),
			UDim2.new(0, 16, 0, 2)
		)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = if owned then UITheme.Rarity[def.rarity] else UITheme.Colors.Text
		local desc = text(
			row,
			if hidden then Strings.Achievements.HiddenDescription else def.description,
			UDim2.new(0.8, -20, 0.45, 0),
			UDim2.new(0, 16, 0.5, 0),
			nil,
			UITheme.Colors.TextDim
		)
		desc.TextXAlignment = Enum.TextXAlignment.Left
		if owned then
			local mark = text(
				row,
				"✓",
				UDim2.new(0.15, 0, 0.8, 0),
				UDim2.fromScale(0.83, 0.1),
				nil,
				UITheme.Colors.Success
			)
			mark.Font = Enum.Font.GothamBold
		end
	end
end

local function slider(parent: Instance, label: string, key: string, order: number, s: number)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -12, 0, math.floor(60 * s))
	row.Parent = parent
	local name = text(row, label, UDim2.new(0.32, 0, 0.7, 0), UDim2.fromScale(0, 0.15))
	name.TextXAlignment = Enum.TextXAlignment.Left
	local track = Instance.new("TextButton")
	track.Text = ""
	track.AutoButtonColor = false
	track.BackgroundColor3 = UITheme.Colors.PanelLight
	track.Position = UDim2.fromScale(0.36, 0.3)
	track.Size = UDim2.fromScale(0.6, 0.4)
	track.Parent = row
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = track
	local fill = block(track, "#FF9A3C", UDim2.fromScale(0, 0), UDim2.fromScale(0, 1))
	local c2 = c:Clone()
	c2.Parent = fill
	local function show(v: number)
		fill.Size = UDim2.fromScale(math.clamp(v, 0, 1), 1)
	end
	show((Settings.get() :: any)[key] or 1)
	local dragging = false
	local function setFrom(x: number)
		local v =
			math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		v = math.floor(v * 20 + 0.5) / 20
		show(v)
		Settings.set(key, v)
	end
	track.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			setFrom(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			setFrom(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
end

local function toggle(
	parent: Instance,
	label: string,
	key: string,
	order: number,
	s: number,
	values: { any },
	names: { string }
)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -12, 0, math.floor(60 * s))
	row.Parent = parent
	local name = text(row, label, UDim2.new(0.32, 0, 0.7, 0), UDim2.fromScale(0, 0.15))
	name.TextXAlignment = Enum.TextXAlignment.Left
	local b = Screen.button(row, "Toggle", "", Vector2.new(140, 44))
	b.Position = UDim2.fromScale(0.36, 0)
	b.Size = UDim2.new(0.3, 0, 1, 0)
	local function refresh()
		local v = (Settings.get() :: any)[key]
		local idx = table.find(values, v) or 1
		b.Text = names[idx]
		b.TextColor3 = if idx == 1 then UITheme.Colors.Success else UITheme.Colors.TextDim
	end
	refresh()
	sounds(b)
	b.Activated:Connect(function()
		local v = (Settings.get() :: any)[key]
		local idx = table.find(values, v) or 1
		Settings.set(key, values[idx % #values + 1])
		refresh()
	end)
end

local function settingsPage(host: Frame, s: number)
	pageTitle(host, Strings.Menu.Settings)
	local sf = scroller(host, 66)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = sf
	local T = Strings.Settings
	slider(sf, T.MusicVolume, "musicVolume", 1, s)
	slider(sf, T.AmbienceVolume, "ambienceVolume", 2, s)
	slider(sf, T.SfxVolume, "sfxVolume", 3, s)
	slider(sf, T.VoiceVolume, "voiceVolume", 4, s)
	toggle(sf, T.Subtitles, "subtitles", 5, s, { true, false }, { T.On, T.Off })
	toggle(sf, T.Voices, "voices", 6, s, { true, false }, { T.On, T.Off })
	toggle(sf, T.CameraShake, "cameraShake", 7, s, { true, false }, { T.On, T.Off })
	toggle(sf, T.Graphics, "graphics", 8, s, { "high", "low" }, { T.GraphicsHigh, T.GraphicsLow })
end

local function creditsPage(host: Frame, s: number)
	pageTitle(host, Strings.Credits.Title)
	local sf = scroller(host, 66)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = sf
	local lines = {}
	for _, l in Strings.Story.Credits do
		table.insert(lines, l)
	end
	table.insert(lines, " ")
	for _, l in Strings.Credits.Lines do
		table.insert(lines, l)
	end
	for i, l in lines do
		local t = text(sf, l, UDim2.new(1, -20, 0, math.floor(34 * s)), UDim2.new())
		t.LayoutOrder = i
	end
	-- a slow scroll, like real credits
	task.spawn(function()
		while sf.Parent do
			sf.CanvasPosition = Vector2.new(0, sf.CanvasPosition.Y + 0.6)
			task.wait(1 / 30)
		end
	end)
end

local PAGES: { [string]: (Frame, number) -> () } = {
	chapters = chaptersPage,
	endings = endingsPage,
	achievements = achievementsPage,
	settings = settingsPage,
	credits = creditsPage,
}

local function showPage(name: string?)
	currentPage = name
	local host = clearPage()
	if not host then
		return
	end
	local buttons = buttonsFrame
	host.Visible = name ~= nil
	if buttons then
		buttons.Visible = name == nil or not isPortrait()
	end
	if not name then
		return
	end
	local builder = PAGES[name]
	if builder then
		builder(host, viewScale())
	end
	local back = Screen.button(host, "Back", Strings.Menu.Back, Vector2.new(120, 48))
	back.AnchorPoint = Vector2.new(1, 0)
	back.Position = UDim2.new(1, -12, 0, 10)
	back.Size = UDim2.fromOffset(math.floor(120 * viewScale()), math.floor(52 * viewScale()))
	back.TextScaled = true
	sounds(back)
	back.Activated:Connect(function()
		showPage(nil)
	end)
end

------------------------------------------------------------------ layout

local function layout()
	local s = viewScale()
	local portrait = isPortrait()
	local t = titleFrame
	local b = buttonsFrame
	local host = pageHost
	if t then
		local scale = t:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = if portrait then s * 0.62 else s * 0.82
		end
		t.AnchorPoint = if portrait then Vector2.new(0.5, 0) else Vector2.new(0, 0)
		t.Position = if portrait then UDim2.new(0.5, 0, 0.06, 0) else UDim2.new(0, 28, 0.06, 0)
	end
	if b then
		local scale = b:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = s
		end
		b.AnchorPoint = if portrait then Vector2.new(0.5, 0) else Vector2.new(0, 0)
		b.Position = if portrait then UDim2.new(0.5, 0, 0.26, 0) else UDim2.new(0, 28, 0.27, 0)
	end
	if host then
		host.Position = if portrait then UDim2.fromScale(0.03, 0.2) else UDim2.fromScale(0.35, 0.24)
		host.Size = if portrait then UDim2.fromScale(0.94, 0.74) else UDim2.fromScale(0.62, 0.68)
	end
	if currentPage then
		showPage(currentPage)
	end
end

------------------------------------------------------------------ open / close

local function play()
	if not open then
		return
	end
	open = false
	local g = gui
	if g then
		for _, d in g:GetDescendants() do
			if d:IsA("GuiObject") then
				TweenService:Create(d, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
				if d:IsA("TextLabel") or d:IsA("TextButton") then
					TweenService:Create(
						d,
						TweenInfo.new(0.6),
						{ TextTransparency = 1, TextStrokeTransparency = 1 }
					):Play()
				end
			end
		end
	end
	stopCamera(true)
	if g then
		g.Enabled = false
	end
	LobbyHud.show()
end

local function buildButtons(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Buttons"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromOffset(290, 6 * 70)
	frame.Parent = parent
	local scale = Instance.new("UIScale")
	scale.Parent = frame
	local items = {
		{ "play", Strings.Menu.Play },
		{ "chapters", Strings.Menu.Chapters },
		{ "endings", Strings.Menu.Endings },
		{ "achievements", Strings.Menu.Achievements },
		{ "settings", Strings.Menu.Settings },
		{ "credits", Strings.Menu.Credits },
	}
	for i, item in items do
		local b = Screen.button(frame, item[1], item[2], Vector2.new(280, 62))
		local y = (i - 1) * 70
		b.Position = UDim2.fromOffset(-340, y)
		b.TextSize = 28
		if item[1] == "play" then
			b.TextColor3 = UITheme.Colors.Orange
		end
		sounds(b)
		-- slide in from the left with a 0.06 s stagger
		task.delay(0.3 + (i - 1) * UITheme.Tween.ButtonStagger, function()
			TweenService:Create(
				b,
				TweenInfo.new(0.45, Enum.EasingStyle.Back),
				{ Position = UDim2.fromOffset(0, y) }
			):Play()
		end)
		b.Activated:Connect(function()
			if item[1] == "play" then
				task.spawn(play)
			else
				showPage(if currentPage == item[1] then nil else item[1])
			end
		end)
	end
	return frame
end

local function watchStare()
	local last = UserInputService:GetMouseLocation()
	local stillSince = os.clock()
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			stillSince = os.clock()
		end
	end)
	UserInputService.InputBegan:Connect(function()
		stillSince = os.clock()
	end)
	task.spawn(function()
		while not stareSent do
			task.wait(1)
			local now = UserInputService:GetMouseLocation()
			if (now - last).Magnitude > 2 then
				stillSince = os.clock()
				last = now
			end
			if open and giallinoFace and os.clock() - stillSince >= STARE_SECONDS then
				stareSent = true
				Remotes.get(Remotes.Names.LobbyStare):FireServer()
			end
			if not open then
				stillSince = os.clock()
			end
		end
	end)
end

function MainMenu.open()
	local g = Screen.gui("MainMenu", 30)
	gui = g
	g.Enabled = true
	open = true
	MusicDirector.setState("lobby")
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = g
	vignette(root)
	local t = buildTitle(root)
	local ts = Instance.new("UIScale")
	ts.Parent = t
	titleFrame = t
	buttonsFrame = buildButtons(root)
	local host = Screen.panel(root, "Page")
	host.Visible = false
	local stroke = Instance.new("UIStroke")
	stroke.Color = UITheme.Colors.Orange
	stroke.Thickness = 1
	stroke.Transparency = 0.6
	stroke.Parent = host
	pageHost = host
	layout()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
	end
	startCamera()
end

function MainMenu.init()
	Profile.Changed:Connect(function()
		-- the last ending arrives a moment after joining: the sun turns into Giallino then
		local t = titleFrame
		if t and open and Profile.lastEnding() == "endless" and not metaShown then
			local old = t:FindFirstChild("Sun")
			if old then
				old:Destroy()
			end
			buildSun(t)
		end
		if open and currentPage then
			showPage(currentPage)
		end
	end)
	watchStare()
	MainMenu.open()
end

return MainMenu
