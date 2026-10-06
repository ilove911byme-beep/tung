--!strict
-- Chapter 5 "The Abandoned Mine" (screenplay.md 5-1 .. 5-5): the code lock (67, CS-15); the
-- minecart ride with the Glitchling wall behind (lean at forks, duck under beams, PERFECT_RIDE);
-- frozen Lirili and her flashback (CS-16); the three Truth Gears (levers 3-1-4-2 with spikes,
-- the lava lake with Cappuccino's secret ledge and FLOOR_IS_LAVA, the dark maze with a wandering
-- shadow); the Crudelino fight (CS-17, dashes with a 1 s scream, flares and Bombardiro's bombs or
-- stalactites when Bombardiro is jailed, CS-18 / CS-19) and the climb out through the sky hole.
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local MapData = require(Shared:WaitForChild("World"):WaitForChild("MapData"))
local Strings = require(Shared:WaitForChild("Strings"))
local TrackPath = require(Shared:WaitForChild("World"):WaitForChild("TrackPath"))

local StoryContext = require(script.Parent.Parent:WaitForChild("StoryContext"))
local SSS = script.Parent.Parent.Parent
local Systems = SSS:WaitForChild("Systems")
local BossFramework = require(Systems:WaitForChild("BossFramework"))
local Hud = require(Systems:WaitForChild("Hud"))
local ParkourService = require(Systems:WaitForChild("ParkourService"))
local Underground =
	require(SSS:WaitForChild("World"):WaitForChild("Map"):WaitForChild("Underground"))

type Ctx = StoryContext.Context

local S = 4
local CODE = "67"
local RIDE_DAMAGE = 40
local SPIKE_DAMAGE = 20
local SHADOW_DAMAGE = 30
local DASH_DAMAGE = 45
local LEVER_ORDER = { 3, 1, 4, 2 }

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

--- A boss / story model that loops an animation on the clients (MapClient plays Anim on NPCs).
local function animated(id: string, anim: string?): Model?
	local m = model(id)
	if m then
		if anim then
			m:SetAttribute("Anim", anim)
		end
		CollectionService:AddTag(m, "NPC")
	end
	return m
end

local function roomBox(
	r: { x: number, z: number, w: number, d: number, y: number, h: number }
): (Vector3, Vector3)
	return blocks(r.x, r.y - 0.5, r.z), blocks(r.x + r.w, r.y + r.h, r.z + r.d)
end

local function anyInside(ctx: Ctx, min: Vector3, max: Vector3): boolean
	for _, p in ctx:alive() do
		if ctx:inside(p, min, max) then
			return true
		end
	end
	return false
end

local function everyoneTo(ctx: Ctx, cf: CFrame)
	ctx:glitch("blackout", { duration = 1.4 })
	task.wait(0.5)
	ctx:teleport(cf, 3)
end

--- A Truth Gear lying at a ground CFrame; yields until somebody takes it.
local function gearPickup(ctx: Ctx, ground: CFrame): Player
	local gear = model("TruthGear")
	local anchor: BasePart
	if gear then
		gear:PivotTo(ground * CFrame.new(0, 2.2, 0))
		gear:SetAttribute("SpinAxis", "Y")
		gear:SetAttribute("SpinSpeed", 60)
		gear.Parent = workspace
		ctx:track(gear)
		CollectionService:AddTag(gear, "Spin")
		anchor = gear.PrimaryPart or (gear:FindFirstChildWhichIsA("BasePart", true) :: BasePart)
	else
		anchor = ctx:newPart({
			Name = "TruthGear",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 3, 3),
			CFrame = ground * CFrame.new(0, 2.2, 0),
			Color = Color3.fromRGB(230, 190, 60),
			Material = Enum.Material.Neon,
		})
	end
	local who = ctx:waitPrompt(
		anchor,
		Strings.Prompts.Take,
		{ objectText = Strings.Items.TruthGear, distance = 10 }
	)
	ctx:sfx("item_pickup", anchor.Position, 0.9)
	if ctx.inv.add(who, "truth_gear", 1) > 0 then
		for _, p in ctx:alive() do
			if p ~= who and ctx.inv.add(p, "truth_gear", 1) == 0 then
				break
			end
		end
	end
	if gear then
		gear:Destroy()
	end
	ctx.flags.set("gears", ctx.flags.get().gears + 1)
	ctx:say("C5_NARR_GEAR")
	return who
end

local function runCourse(
	ctx: Ctx,
	def: ParkourService.SegmentDef,
	origin: CFrame
): ParkourService.Segment
	local course = ParkourService.build(def, workspace, origin)
	ctx:track(course.model)
	ctx:track(function()
		course:destroy()
	end)
	return course
end

local function blk(b: ParkourService.BlockDef): ParkourService.BlockDef
	return b
end

------------------------------------------------------------------ 5-1 the door

