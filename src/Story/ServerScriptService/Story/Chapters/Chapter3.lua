--!strict
-- Chapter 3 "The Investigation" (screenplay.md 3-1 .. 3-5): the journal, 7 real clues and 2
-- fakes from Falsino, the rooftop parkour to clue 3 (ROOFTOP_RUNNER, the hidden branch to the
-- glowing lantern SECRET_LANTERN), interrogations (3 questions each, Fanum tax for rudeness,
-- Patapim's riddle, Bombardiro's map for the polite), Falsino's truth-or-lie fight (CS-07, CS-08)
-- and the accusation vote (CS-09T / C / B / N).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local FalsinoRounds = require(Shared:WaitForChild("StoryData"):WaitForChild("FalsinoRounds"))
local Strings = require(Shared:WaitForChild("Strings"))

local StoryContext = require(script.Parent.Parent:WaitForChild("StoryContext"))
local Systems = script.Parent.Parent.Parent:WaitForChild("Systems")
local BossFramework = require(Systems:WaitForChild("BossFramework"))
local ParkourService = require(Systems:WaitForChild("ParkourService"))

type Ctx = StoryContext.Context

local S = 4
local SQUARE_MIN = Vector3.new(71 * S, 10 * S, 71 * S)
local SQUARE_MAX = Vector3.new(89 * S, 22 * S, 89 * S)

local function blocks(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z) * S
end

local function realClues(ctx: Ctx): number
	return ctx.flags.realClues()
end

local function marker(ctx: Ctx, name: string, size: Vector3?): Part
	return ctx:newPart({
		Name = name,
		Size = size or Vector3.new(3, 3, 3),
		CFrame = ctx:point(name),
		Transparency = 1,
	})
end

------------------------------------------------------------------ rooftop parkour (clue 3)

local function blk(b: ParkourService.BlockDef): ParkourService.BlockDef
	return b
end

local ROOF = Color3.fromHex("#8A4A2A")
local FENCE = Color3.fromHex("#9C7646")

-- origin = the bakery's south-west corner on the ground (x 89.5, z 93.5); +x east, -z north.
-- The stepped roofs are part of the route (each step is one jump); the blocks bridge the gaps.
-- Ridges: bakery y 22 (rel 10, along z), Ballerina's house y 21 (z 76), Lirili's workshop y 21.
local ROOFTOPS: ParkourService.SegmentDef = {
	id = "Rooftops",
	killY = 2, -- back on the street (rel y < 2) = fell: 25 damage, back to the last checkpoint
	fall = "damage",
	fallDamage = 25,
	returnToStart = false,
	blocks = {
		-- the start on the bakery's south eave (players are put there by the "Climb" prompt)
		blk({
			kind = "start",
			at = { 1, 6.25, -0.5 },
			size = { 2, 0.5, 1.4 },
			color = ROOF,
			blockName = "oak_planks",
		}),
		blk({
			kind = "checkpoint",
			at = { 3.5, 10.25, -4.5 },
			size = { 2, 0.5, 2 },
			color = ROOF,
			blockName = "oak_planks",
		}),
		-- hidden branch: two pale blocks east to La Vaca's roof and the chest
		blk({
			kind = "block",
			at = { 6.4, 9.6, -2.6 },
			color = Color3.fromHex("#B7A07A"),
			blockName = "oak_planks",
		}),
		blk({
			kind = "block",
			at = { 8.6, 8.8, -1 },
			color = Color3.fromHex("#B7A07A"),
			blockName = "oak_planks",
		}),
		-- main route: along the ridge to the north end, then over the street
		blk({ kind = "block", at = { 3.5, 9.75, -11.2 }, color = ROOF, blockName = "oak_planks" }),
		blk({
			kind = "moving",
			at = { 3.5, 9.75, -13 },
			move = { 0, 0, -1.2 },
			period = 3,
			color = FENCE,
			blockName = "oak_planks",
		}),
		blk({ kind = "block", at = { 3.5, 9.75, -15.6 }, color = ROOF, blockName = "oak_planks" }),
		blk({
			kind = "collapse",
			at = { 2.4, 9.75, -17.4 },
			color = ROOF,
			blockName = "oak_planks",
		}),
		blk({
			kind = "checkpoint",
			at = { 1.5, 9.75, -20 },
			size = { 2, 0.5, 2 },
			color = ROOF,
			blockName = "oak_planks",
		}),
		-- over the lane to Lirili's workshop roof (a fence beam), finish by the tower ladder
		blk({ kind = "block", at = { 0.5, 9.5, -23 }, color = ROOF, blockName = "oak_planks" }),
		blk({
			kind = "block",
			at = { -1, 9.65, -26 },
			size = { 0.35, 0.5, 3 },
			color = FENCE,
			blockName = "oak_planks",
		}),
		blk({
			kind = "finish",
			at = { -3, 9.75, -29.5 },
			size = { 2, 0.5, 2 },
			color = ROOF,
			blockName = "oak_planks",
		}),
	},
}

