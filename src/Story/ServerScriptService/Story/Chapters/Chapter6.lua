--!strict
-- Chapter 6 "The Clock Tower" (screenplay.md 6-1 .. 6-3 and the endings): Giallino Totale rises
-- (CS-20); phase 1 Falsino face: floating blocks to the village, some of them lies; phase 2
-- Negatino face: the Truth Gears can only be carried inside lantern light through the dark;
-- phase 3 Crudelino face: Tung Tung holds the door (CS-21), the stairs crumble while the face
-- punches through the walls; phase 4: the gears go in and the whole party turns the hands
-- (party QTE, CS-22); the choice (CS-23) and the three endings (CS-E1 / CS-E2 / CS-E3).
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local StoryContext = require(script.Parent.Parent:WaitForChild("StoryContext"))
local SSS = script.Parent.Parent.Parent
local Systems = SSS:WaitForChild("Systems")
local BossFramework = require(Systems:WaitForChild("BossFramework"))
local HealthService = require(Systems:WaitForChild("HealthService"))
local Hud = require(Systems:WaitForChild("Hud"))
local ParkourService = require(Systems:WaitForChild("ParkourService"))
local PartyService = require(Systems:WaitForChild("PartyService"))

type Ctx = StoryContext.Context

local S = 4
local SPEEDRUN_SECONDS = 35 * 60
local CARRY_SPEED = 11
local LANTERN_RADIUS = 11
local GLOWING_RADIUS = 15
local DARK_DAMAGE = 4
local WALL_DAMAGE = 30
local CLIMB_SECONDS = 100
local DOOR_HOLDS = 30 -- seconds when Tung Tung is jailed

-- the tower (map.md): x 76.5-83.5, z 62.5-69.5, door in the south wall, bell chamber floor y 34
local TOWER_MIN = Vector3.new(76.5 * S, 11 * S, 62.5 * S)
local TOWER_MAX = Vector3.new(83.5 * S, 44 * S, 69.5 * S)
local CHAMBER_Y = 33.5 * S

local function blocks(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z) * S
end

local function rootOf(p: Player): BasePart?
	local character = p.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function model(id: string): Model?
	local models = ServerStorage:FindFirstChild("Models")
	local template = models and models:FindFirstChild(id)
	if template and template:IsA("Model") then
		local m = template:Clone()
		for _, d in m:GetDescendants() do
			if d:IsA("BillboardGui") then
				d.Enabled = false
			end
		end
		CollectionService:AddTag(m, "Faced")
		return m
	end
	return nil
end

local function blk(b: ParkourService.BlockDef): ParkourService.BlockDef
	return b
end

------------------------------------------------------------------ Giallino Totale in the sky

-- sides of the cube (RigFactory SIDE_FACES): front Giallino, right Falsino, back Negatino,
-- left Crudelino; the side's yaw turns that face toward the tower
local SIDE_YAW: { [string]: number } =
	{ Giallino = 0, Falsino = -90, Negatino = 180, Crudelino = 90 }
local SKY_POS = blocks(80, 50, 46)
local TOWER_TOP = blocks(80, 36, 66)

local totale: Model? = nil
local totaleSide = "Giallino"

local function ensureTotale(ctx: Ctx): Model?
	local m = totale
	if m and m.Parent then
		return m
	end
	local nm = model("GiallinoTotale")
	if not nm then
		return nil
	end
	for _, sub in nm:GetChildren() do
		if sub:IsA("Model") then
			CollectionService:AddTag(sub, "Faced")
		end
	end
	nm:ScaleTo(10)
	nm:PivotTo(
		CFrame.lookAt(SKY_POS, TOWER_TOP) * CFrame.Angles(0, math.rad(-SIDE_YAW[totaleSide]), 0)
	)
	nm.Parent = workspace
	totale = nm
	ctx:track(function()
		if totale == nm then
			totale = nil
		end
		nm:Destroy()
	end)
	return nm
end

