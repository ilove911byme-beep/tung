--!strict
-- QTE prompts on PC (keys), mobile (big on-screen buttons) and gamepad.
--   tap    : E / ButtonX / tap the button
--   hold   : hold Space / ButtonA / the button: the marker rises while held and falls when
--            released; keep it in the green zone for 80 % of the time
--   choice : A or Left / D or Right / Ctrl or C (duck); gamepad DPad / ButtonB; three buttons
--   party  : everyone mashes E / ButtonX; one shared bar
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))
local UITheme = require(Shared:WaitForChild("UITheme"))

local Screen = require(script.Parent:WaitForChild("Screen"))

local QTEUI = {}

type Active = {
	id: string,
	spec: { [string]: any },
	endsAt: number,
	frame: Frame,
	presses: number,
	holding: boolean,
	marker: number,
	inZone: number,
	elapsed: number,
	done: boolean,
	bar: Frame?,
	fill: Frame?,
	markerFrame: Frame?,
}

local gui: ScreenGui
local current: Active? = nil

local TAP_KEYS = { [Enum.KeyCode.E] = true, [Enum.KeyCode.ButtonX] = true }
local HOLD_KEYS =
	{ [Enum.KeyCode.Space] = true, [Enum.KeyCode.ButtonA] = true, [Enum.KeyCode.E] = true }
local CHOICE_KEYS: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.A] = "left",
	[Enum.KeyCode.Left] = "left",
	[Enum.KeyCode.DPadLeft] = "left",
	[Enum.KeyCode.D] = "right",
	[Enum.KeyCode.Right] = "right",
	[Enum.KeyCode.DPadRight] = "right",
	[Enum.KeyCode.LeftControl] = "duck",
	[Enum.KeyCode.C] = "duck",
	[Enum.KeyCode.ButtonB] = "duck",
	[Enum.KeyCode.DPadDown] = "duck",
}

local function report(q: Active, success: boolean)
	if q.done then
		return
	end
	q.done = true
	if q.spec.type ~= "party" then
		Remotes.get(Remotes.Names.QTEResult):FireServer(q.id, success)
	end
	Audio.play(if success then "xp_orb_pickup" else "player_hurt", nil, { volume = 0.5 })
end

local function close(q: Active)
	if current == q then
		current = nil
	end
	q.frame:Destroy()
end

local function makeLabel(parent: Instance, text: string, y: number, size: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(0, y)
	l.Size = UDim2.new(1, 0, 0, size + 8)
	l.Font = UITheme.Fonts.Body
	l.TextSize = size
	l.TextColor3 = UITheme.Colors.Text
	l.TextStrokeTransparency = 0.4
	l.Text = text
	l.Parent = parent
	return l
end

local function bigButton(
	parent: Instance,
	text: string,
	x: number,
	onPress: () -> (),
	onRelease: (() -> ())?
): TextButton
	local b = Screen.button(parent, "Btn" .. text, text, Vector2.new(120, 90))
	b.Position = UDim2.fromOffset(x, 120)
	b.TextSize = 26
	b.MouseButton1Down:Connect(onPress)
	if onRelease then
		b.MouseButton1Up:Connect(onRelease)
		b.MouseLeave:Connect(onRelease)
	end
	return b
end

local function choose(q: Active, answer: string)
	if q.done then
		return
	end
	report(q, answer == q.spec.answer)
end

local function start(id: string, spec: { [string]: any }, endsAt: number)
	if current then
		close(current)
	end
	local frame = Instance.new("Frame")
	frame.Name = "QTE"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.62)
	frame.Size = UDim2.fromOffset(420, 230)
	frame.Parent = gui
	Screen.autoScale(frame)
	local q: Active = {
		id = id,
		spec = spec,
		endsAt = endsAt,
		frame = frame,
		presses = 0,
		holding = false,
		marker = 0.2,
		inZone = 0,
		elapsed = 0,
		done = false,
	}
	current = q
	local touch = UserInputService.TouchEnabled
	if spec.type == "tap" or spec.type == "party" then
		local key = if touch then "TAP" else "E"
		makeLabel(
			frame,
			spec.label
				or string.format(
					if spec.type == "party" then Strings.QTE.Party else Strings.QTE.Tap,
					key
				),
			0,
			26
		)
		local bar = Screen.panel(frame, "Bar")
		bar.Position = UDim2.fromOffset(10, 60)
		bar.Size = UDim2.new(1, -20, 0, 26)
		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = UITheme.Colors.Orange
		fill.BorderSizePixel = 0
		fill.Size = UDim2.fromScale(0, 1)
		fill.Parent = bar
		q.bar = bar
		q.fill = fill
		bigButton(frame, "TAP", 150, function()
			QTEUI.press()
		end)
	elseif spec.type == "hold" then
		makeLabel(
			frame,
			spec.label or string.format(Strings.QTE.Hold, if touch then "HOLD" else "SPACE"),
			0,
			24
		)
		local bar = Screen.panel(frame, "Bar")
		bar.Position = UDim2.fromOffset(10, 60)
		bar.Size = UDim2.new(1, -20, 0, 30)
		local zone = Instance.new("Frame")
		zone.BackgroundColor3 = UITheme.Colors.Success
		zone.BackgroundTransparency = 0.3
		zone.BorderSizePixel = 0
		zone.Position = UDim2.fromScale(0.45, 0)
		zone.Size = UDim2.fromScale(0.25, 1)
		zone.Parent = bar
		local marker = Instance.new("Frame")
		marker.BackgroundColor3 = UITheme.Colors.White
		marker.BorderSizePixel = 0
		marker.Size = UDim2.new(0, 6, 1, 0)
		marker.Parent = bar
		q.bar = bar
		q.markerFrame = marker
		bigButton(frame, "HOLD", 150, function()
			q.holding = true
		end, function()
			q.holding = false
		end)
	elseif spec.type == "choice" then
		local word = if spec.answer == "left"
			then Strings.QTE.Left
			elseif spec.answer == "right" then Strings.QTE.Right
			else Strings.QTE.Duck
		makeLabel(frame, word .. "!", 0, 44).Font = UITheme.Fonts.Title
		bigButton(frame, "◀", 20, function()
			choose(q, "left")
		end)
		bigButton(frame, "▼", 150, function()
			choose(q, "duck")
		end)
		bigButton(frame, "▶", 280, function()
			choose(q, "right")
		end)
	end
	Audio.play("vote_tick", nil, { volume = 0.6 })
