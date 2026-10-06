--!strict
-- Gameplay HUD: 10 blocky hearts, objective, timer, 4-slot hotbar (keys 1-4 or tap), toasts
-- (achievements in their rarity color, "+100 AURA", info), boss intro cards and Memory Pages.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Achievements = require(Shared:WaitForChild("Achievements"))
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))
local Items = require(Shared:WaitForChild("StoryData"):WaitForChild("Items"))
local MemoryPages = require(Shared:WaitForChild("StoryData"):WaitForChild("MemoryPages"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local UITheme = require(Shared:WaitForChild("UITheme"))

local Screen = require(script.Parent:WaitForChild("Screen"))

local Hud = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local hearts: { Frame } = {}
local objectiveLabel: TextLabel
local timerLabel: TextLabel
local timerEndsAt = 0
local hotbar: { TextButton } = {}
local toastList: Frame
local root: Frame
local voiceSay: ((lineId: string) -> ())? = nil

local function label(parent: Instance, name: string, size: UDim2, textSize: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = size
	l.Font = UITheme.Fonts.Body
	l.TextSize = textSize
	l.TextColor3 = UITheme.Colors.Text
	l.TextStrokeTransparency = 0.5
	l.TextWrapped = true
	l.Parent = parent
	return l
end

local function buildHearts(parent: Frame)
	local row = Instance.new("Frame")
	row.Name = "Hearts"
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0, 1)
	row.Position = UDim2.new(0, 20, 1, -20)
	row.Size = UDim2.fromOffset(10 * 30, 28)
	row.Parent = parent
	Screen.autoScale(row)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 2)
	layout.Parent = row
	for i = 1, Config.Health.HeartCount do
		local heart = Instance.new("Frame")
		heart.Name = "Heart" .. i
		heart.Size = UDim2.fromOffset(28, 28)
		heart.BackgroundColor3 = Color3.fromRGB(60, 10, 14)
		heart.BorderSizePixel = 0
		heart.LayoutOrder = i
		heart.Parent = row
		-- blocky heart: two top squares + a lower block, filled frame inside
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BackgroundColor3 = Color3.fromRGB(220, 40, 50)
		fill.BorderSizePixel = 0
		fill.Size = UDim2.fromScale(1, 1)
		fill.Parent = heart
		local notch = Instance.new("Frame")
		notch.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		notch.BackgroundTransparency = 1
		notch.BorderSizePixel = 0
		notch.Size = UDim2.fromScale(0.25, 0.25)
		notch.Position = UDim2.fromScale(0.375, 0)
		notch.Parent = heart
		local shine = Instance.new("Frame")
		shine.BackgroundColor3 = Color3.fromRGB(255, 160, 160)
		shine.BorderSizePixel = 0
		shine.Size = UDim2.fromScale(0.22, 0.22)
		shine.Position = UDim2.fromScale(0.14, 0.14)
		shine.Parent = fill
		table.insert(hearts, heart)
	end
end

local function refreshHearts()
	local hp = (player:GetAttribute("HP") :: number?) or Config.Health.MaxHealth
	local per = Config.Health.MaxHealth / Config.Health.HeartCount
	for i, heart in hearts do
		local fill = heart:FindFirstChild("Fill") :: Frame?
		if fill then
			local amount = math.clamp((hp - (i - 1) * per) / per, 0, 1)
			fill.Size = UDim2.fromScale(amount, 1)
		end
	end
end

local function buildHotbar(parent: Frame)
	local bar = Instance.new("Frame")
	bar.Name = "Hotbar"
	bar.BackgroundTransparency = 1
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -16)
	bar.Size = UDim2.fromOffset(4 * 70 + 3 * 8, 70)
	bar.Parent = parent
	Screen.autoScale(bar)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.Parent = bar
	for i = 1, Config.Inventory.MaxSlots do
		local slot = Instance.new("TextButton")
		slot.Name = "Slot" .. i
		slot.LayoutOrder = i
		slot.Size = UDim2.fromOffset(70, 70)
		slot.BackgroundColor3 = UITheme.Colors.Panel
		slot.BackgroundTransparency = UITheme.Transparency.Panel
		slot.AutoButtonColor = true
		slot.Font = UITheme.Fonts.Body
		slot.TextSize = 13
		slot.TextWrapped = true
		slot.TextColor3 = UITheme.Colors.Text
		slot.Text = ""
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UITheme.CornerRadius
		corner.Parent = slot
		local key = label(slot, "Key", UDim2.fromOffset(18, 18), 12)
		key.Text = tostring(i)
		key.TextColor3 = UITheme.Colors.TextDim
		local swatch = Instance.new("Frame")
		swatch.Name = "Swatch"
		swatch.AnchorPoint = Vector2.new(0.5, 0)
		swatch.Position = UDim2.new(0.5, 0, 0, 8)
		swatch.Size = UDim2.fromOffset(26, 26)
		swatch.BorderSizePixel = 0
		swatch.Visible = false
		swatch.Parent = slot
		local count = label(slot, "Count", UDim2.fromOffset(30, 18), 14)
		count.AnchorPoint = Vector2.new(1, 1)
		count.Position = UDim2.new(1, -4, 1, -2)
		count.TextXAlignment = Enum.TextXAlignment.Right
		count.Text = ""
		slot.Parent = bar
		slot.Activated:Connect(function()
			Remotes.get(Remotes.Names.UseItem):FireServer(i)
		end)
		table.insert(hotbar, slot)
	end
