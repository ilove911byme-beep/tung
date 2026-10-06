--!strict
-- The lobby HUD after PLAY: the minecart panel while you sit in a cart (count and countdown,
-- Public / Friends only and Start now for the owner, Leave), the emote wheel (button or G),
-- the small aura list, achievement toasts and the first hint. Phone-friendly: every button is
-- at least 44 px after scaling.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Achievements = require(Shared:WaitForChild("Achievements"))
local Audio = require(Shared:WaitForChild("Audio"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local UITheme = require(Shared:WaitForChild("UITheme"))

local Client = script.Parent.Parent
local Screen = require(Client:WaitForChild("UI"):WaitForChild("Screen"))
local Emotes = require(script.Parent:WaitForChild("Emotes"))
local Launch = require(script.Parent:WaitForChild("Launch"))

local LobbyHud = {}

local gui: ScreenGui? = nil
local root: Frame? = nil
local cartPanel: Frame? = nil
local wheel: Frame? = nil
local auraList: Frame? = nil
local cartState: { [string]: any }? = nil
local cartIndex = 0

local function label(
	parent: Instance,
	text: string,
	size: UDim2,
	pos: UDim2,
	font: Enum.Font?
): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Font = font or UITheme.Fonts.Body
	l.TextColor3 = UITheme.Colors.Text
	l.TextScaled = true
	l.Text = text
	l.Parent = parent
	return l
end

local function click(button: TextButton, fn: () -> ())
	button.MouseEnter:Connect(function()
		Audio.play("vote_tick", nil, { volume = 0.4, group = "SFX" })
	end)
	button.Activated:Connect(function()
		Audio.play("item_pickup", nil, { volume = 0.5, group = "SFX" })
		fn()
	end)
end

local function toast(text: string, color: Color3)
	local g = gui
	if not g then
		return
	end
	local frame = Screen.panel(g, "Toast")
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, -90)
	frame.Size = UDim2.fromOffset(420, 70)
	Screen.autoScale(frame)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 2
	stroke.Parent = frame
	local l = label(frame, text, UDim2.new(1, -24, 1, -16), UDim2.fromOffset(12, 8))
	l.TextColor3 = color
	TweenService:Create(
		frame,
		TweenInfo.new(0.35, Enum.EasingStyle.Back),
		{ Position = UDim2.new(0.5, 0, 0, 24) }
	):Play()
	task.delay(4, function()
		TweenService:Create(frame, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 0, -90) })
			:Play()
		task.wait(0.35)
		frame:Destroy()
	end)
end

local function renderCart()
	local panel = cartPanel
	if not panel then
		return
	end
	local state = cartState
	panel.Visible = state ~= nil and not state.failed
	if not state or state.failed then
		return
	end
	local status = panel:FindFirstChild("Status") :: TextLabel?
	local now = workspace:GetServerTimeNow()
	if status then
		if state.launching then
			status.Text = Strings.Queue.Locked
		elseif state.endsAt then
			status.Text = string.format(
				Strings.Queue.Status,
				state.count,
				state.max,
				math.max(0, math.ceil(state.endsAt - now))
			)
		else
			status.Text = string.format(Strings.Queue.Waiting, state.count, state.max)
		end
	end
	local title = panel:FindFirstChild("Title") :: TextLabel?
	if title then
		title.Text = string.format(Strings.Queue.Cart, cartIndex)
	end
	local privacy = panel:FindFirstChild("Privacy") :: TextButton?
	local start = panel:FindFirstChild("Start") :: TextButton?
	local leave = panel:FindFirstChild("Leave") :: TextButton?
	if privacy then
		privacy.Visible = state.owner == true and not state.launching
		privacy.Text = if state.friendsOnly then Strings.Queue.FriendsOnly else Strings.Queue.Public
	end
	if start then
		start.Visible = state.owner == true and not state.launching
	end
	if leave then
		leave.Visible = not state.launching
	end
end

local function buildCartPanel(parent: Instance)
	local panel = Screen.panel(parent, "CartPanel")
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -16)
	panel.Size = UDim2.fromOffset(620, 150)
	panel.Visible = false
	Screen.autoScale(panel)
	local title =
		label(panel, "", UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, 8), UITheme.Fonts.Title)
	title.Name = "Title"
	title.TextColor3 = UITheme.Colors.Orange
	local status = label(panel, "", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 44))
	status.Name = "Status"
	local privacy = Screen.button(panel, "Privacy", Strings.Queue.Public, Vector2.new(190, 60))
	privacy.Position = UDim2.fromOffset(12, 82)
	click(privacy, function()
		local s = cartState
		if s then
			Remotes.get(Remotes.Names.LobbyCart)
				:FireServer(if s.friendsOnly then "public" else "friends")
		end
	end)
	local start = Screen.button(panel, "Start", Strings.Queue.StartNow, Vector2.new(190, 60))
	start.Position = UDim2.fromOffset(215, 82)
	start.TextColor3 = UITheme.Colors.Giallino
	click(start, function()
		Remotes.get(Remotes.Names.LobbyCart):FireServer("start")
	end)
	local leave = Screen.button(panel, "Leave", Strings.Queue.Leave, Vector2.new(190, 60))
	leave.Position = UDim2.fromOffset(418, 82)
	click(leave, function()
		Remotes.get(Remotes.Names.LobbyCart):FireServer("leave")
	end)
	cartPanel = panel
