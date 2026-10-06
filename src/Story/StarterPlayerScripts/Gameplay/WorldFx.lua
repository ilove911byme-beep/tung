--!strict
-- Local world effects used by cutscene cues and by the server's glitch events. Targets are map
-- instances tagged by the MapBuilder ("Grass", "Sign", "Shutter", lamps by name tags...).
--   blockRecolor {duration}       grass blocks flash red
--   skyFlicker {duration}         the sky flickers
--   signSwap {text} / signRestore signs rewrite themselves ("SAY YES")
--   lightsOut {tag, stagger, center} / lightsOn {tag}   lamps go out one after another
--   lampFlicker {tag}             a lamp flickers and goes out
--   shutters {stagger}            window shutters close one after another (with door sounds)
--   doorShake {tag, knocks}       a door shudders from knocks
--   bellSwing {tag, times}        the clock tower bell swings by itself
--   beam {at, duration}           a huge yellow beam into the sky
--   colorDrain {amount, duration} the colors drain away (Negatino)
--   shuttersOpen                  every shutter opens again (morning)
--   keypadDigits {text, gap}      digits light up on the mine keypad (CS-15)
--   doorOpen {tag, time}          tagged doors swing to their OpenCFrame (CS-15)
--   clockHands {turns, duration}  the clock tower hands turn (CS-22)
--   fireflies {at, toward, count, radius, duration} pixels drift away like fireflies (endings)
--   tunnelLamps {duration}        yellow square lamps in the tunnel (CS-E2)
--   oldScreen {duration}          the old game's YES / NO screen (CS-16 shot 7)
--   nameRoll {names, duration}    the villagers' names roll by (CS-E3 shot 10)
--   credits {ending, duration}    the ending title and the credits
--   blind {duration, opacity}     the screen goes dark for a moment (Negatino's touch)
--   blackout {duration}           fade through black (scene transitions)
--   knockback {velocity}          throws the local character (the client owns its physics)
--   convergeBeams {from, to, duration} beams from points meet in one (CS-11)
--   debrisBurst {at, count}       chunks burst outward (CS-13 bell tower)
--   sfx {name, at, volume}        a one-shot sound for everybody (3D at `at`)
--   silence {duration}            every sound group fades to silence, then comes back (CS-04)
--   loadingScreen {duration, greet} the loading screen plays over everything (CS-00)
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local LoadingScreen = require(Shared:WaitForChild("UI"):WaitForChild("LoadingScreen"))

local Overlay = require(script.Parent.Parent:WaitForChild("Cutscene"):WaitForChild("Overlay"))
local StoryScreens = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("StoryScreens"))

local WorldFx = {}

local originalSigns: { [TextLabel]: string } = {}

local function tagged(tag: string): { Instance }
	return CollectionService:GetTagged(tag)
end

local function partsOf(inst: Instance): { BasePart }
	local out = {}
	if inst:IsA("BasePart") then
		table.insert(out, inst)
	end
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(out, d)
		end
	end
	return out
end

local function lightsOf(inst: Instance): { Light }
	local out = {}
	for _, d in inst:GetDescendants() do
		if d:IsA("Light") then
			table.insert(out, d)
		end
	end
	if inst:IsA("Light") then
		table.insert(out, inst)
	end
	return out
end

local function blockRecolor(params: { [string]: any })
	local saved: { [BasePart]: Color3 } = {}
	for _, inst in tagged("Grass") do
		for _, p in partsOf(inst) do
			saved[p] = p.Color
			p.Color = Color3.fromRGB(170, 20, 25)
		end
	end
	task.delay(params.duration or 0.35, function()
		for p, c in saved do
			if p.Parent then
				p.Color = c
			end
		end
	end)
end

local function skyFlicker(params: { [string]: any })
	local base = Lighting.ExposureCompensation
	local untilT = os.clock() + (params.duration or 1.2)
	task.spawn(function()
		while os.clock() < untilT do
			Lighting.ExposureCompensation = base + (math.random() < 0.5 and -1.5 or 0.6)
			task.wait(0.05 + math.random() * 0.08)
		end
		Lighting.ExposureCompensation = base
	end)
end