end

local function refreshHotbar(slots: { { id: string, count: number } })
	for i, button in hotbar do
		local s = slots[i]
		local swatch = button:FindFirstChild("Swatch") :: Frame?
		local count = button:FindFirstChild("Count") :: TextLabel?
		if s and Items[s.id] then
			local def = Items[s.id]
			button.Text = "\n\n" .. def.name
			if swatch then
				swatch.Visible = true
				swatch.BackgroundColor3 = def.color
			end
			if count then
				count.Text = if s.count > 1 then tostring(s.count) else ""
			end
		else
			button.Text = ""
			if swatch then
				swatch.Visible = false
			end
			if count then
				count.Text = ""
			end
		end
	end
end

local function toast(text: string, color: Color3, glitchy: boolean?)
	local frame = Screen.panel(toastList, "Toast")
	frame.Size = UDim2.fromOffset(320, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2
	stroke.Parent = frame
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = frame
	local l = label(frame, "Text", UDim2.new(1, 0, 0, 0), 18)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.RichText = true
	l.Text = text
	l.TextColor3 = color
	if glitchy then
		task.spawn(function()
			local original = text
			for _ = 1, 10 do
				local chars = {}
				for c in string.gmatch(original, ".") do
					table.insert(
						chars,
						if math.random() < 0.15 then string.char(math.random(33, 63)) else c
					)
				end
				l.Text = table.concat(chars)
				task.wait(0.06)
			end
			l.Text = original
		end)
	end
	task.delay(4, function()
		TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.wait(0.45)
		frame:Destroy()
	end)
end

local function auraPop(amount: number)
	local l = label(root, "Aura", UDim2.fromOffset(300, 50), 34)
	l.Font = UITheme.Fonts.Title
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, 0.42)
	l.Text = if amount >= 0
		then string.format(Strings.Aura.Gain, amount)
		else string.format(Strings.Aura.Loss, -amount)
	l.TextColor3 = if amount >= 0 then Color3.fromRGB(170, 120, 255) else UITheme.Colors.Danger
	TweenService:Create(l, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.34),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(1.3, function()
		l:Destroy()
	end)
end

