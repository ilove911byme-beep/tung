--!strict
-- Death screen after CS-DEAD: "REVIVE - 45 R$" and "Spectate" (party) or "Retry from checkpoint"
-- (solo). Spectating follows a living teammate (click / tap to switch) until the next checkpoint.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local UITheme = require(Shared:WaitForChild("UITheme"))

local Screen = require(script.Parent:WaitForChild("Screen"))

local DeathUI = {}

local player = Players.LocalPlayer
local panel: Frame
local spectateBtn: TextButton
local retryBtn: TextButton
local spectating = false
local spectateIndex = 1
local showToken = 0

local function livingTeammates(): { Player }
	local out = {}
	for _, p in Players:GetPlayers() do
		if p ~= player and p:GetAttribute("LifeState") ~= "Dead" and p.Character then
			table.insert(out, p)
		end
	end
	return out
end

local function setSpectate(on: boolean)
	spectating = on
	local camera = workspace.CurrentCamera
	if not on then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

local function show(visible: boolean, solo: boolean)
	showToken += 1
	if not visible then
		panel.Visible = false
		setSpectate(false)
		return
	end
	local token = showToken
	-- CS-DEAD plays first (about 5 s)
	task.delay(5.2, function()
		if token ~= showToken then
			return
		end
		panel.Visible = true
		spectateBtn.Visible = not solo
		retryBtn.Visible = solo
	end)
end

function DeathUI.init()
	local gui = Screen.gui("Death", 80)
	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.BackgroundColor3 = Color3.new(0, 0, 0)
	panel.BackgroundTransparency = 0.35
	panel.Size = UDim2.fromScale(1, 1)
	panel.Visible = false
	panel.Parent = gui
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.fromScale(0.5, 0.22)
	title.Size = UDim2.fromOffset(700, 80)
	title.Font = UITheme.Fonts.Title
	title.TextSize = 48
	title.TextColor3 = UITheme.Colors.Danger
	title.Text = Strings.Health.Dead
	title.Parent = panel
	Screen.autoScale(title)
	local buttons = Instance.new("Frame")
	buttons.BackgroundTransparency = 1
	buttons.AnchorPoint = Vector2.new(0.5, 0.5)
	buttons.Position = UDim2.fromScale(0.5, 0.55)
	buttons.Size = UDim2.fromOffset(340, 220)
	buttons.Parent = panel
	Screen.autoScale(buttons)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 12)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = buttons
	local revive = Screen.button(
		buttons,
		"Revive",
		string.format(Strings.Health.Revive, Config.Revive.PriceRobux),
		Vector2.new(320, 64)
	)
	revive.BackgroundColor3 = Color3.fromRGB(60, 40, 10)
	revive.TextColor3 = UITheme.Colors.Giallino
	revive.Activated:Connect(function()
		Remotes.get(Remotes.Names.DeathChoice):FireServer("revive")
	end)
	spectateBtn = Screen.button(buttons, "Spectate", Strings.Health.Spectate, Vector2.new(320, 64))
	spectateBtn.Activated:Connect(function()
		Remotes.get(Remotes.Names.DeathChoice):FireServer("spectate")
		panel.Visible = false
		setSpectate(true)
	end)
	retryBtn =
		Screen.button(buttons, "Retry", Strings.Health.RetryFromCheckpoint, Vector2.new(320, 64))
	retryBtn.Activated:Connect(function()
		Remotes.get(Remotes.Names.DeathChoice):FireServer("retry")
		panel.Visible = false
	end)

	Remotes.get(Remotes.Names.DeathScreen).OnClientEvent:Connect(show)
	UserInputService.InputBegan:Connect(function(input, processed)
		if
			spectating
			and not processed
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			spectateIndex += 1
		end
	end)
	RunService.RenderStepped:Connect(function()
		if not spectating then
			return
		end
		local list = livingTeammates()
		if #list == 0 then
			return
		end
		local target = list[((spectateIndex - 1) % #list) + 1]
		local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and workspace.CurrentCamera.CameraSubject ~= humanoid then
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			workspace.CurrentCamera.CameraSubject = humanoid
		end
	end)
end

return DeathUI
