--!strict
-- Party vote buttons (in-cutscene choices like CS-02; dialogue choices in Phase 1b).
-- Shows every option with its live vote count and the remaining time. Keys 1-4 also vote.
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local UITheme = require(Shared:WaitForChild("UITheme"))

local Screen = require(script.Parent:WaitForChild("Screen"))

local VoteUI = {}

type Option = { id: string, text: string }

local current: {
	id: string,
	frame: Frame,
	buttons: { TextButton },
	counts: { TextLabel },
	timer: TextLabel,
	endsAt: number,
	chosen: number?,
}? =
	nil

local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }

local function cast(index: number)
	local vote = current
	if not vote then
		return
	end
	vote.chosen = index
	for i, b in vote.buttons do
		b.BackgroundColor3 = if i == index then UITheme.Colors.PanelLight else UITheme.Colors.Panel
		local stroke = b:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = if i == index then 0 else 1
		end
	end
	Audio.play("item_pickup", nil, { volume = 0.5 })
	Remotes.get(Remotes.Names.VoteCast):FireServer(vote.id, index)
end

local function close()
	local vote = current
	if vote then
		vote.frame:Destroy()
		current = nil
	end
end

local function open(voteId: string, options: { Option }, endsAt: number)
	close()
	local gui = Screen.gui("Vote", 70)
	local frame = Instance.new("Frame")
	frame.Name = "Vote"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 0.7, 0)
	frame.Size = UDim2.fromOffset(420, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Parent = gui
	Screen.autoScale(frame)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.LayoutOrder = 0
	timer.BackgroundTransparency = 1
	timer.Size = UDim2.fromOffset(420, 30)
	timer.Font = UITheme.Fonts.Body
	timer.TextSize = 22
	timer.TextColor3 = UITheme.Colors.Orange
	timer.TextStrokeTransparency = 0.5
	timer.Text = ""
	timer.Parent = frame

	local buttons: { TextButton } = {}
	local counts: { TextLabel } = {}
	for i, option in options do
		local button = Screen.button(
			frame,
			"Option" .. i,
			string.format("%d. %s", i, option.text),
			Vector2.new(400, 60)
		)
		button.LayoutOrder = i
		local count = Instance.new("TextLabel")
		count.Name = "Count"
		count.BackgroundTransparency = 1
		count.AnchorPoint = Vector2.new(1, 0.5)
		count.Position = UDim2.new(1, -14, 0.5, 0)
		count.Size = UDim2.fromOffset(40, 40)
		count.Font = UITheme.Fonts.Body
		count.TextSize = 22
		count.TextColor3 = UITheme.Colors.TextDim
		count.Text = string.format(Strings.Dialogue.VoteCount, 0)
		count.Parent = button
		button.Activated:Connect(function()
			cast(i)
		end)
		table.insert(buttons, button)
		table.insert(counts, count)
	end
	current = {
		id = voteId,
		frame = frame,
		buttons = buttons,
		counts = counts,
		timer = timer,
		endsAt = endsAt,
		chosen = nil,
	}
	task.spawn(function()
		local lastShown = -1
		while current and current.id == voteId do
			local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
			if left ~= lastShown then
				lastShown = left
				timer.Text = string.format(Strings.Dialogue.VoteTimer, left)
				if left > 0 and left <= 5 then
					Audio.play("vote_tick", nil, { volume = 0.4 })
				end
			end
			task.wait(0.1)
		end
	end)
end

function VoteUI.init()
	Remotes.get(Remotes.Names.VoteStart).OnClientEvent:Connect(open)
	Remotes.get(Remotes.Names.VoteUpdate).OnClientEvent
		:Connect(function(voteId: string, list: { number })
			local vote = current
			if vote and vote.id == voteId then
				for i, label in vote.counts do
					label.Text = string.format(Strings.Dialogue.VoteCount, list[i] or 0)
				end
			end
		end)
	Remotes.get(Remotes.Names.VoteEnd).OnClientEvent
		:Connect(function(voteId: string, winner: number)
			local vote = current
			if not vote or vote.id ~= voteId then
				return
			end
			for i, b in vote.buttons do
				b.TextTransparency = if i == winner then 0 else 0.6
			end
			task.delay(0.8, function()
				if current and current.id == voteId then
					close()
				end
			end)
		end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not current then
			return
		end
		for i, key in KEYS do
			if input.KeyCode == key and current.buttons[i] then
				cast(i)
			end
		end
	end)
end

return VoteUI