local function signSwap(params: { [string]: any })
	for _, inst in tagged("Sign") do
		for _, d in inst:GetDescendants() do
			if d:IsA("TextLabel") then
				if originalSigns[d] == nil then
					originalSigns[d] = d.Text
				end
				d.Text = params.text or "SAY YES"
				d.TextColor3 = Color3.fromRGB(200, 20, 20)
			end
		end
	end
end

local function signRestore()
	for label, text in originalSigns do
		if label.Parent then
			label.Text = text
			label.TextColor3 = Color3.fromRGB(40, 25, 10)
		end
	end
	table.clear(originalSigns)
end

local function lightsOut(params: { [string]: any })
	local list = tagged(params.tag or "Lamp")
	local center: Vector3? = params.center
	if center then
		table.sort(list, function(a, b)
			local pa = partsOf(a)[1]
			local pb = partsOf(b)[1]
			if not pa or not pb then
				return false
			end
			local da = pa.Position - (center :: Vector3)
			local db = pb.Position - (center :: Vector3)
			return math.atan2(da.Z, da.X) < math.atan2(db.Z, db.X)
		end)
	end
	task.spawn(function()
		for _, inst in list do
			for _, l in lightsOf(inst) do
				l.Enabled = false
			end
			for _, p in partsOf(inst) do
				if p.Material == Enum.Material.Neon then
					p.Material = Enum.Material.SmoothPlastic
					p:SetAttribute("WasNeon", true)
				end
			end
			if params.stagger then
				task.wait(params.stagger)
			end
		end
	end)
end

local function lightsOn(params: { [string]: any })
	for _, inst in tagged(params.tag or "Lamp") do
		for _, l in lightsOf(inst) do
			l.Enabled = true
		end
		for _, p in partsOf(inst) do
			if p:GetAttribute("WasNeon") then
				p.Material = Enum.Material.Neon
			end
		end
	end
end

local function lampFlicker(params: { [string]: any })
	local list = tagged(params.tag or "TavernLamp")
	task.spawn(function()
		for i = 1, 6 do
			for _, inst in list do
				for _, l in lightsOf(inst) do
					l.Enabled = i % 2 == 0
				end
			end
			task.wait(0.08 + math.random() * 0.12)
		end
		for _, inst in list do
			for _, l in lightsOf(inst) do
				l.Enabled = false
			end
		end
		Audio.play("lever_click", nil, { volume = 0.5 })
	end)
end

local function shutters(params: { [string]: any })
	local list = tagged("Shutter")
	task.spawn(function()
		for i, inst in list do
			for _, p in partsOf(inst) do
				p.Transparency = 0
				p.CanCollide = true
			end
			if i % 3 == 1 then
				Audio.play("door_close", partsOf(inst)[1], { volume = 0.6, rollOffMax = 120 })
			end
			task.wait(params.stagger or 0.12)
		end
	end)
end

local function doorShake(params: { [string]: any })
	local list = tagged(params.tag or "TavernDoor")
	task.spawn(function()
		for _ = 1, params.knocks or 3 do
			for _, inst in list do
				for _, p in partsOf(inst) do
					local cf = p.CFrame
					p.CFrame = cf * CFrame.new(0, 0, 0.15)
					task.delay(0.08, function()
						p.CFrame = cf
					end)
				end
			end
			task.wait(params.gap or 0.7)
		end
	end)
end

local function bellSwing(params: { [string]: any })
	local list = tagged(params.tag or "Bell")
	task.spawn(function()
		for _ = 1, params.times or 3 do
			for _, inst in list do
				for _, p in partsOf(inst) do
					local cf = p.CFrame
					local t1 = TweenService:Create(
						p,
						TweenInfo.new(0.5, Enum.EasingStyle.Sine),
						{ CFrame = cf * CFrame.Angles(0, 0, math.rad(25)) }
					)
					t1:Play()
					task.delay(0.5, function()
						TweenService
							:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { CFrame = cf })
							:Play()
					end)
				end
			end
			task.wait(1.2)
		end
	end)
end