end

--- Tap / mash input (keyboard, gamepad or the on-screen button).
function QTEUI.press()
	local q = current
	if not q or q.done then
		return
	end
	if q.spec.type == "tap" then
		q.presses += 1
		if q.presses >= (q.spec.presses or 8) then
			report(q, true)
		end
	elseif q.spec.type == "party" then
		Remotes.get(Remotes.Names.QTETap):FireServer(q.id)
	end
end

function QTEUI.init()
	gui = Screen.gui("QTE", 65)
	UserInputService.InputBegan:Connect(function(input, processed)
		local q = current
		if not q or q.done then
			return
		end
		if q.spec.type == "choice" then
			local answer = CHOICE_KEYS[input.KeyCode]
			if answer then
				choose(q, answer)
			end
		elseif q.spec.type == "hold" then
			if HOLD_KEYS[input.KeyCode] then
				q.holding = true
			end
		elseif not processed and TAP_KEYS[input.KeyCode] then
			QTEUI.press()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		local q = current
		if q and q.spec.type == "hold" and HOLD_KEYS[input.KeyCode] then
			q.holding = false
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		local q = current
		if not q then
			return
		end
		local left = q.endsAt - workspace:GetServerTimeNow()
		if q.spec.type == "tap" and q.fill then
			q.fill.Size = UDim2.fromScale(math.clamp(q.presses / (q.spec.presses or 8), 0, 1), 1)
		elseif q.spec.type == "hold" and not q.done then
			q.elapsed += dt
			q.marker = math.clamp(q.marker + (if q.holding then 0.55 else -0.45) * dt, 0, 1)
			local zoneOk = q.marker >= 0.45 and q.marker <= 0.7
			if zoneOk then
				q.inZone += dt
			end
			if q.markerFrame then
				q.markerFrame.Position = UDim2.fromScale(q.marker, 0)
			end
		end
		if left <= 0 and not q.done then
			if q.spec.type == "hold" then
				report(q, q.inZone >= (q.spec.duration or 5) * 0.8 * 0.85)
			elseif q.spec.type ~= "party" then
				report(q, false)
			end
		end
	end)
	Remotes.get(Remotes.Names.QTEStart).OnClientEvent:Connect(start)
	Remotes.get(Remotes.Names.QTEProgress).OnClientEvent
		:Connect(function(id: string, progress: number)
			local q = current
			if q and q.id == id and q.fill then
				q.fill.Size = UDim2.fromScale(progress, 1)
			end
		end)
	Remotes.get(Remotes.Names.QTEEnd).OnClientEvent:Connect(function(id: string, success: boolean)
		local q = current
		if q and q.id == id then
			makeLabel(q.frame, if success then Strings.QTE.Success else Strings.QTE.Fail, 200, 26).TextColor3 = if success
				then UITheme.Colors.Success
				else UITheme.Colors.Danger
			task.delay(0.6, function()
				close(q)
			end)
		end
	end)
end

return QTEUI
