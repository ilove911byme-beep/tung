--!strict
-- Full-screen story moments that are UI rather than 3D:
--   oldScreen  (CS-16 shot 7): an old game's screen "WILL YOU COME BACK TOMORROW? [YES] [NO]",
--              a cursor clicks NO and the screen powers off
--   nameRoll   (CS-E3 shot 10): the villagers' names roll across the screen like subtitles
--   credits    (after every ending): the ending's title, the cast and "thanks for playing"
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local UITheme = require(Shared:WaitForChild("UITheme"))

local StoryScreens = {}

local function screenGui(name: string, order: number): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = order
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

local function label(
	parent: Instance,
	text: string,
	size: UDim2,
	pos: UDim2,
	font: Enum.Font,
	color: Color3,
	maxSize: number?
): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Size = size
	l.Position = pos
	l.Font = font
	l.TextColor3 = color
	l.TextScaled = true
	l.TextWrapped = true
	l.Text = text
	l.Parent = parent
	if maxSize then
		local c = Instance.new("UITextSizeConstraint")
		c.MaxTextSize = maxSize
		c.Parent = l
	end
	return l
end

function StoryScreens.oldScreen(duration: number)
	local gui = screenGui("OldScreen", 950)
	local bezel = Instance.new("Frame")
	bezel.AnchorPoint = Vector2.new(0.5, 0.5)
	bezel.Position = UDim2.fromScale(0.5, 0.5)
	bezel.Size = UDim2.fromScale(0.62, 0.62)
	bezel.BackgroundColor3 = Color3.fromRGB(48, 46, 44)
	bezel.BorderSizePixel = 0
	bezel.Parent = gui
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 4 / 3
	aspect.Parent = bezel
	local screen = Instance.new("Frame")
	screen.AnchorPoint = Vector2.new(0.5, 0.5)
	screen.Position = UDim2.fromScale(0.5, 0.5)
	screen.Size = UDim2.fromScale(0.86, 0.82)
	screen.BackgroundColor3 = Color3.fromRGB(16, 30, 22)
	screen.BorderSizePixel = 0
	screen.Parent = bezel
	label(
		screen,
		Strings.Story.OldScreenQuestion,
		UDim2.fromScale(0.9, 0.3),
		UDim2.fromScale(0.5, 0.32),
		Enum.Font.Arcade,
		Color3.fromRGB(150, 255, 170),
		48
	)
	label(
		screen,
		"[ YES ]",
		UDim2.fromScale(0.3, 0.14),
		UDim2.fromScale(0.32, 0.68),
		Enum.Font.Arcade,
		Color3.fromRGB(150, 255, 170),
		40
	)
	local no = label(
		screen,
		"[ NO ]",
		UDim2.fromScale(0.3, 0.14),
		UDim2.fromScale(0.68, 0.68),
		Enum.Font.Arcade,
		Color3.fromRGB(150, 255, 170),
		40
	)
	local cursor = label(
		screen,
		"▲",
		UDim2.fromScale(0.06, 0.08),
		UDim2.fromScale(0.45, 0.92),
		Enum.Font.Arcade,
		Color3.fromRGB(255, 255, 255),
		30
	)
	cursor.Rotation = -20
	task.spawn(function()
		task.wait(duration * 0.3)
		TweenService:Create(
			cursor,
			TweenInfo.new(duration * 0.15, Enum.EasingStyle.Quad),
			{ Position = UDim2.fromScale(0.71, 0.74) }
		):Play()
		task.wait(duration * 0.2)
		no.TextColor3 = Color3.fromRGB(10, 20, 14)
		no.BackgroundTransparency = 0
		no.BackgroundColor3 = Color3.fromRGB(150, 255, 170)
		task.wait(duration * 0.15)
		-- power off: the picture collapses into a line, then a dot
		for _, c in screen:GetChildren() do
			if c:IsA("TextLabel") then
				c.Visible = false
			end
		end
		screen.BackgroundColor3 = Color3.fromRGB(220, 255, 230)
		TweenService:Create(screen, TweenInfo.new(0.25), { Size = UDim2.fromScale(0.86, 0.01) })
			:Play()
		task.wait(0.3)
		TweenService:Create(
			screen,
			TweenInfo.new(0.2),
			{ Size = UDim2.fromScale(0.01, 0.01), BackgroundColor3 = Color3.fromRGB(0, 0, 0) }
		):Play()
		task.wait(duration * 0.2)
		gui:Destroy()
	end)
end

function StoryScreens.nameRoll(names: { string }, duration: number)
	local gui = screenGui("NameRoll", 900)
	local step = duration / math.max(#names, 1)
	task.spawn(function()
		for _, name in names do
			local l = label(
				gui,
				name,
				UDim2.new(0.6, 0, 0, 44),
				UDim2.fromScale(0.5, 0.78),
				UITheme.Fonts.Body,
				UITheme.Colors.Giallino,
				40
			)
			l.TextTransparency = 1
			l.TextStrokeTransparency = 0.6
			TweenService:Create(
				l,
				TweenInfo.new(step * 0.3),
				{ TextTransparency = 0, Position = UDim2.fromScale(0.5, 0.74) }
			):Play()
			task.wait(step * 0.8)
			TweenService:Create(l, TweenInfo.new(step * 0.2), { TextTransparency = 1 }):Play()
			task.wait(step * 0.2)
			l:Destroy()
		end
		gui:Destroy()
	end)
end

function StoryScreens.credits(ending: string, duration: number)
	local gui = screenGui("Credits", 960)
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = UITheme.Colors.Black
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.Parent = gui
	TweenService:Create(bg, TweenInfo.new(1.5), { BackgroundTransparency = 0 }):Play()
	local titles = Strings.Story.EndingTitles :: { [string]: string }
	local roll = Instance.new("Frame")
	roll.BackgroundTransparency = 1
	roll.AnchorPoint = Vector2.new(0.5, 0)
	roll.Size = UDim2.fromScale(0.8, 2.2)
	roll.Position = UDim2.fromScale(0.5, 1)
	roll.Parent = bg
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0.01, 0)
	layout.Parent = roll
	local function line(text: string, big: boolean)
		local l = label(
			roll,
			text,
			UDim2.fromScale(1, if big then 0.07 else 0.035),
			UDim2.fromScale(0.5, 0),
			if big then UITheme.Fonts.Title else UITheme.Fonts.Body,
			if big then UITheme.Colors.Orange else UITheme.Colors.Text,
			if big then 72 else 30
		)
		l.AnchorPoint = Vector2.new(0.5, 0)
	end
	line(titles[ending] or "THE END", true)
	line(Strings.GameTitle, false)
	line(" ", false)
	for _, row in Strings.Story.Credits :: { string } do
		line(row, false)
	end
	line(" ", false)
	line(Strings.Story.ThanksForPlaying, true)
	TweenService:Create(
		roll,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ Position = UDim2.fromScale(0.5, -1.4) }
	):Play()
	task.delay(duration + 1, function()
		TweenService:Create(bg, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
		task.wait(1.3)
		gui:Destroy()
	end)
end

return StoryScreens