local function beam(params: { [string]: any })
	local at: Vector3 = params.at or Vector3.zero
	local p = Instance.new("Part")
	p.Name = "GiallinoBeam"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = params.color or Color3.fromRGB(255, 216, 58)
	p.Transparency = 0.2
	p.Size = Vector3.new(params.width or 8, 400, params.width or 8)
	p.CFrame = CFrame.new(at + Vector3.new(0, 200, 0))
	p.Parent = workspace
	local light = Instance.new("PointLight")
	light.Range = 60
	light.Brightness = 3
	light.Color = p.Color
	light.Parent = p
	task.delay(params.duration or 6, function()
		TweenService:Create(p, TweenInfo.new(1), { Transparency = 1 }):Play()
		task.wait(1.1)
		p:Destroy()
	end)
end

local function colorDrain(params: { [string]: any })
	local cc = Lighting:FindFirstChild("FX_ColorDrain")
	if not cc then
		local new = Instance.new("ColorCorrectionEffect")
		new.Name = "FX_ColorDrain"
		new.Parent = Lighting
		cc = new
	end
	TweenService:Create(cc :: ColorCorrectionEffect, TweenInfo.new(params.duration or 1), {
		Saturation = -(params.amount or 0),
	}):Play()
end

local function silence(params: { [string]: any })
	local duration = params.duration or 3
	local groups = { "Music", "Ambience", "SFX" }
	local saved: { [string]: number } = {}
	for _, name in groups do
		local g = Audio.group(name)
		saved[name] = g.Volume
		TweenService:Create(g, TweenInfo.new(0.3), { Volume = 0 }):Play()
	end
	task.delay(duration, function()
		for _, name in groups do
			TweenService:Create(Audio.group(name), TweenInfo.new(0.2), { Volume = saved[name] })
				:Play()
		end
	end)
end

local function loadingScreen(params: { [string]: any })
	task.spawn(
		LoadingScreen.play,
		params.duration or 3,
		params.greet ~= false,
		params.stare == true
	)
end

local function sfx(params: { [string]: any })
	local name = params.name
	if type(name) ~= "string" then
		return
	end
	local at: Vector3? = params.at
	local holder: Part? = nil
	if at then
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Transparency = 1
		p.Size = Vector3.one
		p.Position = at
		p.Parent = workspace
		holder = p
		task.delay(12, function()
			p:Destroy()
		end)
	end
	Audio.play(name, holder, { volume = params.volume or 0.8 })
end

local function shuttersOpen()
	for _, inst in tagged("Shutter") do
		for _, p in partsOf(inst) do
			p.Transparency = 1
			p.CanCollide = false
		end
	end
end

-- light beams that shoot from several points and meet in one (CS-11: the four braziers)
local function convergeBeams(params: { [string]: any })
	local froms: { Vector3 } = params.from or {}
	local to: Vector3 = params.to or Vector3.zero
	local duration = params.duration or 3
	local color = params.color or Color3.fromRGB(255, 170, 70)
	local beams: { Part } = {}
	for _, from in froms do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = 0.15
		p.Size = Vector3.new(1.2, 1.2, 0.1)
		p.CFrame = CFrame.lookAt(from, to)
		p.Parent = workspace
		table.insert(beams, p)
	end
	local start = os.clock()
	task.spawn(function()
		while os.clock() - start < duration do
			local a = math.clamp((os.clock() - start) / (duration * 0.6), 0, 1)
			for i, p in beams do
				local from = froms[i]
				local tip = from:Lerp(to, a)
				local length = math.max((tip - from).Magnitude, 0.1)
				p.Size = Vector3.new(1.2, 1.2, length)
				p.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
			end
			task.wait()
		end
		for _, p in beams do
			TweenService:Create(p, TweenInfo.new(0.6), { Transparency = 1 }):Play()
			task.delay(0.7, function()
				p:Destroy()
			end)
		end
	end)
end

