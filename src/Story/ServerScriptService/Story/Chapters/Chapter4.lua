--!strict
-- Chapter 4 "The Second Night" (screenplay.md 4-1 .. 4-5): night falls in seconds and Giallino
-- becomes Negatino (CS-10); the boss fight on the square (oil bottles, four braziers, Negatino
-- cannot enter light, he puts braziers out, fan them back with a QTE, Glitchling waves, all four
-- burning for 10 s wins -> CS-11); Tung Tung's reveal (CS-12, at the inn door or from the barn);
-- the great light breaks out of the tower (CS-13) and chases the party to the forest; the forest
-- parkour, then the gorge: Patapim's roots (CS-14, riddle solved) or the long way round.
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NamesList = require(Shared:WaitForChild("StoryData"):WaitForChild("NamesList"))
local Strings = require(Shared:WaitForChild("Strings"))

local StoryContext = require(script.Parent.Parent:WaitForChild("StoryContext"))
local Systems = script.Parent.Parent.Parent:WaitForChild("Systems")
local BossFramework = require(Systems:WaitForChild("BossFramework"))
local Hud = require(Systems:WaitForChild("Hud"))
local ParkourService = require(Systems:WaitForChild("ParkourService"))

type Ctx = StoryContext.Context

local S = 4
local SQUARE = Vector3.new(80, 12, 80) * S
local BRAZIER_RADIUS = 22
local LANTERN_RADIUS = 10
local GLOWING_RADIUS = 14
local NEGATINO_SPEED = 14
local TOUCH_DAMAGE = 35

local INN_MIN = Vector3.new(62.5 * S, 11 * S, 75.5 * S)
local INN_MAX = Vector3.new(69.5 * S, 20 * S, 84.5 * S)

local function blocks(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z) * S
end

local function rootOf(p: Player): BasePart?
	local character = p.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
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

------------------------------------------------------------------ 4-1 night in seconds

local function nightfall(ctx: Ctx)
	ctx:companion(false) -- the companion is gone: Giallino is the threat now
	ctx:cutscene("CS_10")
	ctx:preset("night_deep", 0)
	ctx.atmosphere.fog(90, 1)
	ctx:glitch("signSwap", { text = "SAY YES" })
	ctx:glitch("lightsOut", { tag = "Lamp" })
	for _, id in
		{
			"Tralalero",
			"Chimpanzini",
			"TrippiTroppi",
			"BonecaAmbalabu",
			"LaVacaSaturno",
			"GlorboFruttodrillo",
			"Strawberry",
			"Banana",
			"Bombardiro",
			"Cappuccino",
		}
	do
		if ctx.flags.get().jailed ~= id then
			ctx.npcs.show(id, false)
		end
	end
end

------------------------------------------------------------------ 4-2 Negatino

type Brazier = {
	index: number,
	model: Model,
	bowl: BasePart,
	fire: Fire?,
	light: PointLight?,
	lit: boolean,
	busy: boolean,
}

