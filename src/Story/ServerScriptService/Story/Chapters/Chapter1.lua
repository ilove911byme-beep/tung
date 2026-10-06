--!strict
-- Chapter 1 "Arrival" (screenplay.md 1-1 .. 1-6): the carts arrive (CS-01), Giallino says
-- hello and asks for a promise (CS-02 + choice 1-2), the tutorial tasks (wood, lantern, bread)
-- with the daytime cameos, the apple parkour (CLEAN_JUMPS), the bell (CS-03) and the 90 s run
-- to the inn through the fog (Glitchlings if late). Checkpoints: tutorial start, the inn doors.
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local StoryContext = require(script.Parent.Parent:WaitForChild("StoryContext"))
local ParkourService =
	require(script.Parent.Parent.Parent:WaitForChild("Systems"):WaitForChild("ParkourService"))

type Ctx = StoryContext.Context

local S = 4
local WOOD_GOAL = 6

-- the inn (both floors), studs
local INN_MIN = Vector3.new(62.5 * S, 11 * S, 75.5 * S)
local INN_MAX = Vector3.new(69.5 * S, 20 * S, 84.5 * S)

local function stationRow(ctx: Ctx)
	ctx:teleport("Anchor_Station", 3)
end

local function blocks(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z) * S
end

------------------------------------------------------------------ 1-1 / 1-2 arrival

local function arrival(ctx: Ctx)
	ctx:preset("day", 0)
	ctx:companion(false)
	ctx:music("silence")
	ctx.npcs.show("Ballerina", true)
	ctx:cutscene("CS_01")
	stationRow(ctx)
	ctx:cutscene("CS_02")
end

------------------------------------------------------------------ 1-3 tutorial

local CAMEO_LINES: { [string]: string? } = {
	Tralalero = "C1_TRALALERO_DAY",
	Strawberry = "C1_STRAWBERRY",
	Banana = "C1_BANANA",
}
local CAMEOS = {
	"TrippiTroppi",
	"BonecaAmbalabu",
	"UdinDinDinDun",
	"LaVacaSaturno",
	"FrigoCamelo",
	"GlorboFruttodrillo",
	"Tralalero",
	"Strawberry",
	"Banana",
	"Ballerina",
	"Patapim",
	"Bombardiro",
	"Cappuccino",
}

local function tutorial(ctx: Ctx)
	ctx:preset("day", 2)
	ctx:music("day")
	ctx:companion(true)
	ctx:say("C1_GIALLINO_SAFE")
	ctx:say("C1_GIALLINO_TASKS")
	ctx:say("C1_GIALLINO_LANTERN")

	local wood = 0
	local lantern = false
	local bread = false
	local function refresh()
		if wood < WOOD_GOAL then
			ctx:objective("C1_TUTORIAL", wood)
		elseif not lantern then
			ctx:objective("C1_LANTERN")
		elseif not bread then
			ctx:objective("C1_BREAD")
		else
			ctx:clearObjective()
		end
	end
	refresh()

	-- wood: chop the village trees (3 wood each)
	for _, tree in CollectionService:GetTagged("WoodTree") do
		local trunk = tree:FindFirstChild("Trunk")
		if trunk and trunk:IsA("BasePart") then
			local left = (tree:GetAttribute("Wood") :: number?) or 3
			local prompt: ProximityPrompt
			prompt = ctx:prompt(
				trunk,
				Strings.Prompts.Chop,
				{ hold = 0.8, distance = 8 },
				function(player)
					if left <= 0 then
						return
					end
					left -= 1
					wood += 1
					ctx.inv.add(player, "wood", 1)
					ctx:sfx("block_break_wood", trunk.Position, 0.7)
					if left <= 0 then
						prompt.Enabled = false
					end
					refresh()
				end
			)
		end
	end

	-- the lantern from Chimpanzini (everybody who asks gets one)
	local chimpBusy = false
	local chimpPrompt = ctx.npcs.talkPrompt("Chimpanzini", Strings.Prompts.Buy, function(_player)
		if chimpBusy then
			return
		end
		chimpBusy = true
		ctx.npcs.chant("Chimpanzini")
		if not lantern then
			ctx:say("C1_CHIMP_LANTERN")
			ctx:say("C1_CHIMP_TAKE")
		end
		for _, p in ctx:players() do
			if not ctx.inv.has(p, "lantern") then
				ctx.inv.add(p, "lantern", 1)
			end
		end
		ctx:sfx("item_pickup", nil, 0.7)
		lantern = true
		chimpBusy = false
		refresh()
	end)
	if chimpPrompt then
		ctx:track(chimpPrompt)
	end

	-- bread on the bakery shelf
	local shelf = ctx:newPart({
		Name = "BreadPickup",
		Size = Vector3.new(4, 3, 3),
		CFrame = ctx:point("BreadShelf"),
		Transparency = 1,
	})
	ctx:prompt(shelf, Strings.Prompts.Take, { objectText = "Bread", distance = 8 }, function(player)
		ctx.inv.add(player, "bread", 1)
		ctx:sfx("item_pickup", shelf.Position, 0.7)
		bread = true
		refresh()
	end)

	-- daytime cameos: one line each (their chant the first time)
	for _, id in CAMEOS do
		local prompt = ctx.npcs.talkPrompt(id, Strings.Prompts.Talk, function(_player)
			ctx.npcs.chant(id)
			local line = CAMEO_LINES[id]
			if line then
				ctx:say(line)
			end
		end)
		if prompt then
			ctx:track(prompt)
		end
	end
	-- Strawberry and Banana argue at the fountain when someone walks by; Tralalero gossips
	local argued, gossiped = false, false
	ctx:track(function()
		argued, gossiped = true, true
	end)
	task.spawn(function()
		while not (wood >= WOOD_GOAL and lantern and bread) do
			for _, p in ctx:players() do
				if not argued and ctx:inside(p, blocks(72, 10, 92), blocks(88, 20, 108)) then
					argued = true
					ctx:say("C1_STRAWBERRY")
					ctx:say("C1_BANANA")
				end
				if not gossiped and ctx:inside(p, blocks(74, 10, 88), blocks(92, 20, 104)) then
					gossiped = true
					ctx.npcs.chant("Tralalero")
					ctx:say("C1_TRALALERO_NIGHT")
				end
			end
			task.wait(0.5)
		end
	end)

	ctx:waitUntil(function()
		return wood >= WOOD_GOAL and lantern and bread
	end)
	ctx:clearObjective()
	ctx:cleanup()