--- Turns one face of the cube toward the tower (and the players).
local function showFace(ctx: Ctx, side: string, at: Vector3?, look: Vector3?)
	totaleSide = side
	local m = ensureTotale(ctx)
	if not m then
		return
	end
	local goal = CFrame.lookAt(at or SKY_POS, look or TOWER_TOP)
		* CFrame.Angles(0, math.rad(-SIDE_YAW[side]), 0)
	local start = m:GetPivot()
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 2.5 and m.Parent do
			local a = TweenService:GetValue(
				(os.clock() - t0) / 2.5,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut
			)
			m:PivotTo(start:Lerp(goal, a))
			task.wait()
		end
		if m.Parent then
			m:PivotTo(goal)
		end
	end)
end

------------------------------------------------------------------ 6-1 Totale rises

local function rise(ctx: Ctx)
	ctx:companion(false)
	ctx:preset("finale", 1)
	ctx:music("finale")
	ctx:cutscene("CS_20")
	ensureTotale(ctx)
	local boss = BossFramework.new({
		name = "GiallinoTotale",
		cardTitle = Strings.Bosses.Totale.title,
		cardSubtitle = Strings.Bosses.Totale.subtitle,
		signature = "glitch_burst",
		phases = {},
	})
	boss:card()
	if ctx.flags.get().jailed == nil then
		ctx:award("NO_ONE_JAILED")
	end
end

------------------------------------------------------------------ phase 1: the sky path (Falsino)

-- from the hill top over the mine (FinaleStart x 118, z 34) to the north edge of the village;
-- every third step is a pair: one real block and one lie beside it (its edge flickers)
local START = Vector3.new(118, 18, 34)
local FINISH = Vector3.new(98.5, 18, 55.5)
local STEPS = 14

local function skyDef(): ParkourService.SegmentDef
	local list: { ParkourService.BlockDef } = {
		blk({ kind = "start", at = { 0, 0.25, 0 }, size = { 2, 0.5, 2 } }),
	}
	local dir = Vector3.new(FINISH.X - START.X, 0, FINISH.Z - START.Z)
	local side = Vector3.new(-dir.Unit.Z, 0, dir.Unit.X)
	local rng = Random.new(6)
	for k = 1, STEPS do
		local t = k / (STEPS + 1)
		local flat = dir * t
		local y = 1 + math.sin(t * math.pi) * 4 -- an arc over the slope
		local at = Vector3.new(flat.X, y - 0.5, flat.Z)
		if k == math.floor(STEPS / 2) then
			table.insert(
				list,
				blk({ kind = "checkpoint", at = { at.X, at.Y, at.Z }, size = { 2, 1, 2 } })
			)
		elseif k % 3 == 0 then
			local sign = if rng:NextNumber() < 0.5 then 1 else -1
			local real = at + side * sign * 1.1
			local lie = at - side * sign * 1.1
			table.insert(
				list,
				blk({
					kind = "block",
					at = { real.X, real.Y, real.Z },
					size = { 1.2, 1, 1.2 },
					color = Color3.fromHex("#C8B070"),
				})
			)
			table.insert(
				list,
				blk({
					kind = "fake",
					at = { lie.X, lie.Y, lie.Z },
					size = { 1.2, 1, 1.2 },
					color = Color3.fromHex("#C8B070"),
				})
			)
		else
			table.insert(
				list,
				blk({
					kind = "block",
					at = { at.X, at.Y, at.Z },
					size = { 1.2, 1, 1.2 },
					color = Color3.fromHex("#C8B070"),
				})
			)
		end
	end
	local f = Vector3.new(FINISH.X - START.X, 0.25, FINISH.Z - START.Z)
	table.insert(list, blk({ kind = "finish", at = { f.X, f.Y, f.Z }, size = { 2.5, 0.5, 2.5 } }))
	-- a ladder down from the finish platform to the village
	table.insert(list, blk({ kind = "ladder", at = { f.X + 1.6, -3, f.Z }, size = { 1, 6.5, 1 } }))
	return {
		id = "SkyPath",
		killY = -2,
		fall = "damage",
		fallDamage = 30,
		blocks = list,
	}
end