-- chunks of a roof burst outward from a point (CS-13: Giallino breaks out of the bell tower)
local function debrisBurst(params: { [string]: any })
	local at: Vector3 = params.at or Vector3.zero
	local colors: { Color3 } = params.colors
		or { Color3.fromHex("#7A5230"), Color3.fromHex("#9A4636"), Color3.fromHex("#767676") }
	for i = 1, params.count or 30 do
		local size = 1 + math.random() * 2.5
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Size = Vector3.new(size, size, size)
		p.Color = colors[(i % #colors) + 1]
		p.Material = Enum.Material.WoodPlanks
		p.CFrame = CFrame.new(
			at + Vector3.new(math.random() - 0.5, math.random(), math.random() - 0.5) * 8
		)
		p.Parent = workspace
		local up = if params.down then -(0.3 + math.random()) else 0.6 + math.random()
		local speed = if params.down then 20 + math.random() * 15 else 40 + math.random() * 30
		local vel = Vector3.new(math.random() - 0.5, up, math.random() - 0.5).Unit * speed
		local spin = Vector3.new(math.random(), math.random(), math.random()) * 6
		local t0 = os.clock()
		task.spawn(function()
			local pos = p.Position
			while os.clock() - t0 < 3 do
				local dt = task.wait()
				vel += Vector3.new(0, -80 * dt, 0)
				pos += vel * dt
				p.CFrame = CFrame.new(pos)
					* CFrame.Angles(spin.X * (os.clock() - t0), spin.Y * (os.clock() - t0), 0)
			end
			p:Destroy()
		end)
	end
end

-- the screen goes dark (Negatino's touch: 3 s) or fades through black (scene transitions)
local function blind(params: { [string]: any })
	local duration = params.duration or 3
	Overlay.fadeTo(Color3.new(0, 0, 0), params.opacity or 0.92, 0.15)
	task.delay(duration, function()
		Overlay.fadeTo(Color3.new(0, 0, 0), 0, 0.6)
	end)
end

-- a hit throws your own character (server-set velocities are overwritten by the owning client)
local function knockback(params: { [string]: any })
	local character = game:GetService("Players").LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") and typeof(params.velocity) == "Vector3" then
		root.AssemblyLinearVelocity = params.velocity
	end
end

-- digits appear one by one on the mine keypad (CS-15)
local function keypadDigits(params: { [string]: any })
	for _, pad in tagged("MineKeypad") do
		if pad:IsA("BasePart") then
			local gui = pad:FindFirstChild("Digits") :: SurfaceGui?
			if not gui then
				local g = Instance.new("SurfaceGui")
				g.Name = "Digits"
				g.Face = Enum.NormalId.Front
				g.CanvasSize = Vector2.new(120, 120)
				g.LightInfluence = 0
				local l = Instance.new("TextLabel")
				l.Name = "Text"
				l.BackgroundColor3 = Color3.fromRGB(10, 30, 10)
				l.Size = UDim2.fromScale(1, 1)
				l.Font = Enum.Font.Arcade
				l.TextScaled = true
				l.TextColor3 = Color3.fromRGB(120, 255, 120)
				l.Text = ""
				l.Parent = g
				g.Parent = pad
				gui = g
			end
			local label = (gui :: SurfaceGui):FindFirstChild("Text") :: TextLabel
			local text: string = params.text or "67"
			task.spawn(function()
				for i = 1, #text do
					label.Text = string.sub(text, 1, i)
					Audio.play("button_click", pad, { volume = 0.7 })
					task.wait(params.gap or 0.8)
				end
			end)
		end
	end
end

-- doors that carry OpenCFrame swing open locally (the server opens them too)
local function doorOpen(params: { [string]: any })
	for _, d in tagged(params.tag or "MineDoor") do
		local cf = d:GetAttribute("OpenCFrame")
		if d:IsA("BasePart") and typeof(cf) == "CFrame" then
			TweenService
				:Create(d, TweenInfo.new(params.time or 2, Enum.EasingStyle.Quad), { CFrame = cf })
				:Play()
		end
	end
end

-- the clock hands turn around their pivot (CS-22): `turns` full minute-hand circles
local function clockHands(params: { [string]: any })
	for _, face in tagged("ClockFace") do
		local hour = face:FindFirstChild("HourHand")
		local minute = face:FindFirstChild("MinuteHand")
		if hour and minute and hour:IsA("BasePart") and minute:IsA("BasePart") then
			local pivot = minute:GetAttribute("Pivot")
			if typeof(pivot) == "CFrame" then
				local hStart = pivot:ToObjectSpace(hour.CFrame)
				local mStart = pivot:ToObjectSpace(minute.CFrame)
				local turns = params.turns or 1
				local duration = params.duration or 5
				task.spawn(function()
					local t0 = os.clock()
					while os.clock() - t0 < duration do
						local a = math.clamp((os.clock() - t0) / duration, 0, 1)
						local angle = -a * turns * math.pi * 2
						minute.CFrame = pivot * CFrame.Angles(0, 0, angle) * mStart
						hour.CFrame = pivot * CFrame.Angles(0, 0, angle / 12) * hStart
						task.wait()
					end
				end)
			end
		end
	end
end

-- little lights drift out over the valley like fireflies (CS-E1 / CS-E3)
local function fireflies(params: { [string]: any })
	local at: Vector3 = params.at or Vector3.zero
	local count = params.count or 160
	local radius = params.radius or 160
	local duration = params.duration or 8
	local toward: Vector3? = params.toward
	for _ = 1, count do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = params.color or Color3.fromRGB(255, 226, 120)
		p.Size = Vector3.new(0.4, 0.4, 0.4)
		p.Position = at
		p.Parent = workspace
		local angle = math.random() * math.pi * 2
		local goal = if toward
			then toward + Vector3.new(math.random() - 0.5, math.random() * 0.5, math.random() - 0.5) * 30
			else at + Vector3.new(
				math.cos(angle) * radius * math.random(),
				-math.random() * 60,
				math.sin(angle) * radius * math.random()
			)
		local life = duration * (0.6 + math.random() * 0.4)
		TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Sine), { Position = goal })
			:Play()
		task.delay(life * 0.8, function()
			TweenService:Create(p, TweenInfo.new(life * 0.2), { Transparency = 1 }):Play()
		end)
		task.delay(life + 0.1, function()
			p:Destroy()
		end)
	end
end

-- yellow, square lamps along the tunnel walls (CS-E2: the loop starts again)
local function tunnelLamps(params: { [string]: any })
	local lamps = {}
	for x = 3, 22, 3 do
		for _, z in { 78.15, 82.85 } do
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromRGB(255, 216, 58)
			p.Size = Vector3.new(1.2, 1.2, 0.2)
			p.CFrame = CFrame.new(Vector3.new(x, 14.5, z) * 4)
			p.Parent = workspace
			local light = Instance.new("PointLight")
			light.Color = p.Color
			light.Range = 10
			light.Parent = p
			table.insert(lamps, p)
		end
	end
	task.delay(params.duration or 25, function()
		for _, p in lamps do
			p:Destroy()
		end
	end)
end

local HANDLERS: { [string]: ({ [string]: any }) -> () } = {
	keypadDigits = keypadDigits,
	doorOpen = doorOpen,
	clockHands = clockHands,
	fireflies = fireflies,
	tunnelLamps = tunnelLamps,
	oldScreen = function(params: { [string]: any })
		StoryScreens.oldScreen(params.duration or 7)
	end,
	nameRoll = function(params: { [string]: any })
		StoryScreens.nameRoll(params.names or {}, params.duration or 10)
	end,
	credits = function(params: { [string]: any })
		StoryScreens.credits(params.ending or "dawn", params.duration or 30)
	end,
	blind = blind,
	knockback = knockback,
	blackout = function(params: { [string]: any })
		blind({ duration = params.duration or 1.5, opacity = 1 })
	end,
	convergeBeams = convergeBeams,
	debrisBurst = debrisBurst,
	shuttersOpen = function()
		shuttersOpen()
	end,
	sfx = sfx,
	silence = silence,
	loadingScreen = loadingScreen,
	blockRecolor = blockRecolor,
	skyFlicker = skyFlicker,
	signSwap = signSwap,
	signRestore = function()
		signRestore()
	end,
	lightsOut = lightsOut,
	lightsOn = lightsOn,
	lampFlicker = lampFlicker,
	shutters = shutters,
	doorShake = doorShake,
	bellSwing = bellSwing,
	beam = beam,
	colorDrain = colorDrain,
}

function WorldFx.play(kind: string, params: { [string]: any }?)
	local handler = HANDLERS[kind]
	if handler then
		handler(params or {})
	else
		warn("[WorldFx] unknown effect " .. kind)
	end
end

function WorldFx.init()
	Remotes.get(Remotes.Names.WorldFx).OnClientEvent:Connect(function(kind: string, params: any)
		WorldFx.play(kind, params)
	end)
end

return WorldFx