local function braziers(): { Brazier }
	local out: { Brazier } = {}
	for _, m in CollectionService:GetTagged("Brazier") do
		if m:IsA("Model") then
			local bowl = m:FindFirstChild("Bowl")
			if bowl and bowl:IsA("BasePart") then
				table.insert(out, {
					index = (m:GetAttribute("Index") :: number?) or (#out + 1),
					model = m,
					bowl = bowl,
					fire = bowl:FindFirstChildOfClass("Fire"),
					light = bowl:FindFirstChildOfClass("PointLight"),
					lit = false,
					busy = false,
				})
			end
		end
	end
	table.sort(out, function(a, b)
		return a.index < b.index
	end)
	return out
end

local function setLit(b: Brazier, on: boolean)
	b.lit = on
	if b.fire then
		b.fire.Enabled = on
	end
	if b.light then
		b.light.Enabled = on
	end
	b.model:SetAttribute("Lit", on)
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function negatino(ctx: Ctx)
	ctx:preset("night_deep", 0)
	ctx:music("boss")
	ctx.inv.setFuelDrain(true)
	ctx:track(function()
		ctx.inv.setFuelDrain(false)
	end)
	local boss = BossFramework.new({
		name = "Negatino",
		cardTitle = Strings.Bosses.Negatino.title,
		cardSubtitle = Strings.Bosses.Negatino.subtitle,
		signature = "negatino_signature",
		phases = {},
	})
	boss:card()
	ctx:say("C4_NARR_OIL")

	local list = braziers()
	for _, b in list do
		setLit(b, false)
	end
	ctx:track(function()
		for _, b in list do
			setLit(b, false)
		end
	end)

	-- the boss
	local neg = model("Negatino")
	local pos = SQUARE + Vector3.new(0, 24, 0)
	if neg then
		neg:SetAttribute("Face", "neutral")
		neg:PivotTo(CFrame.new(pos))
		neg.Parent = workspace
		ctx:track(neg)
	end

	-- oil bottles in the alleys
	for i = 1, 4 do
		local bottle = ctx:newPart({
			Name = "OilBottle",
			Size = Vector3.new(1, 1.6, 1),
			CFrame = ctx:ground("OilSpot" .. i) * CFrame.new(0, 0.8, 0),
			Color = Color3.fromRGB(80, 140, 60),
			Material = Enum.Material.Glass,
			Transparency = 0.2,
		})
		local light = Instance.new("PointLight")
		light.Range = 6
		light.Brightness = 0.6
		light.Color = Color3.fromRGB(150, 255, 120)
		light.Parent = bottle
		ctx:prompt(
			bottle,
			Strings.Prompts.Pickup,
			{ objectText = "Oil", distance = 8 },
			function(player)
				if bottle.Parent then
					ctx.inv.add(player, "oil_bottle", 1)
					ctx:sfx("item_pickup", bottle.Position, 0.7)
					bottle:Destroy()
				end
			end
		)
	end

	local phase = 1
	local everLit = 0
	-- lighting / fanning each brazier
	for _, b in list do
		ctx:prompt(
			b.bowl,
			Strings.Prompts.Light,
			{ objectText = "Brazier", distance = 10, hold = 0.5 },
			function(player)
				if b.lit or b.busy then
					return
				end
				if phase == 1 or not b.model:GetAttribute("WasLit") then
					if not ctx.inv.remove(player, "oil_bottle", 1) then
						return
					end
					b.model:SetAttribute("WasLit", true)
					setLit(b, true)
					ctx:sfx("torch_ignite", b.bowl.Position, 0.9)
				else
					-- fan the fire back to life (QTE)
					b.busy = true
					local results = ctx.qte.run(
						{ player },
						{ type = "tap", presses = 10, duration = 4, label = Strings.Prompts.Fan }
					)
					b.busy = false
					if results[player] and not b.lit then
						setLit(b, true)
						ctx:sfx("torch_ignite", b.bowl.Position, 0.9)
					end
				end
			end
		)
	end

	local function circles(): { { at: Vector3, r: number } }
		local out = {}
		for _, b in list do
			if b.lit then
				table.insert(out, { at = b.bowl.Position, r = BRAZIER_RADIUS })
			end
		end
		for _, p in ctx:alive() do
			local root = rootOf(p)
			local fuel = (p:GetAttribute("LanternFuel") :: number?) or 0
			if root and fuel > 0 then
				if ctx.inv.has(p, "glowing_lantern") then
					table.insert(out, { at = root.Position, r = GLOWING_RADIUS })
				elseif ctx.inv.has(p, "lantern") then
					table.insert(out, { at = root.Position, r = LANTERN_RADIUS })
				end
			end
		end
		return out
	end
	local function inLight(at: Vector3, list_: { { at: Vector3, r: number } }): boolean
		for _, c in list_ do
			if flatDistance(at, c.at) < c.r then
				return true
			end
		end
		return false
	end

	local hitCooldown: { [Player]: number } = {}
	local litFor = 0
	local nextOut = math.huge
	local nextWave = math.huge
	local nextTaunt = os.clock() + 12
	local nextDrain = 0
	local taunts = { "C4_NEGATINO_TAUNT_1", "C4_NEGATINO_TAUNT_2", "C4_NEGATINO_TAUNT_3" }
	local won = false
	local last = os.clock()
	while not won do
		task.wait(0.1)
		local now = os.clock()
		local dt = now - last
		last = now
		local litCount = 0
		for _, b in list do
			if b.lit then
				litCount += 1
			end
		end
		everLit = math.max(everLit, litCount)
		if phase == 1 then
			ctx:objective("C4_OIL", litCount)
			if litCount == #list then
				phase = 2
				ctx:say("C4_NEGATINO_PHASE2")
				ctx:objective("C4_KEEP_LIT")
				nextOut = now + 3
				nextWave = now + 20
			end
		else
			if litCount == #list then
				litFor += dt
				if litFor >= 10 then
					won = true
				end
			else
				litFor = 0
			end
			-- Negatino puts out a brazier unless somebody guards it
			if now >= nextOut then
				nextOut = now + math.random(7, 10)
				local lit = {}
				for _, b in list do
					if b.lit then
						table.insert(lit, b)
					end
				end
				if #lit > 0 then
					local target = lit[math.random(1, #lit)]
					task.spawn(function()
						boss:telegraph(target.model, 2.5, "negatino_signature")
						local guarded = false
						for _, p in ctx:alive() do
							local root = rootOf(p)
							if root and flatDistance(root.Position, target.bowl.Position) < 9 then
								guarded = true
							end
						end
						if not guarded and target.lit then
							setLit(target, false)
							ctx.flags.set("neverDark", false)
							ctx:sfx("torch_ignite", target.bowl.Position, 0.5)
						end
					end)
				end
			end
			if now >= nextWave then
				nextWave = now + 20
				boss:wave(3, CFrame.new(SQUARE), 30)
			end
		end
		if now >= nextTaunt then
			nextTaunt = now + math.random(14, 22)
			task.spawn(ctx.say, ctx, taunts[math.random(1, #taunts)])
		end
		-- movement: toward the nearest player outside the light, never into the light
		if neg then
			local light = circles()
			local best: Player? = nil
			local bestD = math.huge
			for _, p in ctx:alive() do
				local root = rootOf(p)
				if
					root
					and not p:GetAttribute("HidingIn")
					and not inLight(root.Position, light)
				then
					local d = flatDistance(root.Position, pos)
					if d < bestD then
						best, bestD = p, d
					end
				end
			end
			local goal = SQUARE + Vector3.new(0, 24, 0)
			local bestRoot = best and rootOf(best)
			if bestRoot then
				goal = bestRoot.Position + Vector3.new(0, 3, 0)
			end
			local delta = goal - pos
			local step = if delta.Magnitude > 0
				then delta.Unit * math.min(delta.Magnitude, NEGATINO_SPEED * dt)
				else Vector3.zero
			local nextPos = pos + step
			if not inLight(nextPos, light) or nextPos.Y > SQUARE.Y + 20 then
				pos = nextPos
			end
			neg:PivotTo(
				CFrame.lookAt(pos, Vector3.new(goal.X, pos.Y, goal.Z) + Vector3.new(0.01, 0, 0))
			)
			-- touch: 35 damage and 3 s of darkness
			for _, p in ctx:alive() do
				local root = rootOf(p)
				if
					root
					and flatDistance(root.Position, pos) < 5
					and math.abs(root.Position.Y - pos.Y) < 9
				then
					if (hitCooldown[p] or 0) < now and not inLight(root.Position, light) then
						hitCooldown[p] = now + 3
						ctx.health.damage(p, TOUCH_DAMAGE, "negatino")
						Hud.worldFxFor({ p }, "blind", { duration = 3 })
					end
				end
			end
			-- colors drain away as he comes closer
			if now >= nextDrain then
				nextDrain = now + 0.6
				for _, p in ctx:players() do
					local root = rootOf(p)
					if root then
						local amount = math.clamp(1 - (root.Position - pos).Magnitude / 90, 0, 0.85)
						Hud.worldFxFor({ p }, "colorDrain", { amount = amount, duration = 0.6 })
					end
				end
			end
		end
	end
	ctx.threats.clear()
	ctx:clearObjective()
	if neg then
		neg:Destroy()
	end
	Hud.worldFx("colorDrain", { amount = 0, duration = 1 })
	ctx:cutscene("CS_11")
	ctx:award("BEAT_NEGATINO")
	if ctx.flags.get().neverDark then
		ctx:award("NEVER_DARK")
	end
	ctx:preset("night", 2)
	ctx.inv.setFuelDrain(false)
end

------------------------------------------------------------------ 4-3 / 4-4 Tung Tung, the great light, the chase

local function tungReveal(ctx: Ctx)
	-- back into the inn for the rest of the night
	ctx:glitch("blackout", { duration = 1.6 })
	task.wait(0.4)
	for _, p in ctx:players() do
		if not ctx:inside(p, INN_MIN, INN_MAX) and p.Character then
			p.Character:PivotTo(ctx:point("Fireplace") * CFrame.new(math.random(-3, 3), 3, -6))
		end
	end
	local door = ctx.map.find("Village", "Tavern", "Door")
	local jailed = ctx.flags.get().jailed == "TungTung"
	if door and door:IsA("BasePart") then
		ctx.map.setDoor(door, false)
		if not jailed then
			door.Transparency = 1
			door.CanCollide = false
		end
	end
	ctx:cutscene("CS_12", if jailed then "jailed" else "free")
	if door and door:IsA("BasePart") then
		door.Transparency = 0
		door.CanCollide = true
		ctx.map.setDoor(door, true)
	end
	if not jailed and not ctx.clues.namesUnlocked() then
		ctx.clues.unlockNames() -- he showed his board of names
		for _, p in ctx:players() do
			ctx.inv.add(p, "name_board", 1)
		end
	end
	ctx.npcs.show("TungTung", false)
end

local CHASE_PATH = {
	blocks(71.5, 12.6, 84),
	blocks(75, 12.6, 88.5),
	blocks(77.5, 12.6, 96),
	blocks(77, 12.6, 104),
	blocks(68, 12.6, 108.5),
	blocks(60, 12.6, 110.5),
	blocks(55, 12.6, 113),
}

local function chase(ctx: Ctx)
	ctx:cutscene("CS_13")
	ctx:music("chase")
	ctx:objective("C4_RUN")
	-- the huge Giallino follows the path, a few steps behind the party
	local giant = model("Giallino")
	if giant then
		giant:SetAttribute("Face", "happy")
		giant:ScaleTo(8)
		giant.Parent = workspace
		ctx:track(giant)
		local glow = giant:FindFirstChild("Glow", true)
		if glow and glow:IsA("PointLight") then
			glow.Range = 60
			glow.Brightness = 4
		end
	end
	-- falling fences and Glitchlings on the way
	for i, f in { { 76.5, 100 }, { 66, 108.5 } } do
		local fence = ctx:newPart({
			Name = "FallingFence" .. i,
			Size = Vector3.new(12, 4, 0.6),
			CFrame = CFrame.new(blocks(f[1], 12, f[2]) + Vector3.new(0, 2, 0)),
			Color = Color3.fromHex("#9C7646"),
			Material = Enum.Material.WoodPlanks,
			CanCollide = true,
		})
		task.delay(3 + i * 4, function()
			if fence.Parent then
				fence.CFrame = fence.CFrame
					* CFrame.new(0, -1.7, -1.6)
					* CFrame.Angles(math.rad(-80), 0, 0)
				ctx:sfx("block_break_wood", fence.Position, 0.9)
			end
		end)
	end
	ctx.threats.spawnGlitchling(CFrame.new(blocks(79, 12, 102)))
	ctx.threats.spawnGlitchling(CFrame.new(blocks(64, 12, 111)))
	task.delay(4, function()
		ctx:say("C4_GIALLINO_CHASE_1")
	end)
	task.delay(12, function()
		ctx:say("C4_GIALLINO_CHASE_2")
	end)
	ctx.threats.chase({
		path = CHASE_PATH,
		speed = 13,
		model = giant,
		lagSeconds = 3,
		players = ctx:players(),
	})
	ctx.threats.clear()
	ctx:clearObjective()
end

------------------------------------------------------------------ 4-5 the forest and the gorge

local function blk(b: ParkourService.BlockDef): ParkourService.BlockDef
	return b
end

local LOG = Color3.fromHex("#604428")
local VINE = Color3.fromHex("#2E6222")

-- origin = the forest entrance (x 55, z 113), course runs south-west to the gorge's north edge
local FOREST: ParkourService.SegmentDef = {
	id = "ForestRun",
	killY = -1.5,
	fall = "damage",
	fallDamage = 20,
	blocks = {
		blk({ kind = "start", at = { 0, 0.25, 0 }, size = { 3, 0.5, 3 } }),
		blk({
			kind = "block",
			at = { -3, 0.5, 3 },
			size = { 5, 1, 1 },
			color = LOG,
			blockName = "oak_log",
		}),
		blk({
			kind = "block",
			at = { -6.5, 1.5, 5 },
			size = { 1, 1, 4 },
			color = LOG,
			blockName = "oak_log",
		}),
		blk({
			kind = "block",
			at = { -9, 2.5, 7.5 },
			size = { 4, 1, 1 },
			color = LOG,
			blockName = "oak_log",
		}),
		blk({ kind = "vine", at = { -11.5, 4, 9 }, size = { 1, 4, 1 }, color = VINE }),
		blk({
			kind = "checkpoint",
			at = { -12.5, 5.75, 11 },
			size = { 2, 0.5, 2 },
			color = LOG,
			blockName = "oak_log",
		}),
		blk({ kind = "collapse", at = { -14.5, 5.5, 13 }, color = LOG, blockName = "oak_log" }),
		blk({
			kind = "block",
			at = { -16.5, 4.5, 15 },
			size = { 1, 1, 3 },
			color = LOG,
			blockName = "oak_log",
		}),
		blk({
			kind = "block",
			at = { -18, 3, 18 },
			size = { 3, 1, 1 },
			color = LOG,
			blockName = "oak_log",
		}),
		blk({
			kind = "block",
			at = { -19.5, 1.5, 20.5 },
			size = { 1, 1, 3 },
			color = LOG,
			blockName = "oak_log",
		}),
		blk({ kind = "finish", at = { -20, 0.25, 23.5 }, size = { 4, 0.5, 2 } }),
	},
}

-- the long way round over the narrow west end of the gorge: two hard jumps
local DETOUR: ParkourService.SegmentDef = {
	id = "GorgeDetour",
	killY = -3,
	fall = "damage",
	fallDamage = 20,
	returnToStart = true,
	blocks = {
		blk({ kind = "start", at = { 0, 0.25, 0 }, size = { 2, 0.5, 2 } }),
		blk({
			kind = "block",
			at = { 0, -0.5, 2.6 },
			size = { 1, 1, 1 },
			color = Color3.fromHex("#767676"),
			blockName = "cobblestone",
		}),
		blk({
			kind = "block",
			at = { 0.4, -0.5, 5.4 },
			size = { 1, 1, 1 },
			color = Color3.fromHex("#767676"),
			blockName = "cobblestone",
		}),
		blk({ kind = "finish", at = { 0, 0.25, 8.2 }, size = { 2, 0.5, 2 } }),
	},
}

local function runCourse(ctx: Ctx, def: ParkourService.SegmentDef, origin: CFrame, timeout: number)
	local course = ParkourService.build(def, workspace, origin)
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
		if firstDone and os.clock() - firstDone > 60 then
			return true
		end
		return os.clock() - started > timeout
	end, nil, 0.5)
end

local function forest(ctx: Ctx)
	ctx:objective("C4_FOREST")
	ctx.atmosphere.fog(70, 2)
	runCourse(ctx, FOREST, CFrame.new(blocks(55, 12, 113)), 240)
	-- the gorge
	ctx:objective("C4_GORGE")
	ctx:teleport(ctx:ground("GorgeNorth") * CFrame.new(0, 0, 12), 3)
	if ctx.flags.get().riddleCorrect then
		ctx:cutscene("CS_14")
		ctx.flags.set("patapimGone", true)
		ctx.clues.addName(NamesList.afterPatapim)
		ctx.npcs.show("Patapim", false)
		-- the root bridge stays (server side, so everyone can cross)
		for i = 0, 5 do
			local root = ctx:newPart({
				Name = "RootBridge",
				Size = Vector3.new(1.1, 1.1, 7.2 * S),
				CFrame = CFrame.new(blocks(33.6 + i * 0.55, 11.8, 141))
					* CFrame.Angles(0, 0, math.rad(i * 25)),
				Color = Color3.fromHex("#5A3C22"),
				Material = Enum.Material.Wood,
				CanCollide = true,
			})
			root:SetAttribute("Block", "oak_log")
			root.Parent = workspace
		end
		-- Patapim stays behind as a dry tree
		local dead = model("Patapim")
		if dead then
			for _, d in dead:GetDescendants() do
				if d:IsA("BasePart") then
					d.Color = Color3.fromRGB(96, 78, 58)
					if string.find(d.Name, "Leaves") or string.find(d.Name, "Moss") then
						d.Transparency = 1
					end
				end
			end
			dead:SetAttribute("Face", "off")
			dead:PivotTo(
				CFrame.new(blocks(35, 12, 136.6))
					* CFrame.new(0, (dead:GetAttribute("RootHeight") :: number?) or 0, 0)
			)
			dead.Parent = workspace
		end
		ctx:teleport(ctx:ground("GorgeSouth") * CFrame.new(0, 0, -8), 3)
	else
		ctx:say("C4_PATAPIM_FAR")
		ctx:objective("C4_DETOUR")
		runCourse(ctx, DETOUR, CFrame.new(blocks(22, 12, 136.5)), 300)
	end
	ctx:clearObjective()
	-- through the rest of the night to the mine on the far hill
	ctx:glitch("blackout", { duration = 2 })
	task.wait(0.6)
	ctx:teleport(CFrame.new(blocks(122, 12, 36)), 3)
	ctx.atmosphere.fog(140, 2)
	ctx:award("CHAPTER_4")
end

local chapter: StoryContext.Chapter = {
	index = 4,
	title = "The Second Night",
	steps = {
		StoryContext.step({
			name = "nightfall",
			checkpoint = { point = "FalsinoArena", offset = Vector3.new(-20, 0, 0) },
			run = nightfall,
		}),
		StoryContext.step({
			name = "negatino",
			checkpoint = { point = "FalsinoArena", offset = Vector3.new(-20, 0, 0) },
			run = negatino,
		}),
		StoryContext.step({ name = "tung", run = tungReveal }),
		StoryContext.step({
			name = "chase",
			checkpoint = { point = "TavernEntrance" },
			run = chase,
		}),
		StoryContext.step({
			name = "forest",
			checkpoint = { point = "ForestEntrance" },
			run = forest,
		}),
		StoryContext.step({
			name = "mine",
			checkpoint = { anchor = "Anchor_Mine_Door", offset = Vector3.new(0, 0, -24) },
			run = function(_ctx: Ctx) end,
		}),
	},
}

return chapter