local function skyPath(ctx: Ctx)
	showFace(ctx, "Falsino")
	ctx:objective("C6_SKYPATH")
	ctx:say("C6_NARR_SKYPATH")
	task.delay(7, function()
		ctx:say("C6_TOTALE_FALSINO")
	end)
	local course = ParkourService.build(skyDef(), workspace, CFrame.new(START * S))
	ctx:track(course.model)
	ctx:track(function()
		course:destroy()
	end)
	course:track(ctx:alive(), true)
	local started = os.clock()
	local firstDone: number? = nil
	course.Finished:Connect(function()
		firstDone = firstDone or os.clock()
	end)
	ctx:waitUntil(function()
		if course:allFinished() then
			return true
		end
		if firstDone and os.clock() - firstDone > 75 then
			return true
		end
		return os.clock() - started > 360
	end, nil, 0.5)
	ctx:clearObjective()
	local down = CFrame.new(blocks(FINISH.X + 2, 12, FINISH.Z + 2))
	for i, p in ctx:players() do
		local root = rootOf(p)
		if p.Character and (not root or root.Position.Y > 13.5 * S or course:isRunning(p)) then
			p.Character:PivotTo(down * CFrame.new((i - 1) * 2.5, 3, 0))
		end
	end
end

------------------------------------------------------------------ phase 2: darkness (Negatino)

local function lightRadius(p: Player, ctx: Ctx): number
	local fuel = (p:GetAttribute("LanternFuel") :: number?) or 0
	if fuel <= 0 then
		return 0
	end
	if ctx.inv.has(p, "glowing_lantern") then
		return GLOWING_RADIUS
	elseif ctx.inv.has(p, "lantern") then
		return LANTERN_RADIUS
	end
	return 0
end

local function carriers(ctx: Ctx): { Player }
	local out = {}
	for _, p in ctx:alive() do
		if ctx.inv.has(p, "truth_gear") then
			table.insert(out, p)
		end
	end
	return out
end

local function setSpeed(p: Player, speed: number)
	local character = p.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and p:GetAttribute("LifeState") == "Alive" then
		humanoid.WalkSpeed = speed
	end
end