local function door(ctx: Ctx)
	ctx:preset("night", 1)
	ctx:music("cave")
	ctx:objective("C5_CODE")
	local pad: BasePart? = nil
	for _, k in CollectionService:GetTagged("MineKeypad") do
		if k:IsA("BasePart") then
			pad = k
		end
	end
	assert(pad, "the mine keypad is missing")
	task.delay(4, function()
		ctx:say("C5_NARR_CODE")
	end)
	while true do
		ctx:waitPrompt(pad, Strings.Prompts.Code, { objectText = "Keypad", distance = 10 })
		local choice = ctx:vote({
			{ id = "41", text = "4 1" },
			{ id = "67", text = "6 7" },
			{ id = "76", text = "7 6" },
			{ id = "13", text = "1 3" },
		}, 15)
		if choice == CODE then
			break
		end
		ctx:sfx("button_click", pad.Position, 1)
		ctx:say("C5_NARR_WRONG")
	end
	ctx:clearObjective()
	ctx:cutscene("CS_15")
	for _, d in CollectionService:GetTagged("MineDoor") do
		if d:IsA("BasePart") then
			ctx.map.setDoor(d, true)
			d.CanCollide = false
			ctx:track(function()
				ctx.map.setDoor(d, false)
				d.CanCollide = true
			end)
		end
	end
	ctx:objective("C5_DOWN")
	local minA, maxA = roomBox(MapData.Caves.Adit)
	ctx:waitUntil(function()
		return anyInside(ctx, minA, maxA)
	end, 120)
	ctx:clearObjective()
end

------------------------------------------------------------------ 5-2 the minecarts

type RideEvent = { dist: number, answer: string }

local function rideEvents(): { RideEvent }
	local list: { RideEvent } = {}
	for _, b in MapData.Track.beams do
		table.insert(list, { dist = TrackPath.project(b[1], b[2]), answer = "duck" })
	end
	-- lean toward the main line at each fork (the dead end goes straight on)
	local lean = { [2] = "right", [3] = "right", [4] = "left" }
	for _, f in MapData.Track.forks do
		table.insert(list, { dist = TrackPath.vertex(f.at), answer = lean[f.at] or "right" })
	end
	table.sort(list, function(a, b)
		return a.dist < b.dist
	end)
	return list
end