local function bossCard(title: string, subtitle: string, signature: string)
	local card = Instance.new("Frame")
	card.Name = "BossCard"
	card.BackgroundColor3 = Color3.new(0, 0, 0)
	card.Size = UDim2.fromScale(1, 1)
	card.ZIndex = 20
	card.Parent = gui
	local t = label(card, "Title", UDim2.new(1, 0, 0, 90), 72)
	t.Font = UITheme.Fonts.Title
	t.Position = UDim2.fromScale(0, 0.38)
	t.Text = title
	t.TextColor3 = UITheme.Colors.Orange
	t.ZIndex = 21
	local s = label(card, "Subtitle", UDim2.new(1, 0, 0, 40), 28)
	s.Position = UDim2.fromScale(0, 0.52)
	s.Text = subtitle
	s.Font = Enum.Font.FredokaOne
	s.TextColor3 = UITheme.Colors.TextDim
	s.ZIndex = 21
	Audio.play(signature, nil, { volume = 0.9 })
	task.delay(2.6, function()
		TweenService:Create(card, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(t, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		TweenService:Create(s, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		task.wait(0.55)
		card:Destroy()
	end)
end

local function memoryPage(pageId: string)
	local page = nil
	for _, p in MemoryPages do
		if p.id == pageId then
			page = p
		end
	end
	if not page then
		return
	end
	local panel = Screen.panel(gui, "MemoryPage")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.45)
	panel.Size = UDim2.fromOffset(520, 260)
	panel.BackgroundColor3 = Color3.fromRGB(235, 222, 190)
	panel.BackgroundTransparency = 0.05
	panel.ZIndex = 15
	Screen.autoScale(panel)
	local head = label(panel, "Head", UDim2.new(1, 0, 0, 40), 24)
	head.Text = Strings.Hud.Memory .. " " .. page.id
	head.TextColor3 = Color3.fromRGB(90, 60, 30)
	head.TextStrokeTransparency = 1
	head.ZIndex = 16
	local body = label(panel, "Body", UDim2.new(1, -40, 1, -60), 22)
	body.Position = UDim2.fromOffset(20, 48)
	body.Text = page.text
	body.TextColor3 = Color3.fromRGB(50, 35, 20)
	body.TextStrokeTransparency = 1
	body.ZIndex = 16
	if voiceSay then
		voiceSay("MEM_" .. pageId)
	end
	task.delay(8, function()
		panel:Destroy()
	end)
end

function Hud.setVoice(fn: (lineId: string) -> ())
	voiceSay = fn
end

function Hud.init()
	gui = Screen.gui("Hud", 20)
	root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui

	buildHearts(root)
	buildHotbar(root)

	objectiveLabel = label(root, "Objective", UDim2.fromOffset(520, 60), 22)
	objectiveLabel.AnchorPoint = Vector2.new(0.5, 0)
	objectiveLabel.Position = UDim2.new(0.5, 0, 0, 16)
	objectiveLabel.TextColor3 = UITheme.Colors.Orange
	objectiveLabel.Text = ""
	Screen.autoScale(objectiveLabel)

	timerLabel = label(root, "Timer", UDim2.fromOffset(160, 44), 34)
	timerLabel.AnchorPoint = Vector2.new(0.5, 0)
	timerLabel.Position = UDim2.new(0.5, 0, 0, 70)
	timerLabel.Font = UITheme.Fonts.Title
	timerLabel.Text = ""
	Screen.autoScale(timerLabel)

	toastList = Instance.new("Frame")
	toastList.Name = "Toasts"
	toastList.BackgroundTransparency = 1
	toastList.AnchorPoint = Vector2.new(1, 0)
	toastList.Position = UDim2.new(1, -16, 0, 16)
	toastList.Size = UDim2.fromOffset(320, 400)
	toastList.Parent = root
	Screen.autoScale(toastList)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = toastList

	player:GetAttributeChangedSignal("HP"):Connect(refreshHearts)
	refreshHearts()

	Remotes.get(Remotes.Names.Objective).OnClientEvent:Connect(function(text: string)
		objectiveLabel.Text = text or ""
	end)
	Remotes.get(Remotes.Names.Timer).OnClientEvent:Connect(function(endsAt: number)
		timerEndsAt = endsAt or 0
	end)
	Remotes.get(Remotes.Names.InventoryUpdate).OnClientEvent:Connect(refreshHotbar)
	Remotes.get(Remotes.Names.Toast).OnClientEvent:Connect(function(kind: string, data: any)
		if kind == "achievement" then
			local def = Achievements.ById[data.id]
			if def then
				local color = UITheme.Rarity[def.rarity]
				local text = string.format(
					"<b>%s</b>\n%s · %s",
					Strings.Achievements.ToastTitle,
					def.name,
					Strings.Rarity[def.rarity]
				)
				toast(text, color, def.rarity == "Secret")
				Audio.play("xp_orb_pickup", nil, { volume = 0.7 })
			end
		elseif kind == "aura" then
			auraPop(data.amount)
		elseif kind == "info" then
			toast(data.text, UITheme.Colors.Text)
		end
	end)
	Remotes.get(Remotes.Names.BossCard).OnClientEvent:Connect(bossCard)
	Remotes.get(Remotes.Names.MemoryPage).OnClientEvent:Connect(memoryPage)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		-- number keys belong to the vote buttons while a vote is open
		local voteGui = player.PlayerGui:FindFirstChild("Vote")
		if voteGui and voteGui:FindFirstChild("Vote") then
			return
		end
		local keys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }
		for i, k in keys do
			if input.KeyCode == k then
				Remotes.get(Remotes.Names.UseItem):FireServer(i)
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		root.Visible = not player:GetAttribute("InCutscene")
		if timerEndsAt > 0 then
			local left = math.max(0, math.ceil(timerEndsAt - workspace:GetServerTimeNow()))
			timerLabel.Text = tostring(left)
			timerLabel.TextColor3 = if left <= 10
				then UITheme.Colors.Danger
				else UITheme.Colors.Text
		else
			timerLabel.Text = ""
		end
	end)
end

return Hud
