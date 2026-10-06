--!strict
-- Subtitles at the bottom center: speaker name in the speaker's color + typewriter text.
-- An optional per-letter callback lets Giallino "talk" with blips.
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Strings = require(Shared:WaitForChild("Strings"))
local UITheme = require(Shared:WaitForChild("UITheme"))

local Settings = require(script.Parent.Parent:WaitForChild("Settings"))
local Screen = require(script.Parent:WaitForChild("Screen"))

local Subtitles = {}

local panel: Frame? = nil
local label: TextLabel? = nil
local token = 0

local function ensure(): (Frame, TextLabel)
	if panel and label then
		return panel, label
	end
	local screen = Screen.gui("Subtitles", 60)
	local p = Screen.panel(screen, "Panel")
	p.AnchorPoint = Vector2.new(0.5, 1)
	p.Position = UDim2.new(0.5, 0, 0.87, 0)
	p.Size = UDim2.new(0.92, 0, 0, 0)
	p.AutomaticSize = Enum.AutomaticSize.Y
	p.BackgroundTransparency = 0.35
	p.Visible = false
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(860, math.huge)
	constraint.Parent = p
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UITheme.Padding
	padding.PaddingBottom = UITheme.Padding
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.Parent = p
	Screen.autoScale(p)
	local l = Instance.new("TextLabel")
	l.Name = "Text"
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, 0)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.Font = UITheme.Fonts.Body
	l.TextSize = 24
	l.TextWrapped = true
	l.RichText = true
	l.TextColor3 = UITheme.Colors.Text
	l.TextXAlignment = Enum.TextXAlignment.Center
	l.Parent = p
	panel = p
	label = l
	return p, l
end

local function escape(text: string): string
	return (string.gsub(string.gsub(string.gsub(text, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
end

--- Shows a line. Returns how long it stays on screen (typing + hold).
function Subtitles.show(speaker: string, text: string, onLetter: ((number) -> ())?): number
	token += 1
	local myToken = token
	local typing = utf8.len(text) or #text
	local typeTime = typing / Config.Voice.SubtitleCharsPerSecond
	local total = typeTime + Config.Voice.SubtitleHoldSeconds + typing * 0.02
	if not Settings.get().subtitles then
		-- still "type" for the blips, just do not show
		if onLetter then
			task.spawn(function()
				for i = 1, typing do
					if token ~= myToken then
						return
					end
					onLetter(i)
					task.wait(1 / Config.Voice.SubtitleCharsPerSecond)
				end
			end)
		end
		return total
	end
	local p, l = ensure()
	local color = UITheme.Speaker[speaker :: any] or UITheme.Colors.Text
	local name = Strings.Speakers[speaker] or speaker
	local prefix = string.format('<font color="#%s">%s</font>: ', color:ToHex(), escape(name))
	l.Text = prefix .. escape(text)
	local prefixLength = (utf8.len(name) or #name) + 2
	l.MaxVisibleGraphemes = prefixLength
	p.Visible = true
	task.spawn(function()
		local shown = 0
		local start = os.clock()
		while token == myToken and shown < typing do
			local target = math.min(
				typing,
				math.floor((os.clock() - start) * Config.Voice.SubtitleCharsPerSecond)
			)
			while shown < target do
				shown += 1
				if onLetter then
					onLetter(shown)
				end
			end
			l.MaxVisibleGraphemes = prefixLength + shown
			RunService.RenderStepped:Wait()
		end
		if token == myToken then
			l.MaxVisibleGraphemes = -1
		end
	end)
	task.delay(total, function()
		if token == myToken then
			p.Visible = false
		end
	end)
	return total
end

function Subtitles.clear()
	token += 1
	if panel then
		panel.Visible = false
	end
end

return Subtitles
