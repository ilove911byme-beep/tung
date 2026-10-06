--!strict
-- Dialogue box (brief, gameplay system 4): speaker name + portrait color + typewriter text, with
-- the voice from VoiceService. Choices are party votes (VoteUI).
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local UITheme = require(Shared:WaitForChild("UITheme"))
local VoiceLines = require(Shared:WaitForChild("VoiceLines"))

local Screen = require(script.Parent:WaitForChild("Screen"))
local VoiceService =
	require(script.Parent.Parent:WaitForChild("Audio"):WaitForChild("VoiceService"))

local DialogueUI = {}

local panel: Frame
local portrait: Frame
local nameLabel: TextLabel
local textLabel: TextLabel
local token = 0

local function speakerModel(speaker: string): Model?
	for _, m in game:GetService("CollectionService"):GetTagged("NPC") do
		if m:IsA("Model") and m:GetAttribute("CharacterId") == speaker then
			return m
		end
	end
	return nil
end

local function show(lineId: string, tokens: { [string]: string }?)
	local line = VoiceLines.get(lineId)
	if not line then
		return
	end
	token += 1
	local myToken = token
	local text = VoiceService.personalize(line.text, tokens)
	local color = UITheme.Speaker[line.speaker :: any] or UITheme.Colors.Text
	portrait.BackgroundColor3 = color
	nameLabel.Text = Strings.Speakers[line.speaker] or line.speaker
	nameLabel.TextColor3 = color
	textLabel.Text = text
	textLabel.MaxVisibleGraphemes = 0
	panel.Visible = true
	VoiceService.say(
		lineId,
		{ speakerModel = speakerModel(line.speaker), tokens = tokens, noSubtitle = true }
	)
	local total = utf8.len(text) or #text
	task.spawn(function()
		local start = os.clock()
		while token == myToken do
			local n = math.floor((os.clock() - start) * Config.Voice.SubtitleCharsPerSecond)
			textLabel.MaxVisibleGraphemes = math.min(n, total)
			if n >= total then
				break
			end
			RunService.RenderStepped:Wait()
		end
	end)
	task.delay(total / Config.Voice.SubtitleCharsPerSecond + 4, function()
		if token == myToken then
			panel.Visible = false
		end
	end)
end

function DialogueUI.init()
	local gui = Screen.gui("Dialogue", 55)
	panel = Screen.panel(gui, "Box")
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -110)
	panel.Size = UDim2.new(0.9, 0, 0, 120)
	panel.Visible = false
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(820, 160)
	constraint.Parent = panel
	Screen.autoScale(panel)
	portrait = Instance.new("Frame")
	portrait.Name = "Portrait"
	portrait.Position = UDim2.fromOffset(12, 12)
	portrait.Size = UDim2.fromOffset(96, 96)
	portrait.BorderSizePixel = 0
	portrait.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UITheme.CornerRadius
	corner.Parent = portrait
	nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(122, 8)
	nameLabel.Size = UDim2.new(1, -134, 0, 28)
	nameLabel.Font = UITheme.Fonts.Body
	nameLabel.TextSize = 22
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = panel
	textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.fromOffset(122, 38)
	textLabel.Size = UDim2.new(1, -134, 1, -46)
	textLabel.Font = UITheme.Fonts.Body
	textLabel.TextSize = 20
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.TextColor3 = UITheme.Colors.Text
	textLabel.Parent = panel
	Remotes.get(Remotes.Names.DialogueLine).OnClientEvent:Connect(show)
	Remotes.get(Remotes.Names.DialogueEnd).OnClientEvent:Connect(function()
		token += 1
		task.delay(1.5, function()
			panel.Visible = false
		end)
	end)
end

return DialogueUI