local function rooftops(ctx: Ctx, onGlass: () -> ())
	local origin = CFrame.new(blocks(89.5, 12, 93.5))
	local course = ParkourService.build(ROOFTOPS, workspace, origin)
	ctx:track(course.model)
	ctx:track(function()
		course:destroy()
	end)
	-- the melted glass on top of the bakery ridge (clue 3)
	local glass = ctx:newPart({
		Name = "MeltedGlass",
		Size = Vector3.new(1.6, 0.3, 1.6),
		CFrame = origin * CFrame.new(3.5 * S, 10.2 * S, -4.5 * S),
		Color = Color3.fromRGB(255, 226, 120),
		Material = Enum.Material.Glass,
		Transparency = 0.2,
	})
	ctx:prompt(
		glass,
		Strings.Prompts.Inspect,
		{ objectText = "Melted glass", distance = 7 },
		function(player)
			ctx.clues.found("C3", player)
			ctx:say("C3_NARR_GLASS")
			onGlass()
		end
	)
	-- the secret chest with the glowing lantern on La Vaca's roof
	local chest = ctx:newPart({
		Name = "SecretChest",
		Size = Vector3.new(2.4, 1.8, 1.8),
		CFrame = origin * CFrame.new(9.2 * S, 8.9 * S, 1 * S),
		Color = Color3.fromHex("#8A6436"),
		Material = Enum.Material.WoodPlanks,
		CanCollide = true,
	})
	local opened = false
	ctx:prompt(chest, Strings.Prompts.Open, { objectText = "Chest", distance = 7 }, function(player)
		if opened then
			return
		end
		opened = true
		ctx:sfx("chest_open", chest.Position, 0.8)
		ctx.inv.add(player, "glowing_lantern", 1)
		ctx.flags.set("glowingLantern", true)
		ctx:award("SECRET_LANTERN", { player })
	end)
	course.Finished:Connect(function(player: Player, clean: boolean)
		if clean then
			ctx:award("ROOFTOP_RUNNER", { player })
		end
	end)
	-- opt in: a ladder at the bakery's south-west corner puts you on the course
	local ladder = ctx:newPart({
		Name = "RooftopLadder",
		Size = Vector3.new(1.2, 24, 1.2),
		CFrame = origin * CFrame.new(-0.3 * S, 3 * S, 0.3 * S),
		Color = Color3.fromHex("#7A5A34"),
		Material = Enum.Material.Wood,
	})
	ctx:prompt(
		ladder,
		Strings.Prompts.Enter,
		{ objectText = "Climb the rooftops", distance = 8 },
		function(player)
			if not course:isRunning(player) then
				course:track({ player }, true)
			end
		end
	)
end

------------------------------------------------------------------ 3-1 .. 3-3 the investigation