local function darkness(ctx: Ctx)
	showFace(ctx, "Negatino")
	ctx:preset("night_deep", 2)
	ctx.atmosphere.fog(45, 2)
	ctx:glitch("lightsOut", { tag = "Lamp" })
	ctx:track(function()
		ctx.atmosphere.fog(140, 2)
		ctx:glitch("lightsOn", { tag = "Lamp" })
	end)
	ctx:say("C6_TOTALE_NEGATINO")
	ctx:objective("C6_DARK")
	task.delay(5, function()
		ctx:say("C6_NARR_CARRY")
	end)
	-- the gears must be with somebody
	if #carriers(ctx) == 0 then
		local alive = ctx:alive()
		if #alive > 0 then
			ctx.inv.add(
				alive[math.random(1, #alive)],
				"truth_gear",
				math.max(ctx.flags.get().gears, 3)
			)
		end
	end
	ctx.inv.setFuelDrain(true)
	local slowed: { [Player]: boolean } = {}
	ctx:track(function()
		ctx.inv.setFuelDrain(false)
		for p in slowed do
			setSpeed(p, 16)
		end
	end)
	local door = ctx:ground("TowerDoor").Position
	local nextWave = os.clock() + 8
	local nextHurt: { [Player]: number } = {}
	while true do
		task.wait(0.25)
		local holders = carriers(ctx)
		if #holders == 0 then
			-- every carrier is down: their gears wait for a teammate to revive them
			continue
		end
		local alive = ctx:alive()
		local allThere = true
		for _, h in holders do
			if not slowed[h] then
				slowed[h] = true
				setSpeed(h, CARRY_SPEED)
			end
			local root = rootOf(h)
			if not root then
				continue
			end
			if flatDistance(root.Position, door) > 14 then
				allThere = false
			end
			-- inside somebody's lantern light? (your own lantern only counts when you are alone)
			local lit = false
			for _, p in alive do
				local other = rootOf(p)
				if other and (p ~= h or #alive == 1) then
					local r = lightRadius(p, ctx)
					if r > 0 and (other.Position - root.Position).Magnitude < r then
						lit = true
					end
				end
			end
			local now = os.clock()
			if not lit and (nextHurt[h] or 0) < now then
				nextHurt[h] = now + 0.75
				ctx.health.damage(h, DARK_DAMAGE, "dark")
				Hud.worldFxFor({ h }, "colorDrain", { amount = 0.8, duration = 0.75 })
			elseif lit then
				Hud.worldFxFor({ h }, "colorDrain", { amount = 0, duration = 0.5 })
			end
		end
		for p in slowed do
			if not table.find(holders, p) then
				slowed[p] = nil
				setSpeed(p, 16)
			end
		end
		if allThere then
			break
		end
		if os.clock() > nextWave then
			nextWave = os.clock() + 13
			local h = holders[math.random(1, #holders)]
			local root = rootOf(h)
			if root then
				ctx.threats.wave(math.min(1 + #alive, 4), CFrame.new(root.Position), 28)
			end
		end
	end
	ctx.threats.clear()
	ctx:clearObjective()
	Hud.worldFx("colorDrain", { amount = 0, duration = 1 })
end

------------------------------------------------------------------ phase 3: the climb (Crudelino)

local function climb(ctx: Ctx)
	showFace(ctx, "Crudelino", blocks(80, 40, 50), blocks(80, 38, 66))
	local flags = ctx.flags.get()
	local tungJailed = flags.jailed == "TungTung"
	-- everybody inside, at the bottom of the stairs
	local towerDoor: BasePart? = nil
	for _, d in CollectionService:GetTagged("TowerDoor") do
		if d:IsA("BasePart") then
			towerDoor = d
		end
	end
	for i, p in ctx:players() do
		if p.Character then
			p.Character:PivotTo(
				CFrame.new(
					blocks(79 + (i % 3) * 0.8, 12, 67.4 - math.floor((i - 1) / 3) * 0.8)
						+ Vector3.new(0, 3, 0)
				)
			)
		end
	end
	ctx:cutscene(
		"CS_21",
		if tungJailed then "jailed" elseif flags.patapimGone then "free" else "freeNoPatapim"
	)
	if towerDoor then
		ctx.map.setDoor(towerDoor, false)
		local d = towerDoor
		ctx:track(function()
			ctx.map.setDoor(d, true)
		end)
	end
	-- Tung Tung stays at the door (only when he is free)
	local tung: Model? = nil
	if not tungJailed then
		tung = model("TungTung")
		if tung then
			tung:SetAttribute("Anim", "A-BRACE_DOOR")
			tung:SetAttribute("Face", "angry")
			CollectionService:AddTag(tung, "NPC")
			tung:PivotTo(
				CFrame.new(blocks(80, 12, 68.3))
					* CFrame.new(0, (tung:GetAttribute("RootHeight") :: number?) or 0, 0)
			)
			tung.Parent = workspace
			ctx:track(tung)
		end
	end
	ctx:music("boss")
	ctx:say("C6_TOTALE_CRUDELINO")
	local endsAt = ctx:timer(CLIMB_SECONDS)
	ctx:objective("C6_CLIMB", CLIMB_SECONDS)

	-- the stairs crumble from the bottom up
	type Stair = { part: BasePart, rest: CFrame, index: number }
	local stairs: { Stair } = {}
	for _, s in CollectionService:GetTagged("TowerStair") do
		if s:IsA("BasePart") then
			table.insert(
				stairs,
				{ part = s, rest = s.CFrame, index = (s:GetAttribute("Index") :: number?) or 0 }
			)
		end
	end
	table.sort(stairs, function(a, b)
		return a.index < b.index
	end)
	ctx:track(function()
		for _, s in stairs do
			s.part.CFrame = s.rest
			s.part.Transparency = 0
			s.part.CanCollide = true
		end
	end)
	local active = true
	ctx:track(function()
		active = false
	end)
	task.spawn(function()
		task.wait(8)
		for _, s in stairs do
			if not active or s.index >= #stairs - 2 then
				break
			end
			ctx:sfx("block_break_wood", s.part.Position, 0.8)
			s.part.CanCollide = false
			TweenService:Create(s.part, TweenInfo.new(0.8), {
				CFrame = s.rest - Vector3.new(0, 10, 0),
				Transparency = 1,
			}):Play()
			task.wait(1.7)
		end
	end)
	-- the Crudelino face punches through the walls (red glow on the wall 1 s before)
	task.spawn(function()
		task.wait(5)
		while active do
			local inside = {}
			for _, p in ctx:alive() do
				if ctx:inside(p, TOWER_MIN, TOWER_MAX) then
					table.insert(inside, p)
				end
			end
			if #inside > 0 then
				local target = inside[math.random(1, #inside)]
				local root = rootOf(target)
				if root then
					local p = root.Position
					-- the nearest outer wall
					local c = (TOWER_MIN + TOWER_MAX) / 2
					local dx, dz = p.X - c.X, p.Z - c.Z
					local wallAt: Vector3
					local size: Vector3
					if math.abs(dx) > math.abs(dz) then
						wallAt = Vector3.new(if dx > 0 then TOWER_MAX.X else TOWER_MIN.X, p.Y, p.Z)
						size = Vector3.new(1, 10, 10)
					else
						wallAt = Vector3.new(p.X, p.Y, if dz > 0 then TOWER_MAX.Z else TOWER_MIN.Z)
						size = Vector3.new(10, 10, 1)
					end
					local glow = ctx:newPart({
						Name = "PunchWarning",
						Size = size,
						CFrame = CFrame.new(wallAt),
						Color = Color3.fromRGB(255, 30, 30),
						Material = Enum.Material.Neon,
						Transparency = 0.5,
					})
					ctx:sfx("crudelino_signature", wallAt, 0.9)
					task.wait(1)
					glow:Destroy()
					ctx:sfx("block_break_stone", wallAt, 1)
					Hud.worldFx(
						"debrisBurst",
						{ at = wallAt, count = 12, colors = { "#C0281E", "#7D7D7D" } }
					)
					for _, q in ctx:alive() do
						local r = rootOf(q)
						if r and (r.Position - wallAt).Magnitude < 9 then
							ctx.health.damage(q, WALL_DAMAGE, "crudelino")
							r.AssemblyLinearVelocity = (c - wallAt).Unit * 30
						end
					end
				end
			end
			task.wait(math.random(35, 55) / 10)
		end
	end)
	-- without Tung Tung the door gives way after 30 s and Glitchlings climb in
	if tungJailed then
		task.spawn(function()
			task.wait(DOOR_HOLDS)
			if not active then
				return
			end
			if towerDoor then
				ctx.map.setDoor(towerDoor, true)
				ctx:sfx("door_open", towerDoor.Position, 1)
			end
			while active do
				ctx.threats.wave(2, CFrame.new(blocks(80, 12, 67)), 4)
				task.wait(10)
			end
		end)
	end
	ctx:waitUntil(function()
		local now = workspace:GetServerTimeNow()
		ctx:objective("C6_CLIMB", math.max(0, math.ceil(endsAt - now)))
		if now > endsAt then
			return true
		end
		local alive = ctx:alive()
		if #alive == 0 then
			return false
		end
		for _, p in alive do
			local root = rootOf(p)
			if not root or root.Position.Y < CHAMBER_Y then
				return false
			end
		end
		return true
	end, nil, 0.5)
	active = false
	ctx:clearTimer()
	ctx:clearObjective()
	ctx.threats.clear()
	-- stragglers are thrown up by the last punch
	local top = ctx:ground("TowerTopRoom")
	for i, p in ctx:players() do
		local root = rootOf(p)
		if p.Character and (not root or root.Position.Y < CHAMBER_Y) then
			if p:GetAttribute("LifeState") == "Alive" then
				ctx.health.damage(p, WALL_DAMAGE, "crudelino")
			end
			p.Character:PivotTo(top * CFrame.new((i - 1) * 1.5 - 3, 3, 0))
		end
	end
end

------------------------------------------------------------------ phase 4: the mechanism

local function mechanism(ctx: Ctx): boolean
	showFace(ctx, "Giallino", blocks(80, 37, 74), blocks(80, 37, 66))
	ctx:music("finale")
	ctx:objective("C6_MECHANISM")
	ctx:say("C6_NARR_MECHANISM")
	local sockets: { BasePart } = {}
	for _, s in CollectionService:GetTagged("GearSocket") do
		if s:IsA("BasePart") then
			table.insert(sockets, s)
		end
	end
	table.sort(sockets, function(a, b)
		return ((a:GetAttribute("Index") :: number?) or 0)
			< ((b:GetAttribute("Index") :: number?) or 0)
	end)
	local inserted = 0
	local done = Instance.new("BindableEvent")
	ctx:track(done)
	for _, socket in sockets do
		local filled = false
		local prompt: ProximityPrompt? = nil
		prompt = ctx:prompt(
			socket,
			Strings.Prompts.Insert,
			{ objectText = Strings.Items.TruthGear, distance = 8 },
			function(player)
				if filled then
					return
				end
				local nobodyHasOne = #carriers(ctx) == 0
				if not ctx.inv.remove(player, "truth_gear", 1) and not nobodyHasOne then
					return
				end
				filled = true
				local gear = model("TruthGear")
				if gear then
					gear:PivotTo(socket.CFrame)
					gear.Parent = workspace
					ctx:track(gear)
				end
				ctx:sfx("lever_click", socket.Position, 1)
				if prompt then
					prompt:Destroy()
				end
				inserted += 1
				if inserted >= #sockets then
					done:Fire()
				end
			end
		)
	end
	if #sockets > 0 then
		done.Event:Wait()
	end
	ctx:clearObjective()
	-- Totale clings to the hands: everybody turns them together
	local ok = ctx.qte.party(ctx:alive(), {
		type = "party",
		duration = 16,
		drain = 0.08,
		label = Strings.Prompts.Push,
	})
	return ok
end

------------------------------------------------------------------ the choice and the endings

local function finishGame(ctx: Ctx, ending: string)
	ctx.flags.set("ending", ending)
	PartyService.setReturnData("ending", ending)
	local players = ctx:players()
	local wholeStory = workspace:GetAttribute("StartChapter") == 1
	local elapsed = os.clock() - ctx.flags.get().startedAt
	if wholeStory and elapsed < SPEEDRUN_SECONDS then
		ctx:award("SPEEDRUN")
	end
	for _, p in players do
		if wholeStory and HealthService.nobodyDied(p) then
			ctx:award("NO_DEATHS", { p })
		end
	end
	workspace:SetAttribute("StoryEnded", ending)
end

local function credits(ctx: Ctx, ending: string, seconds: number)
	ctx:glitch("credits", { ending = ending, duration = seconds })
	task.wait(seconds)
end

local function finale(ctx: Ctx)
	local turned = mechanism(ctx)
	local choice = "stay"
	if turned then
		ctx:cutscene("CS_22")
		local flags = ctx.flags.get()
		local secret = ctx.flags.realClues() >= 7
			and flags.riddleCorrect
			and flags.spottedFalsino
			and flags.jailed == nil
		local result = ctx:cutscene("CS_23", if secret then "secret" else "main")
		choice = result.choice or "shut"
	end
	ctx.flags.set("finalChoice", choice)
	ctx.threats.clear()
	if totale then
		totale:Destroy()
		totale = nil
	end
	if choice == "teach" then
		ctx:cutscene("CS_E3", "main")
		ctx:award("ENDING_SAHUR")
		finishGame(ctx, "sahur")
		credits(ctx, "sahur", 30)
		ctx:cutscene("CS_E3", "post")
	elseif choice == "shut" then
		ctx:cutscene("CS_E1", if ctx.flags.get().jailed == "TungTung" then "jailed" else "free")
		ctx:award("ENDING_DAWN")
		finishGame(ctx, "dawn")
		credits(ctx, "dawn", 30)
	else
		ctx:cutscene("CS_E2")
		ctx:award("ENDING_ENDLESS_NIGHT")
		finishGame(ctx, "endless")
		credits(ctx, "endless", 24)
	end
	ctx:preset(if choice == "stay" then "night_deep" else "dawn", 1)
end

local chapter: StoryContext.Chapter = {
	index = 6,
	title = "The Clock Tower",
	steps = {
		StoryContext.step({
			name = "totale",
			checkpoint = { point = "CaveExitTop" },
			run = rise,
		}),
		StoryContext.step({
			name = "skypath",
			checkpoint = { point = "FinaleStart" },
			run = skyPath,
		}),
		StoryContext.step({
			name = "darkness",
			checkpoint = { anchor = "Anchor_Ballerina_House" },
			run = darkness,
		}),
		StoryContext.step({
			name = "climb",
			checkpoint = { point = "TowerDoor" },
			run = climb,
		}),
		StoryContext.step({
			name = "finale",
			checkpoint = { point = "TowerTopRoom" },
			run = finale,
		}),
	},
}

return chapter
