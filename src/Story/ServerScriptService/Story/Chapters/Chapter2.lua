--!strict
-- Chapter 2 "The First Night" (screenplay.md 2-1 .. 2-4): the knocking (CS-04) and the party's
-- choice (open -> CS-04A, barricade -> crate QTE, hide -> hiding spots + hold-breath QTE), two
-- minutes keeping the fire alive while Glitchlings scratch at the windows, Ballerina's last
-- dance through the window (CS-05, lock), and the morning (CS-06).
-- Frigo Camelo and Udin Din Din Dun vanish this night (their names are on Tung Tung's board).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local StoryContext = require(script.Parent.Parent:WaitForChild("StoryContext"))

type Ctx = StoryContext.Context

local S = 4
local NIGHT_SECONDS = 120
local FIRE_DRAIN = 100 / 40 -- an untended fire burns down in 40 s
local WOOD_FUEL = 34

local INN_MIN = Vector3.new(62.5 * S, 11 * S, 75.5 * S)
local INN_MAX = Vector3.new(69.5 * S, 20 * S, 84.5 * S)

local VILLAGERS = {
	"Tralalero",
	"Chimpanzini",
	"TrippiTroppi",
	"BonecaAmbalabu",
	"UdinDinDinDun",
	"LaVacaSaturno",
	"FrigoCamelo",
	"GlorboFruttodrillo",
	"Strawberry",
	"Banana",
	"Ballerina",
	"Patapim",
	"Bombardiro",
	"Cappuccino",
	"TungTung",
}

local function tavernDoor(ctx: Ctx): BasePart?
	local d = ctx.map.find("Village", "Tavern", "Door")
	return if d and d:IsA("BasePart") then d else nil
end

local function fireParts(ctx: Ctx): (BasePart?, Fire?, PointLight?)
	local fp = ctx.map.find("Village", "Tavern", "Fireplace")
	local part = fp and fp:FindFirstChild("FirePlace")
	if not part or not part:IsA("BasePart") then
		return nil, nil, nil
	end
	return part, part:FindFirstChildOfClass("Fire"), part:FindFirstChildOfClass("PointLight")
end

local function intoTheInn(ctx: Ctx)
	for _, p in ctx:players() do
		if not ctx:inside(p, INN_MIN, INN_MAX) then
			local character = p.Character
			if character then
				character:PivotTo(ctx:point("Fireplace") * CFrame.new(math.random(-3, 3), 3, -6))
			end
		end
	end
end

------------------------------------------------------------------ 2-1 / 2-2 the knock

local function barricade(ctx: Ctx)
	ctx:say("C2_GIALLINO_BARRICADE")
	ctx:objective("C2_BARRICADE")
	local ok = ctx.qte.party(ctx:alive(), {
		type = "party",
		duration = 9,
		perTap = 0.05,
		drain = 0.05,
		label = Strings.Prompts.Push,
	})
	ctx:clearObjective()
	local door = tavernDoor(ctx)
	if ok then
		-- the crates slide in front of the door
		local tavern = ctx.map.find("Village", "Tavern")
		for i = 1, 3 do
			local crate = tavern and tavern:FindFirstChild("Crate" .. i)
			if crate and crate:IsA("BasePart") then
				crate.CFrame = CFrame.new(
					Vector3.new(
						68.9,
						12.4 + (if i == 3 then 0.8 else 0),
						83.2 + (if i == 2 then 1.2 else 0)
					) * S
				)
			end
		end
		ctx:sfx("door_close", door and door.Position, 0.6)
	else
		-- the door cracks: 15 damage to everybody
		ctx:glitch("doorShake", { tag = "TavernDoor", knocks = 4, gap = 0.35 })
		ctx:sfx("knock_tung_x3", door and door.Position, 1)
		task.wait(1.2)
		for _, p in ctx:alive() do
			ctx.health.damage(p, 15, "door")
		end
	end
end

local function hide(ctx: Ctx)
	ctx:say("C2_GIALLINO_HIDE")
	ctx.hiding.setEnabled(true)
	ctx:timer(5)
	for left = 5, 1, -1 do
		ctx:objective("C2_HIDE", left)
		task.wait(1)
	end
	ctx:clearTimer()
	ctx:clearObjective()
	-- whoever did not hide is found right away
	for _, p in ctx:alive() do
		if not p:GetAttribute("HidingIn") then
			ctx.health.damage(p, 20, "found")
		end
	end
	local door = tavernDoor(ctx)
	ctx:glitch("doorShake", { tag = "TavernDoor", knocks = 3, gap = 0.8 })
	ctx:sfx("knock_tung_x3", door and door.Position, 0.8)
	ctx.hiding.check(20)
	task.wait(0.5)
	ctx.hiding.setEnabled(false)
end

local function openDoor(ctx: Ctx)
	local door = tavernDoor(ctx)
	if door then
		door.Transparency = 1
		door.CanCollide = false
	end
	ctx:cutscene("CS_04A")
	if door then
		door.Transparency = 0
		door.CanCollide = true
		ctx.map.setDoor(door, false) -- Giallino slams it shut again
	end
	ctx.flags.set("sawTungRunning", true)
	ctx:award("OPEN_THE_DOOR")
end

local function knock(ctx: Ctx)
	ctx:preset("night", 1)
	ctx:music("night")
	ctx:companion(true)
	for _, id in VILLAGERS do
		ctx.npcs.show(id, false) -- everybody is locked inside at night
	end
	local door = tavernDoor(ctx)
	if door then
		ctx.map.setDoor(door, false)
	end
	intoTheInn(ctx)
	ctx:cutscene("CS_04")
	ctx:objective("C2_CHOICE")
	local choice = ctx:vote({
		{ id = "open", text = "Open the door" },
		{ id = "barricade", text = "Barricade it" },
		{ id = "hide", text = "Hide" },
	}, 15)
	ctx:clearObjective()
	if choice == "open" then
		openDoor(ctx)
	elseif choice == "barricade" then
		barricade(ctx)
	else
		hide(ctx)
	end
end

------------------------------------------------------------------ 2-3 keep the fire alive

local function peek(ctx: Ctx, windowName: string)
	-- a Glitchling face presses against the window glass for a moment and scratches
	local cf = ctx:point(windowName)
	local outward = cf.LookVector
	local face = ctx:newPart({
		Name = "WindowGlitchling",
		Size = Vector3.new(2.4, 2.4, 2.4),
		CFrame = CFrame.lookAt(cf.Position + outward * 2.2, cf.Position),
		Color = Color3.fromRGB(20, 18, 26),
		Material = Enum.Material.SmoothPlastic,
	})
	local eye = Instance.new("Part")
	eye.Anchored = true
	eye.CanCollide = false
	eye.Size = Vector3.new(0.7, 0.7, 0.1)
	eye.Material = Enum.Material.Neon
	eye.Color = Color3.fromRGB(255, 216, 58)
	eye.CFrame = face.CFrame * CFrame.new(0, 0.3, -1.25)
	eye.Parent = face
	ctx:sfx("block_break_glass", cf.Position, 0.25)
	task.delay(1.6, function()
		face:Destroy()
	end)
end

local function night(ctx: Ctx)
	ctx:preset("night", 0)
	ctx:music("night")
	intoTheInn(ctx)
	local door = tavernDoor(ctx)
	if door then
		ctx.map.setDoor(door, false)
	end
	ctx:say("C2_GIALLINO_FIRE")
	local fuel = 100
	local firePart, fire, light = fireParts(ctx)
	local function showFire()
		if fire then
			fire.Enabled = fuel > 0
			fire.Size = 1 + fuel / 100 * 4
		end
		if light then
			light.Enabled = fuel > 0
			light.Brightness = 0.3 + fuel / 100 * 1.3
		end
	end
	ctx:track(function()
		fuel = 100
		showFire()
	end)
	showFire()
	-- wood: the log pile by the hearth gives wood, the fireplace takes it
	local pile = ctx:newPart({
		Name = "WoodPile",
		Size = Vector3.new(4, 3, 4),
		CFrame = ctx:point("Fireplace") * CFrame.new(-8, 0, -3), -- north of the hearth
		Transparency = 1,
	})
	ctx:prompt(pile, Strings.Prompts.Take, { objectText = "Wood", distance = 8 }, function(player)
		if ctx.inv.count(player, "wood") < 3 then
			ctx.inv.add(player, "wood", 1)
		end
	end)
	if firePart then
		ctx:prompt(firePart, Strings.Prompts.AddWood, { distance = 9 }, function(player)
			if ctx.inv.remove(player, "wood", 1) then
				fuel = math.min(100, fuel + WOOD_FUEL)
				showFire()
				ctx:sfx("torch_ignite", firePart.Position, 0.5)
			end
		end)
	end
	local endsAt = ctx:timer(NIGHT_SECONDS)
	local warned = false
	local intruders: { any } = {}
	local windows = { "TavernWindow1", "TavernWindow2", "TavernWindow3", "TavernWindow4" }
	local nextPeek = os.clock() + 6
	while workspace:GetServerTimeNow() < endsAt do
		local dt = task.wait(0.25)
		fuel = math.max(0, fuel - FIRE_DRAIN * dt)
		showFire()
		ctx:objective("C2_FIRE", math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow())))
		if fuel < 30 and not warned then
			warned = true
			ctx:say("C2_GIALLINO_FIRE_LOW")
		elseif fuel >= 30 then
			warned = false
		end
		if os.clock() >= nextPeek then
			nextPeek = os.clock() + math.random(5, 9)
			task.spawn(peek, ctx, windows[math.random(1, #windows)])
		end
		if fuel <= 0 and #intruders == 0 then
			-- the fire died: two Glitchlings climb in through the windows
			for i = 1, 2 do
				local w = ctx:point(windows[i])
				table.insert(intruders, ctx.threats.spawnGlitchling(w * CFrame.new(0, -1, 3)))
			end
		elseif fuel > 20 and #intruders > 0 then
			-- they hate the light: back out
			for _, g in intruders do
				ctx.threats.remove(g)
			end
			table.clear(intruders)
		end
	end
	ctx.threats.clear()
	ctx:clearTimer()
	ctx:clearObjective()
	fuel = 60
	showFire()
	ctx:say("C2_GIALLINO_DAWN")
	ctx:cleanup()
end

------------------------------------------------------------------ 2-3a / 2-4 the last dance, morning

local function lastDance(ctx: Ctx)
	ctx:cutscene("CS_05")
	ctx.npcs.show("Ballerina", false)
	ctx.npcs.show("FrigoCamelo", false)
	ctx.npcs.show("UdinDinDinDun", false)
end

local function morning(ctx: Ctx)
	ctx:preset("dawn", 1)
	ctx:glitch("shuttersOpen")
	-- Ballerina's door: broken OUTWARD, lying on the street with splinters around it
	local door = ctx.map.find("Village", "BallerinaHouse", "Door")
	if door and door:IsA("BasePart") then
		door.CFrame = CFrame.new(Vector3.new(89.8, 12.05, 76.3) * S)
			* CFrame.Angles(math.rad(90), math.rad(20), 0)
		door.CanCollide = false
		door:SetAttribute("Broken", true)
	end
	for _ = 1, 7 do
		local splinter = Instance.new("Part")
		splinter.Name = "Splinter"
		splinter.Anchored = true
		splinter.CanCollide = false
		splinter.Size = Vector3.new(0.3, 0.15, 0.8 + math.random() * 1.2)
		splinter.Color = Color3.fromHex("#F2A7C3")
		splinter.Material = Enum.Material.WoodPlanks
		splinter.CFrame = CFrame.new(
			Vector3.new(88.6 + math.random() * 2.4, 12.03, 74.8 + math.random() * 3) * S
		) * CFrame.Angles(0, math.random() * math.pi, 0)
		splinter.Parent = ctx.map.find("Village", "BallerinaHouse") or workspace
	end
	for _, id in VILLAGERS do
		if id ~= "Ballerina" and id ~= "FrigoCamelo" and id ~= "UdinDinDinDun" then
			ctx.npcs.show(id, true)
			ctx.npcs.home(id)
		end
	end
	local innDoor = tavernDoor(ctx)
	if innDoor then
		ctx.map.setDoor(innDoor, true)
	end
	ctx:cutscene("CS_06")
	ctx:teleport(ctx:ground("ClueFootprints") * CFrame.new(0, 0, 10), 3)
	ctx:award("CHAPTER_2")
end

local chapter: StoryContext.Chapter = {
	index = 2,
	title = "The First Night",
	steps = {
		StoryContext.step({
			name = "knock",
			checkpoint = { point = "Fireplace", offset = Vector3.new(0, 0, -8) },
			run = knock,
		}),
		StoryContext.step({
			name = "night",
			checkpoint = { point = "Fireplace", offset = Vector3.new(0, 0, -8) },
			run = night,
		}),
		StoryContext.step({ name = "lastDance", run = lastDance }),
		StoryContext.step({ name = "morning", run = morning }),
	},
}

return chapter