end

------------------------------------------------------------------ 1-4 parkour tutorial

local LEAF = Color3.fromHex("#2E6222")
local STONE = Color3.fromHex("#767676")

local function blk(b: ParkourService.BlockDef): ParkourService.BlockDef
	return b
end

local function leaf(x: number, y: number, z: number): ParkourService.BlockDef
	return blk({
		kind = "block",
		at = { x, y, z },
		color = LEAF,
		material = Enum.Material.Grass,
		blockName = "leaves",
	})
end

local function stone(x: number, y: number, z: number): ParkourService.BlockDef
	return blk({
		kind = "block",
		at = { x, y, z },
		color = STONE,
		material = Enum.Material.Cobblestone,
		blockName = "cobblestone",
	})
end

local APPLE_COURSE: ParkourService.SegmentDef = {
	id = "AppleTree",
	killY = -2.2, -- the river (its surface is 2 blocks below the start)
	fall = "return",
	blocks = {
		blk({ kind = "start", at = { 0, 0.25, 0 }, size = { 3, 0.5, 3 } }),
		leaf(2, 1.5, -1),
		leaf(3.5, 2.5, -2.5),
		leaf(5.5, 3.5, -3),
		leaf(6.5, 4.5, -1),
		leaf(5.5, 5.5, 1),
		blk({
			kind = "checkpoint",
			at = { 3.5, 6.5, 1 },
			size = { 2, 1, 2 },
			color = LEAF,
			material = Enum.Material.Grass,
			blockName = "leaves",
		}),
		-- down the other side and across the river on stones
		leaf(6, 4.5, 3),
		stone(8.5, -1.75, 3),
		stone(10.3, -1.75, 4.2),
		stone(12.1, -1.75, 3),
		blk({ kind = "finish", at = { 15, 0.25, 3 }, size = { 3, 0.5, 3 } }),
	},
}