end

local EMOTE_NAMES: { [string]: string } = {
	["A-EMOTE_67"] = Strings.Lobby.Emote67,
	["A-EMOTE_AURA"] = Strings.Lobby.EmoteAura,
	["A-EMOTE_BRAINROT"] = Strings.Lobby.EmoteBrainrot,
	["A-EMOTE_BAT"] = Strings.Lobby.EmoteBat,
}

local function buildWheel(parent: Instance)
	local w = Instance.new("Frame")
	w.Name = "EmoteWheel"
	w.AnchorPoint = Vector2.new(0.5, 0.5)
	w.Position = UDim2.fromScale(0.5, 0.5)
	w.Size = UDim2.fromOffset(420, 420)
	w.BackgroundTransparency = 1
	w.Visible = false
	w.Parent = parent
	Screen.autoScale(w)
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromOffset(300, 300)
	ring.BackgroundColor3 = UITheme.Colors.Panel
	ring.BackgroundTransparency = 0.4
	ring.Parent = w
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = ring
	for i, id in Emotes.List do
		local a = (i - 1) / #Emotes.List * math.pi * 2 - math.pi / 2
		local b = Screen.button(w, "Emote" .. i, EMOTE_NAMES[id] or id, Vector2.new(170, 64))
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.new(0.5, math.cos(a) * 140, 0.5, math.sin(a) * 140)
		b.TextSize = 20
		click(b, function()
			Emotes.play(id)
			w.Visible = false
		end)
	end
	wheel = w
end

local function toggleWheel()
	local w = wheel
	if w then
		w.Visible = not w.Visible
	end
end

local function buildAura(parent: Instance)
	local panel = Screen.panel(parent, "AuraList")
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -16, 0, 70)
	panel.Size = UDim2.fromOffset(220, 150)
	panel.BackgroundTransparency = 0.4
	Screen.autoScale(panel)
	local title = label(
		panel,
		Strings.Lobby.AuraBoard,
		UDim2.new(1, -16, 0, 30),
		UDim2.fromOffset(8, 4),
		UITheme.Fonts.Title
	)
	title.TextColor3 = UITheme.Colors.Orange
	local list = Instance.new("Frame")
	list.Name = "Rows"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(8, 38)
	list.Size = UDim2.new(1, -16, 1, -44)
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	auraList = list
end

local function renderAura(rows: { { any } })
	local list = auraList
	if not list then
		return
	end
	for _, c in list:GetChildren() do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	for i, row in rows do
		if i > 3 then
			break
		end
		local l = label(
			list,
			string.format("%d. %s  %d", i, tostring(row[1]), tonumber(row[2]) or 0),
			UDim2.new(1, 0, 0, 34),
			UDim2.new()
		)
		l.LayoutOrder = i
		l.TextXAlignment = Enum.TextXAlignment.Left
	end
end

--- Shows the HUD (after the main menu's PLAY).
function LobbyHud.show()
	local r = root
	if not r then
		return
	end
	r.Visible = true
	local hint = label(r, Strings.Lobby.Hint, UDim2.new(0.6, 0, 0, 36), UDim2.new(0.2, 0, 0, 18))
	hint.TextStrokeTransparency = 0.5
	task.delay(10, function()
		TweenService
			:Create(hint, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 })
			:Play()
		task.wait(1.1)
		hint:Destroy()
	end)
end

function LobbyHud.hide()
	local r = root
	if r then
		r.Visible = false
	end
end

function LobbyHud.init()
	local g = Screen.gui("LobbyHud", 20)
	gui = g
	local r = Instance.new("Frame")
	r.Name = "Root"
	r.Size = UDim2.fromScale(1, 1)
	r.BackgroundTransparency = 1
	r.Visible = false
	r.Parent = g
	root = r
	buildCartPanel(r)
	buildWheel(r)
	buildAura(r)
	local emoteButton = Screen.button(r, "EmoteButton", Strings.Lobby.Emotes, Vector2.new(150, 60))
	emoteButton.AnchorPoint = Vector2.new(0, 1)
	emoteButton.Position = UDim2.new(0, 16, 1, -16)
	Screen.autoScale(emoteButton)
	click(emoteButton, toggleWheel)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and input.KeyCode == Enum.KeyCode.G and r.Visible then
			toggleWheel()
		end
	end)
	Remotes.get(Remotes.Names.LobbyCartState).OnClientEvent
		:Connect(function(index: number, state: { [string]: any }?)
			cartIndex = index
			cartState = state
			if state and state.failed then
				Launch.cancel()
				toast(
					if RunService:IsStudio()
						then Strings.Lobby.StudioNoTeleport
						else Strings.Lobby.TeleportFailed,
					UITheme.Colors.Danger
				)
			end
			renderCart()
		end)
	Remotes.get(Remotes.Names.LobbyToast).OnClientEvent:Connect(function(id: string)
		local def = Achievements.ById[id]
		if def then
			toast(Strings.Achievements.ToastTitle .. ": " .. def.name, UITheme.Rarity[def.rarity])
			Audio.play("xp_orb_pickup", nil, { volume = 0.7, group = "SFX" })
		end
	end)
	Remotes.get(Remotes.Names.LobbyAura).OnClientEvent:Connect(renderAura)
	Launch.Started:Connect(function()
		local w = wheel
		if w then
			w.Visible = false
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			renderCart()
		end
	end)
end

return LobbyHud