local function ride(ctx: Ctx)
	local cappuccinoFree = ctx.flags.get().jailed ~= "Cappuccino"
	if cappuccinoFree then
		ctx.npcs.show("Cappuccino", true)
		ctx.npcs.place("Cappuccino", ctx:ground("MineShaftBottom") * CFrame.new(3, 0, 0))
		ctx:say("C5_CAPPUCCINO_TUNNEL")
	end
	local riders = ctx:alive()
	if #riders == 0 then
		return
	end
	for i, p in riders do
		p:SetAttribute("CartSeat", i)
		p:SetAttribute("CartFlipUntil", nil)
	end
	local start = workspace:GetServerTimeNow() + 4
	workspace:SetAttribute("CartRiders", #riders)
	workspace:SetAttribute("CartRideStart", start)
	local function stop()
		workspace:SetAttribute("CartRideStart", nil)
		workspace:SetAttribute("CartRiders", nil)
		for _, p in riders do
			p:SetAttribute("CartSeat", nil)
			p:SetAttribute("CartFlipUntil", nil)
		end
	end
	ctx:track(stop)
	ctx:objective("C5_RIDE")
	task.wait(3)
	if cappuccinoFree then
		ctx.npcs.show("Cappuccino", false)
	end
	ctx:music("chase")
	ctx:sfx("amb_minecart_loop", nil, 0.8)
	ctx:say("C5_NARR_RIDE")
	for _, e in rideEvents() do
		local at = start + TrackPath.leadTime(e.dist, #riders)
		local untilQte = at - 1.1 - workspace:GetServerTimeNow()
		if untilQte > 0 then
			task.wait(untilQte)
		end
		local seated = {}
		for _, p in riders do
			local flip = (p:GetAttribute("CartFlipUntil") :: number?) or 0
			if
				p.Parent
				and p:GetAttribute("LifeState") == "Alive"
				and flip < workspace:GetServerTimeNow()
			then
				table.insert(seated, p)
			end
		end
		if #seated > 0 then
			local results =
				ctx.qte.run(seated, { type = "choice", answer = e.answer, window = 1.6 })
			for _, p in seated do
				if not results[p] then
					ctx.flags.set("perfectRide", false)
					p:SetAttribute("CartFlipUntil", workspace:GetServerTimeNow() + 2.6)
					ctx.health.damage(p, RIDE_DAMAGE, "minecart")
					local root = rootOf(p)
					ctx:sfx("block_break_wood", root and root.Position, 1)
				end
			end
		end
	end
	local finish = start + TrackPath.length / TrackPath.speed + 0.6
	local left = finish - workspace:GetServerTimeNow()
	if left > 0 then
		task.wait(left)
	end
	stop()
	local endCf = ctx:ground("TrackEnd")
	for i, p in riders do
		if p.Character then
			p.Character:PivotTo(endCf * CFrame.new((i - 1) * 2.5 - 3, 3, -4))
		end
	end
	ctx:clearObjective()
	ctx:music("cave")
	if ctx.flags.get().perfectRide then
		ctx:award("PERFECT_RIDE", riders)
	end
end

------------------------------------------------------------------ 5-3 frozen Lirili

local function lab(ctx: Ctx)
	ctx:objective("C5_LAB")
	local minL, maxL = roomBox(MapData.Caves.Lab)
	if not ctx:waitUntil(function()
		return anyInside(ctx, minL, maxL)
	end, 150) then
		everyoneTo(ctx, ctx:ground("LabEntrance"))
	end
	ctx:clearObjective()
	ctx:preset("cave", 0)
	ctx:cutscene("CS_16")
	-- she stays frozen mid-step for the rest of the chapter
	local lirili = animated("Lirili", "A-FROZEN_STEP")
	if lirili then
		lirili:SetAttribute("Face", "sad")
		lirili:PivotTo(
			ctx:ground("LiriliFrozen")
				* CFrame.new(0, (lirili:GetAttribute("RootHeight") :: number?) or 0, 0)
		)
		lirili.Parent = workspace
		ctx:track(lirili)
	end
end

------------------------------------------------------------------ 5-4 the three Truth Gears

local function gearLevers(ctx: Ctx)
	ctx:objective("C5_DIARY")
	local L = MapData.Caves.Lab
	local diary = ctx:newPart({
		Name = "LiriliDiary",
		Size = Vector3.new(1.6, 0.3, 1.2),
		CFrame = CFrame.new(blocks(L.x + 1.5, L.y + 1.05, L.z + 6.5))
			* CFrame.Angles(0, math.rad(15), 0),
		Color = Color3.fromRGB(110, 60, 40),
		Material = Enum.Material.Fabric,
	})
	local read = false
	ctx:prompt(
		diary,
		Strings.Prompts.Read,
		{ objectText = "Lirili's diary", distance = 8 },
		function()
			if not read then
				read = true
				ctx:say("C5_NARR_LEVERS")
				ctx:objective("C5_GEAR1")
			end
		end
	)
	task.delay(50, function()
		if not read and diary.Parent then
			read = true
			ctx:say("C5_NARR_LEVERS")
			ctx:objective("C5_GEAR1")
		end
	end)

	type Lever = { index: number, handle: BasePart, rest: CFrame, pulled: boolean }
	local levers: { Lever } = {}
	for _, m in CollectionService:GetTagged("Lever") do
		local handle = m:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			table.insert(levers, {
				index = (handle:GetAttribute("Index") :: number?) or (#levers + 1),
				handle = handle,
				rest = handle.CFrame,
				pulled = false,
			})
		end
	end
	local spikes: { BasePart } = {}
	for _, s in CollectionService:GetTagged("Spikes") do
		if s:IsA("BasePart") then
			table.insert(spikes, s)
		end
	end
	local function resetLevers()
		for _, l in levers do
			l.pulled = false
			TweenService:Create(l.handle, TweenInfo.new(0.4), { CFrame = l.rest }):Play()
		end
	end
	ctx:track(function()
		for _, l in levers do
			l.handle.CFrame = l.rest
		end
		for _, s in spikes do
			s.Transparency = 1
			s.CanCollide = false
		end
	end)
	local minR, maxR = roomBox(MapData.Caves.Levers)
	local progress = 0
	local busy = false
	local solved = Instance.new("BindableEvent")
	ctx:track(solved)
	for _, l in levers do
		ctx:prompt(
			l.handle,
			Strings.Prompts.Pull,
			{ objectText = "Lever " .. l.index, distance = 8 },
			function()
				if busy or l.pulled or progress >= #LEVER_ORDER then
					return
				end
				l.pulled = true
				ctx:sfx("lever_click", l.handle.Position, 1)
				TweenService:Create(l.handle, TweenInfo.new(0.3), {
					CFrame = l.rest * CFrame.Angles(0, 0, math.rad(70)),
				}):Play()
				if LEVER_ORDER[progress + 1] == l.index then
					progress += 1
					if progress == #LEVER_ORDER then
						solved:Fire()
					end
					return
				end
				-- wrong: spikes slide out of the floor
				busy = true
				progress = 0
				ctx:say("C5_NARR_LEVERS_WRONG")
				ctx:sfx("block_break_stone", l.handle.Position, 1)
				for _, s in spikes do
					s.Transparency = 0
					s.CanCollide = true
				end
				for _, p in ctx:alive() do
					if ctx:inside(p, minR, maxR) then
						ctx.health.damage(p, SPIKE_DAMAGE, "spikes")
					end
				end
				task.wait(1.6)
				for _, s in spikes do
					s.Transparency = 1
					s.CanCollide = false
				end
				resetLevers()
				busy = false
			end
		)
	end
	solved.Event:Wait()
	ctx:sfx("clock_time_stop", blocks(131, -14, 52), 0.6)
	ctx:clearObjective()
	gearPickup(ctx, ctx:ground("LeverGear"))
end

local LAVA_ROCK = Color3.fromHex("#5A4A44")

-- origin = LavaStart (x 116.5, z 49, top of the start platform), the course runs west (-X)
local LAVA: ParkourService.SegmentDef = {
	id = "LavaLake",
	killY = -1,
	fall = "downed",
	blocks = {
		blk({ kind = "start", at = { 0, 0.25, 0 }, size = { 2, 0.5, 2 } }),
		blk({
			kind = "collapse",
			at = { -2.5, -0.5, 0.5 },
			size = { 1.2, 1, 1.2 },
			color = LAVA_ROCK,
			blockName = "stone",
		}),
		blk({
			kind = "collapse",
			at = { -4.5, -0.5, -0.5 },
			size = { 1.2, 1, 1.2 },
			color = LAVA_ROCK,
			blockName = "stone",
		}),
		blk({
			kind = "collapse",
			at = { -6.5, -0.2, 0.8 },
			size = { 1.2, 1, 1.2 },
			color = LAVA_ROCK,
			blockName = "stone",
		}),
		blk({
			kind = "checkpoint",
			at = { -8.6, -0.5, 0 },
			size = { 2, 1, 2 },
			blockName = "stone",
		}),
		blk({
			kind = "collapse",
			at = { -10.8, -0.5, -1 },
			size = { 1.2, 1, 1.2 },
			color = LAVA_ROCK,
			blockName = "stone",
		}),
		blk({
			kind = "moving",
			at = { -12.8, -0.5, 0 },
			size = { 1.4, 1, 1.4 },
			move = { 0, 0, 2 },
			period = 2.5,
			color = LAVA_ROCK,
			blockName = "stone",
		}),
		blk({
			kind = "collapse",
			at = { -14.6, -0.5, 0.6 },
			size = { 1.2, 1, 1.2 },
			color = LAVA_ROCK,
			blockName = "stone",
		}),
		blk({ kind = "finish", at = { -16.8, 0.25, 0 }, size = { 2, 0.5, 2 } }),
	},
}

local function gearLava(ctx: Ctx)
	ctx:objective("C5_GEAR2")
	local L = MapData.Caves.Lava
	local lavaTop = MapData.LavaLevel * S
	-- the secret ledge only exists once Cappuccino shows it
	local ledge = ctx.map.find("Underground", "LavaLake", "SecretLedge")
	local bridges: { BasePart } = {}
	local function setLedge(on: boolean)
		if ledge and ledge:IsA("BasePart") then
			ledge.Transparency = if on then 0 else 1
			ledge.CanCollide = on
		end
		for _, b in bridges do
			b.Transparency = if on then 0 else 1
			b.CanCollide = on
		end
	end
	for _, b in { { 115, 41, 2, 5 }, { 99, 41, 2, 5 } } do
		local part = ctx:newPart({
			Name = "LedgeBridge",
			Size = Vector3.new(b[3] * S, 1 * S, b[4] * S),
			CFrame = CFrame.new(blocks(b[1] + b[3] / 2, L.y + 3.5, b[2] + b[4] / 2)),
			Color = Color3.fromHex("#7D7D7D"),
			Material = Enum.Material.Slate,
		})
		part:SetAttribute("Block", "stone")
		table.insert(bridges, part)
	end
	setLedge(false)
	ctx:track(function()
		setLedge(true)
	end)

	local course = runCourse(ctx, LAVA, CFrame.new(blocks(116.5, -20, 49)))
	local fell: { [Player]: boolean } = {}
	local clean: { [Player]: boolean } = {}
	course.Fell:Connect(function(p: Player)
		fell[p] = true
	end)
	course.Finished:Connect(function(p: Player, noFalls: boolean)
		clean[p] = noFalls
	end)
	course:track(ctx:alive(), true)
	if ctx.flags.get().jailed ~= "Cappuccino" then
		task.delay(5, function()
			ctx.npcs.show("Cappuccino", true)
			ctx.npcs.place("Cappuccino", ctx:ground("LavaSecretPath"))
			ctx.npcs.setAnim("Cappuccino", "A-POINT")
			ctx:say("C5_CAPPUCCINO_LEDGE")
			setLedge(true)
		end)
		ctx:track(function()
			ctx.npcs.setAnim("Cappuccino", nil)
			ctx.npcs.show("Cappuccino", false)
		end)
	end
	-- anybody in the lava (also from the ledge, also after finishing) goes down
	local active = true
	ctx:track(function()
		active = false
	end)
	local minLava, maxLava =
		blocks(L.x, L.y, L.z), blocks(L.x + L.w, MapData.LavaLevel + 0.9, L.z + L.d)
	task.spawn(function()
		while active do
			for _, p in ctx:alive() do
				local root = rootOf(p)
				if root and ctx:inside(p, minLava, maxLava) and root.Position.Y < lavaTop + 4 then
					fell[p] = true
					ctx.health.down(p)
					if p.Character then
						p.Character:PivotTo(
							CFrame.new(blocks(116.5, -20, 49) + Vector3.new(0, 3, 0))
						)
					end
				end
			end
			task.wait(0.15)
		end
	end)
	-- the gear waits on the far platform
	gearPickup(ctx, ctx:ground("LavaGear"))
	local taken = os.clock()
	ctx:waitUntil(function()
		return course:allFinished() or os.clock() - taken > 40
	end, nil, 0.5)
	for p, noFalls in clean do
		if noFalls and not fell[p] and p.Parent then
			ctx:award("FLOOR_IS_LAVA", { p })
		end
	end
	active = false
	ctx:clearObjective()
	everyoneTo(ctx, ctx:ground("MazeStart"))
end

local function gearMaze(ctx: Ctx)
	ctx:objective("C5_GEAR3")
	ctx:say("C5_NARR_MAZE")
	ctx.atmosphere.fog(26, 1.5)
	ctx:track(function()
		ctx.atmosphere.fog(140, 2)
	end)
	local M = MapData.Caves.Maze
	local cells = Underground.mazeCells
	local floorY = M.y * S
	-- the shadow
	local shadow = model("GlitchlingRig")
	local shadowPos: Vector3
	local current = #cells -- far corner from the start
	if #cells == 0 then
		current = 0
	end
	local function cellPos(i: number): Vector3
		local c = cells[i]
		return Vector3.new(c.x * S, floorY + 3, c.z * S)
	end
	shadowPos = if current > 0 then cellPos(current) else blocks(150, M.y, 20)
	if shadow then
		shadow:ScaleTo(1.5)
		shadow:SetAttribute("Face", "angry")
		shadow:PivotTo(CFrame.new(shadowPos))
		shadow.Parent = workspace
		ctx:track(shadow)
	end
	local active = true
	ctx:track(function()
		active = false
	end)
	task.spawn(function()
		local previous = 0
		local hitCooldown: { [Player]: number } = {}
		local nextBeat: { [Player]: number } = {}
		while active and current > 0 do
			-- choose the next cell: toward a near player, else a random way (no turning back)
			local c = cells[current]
			local nearest: Vector3? = nil
			local nearD = 28
			for _, p in ctx:alive() do
				local root = rootOf(p)
				if root and math.abs(root.Position.Y - floorY) < 16 then
					local d = (root.Position - shadowPos).Magnitude
					if d < nearD then
						nearest, nearD = root.Position, d
					end
				end
			end
			local nextCell = c.links[1] or current
			if nearest then
				local best = math.huge
				for _, n in c.links do
					local d = flatDistance(cellPos(n), nearest)
					if d < best then
						best, nextCell = d, n
					end
				end
			else
				local options = {}
				for _, n in c.links do
					if n ~= previous then
						table.insert(options, n)
					end
				end
				if #options == 0 then
					options = c.links
				end
				if #options > 0 then
					nextCell = options[math.random(1, #options)]
				end
			end
			previous = current
			current = nextCell
			local from, to = shadowPos, cellPos(current)
			local speed = if nearest then 10 else 5
			local t0 = os.clock()
			local duration = math.max((to - from).Magnitude / speed, 0.1)
			while active do
				local a = math.clamp((os.clock() - t0) / duration, 0, 1)
				shadowPos = from:Lerp(to, a)
				if shadow and shadow.Parent then
					local look = Vector3.new(to.X, shadowPos.Y, to.Z)
					if (look - shadowPos).Magnitude > 0.1 then
						shadow:PivotTo(CFrame.lookAt(shadowPos, look))
					end
				end
				local now = os.clock()
				for _, p in ctx:alive() do
					local root = rootOf(p)
					if root then
						local d = (root.Position - shadowPos).Magnitude
						if d < 4.5 and (hitCooldown[p] or 0) < now then
							hitCooldown[p] = now + 2.5
							ctx.health.damage(p, SHADOW_DAMAGE, "shadow")
							Hud.worldFxFor({ p }, "blind", { duration = 1.2, opacity = 0.7 })
						end
						if d < 24 and (nextBeat[p] or 0) < now then
							nextBeat[p] = now + 1.6
							Hud.worldFxFor({ p }, "sfx", {
								name = "heartbeat_loop",
								volume = math.clamp(1.1 - d / 24, 0.2, 1),
							})
						end
					end
				end
				if a >= 1 then
					break
				end
				task.wait()
			end
		end
	end)
	gearPickup(ctx, ctx:ground("MazeGear"))
	active = false
	if shadow then
		shadow:Destroy()
	end
	ctx:clearObjective()
	ctx.atmosphere.fog(140, 2)
	ctx:objective("C5_CAVE")
	local minC, maxC = roomBox(MapData.Caves.Cave)
	if not ctx:waitUntil(function()
		return anyInside(ctx, minC, maxC)
	end, 120) then
		everyoneTo(ctx, ctx:ground("CaveArena"))
	end
	ctx:clearObjective()
end

------------------------------------------------------------------ 5-5 Crudelino

-- origin = the cave floor under the sky hole (x 134, z 20); a crumbling spiral up to the roof,
-- then a vine up the hole to the hill top
local function escapeDef(): ParkourService.SegmentDef
	local list: { ParkourService.BlockDef } = {
		blk({ kind = "start", at = { 0, 0.25, 0 }, size = { 2, 0.5, 2 } }),
	}
	for k = 1, 11 do
		local a = math.rad(k * 40)
		table.insert(
			list,
			blk({
				kind = if k % 4 == 0 then "block" else "collapse",
				at = { 1.5 + 3.5 * math.cos(a), k * 1.0 - 0.5, 0.5 + 3.5 * math.sin(a) },
				size = { 1.5, 1, 1.5 },
				color = Color3.fromHex("#6E6E6E"),
				blockName = "cobblestone",
			})
		)
	end
	table.insert(
		list,
		blk({
			kind = "checkpoint",
			at = { 1.5, 11.75, 0.5 },
			size = { 2, 0.5, 2 },
			blockName = "stone",
		})
	)
	table.insert(list, blk({ kind = "vine", at = { 1.5, 27.5, 0.5 }, size = { 1, 31, 1 } }))
	table.insert(list, blk({ kind = "finish", at = { 1.5, 43.25, 2.6 }, size = { 3, 0.5, 2 } }))
	return {
		id = "CaveEscape",
		killY = -0.6,
		fall = "damage",
		fallDamage = 20,
		blocks = list,
	}
end

local function crudelino(ctx: Ctx)
	local C = MapData.Caves.Cave
	local center = blocks(C.x + C.w / 2, C.y, C.z + C.d / 2)
	local hover = center.Y + 5
	ctx:preset("cave", 0)
	ctx:cutscene("CS_17")
	ctx:music("boss")
	local boss = BossFramework.new({
		name = "Crudelino",
		cardTitle = Strings.Bosses.Crudelino.title,
		cardSubtitle = Strings.Bosses.Crudelino.subtitle,
		signature = "crudelino_signature",
		phases = {},
	})
	boss:card()
	boss:arena(center, 36)
	ctx:track(function()
		boss:cleanup()
	end)
	ctx:objective("C5_CRUDELINO")

	local cube = model("Crudelino")
	local pos = Vector3.new(center.X, hover, C.z * S + 10)
	if cube then
		cube:SetAttribute("Face", "angry")
		cube:PivotTo(CFrame.new(pos))
		cube.Parent = workspace
		ctx:track(cube)
	end
	-- broken columns come back after a wipe
	local columns: { BasePart } = {}
	for _, c in CollectionService:GetTagged("CaveColumn") do
		if c:IsA("BasePart") then
			table.insert(columns, c)
		end
	end
	ctx:track(function()
		for _, c in columns do
			c.Transparency = 0
			c.CanCollide = true
		end
	end)

	local function face(target: Vector3)
		if cube and cube.Parent then
			local look = Vector3.new(target.X, pos.Y, target.Z)
			if (look - pos).Magnitude > 0.1 then
				cube:PivotTo(CFrame.lookAt(pos, look))
			else
				cube:PivotTo(CFrame.new(pos))
			end
		end
	end

	local hitCooldown: { [Player]: number } = {}
	--- One dash at the nearest player: 1 s scream (red telegraph), then a straight charge.
	local function dash()
		local target: BasePart? = nil
		local best = math.huge
		for _, p in ctx:alive() do
			local root = rootOf(p)
			if root then
				local d = flatDistance(root.Position, pos)
				if d < best then
					best, target = d, root
				end
			end
		end
		if not target then
			task.wait(1)
			return
		end
		face(target.Position)
		if cube then
			boss:telegraph(cube, 1, "crudelino_signature")
		else
			task.wait(1)
		end
		local goal = Vector3.new(target.Position.X, hover, target.Position.Z)
		local dir = goal - pos
		if dir.Magnitude < 1 then
			return
		end
		goal = pos + dir.Unit * math.min(dir.Magnitude + 16, 70)
		goal = Vector3.new(
			math.clamp(goal.X, (C.x + 1.5) * S, (C.x + C.w - 1.5) * S),
			hover,
			math.clamp(goal.Z, (C.z + 1.5) * S, (C.z + C.d - 1.5) * S)
		)
		local from = pos
		local duration = math.max((goal - from).Magnitude / 70, 0.2)
		local t0 = os.clock()
		while true do
			local a = math.clamp((os.clock() - t0) / duration, 0, 1)
			pos = from:Lerp(goal, a)
			face(goal)
			local now = os.clock()
			for _, p in ctx:alive() do
				local root = rootOf(p)
				if
					root
					and flatDistance(root.Position, pos) < 5.5
					and (hitCooldown[p] or 0) < now
				then
					hitCooldown[p] = now + 1.5
					ctx.health.damage(p, DASH_DAMAGE, "crudelino")
					ctx.flags.set("untouchable", false)
					root.AssemblyLinearVelocity = (root.Position - pos).Unit * 60
						+ Vector3.new(0, 40, 0)
				end
			end
			for _, c in columns do
				if c.CanCollide and flatDistance(c.Position, pos) < 7 then
					c.CanCollide = false
					c.Transparency = 1
					ctx:sfx("block_break_stone", c.Position, 1)
					Hud.worldFx(
						"debrisBurst",
						{ at = c.Position, count = 10, colors = { "#7D7D7D", "#5A5A5A" } }
					)
				end
			end
			if a >= 1 then
				break
			end
			task.wait()
		end
		ctx:sfx("block_break_stone", pos, 0.8)
	end

	-- phase 1: dashes
	task.delay(2, function()
		ctx:say("C5_CRUDELINO_TAUNT")
	end)
	for _ = 1, 7 do
		dash()
		task.wait(1.6)
	end

	-- phase 2: marks (flares + Bombardiro) or stalactites when Bombardiro is jailed
	local hits = 0
	local bombardiroFree = ctx.flags.get().jailed ~= "Bombardiro"
	local stunnedUntil = 0
	local function stunned(): boolean
		return os.clock() < stunnedUntil
	end
	if bombardiroFree then
		ctx:objective("C5_FLARES", hits)
		ctx:say("C5_BOMBARDIRO_MARK")
		-- flare piles at the walls (respawn)
		for i = 1, 4 do
			local cf = ctx:ground("Flare" .. i)
			local pile = ctx:newPart({
				Name = "FlarePile",
				Size = Vector3.new(1.6, 0.8, 1.6),
				CFrame = cf * CFrame.new(0, 0.4, 0),
				Color = Color3.fromRGB(200, 40, 40),
				Material = Enum.Material.SmoothPlastic,
			})
			local glow = Instance.new("PointLight")
			glow.Color = Color3.fromRGB(255, 60, 60)
			glow.Range = 8
			glow.Parent = pile
			ctx:prompt(
				pile,
				Strings.Prompts.Take,
				{ objectText = "Flares", distance = 8 },
				function(player)
					if ctx.inv.count(player, "flare") < 3 then
						ctx.inv.add(player, "flare", 1)
						ctx:sfx("item_pickup", pile.Position, 0.6)
					end
				end
			)
		end
		local bombing = false
		ctx.inv.onUse("flare", function(player: Player): boolean
			local root = rootOf(player)
			if not root or bombing then
				return false
			end
			local at = Vector3.new(root.Position.X, center.Y + 0.4, root.Position.Z)
				+ root.CFrame.LookVector * 4
			local flare = ctx:newPart({
				Name = "Flare",
				Size = Vector3.new(0.5, 1.2, 0.5),
				CFrame = CFrame.new(at),
				Color = Color3.fromRGB(255, 50, 50),
				Material = Enum.Material.Neon,
			})
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 50, 50)
			light.Range = 18
			light.Brightness = 3
			light.Parent = flare
			local smoke = Instance.new("Smoke")
			smoke.Color = Color3.fromRGB(255, 80, 80)
			smoke.RiseVelocity = 4
			smoke.Parent = flare
			ctx:sfx("torch_ignite", at, 1)
			bombing = true
			task.spawn(function()
				-- Bombardiro comes round over the hole and drops a bomb on the mark
				local plane = animated("Bombardiro", "A-FLY")
				local hole = blocks(MapData.SkyHole.x + 2.5, 30, MapData.SkyHole.z + 2.5)
				if plane then
					plane:SetAttribute("CharacterId", "BombardiroFlyby")
					plane.Parent = workspace
					ctx:track(plane)
					local a, b = hole + Vector3.new(-90, 0, 0), hole + Vector3.new(90, 0, 0)
					local t0 = os.clock()
					while os.clock() - t0 < 2.4 do
						local k = (os.clock() - t0) / 2.4
						local p = a:Lerp(b, k)
						plane:PivotTo(CFrame.lookAt(p, p + Vector3.xAxis))
						task.wait()
					end
					plane:Destroy()
				else
					task.wait(2.4)
				end
				local bomb = ctx:newPart({
					Name = "Bomb",
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(2.4, 2.4, 2.4),
					CFrame = CFrame.new(Vector3.new(at.X, hole.Y - 30, at.Z)),
					Color = Color3.fromRGB(30, 30, 34),
					Material = Enum.Material.Metal,
				})
				TweenService
					:Create(
						bomb,
						TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
						{
							CFrame = CFrame.new(at),
						}
					)
					:Play()
				task.wait(1.1)
				bomb:Destroy()
				ctx:sfx("explosion_boom", at, 1)
				Hud.worldFx(
					"debrisBurst",
					{ at = at, count = 16, colors = { "#FF7020", "#FFD040", "#5A5A5A" } }
				)
				local explosion = Instance.new("Explosion")
				explosion.Position = at
				explosion.BlastPressure = 0
				explosion.DestroyJointRadiusPercent = 0
				explosion.BlastRadius = 10
				explosion.Parent = workspace
				for _, p in ctx:alive() do
					local r = rootOf(p)
					if r and (r.Position - at).Magnitude < 9 then
						ctx.health.damage(p, 20, "bomb")
					end
				end
				if flatDistance(pos, at) < 14 then
					hits += 1
					stunnedUntil = os.clock() + 3
					ctx:objective("C5_FLARES", hits)
					if hits < 3 then
						ctx:say("C5_BOMBARDIRO_HIT")
					end
				end
				flare:Destroy()
				bombing = false
			end)
			return true
		end)
		ctx:track(function()
			ctx.inv.onUse("flare", function()
				return false
			end)
		end)
	else
		ctx:objective("C5_STALACTITES", hits)
		ctx:say("C5_NARR_STALACTITES")
		for _, r in CollectionService:GetTagged("Rock") do
			if r:IsA("BasePart") then
				local rest = r.CFrame
				ctx:prompt(
					r,
					Strings.Prompts.Pickup,
					{ objectText = "Stone", distance = 7 },
					function(player)
						if r.Transparency < 1 and ctx.inv.add(player, "stone", 1) == 0 then
							r.Transparency = 1
							r.CanCollide = false
							task.delay(10, function()
								r.CFrame = rest
								r.Transparency = 0
								r.CanCollide = true
							end)
						end
					end
				)
				ctx:track(function()
					r.CFrame = rest
					r.Transparency = 0
					r.CanCollide = true
				end)
			end
		end
		type Stalactite = { part: BasePart, rest: CFrame, down: boolean }
		local stalactites: { Stalactite } = {}
		for _, s in CollectionService:GetTagged("Stalactite") do
			if s:IsA("BasePart") then
				table.insert(stalactites, { part = s, rest = s.CFrame, down = false })
			end
		end
		ctx:track(function()
			for _, s in stalactites do
				s.part.CFrame = s.rest
				s.part.Transparency = 0
				s.down = false
			end
		end)
		ctx.inv.onUse("stone", function(player: Player): boolean
			local root = rootOf(player)
			if not root then
				return false
			end
			local target: Stalactite? = nil
			local best = 40
			for _, s in stalactites do
				local d = flatDistance(root.Position, s.part.Position)
				if not s.down and d < best then
					best, target = d, s
				end
			end
			if not target then
				return false
			end
			local s = target
			s.down = true
			ctx:sfx("block_break_stone", s.part.Position, 1)
			local ground = Vector3.new(s.part.Position.X, center.Y + 2, s.part.Position.Z)
			TweenService
				:Create(
					s.part,
					TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{
						CFrame = CFrame.new(ground),
					}
				)
				:Play()
			task.delay(0.7, function()
				Hud.worldFx(
					"debrisBurst",
					{ at = ground, count = 12, colors = { "#7D7D7D", "#5A5A5A" } }
				)
				if flatDistance(pos, ground) < 9 then
					hits += 1
					stunnedUntil = os.clock() + 3
					ctx:objective("C5_STALACTITES", hits)
					ctx:sfx("explosion_boom", ground, 0.6)
				end
				task.wait(6)
				s.part.Transparency = 1
				s.part.CFrame = s.rest
				task.wait(4)
				s.part.Transparency = 0
				s.down = false
			end)
			return true
		end)
		ctx:track(function()
			ctx.inv.onUse("stone", function()
				return false
			end)
		end)
	end
	local nextTaunt = os.clock() + 15
	while hits < 3 do
		if stunned() then
			task.wait(0.2)
		else
			dash()
			-- after each charge he stands still a moment: the time to mark him
			local pause = os.clock() + (if bombardiroFree then 4 else 3)
			while os.clock() < pause and hits < 3 do
				task.wait(0.2)
			end
		end
		if os.clock() > nextTaunt then
			nextTaunt = os.clock() + math.random(15, 24)
			task.spawn(ctx.say, ctx, "C5_CRUDELINO_TAUNT")
		end
	end
	ctx:clearObjective()
	ctx.threats.clear()
	if cube then
		cube:Destroy()
	end
	if bombardiroFree then
		ctx:cutscene("CS_18")
		ctx.flags.set("bombardiroDown", true)
		ctx.npcs.show("Bombardiro", false)
	end
	ctx:cutscene("CS_19")

	-- phase 3: the cave falls in, climb out
	ctx:music("chase")
	ctx:say("C5_NARR_CLIMB")
	ctx:objective("C5_ESCAPE")
	local course = runCourse(ctx, escapeDef(), CFrame.new(blocks(134, C.y, 20)))
	course:track(ctx:alive(), false)
	local endsAt = ctx:timer(120)
	local active = true
	ctx:track(function()
		active = false
	end)
	task.spawn(function()
		while active do
			local p = blocks(
				C.x + 2 + math.random() * (C.w - 4),
				C.y + C.h - 1,
				C.z + 2 + math.random() * (C.d - 4)
			)
			Hud.worldFx(
				"debrisBurst",
				{ at = p, count = 8, colors = { "#7D7D7D", "#5A5A5A" }, down = true }
			)
			ctx:sfx("block_break_stone", p, 0.7)
			task.wait(1.4)
		end
	end)
	ctx:waitUntil(function()
		return course:allFinished() or workspace:GetServerTimeNow() > endsAt
	end, nil, 0.5)
	active = false
	ctx:clearTimer()
	ctx:clearObjective()
	local top = ctx:ground("CaveExitTop")
	for i, p in ctx:players() do
		if course:isRunning(p) and p:GetAttribute("LifeState") == "Alive" then
			ctx.health.damage(p, 40, "cavein")
		end
		if p.Character then
			p.Character:PivotTo(top * CFrame.new((i - 1) * 2.5 - 6, 3, 0))
		end
	end
	ctx:award("BEAT_CRUDELINO")
	if ctx.flags.get().untouchable then
		ctx:award("UNTOUCHABLE")
	end
	ctx:award("CHAPTER_5")
end

local chapter: StoryContext.Chapter = {
	index = 5,
	title = "The Abandoned Mine",
	steps = {
		StoryContext.step({
			name = "door",
			checkpoint = { anchor = "Anchor_Mine_Door", offset = Vector3.new(0, 0, -24) },
			run = door,
		}),
		StoryContext.step({
			name = "ride",
			checkpoint = { point = "MineShaftBottom" },
			run = ride,
		}),
		StoryContext.step({ name = "lab", run = lab }),
		StoryContext.step({
			name = "gear1",
			checkpoint = { point = "LabEntrance" },
			run = gearLevers,
		}),
		StoryContext.step({
			name = "gear2",
			checkpoint = { point = "LavaStart" },
			run = gearLava,
		}),
		StoryContext.step({
			name = "gear3",
			checkpoint = { point = "MazeStart" },
			run = gearMaze,
		}),
		StoryContext.step({
			name = "crudelino",
			checkpoint = { point = "CaveArena" },
			run = crudelino,
		}),
	},
}

return chapter
