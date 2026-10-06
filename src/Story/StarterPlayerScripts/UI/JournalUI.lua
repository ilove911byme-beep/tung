--!strict
-- Journal (J key or the button): tabs Clues (real + fake with "?"), Suspects, Memories (the 12
-- Memory Pages) and Names (Tung Tung's list; "Read aloud" awards SAY_THEIR_NAMES).
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Clues = require(Shared:WaitForChild("StoryData"):WaitForChild("Clues"))
local MemoryPages = require(Shared:WaitForChild("StoryData"):WaitForChild("MemoryPages"))
local NamesList = require(Shared:WaitForChild("StoryData"):WaitForChild("NamesList"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local Suspects = require(Shared:WaitForChild("StoryData"):WaitForChild("Suspects"))
local UITheme = require(Shared:WaitForChild("UITheme"))

local Screen = require(script.Parent:WaitForChild("Screen"))

local JournalUI = {}

type State = { clues: { [string]: boolean }, memories: { [string]: boolean }, names: { string } }

local state: State = { clues = {}, memories = {}, names = {} }
local panel: Frame
local content: ScrollingFrame
local tab = "Clues"

local function entry(title: string, body: string, color: Color3?)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = UITheme.Colors.PanelLight
	f.BackgroundTransparency = 0.2
	f.Size = UDim2.new(1, -8, 0, 0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = f
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = f
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, 0)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.Font = UITheme.Fonts.Body
	l.TextSize = 18
	l.TextWrapped = true
	l.RichText = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = color or UITheme.Colors.Text
	l.Text = string.format("<b>%s</b>\n%s", title, body)
	l.Parent = f
	f.Parent = content
end

local function render()
	for _, c in content:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	if tab == "Clues" then
		for _, clue in Clues do
			if state.clues[clue.id] then
				local unverified = clue.fake
					and not (clue.debunkedBy and state.clues[clue.debunkedBy])
				local debunked = clue.fake and not unverified
				local title = clue.number .. ". " .. clue.title
				if unverified then
					title = title .. " " .. Strings.Journal.Unverified
				elseif debunked then
					title = "<s>" .. title .. "</s>"
				end
				entry(title, clue.text, if clue.fake then UITheme.Colors.TextDim else nil)
			end
		end
	elseif tab == "Suspects" then
		for _, s in Suspects do
			local found = 0
			for _, id in s.clues do
				if state.clues[id] then
					found += 1
				end
			end
			entry(s.name, string.format("%s (%d)", s.note, found))
		end
	elseif tab == "Memories" then
		for _, page in MemoryPages do
			if state.memories[page.id] then
				entry(page.id, page.text)
			else
				entry(page.id, Strings.Menu.Unknown, UITheme.Colors.TextDim)
			end
		end
	elseif tab == "Names" then
		if #state.names == 0 then
			entry(Strings.Journal.TabNames, Strings.Menu.Unknown, UITheme.Colors.TextDim)
		else
			entry(
				Strings.Journal.TabNames,
				table.concat(state.names, "\n") .. "\n\n" .. NamesList.footer
			)
			local read =
				Screen.button(content, "ReadAloud", Strings.Journal.ReadAloud, Vector2.new(220, 50))
			read.Activated:Connect(function()
				Remotes.get(Remotes.Names.JournalRead):FireServer("names")
			end)
		end
	end
end

local function toggle()
	panel.Visible = not panel.Visible
	if panel.Visible then
		render()
	end
end

function JournalUI.init()
	local gui = Screen.gui("Journal", 40)
	local open =
		Screen.button(gui, "OpenJournal", Strings.Journal.Title .. " (J)", Vector2.new(150, 60))
	open.AnchorPoint = Vector2.new(1, 1)
	open.Position = UDim2.new(1, -16, 1, -16)
	open.TextSize = 18
	Screen.autoScale(open)
	open.Activated:Connect(toggle)

	panel = Screen.panel(gui, "Panel")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(640, 460)
	panel.Visible = false
	Screen.autoScale(panel)
	local tabs = Instance.new("Frame")
	tabs.BackgroundTransparency = 1
	tabs.Size = UDim2.new(1, 0, 0, 64)
	tabs.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = tabs
	local tabNames = {
		{ "Clues", Strings.Journal.TabClues },
		{ "Suspects", Strings.Journal.TabSuspects },
		{ "Memories", Strings.Journal.TabMemories },
		{ "Names", Strings.Journal.TabNames },
	}
	for _, t in tabNames do
		local b = Screen.button(tabs, "Tab" .. t[1], t[2], Vector2.new(140, 52))
		b.TextSize = 18
		b.Activated:Connect(function()
			tab = t[1]
			render()
		end)
	end
	content = Instance.new("ScrollingFrame")
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromOffset(12, 70)
	content.Size = UDim2.new(1, -24, 1, -82)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new()
	content.ScrollBarThickness = 6
	content.BorderSizePixel = 0
	content.Parent = panel
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.Parent = content

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.J then
			toggle()
		end
	end)
	Remotes.get(Remotes.Names.JournalUpdate).OnClientEvent:Connect(function(s: State)
		state = s
		if panel.Visible then
			render()
		end
	end)
end

return JournalUI