local function investigation(ctx: Ctx)
	ctx:preset("day", 2)
	ctx:music("investigation")
	ctx:companion(true)
	ctx:glitch("shuttersOpen")
	ctx:say("C3_GIALLINO_JOURNAL")
	local function refresh()
		local n = realClues(ctx)
		if n >= 4 then
			ctx:objective("C3_READY", n)
		else
			ctx:objective("C3_CLUES", n)
		end
	end
	refresh()
	local found = ctx.clues.ClueFound:Connect(function()
		refresh()
	end)
	ctx:track(function()
		found:Disconnect()
	end)

	local sixSevenDone = false
	local function sixSeven()
		if ctx.clues.has("C6") and ctx.clues.has("C7") and not sixSevenDone then
			sixSevenDone = true
			ctx:say("C3_BOMBARDIRO_SIXSEVEN")
			ctx:award("SIX_SEVEN")
		end
	end

	-- 1: round footprints by Ballerina's house
	ctx:prompt(
		marker(ctx, "ClueFootprints", Vector3.new(6, 2, 6)),
		Strings.Prompts.Inspect,
		{ objectText = "Footprints", distance = 9 },
		function(player)
			ctx.clues.found("C1", player)
			ctx:say("C3_CAPPUCCINO_FOOTPRINTS")
		end
	)
	-- 2: the coordinates scratched into the well sign
	local well = ctx.map.find("Village", "Well", "CoordSign")
	if well and well:IsA("BasePart") then
		ctx:prompt(
			well,
			Strings.Prompts.Read,
			{ objectText = "Sign", distance = 9 },
			function(player)
				ctx.clues.found("C2", player)
				ctx:say("C3_NARR_WELL")
			end
		)
	end
	-- 3: the rooftop parkour to the melted glass
	rooftops(ctx, refresh)
	-- 4: the squeaky floorboard in Ballerina's house
	local boards = ctx.map.find("Village", "BallerinaHouse", "Floorboards")
	if boards then
		for _, b in boards:GetChildren() do
			if b:IsA("BasePart") then
				ctx:prompt(
					b,
					Strings.Prompts.Push,
					{ objectText = "Floorboard", distance = 6 },
					function(player)
						if b:GetAttribute("Index") == 4 then
							ctx:sfx("door_open", b.Position, 0.9)
							if not ctx.clues.has("C4") then
								ctx.clues.found("C4", player)
								ctx:say("C3_NARR_DIARY")
							end
						else
							ctx:sfx("block_place_wood", b.Position, 0.5)
						end
					end
				)
			end
		end
	end
	-- 5: Lirili's music box (code 3-1-2 from her board)
	local box = ctx.map.find("Village", "LiriliWorkshop", "MusicBox")
	if box and box:IsA("BasePart") then
		local busy = false
		ctx:prompt(
			box,
			Strings.Prompts.Open,
			{ objectText = "Music box", distance = 8 },
			function(player)
				if busy or ctx.clues.has("C5") then
					return
				end
				busy = true
				local code = ctx:vote({
					{ id = "123", text = "1 - 2 - 3" },
					{ id = "312", text = "3 - 1 - 2" },
					{ id = "231", text = "2 - 3 - 1" },
					{ id = "213", text = "2 - 1 - 3" },
				}, 15)
				if code == "312" then
					ctx:sfx("chest_open", box.Position, 0.8)
					ctx.clues.found("C5", player)
					ctx:say("C3_LIRILI_NOTE")
				else
					ctx:say("C3_NARR_WRONG_CODE")
				end
				busy = false
			end
		)
	end
	-- 6: Bombardiro's map (polite only)
	local bomb = ctx.npcs.talkPrompt("Bombardiro", Strings.Prompts.Talk, function(player)
		ctx.npcs.chant("Bombardiro")
		local result = ctx:dialogue("Bombardiro")
		if table.find(result.choices, "polite") then
			ctx.clues.found("C6", player)
			ctx.inv.add(player, "cave_map", 1)
			sixSeven()
		end
	end)
	if bomb then
		ctx:track(bomb)
	end
	-- 7: Patapim's riddle -> the yellow shard
	local pat = ctx.npcs.talkPrompt("Patapim", Strings.Prompts.Talk, function(player)
		if ctx.clues.has("C7") then
			ctx:say("CS14_PATAPIM_ROOTS")
			return
		end
		ctx.npcs.chant("Patapim")
		local result = ctx:dialogue("PatapimRiddle")
		if table.find(result.choices, "giallino") then
			ctx.clues.found("C7", player)
			sixSeven()
		end
	end)
	if pat then
		ctx:track(pat)
	end
	-- the fakes: the bat at the mill and the note on the board
	local bat = ctx:newPart({
		Name = "FakeBat",
		Size = Vector3.new(0.5, 0.5, 3.4),
		CFrame = ctx:ground("FakeBat") * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, math.rad(30), 0),
		Color = Color3.fromHex("#7A4E28"),
		Material = Enum.Material.Wood,
	})
	local paint = ctx:newPart({
		Name = "Paint",
		Size = Vector3.new(0.55, 0.1, 1.2),
		CFrame = bat.CFrame * CFrame.new(0, 0.26, 0.8),
		Color = Color3.fromRGB(150, 20, 20),
	})
	paint.Parent = bat
	local fakeTalked = false
	local function fakeLine()
		if not fakeTalked then
			fakeTalked = true
			ctx:say("C3_FALSINO_FAKE")
		end
	end
	ctx:prompt(bat, Strings.Prompts.Inspect, { objectText = "Bat", distance = 8 }, function(player)
		ctx.clues.found("F1", player)
		ctx:say("C3_NARR_FAKE_BAT")
		fakeLine()
	end)
	ctx:prompt(
		marker(ctx, "FakeNote"),
		Strings.Prompts.Read,
		{ objectText = "Note", distance = 8 },
		function(player)
			ctx.clues.found("F2", player)
			ctx:say("C3_NARR_FAKE_NOTE")
			fakeLine()
		end
	)
	-- interrogations
	for _, id in { "Tralalero", "Cappuccino" } do
		local prompt = ctx.npcs.talkPrompt(id, Strings.Prompts.Talk, function(_player)
			ctx.npcs.chant(id)
			ctx:dialogue(id)
		end)
		if prompt then
			ctx:track(prompt)
		end
	end
	local chimp = ctx.npcs.talkPrompt("Chimpanzini", Strings.Prompts.Talk, function(player)
		ctx.npcs.chant("Chimpanzini")
		local result = ctx:dialogue("Chimpanzini")
		if table.find(result.choices, "rude") then
			ctx.inv.takeRandom(player) -- Fanum tax
		end
	end)
	if chimp then
		ctx:track(chimp)
	end
	-- Tung Tung on his hill: three talks = TUNG_FRIEND
	local tungLines = { "C3_TUNG_HILL_1", "C3_TUNG_HILL_2", "C3_TUNG_HILL_3" }
	local tung = ctx.npcs.talkPrompt("TungTung", Strings.Prompts.Talk, function(player)
		ctx.npcs.chant("TungTung")
		local f = ctx.flags.get()
		local n = f.tungTalks + 1
		ctx.flags.set("tungTalks", n)
		ctx:say(tungLines[((n - 1) % #tungLines) + 1])
		if n >= 3 then
			ctx:award("TUNG_FRIEND", { player })
		end
	end)
	if tung then
		ctx:track(tung)
	end

	-- the truth comes when 4+ real clues are found and someone walks onto the square
	ctx:waitUntil(function()
		local n = realClues(ctx)
		if n >= 7 then
			return true
		end
		if n < 4 then
			return false
		end
		for _, p in ctx:alive() do
			if ctx:inside(p, SQUARE_MIN, SQUARE_MAX) then
				return true
			end
		end
		return false
	end, nil, 0.5)
	ctx:clearObjective()
	ctx:cleanup()
end

------------------------------------------------------------------ 3-4 Falsino: truth or lie

local SIGN_SPOTS = { { 75.4, 76.6 }, { 74.6, 80 }, { 75.4, 83.4 } }

local function statementSigns(ctx: Ctx, texts: { string }): { Part }
	local signs = {}
	for i, spot in SIGN_SPOTS do
		local board = ctx:newPart({
			Name = "TruthSign" .. i,
			Size = Vector3.new(7, 3.4, 0.4),
			CFrame = CFrame.new(blocks(spot[1], 13.4, spot[2])) * CFrame.Angles(0, math.rad(90), 0),
			Color = Color3.fromHex("#B08A5A"),
			Material = Enum.Material.WoodPlanks,
			CanCollide = true,
		})
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(420, 200)
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.TextScaled = true
		label.TextWrapped = true
		label.Font = Enum.Font.Arcade
		label.TextColor3 = Color3.fromRGB(40, 26, 14)
		label.Text = string.format("%d. %s", i, texts[i])
		label.Parent = gui
		table.insert(signs, board)
	end
	return signs
end

local function playRound(ctx: Ctx, round: FalsinoRounds.Round): boolean
	local signs = statementSigns(ctx, round.texts)
	for _, lineId in round.lines do
		ctx:say(lineId)
	end
	local options = {}
	for i, text in round.texts do
		table.insert(options, { id = tostring(i), text = string.format("%d. %s", i, text) })
	end
	local _, chosen, byPlayer =
		ctx.votes.run({ options = options, voters = ctx:alive(), seconds = 15 })
	local correct = chosen == tostring(round.lie)
	-- 30 damage to everybody who voted for a true statement
	for p, choice in byPlayer do
		if choice ~= tostring(round.lie) then
			ctx.health.damage(p, 30, "falsino")
		end
	end
	ctx:say(if correct then "C3_FALSINO_RIGHT" else "C3_FALSINO_WRONG")
	for _, s in signs do
		s:Destroy()
	end
	return correct
end

local function falsino(ctx: Ctx)
	ctx:companion(false)
	ctx:music("boss")
	ctx:cutscene("CS_07")
	local boss = BossFramework.new({
		name = "Falsino",
		cardTitle = Strings.Bosses.Falsino.title,
		cardSubtitle = Strings.Bosses.Falsino.subtitle,
		signature = "falsino_signature",
		phases = {},
	})
	boss:card()
	-- Falsino hovers over the table during the game
	local models = game:GetService("ServerStorage"):FindFirstChild("Models")
	local template = models and models:FindFirstChild("Falsino")
	if template and template:IsA("Model") then
		local m = template:Clone()
		m:PivotTo(CFrame.lookAt(blocks(80, 14.6, 80), blocks(70, 14.6, 80)))
		m:SetAttribute("Face", "smile_crooked")
		game:GetService("CollectionService"):AddTag(m, "Faced")
		m.Parent = workspace
		ctx:track(m)
	end
	ctx:dialogue("FalsinoGame")
	-- round 1 is the screenplay's example, the others are drawn from the pool
	local pool = {}
	for i = 2, #FalsinoRounds do
		table.insert(pool, i)
	end
	local first = true
	while true do
		local order: { number } =
			{ if first then 1 else table.remove(pool, math.random(1, #pool)) :: number }
		first = false
		while #order < 3 do
			if #pool == 0 then
				for i = 1, #FalsinoRounds do
					table.insert(pool, i)
				end
			end
			table.insert(order, table.remove(pool, math.random(1, #pool)) :: number)
		end
		local wins = 0
		for r, index in order do
			ctx:objective("C3_FALSINO", r)
			if playRound(ctx, FalsinoRounds[index]) then
				wins += 1
			end
			if r < 3 then
				-- Glitchlings run across the arena between rounds
				boss:wave(3, CFrame.new(blocks(76, 12, 80)), 22)
				task.wait(10)
				ctx.threats.clear()
			end
		end
		if wins >= 2 then
			break
		end
		ctx:say("C3_FALSINO_AGAIN")
	end
	ctx:clearObjective()
	ctx:cleanup()
	ctx:cutscene("CS_08")
	ctx:award("BEAT_FALSINO")
end

------------------------------------------------------------------ 3-5 the accusation

local function lockInBarn(ctx: Ctx, id: string)
	ctx.flags.set("jailed", id)
	ctx.npcs.show(id, true)
	ctx.npcs.place(id, ctx:ground("BarnCell"))
	local gate = ctx.map.find("Village", "Barn", "Door")
	if gate and gate:IsA("BasePart") then
		ctx.map.setDoor(gate, false)
	end
end

local function accusation(ctx: Ctx)
	ctx:companion(true)
	ctx:music("silence")
	ctx:say("C3_NARR_ACCUSE")
	ctx:objective("C3_ACCUSE")
	local choice = ctx:vote({
		{ id = "tung", text = "Tung Tung Tung Sahur" },
		{ id = "cappuccino", text = "Cappuccino Assassino" },
		{ id = "bombardiro", text = "Bombardiro Crocodilo" },
		{ id = "unsure", text = "We are not sure yet" },
	}, 20)
	ctx:clearObjective()
	if choice == "tung" then
		ctx:cutscene("CS_09T")
		lockInBarn(ctx, "TungTung")
		ctx.clues.unlockNames() -- he gave the board of names
		for _, p in ctx:players() do
			ctx.inv.add(p, "name_board", 1)
		end
	elseif choice == "cappuccino" then
		ctx:cutscene("CS_09C")
		lockInBarn(ctx, "Cappuccino")
		for _, p in ctx:players() do
			ctx.inv.add(p, "pointe_shoe", 1)
		end
	elseif choice == "bombardiro" then
		ctx:cutscene("CS_09B")
		lockInBarn(ctx, "Bombardiro")
		for _, p in ctx:players() do
			if not ctx.inv.has(p, "cave_map") then
				ctx.inv.add(p, "cave_map", 1)
			end
		end
		if not ctx.clues.has("C6") then
			ctx.clues.found("C6")
		end
	else
		ctx:cutscene("CS_09N")
		ctx.flags.addMood(-5)
	end
	ctx:award("CHAPTER_3")
end

local chapter: StoryContext.Chapter = {
	index = 3,
	title = "The Investigation",
	steps = {
		StoryContext.step({
			name = "investigation",
			checkpoint = { point = "DawnSquare" },
			run = investigation,
		}),
		StoryContext.step({
			name = "falsino",
			checkpoint = { point = "FalsinoArena", offset = Vector3.new(-20, 0, 0) },
			run = falsino,
		}),
		StoryContext.step({
			name = "accusation",
			checkpoint = { point = "FalsinoArena", offset = Vector3.new(-20, 0, 0) },
			run = accusation,
		}),
	},
}

return chapter