local function parkour(ctx: Ctx)
	ctx:objective("C1_APPLE")
	ctx:say("C1_GIALLINO_APPLE")
	local origin = CFrame.new(blocks(104, 12, 72))
	local course = ctx.parkour.build(APPLE_COURSE, workspace, origin)
	ctx:track(course.model)
	ctx:track(function()
		course:destroy()
	end)
	-- the tall tree itself (scenery around the leaf steps) and the red apple on top
	local trunk = ctx:newPart({
		Name = "AppleTreeTrunk",
		Size = Vector3.new(S, 6 * S, S),
		CFrame = origin * CFrame.new(4.5 * S, 3 * S, -1 * S),
		Color = Color3.fromHex("#604428"),
		Material = Enum.Material.Wood,
		CanCollide = true,
	})
	trunk:SetAttribute("Block", "oak_log")
	local apple = ctx:newPart({
		Name = "TreeApple",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.4, 1.4, 1.4),
		CFrame = origin * CFrame.new(3.5 * S, 7.5 * S, 1 * S),
		Color = Color3.fromRGB(200, 40, 40),
		Material = Enum.Material.SmoothPlastic,
	})
	ctx:prompt(
		apple,
		Strings.Prompts.Pickup,
		{ objectText = "Apple", distance = 8 },
		function(player)
			if not ctx.inv.has(player, "apple") then
				ctx.inv.add(player, "apple", 1)
				ctx:sfx("item_pickup", apple.Position, 0.8)
			end
		end
	)
	local finishedAt: number? = nil
	local finishers: { [Player]: boolean } = {}
	course.Finished:Connect(function(player: Player, clean: boolean)
		finishers[player] = true
		finishedAt = finishedAt or os.clock()
		if clean then
			ctx:award("CLEAN_JUMPS", { player })
		end
	end)
	course:track(ctx:players(), true)
	local started = os.clock()
	ctx:waitUntil(function()
		local all = true
		for _, p in ctx:alive() do
			if not finishers[p] then
				all = false
			end
		end
		if all and next(finishers) ~= nil then
			return true
		end
		if finishedAt and os.clock() - finishedAt > 75 then
			return true
		end
		return os.clock() - started > 240
	end, nil, 0.5)
	ctx:say("C1_GIALLINO_APPLE_DONE")
	ctx:clearObjective()
	ctx:cleanup()
end

------------------------------------------------------------------ 1-5 / 1-6 dusk and the run

local function allInside(ctx: Ctx): boolean
	local any = false
	for _, p in ctx:alive() do
		any = true
		if not ctx:inside(p, INN_MIN, INN_MAX) then
			return false
		end
	end
	return any
end

local function duskRun(ctx: Ctx)
	ctx:cutscene("CS_03")
	ctx:preset("dusk", 1)
	ctx.atmosphere.clock(18.9, 0)
	ctx.atmosphere.fog(160, 1)
	ctx:music("chase")
	ctx:say("C1_GIALLINO_HURRY")
	local endsAt = ctx:timer(90)
	local spawned = false
	task.spawn(function()
		while workspace:GetServerTimeNow() < endsAt and not allInside(ctx) do
			local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
			ctx:objective("C1_RUN_INN", left)
			task.wait(1)
		end
	end)
	ctx.atmosphere.fog(60, 90)
	ctx:waitUntil(function()
		return allInside(ctx) or workspace:GetServerTimeNow() >= endsAt
	end, nil, 0.3)
	if not allInside(ctx) then
		-- too late: two Glitchlings at the inn door (easy to escape)
		spawned = true
		ctx:say("C1_GIALLINO_LATE")
		ctx:objective("C1_ENTER_INN")
		local door = ctx:ground("TavernEntrance")
		ctx.threats.spawnGlitchling(door * CFrame.new(-6, 0, -6))
		ctx.threats.spawnGlitchling(door * CFrame.new(6, 0, -6))
		ctx:waitUntil(function()
			return allInside(ctx)
		end, 120, 0.3)
	end
	ctx:clearTimer()
	ctx:clearObjective()
	ctx.threats.clear()
	if spawned then
		ctx.aura.addAll(-10)
	end
	-- the inn door closes behind the party
	local door = ctx.map.find("Village", "Tavern", "Door")
	if door and door:IsA("BasePart") then
		ctx.map.setDoor(door, false)
	end
	ctx:award("CHAPTER_1")
end

local chapter: StoryContext.Chapter = {
	index = 1,
	title = "Arrival",
	steps = {
		StoryContext.step({ name = "arrival", run = arrival }),
		StoryContext.step({
			name = "tutorial",
			checkpoint = { anchor = "Anchor_Station" },
			run = tutorial,
		}),
		StoryContext.step({
			name = "parkour",
			checkpoint = { point = "TutorialStart" },
			run = parkour,
		}),
		StoryContext.step({ name = "dusk", run = duskRun }),
		StoryContext.step({
			name = "inn",
			checkpoint = { point = "TavernEntrance" },
			run = function(_ctx: Ctx) end,
		}),
	},
}

return chapter
