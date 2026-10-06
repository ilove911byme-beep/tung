--!strict
-- The lobby place world, built by code like the story map (1 block = 4 studs, ground top y 12):
--   * the "Last Stop" station at dusk: platform, lanterns, ticket booth, notice boards with lore
--     posters, the main line (z 20) into the black tunnel through the hill (x 46-96, wall lamps
--     tagged TunnelLamp for CS-00), 4 queue minecarts on sidings (QueueService drives them)
--   * the meme corner: emote stage, the big "6 7" sign, the session Aura board
--   * the endings wall with three framed blocky paintings (lit on the client for owned endings)
--   * a foggy hill in the north where Tung Tung stands (client teaser)
--   * the night valley behind the tunnel for the main menu fly-through: blocky hills, a far
--     village with warm windows, the clock tower on the horizon
-- Camera anchors: Anchor_Lobby_Platform (20, 12, 20), Anchor_Lobby_Tunnel (48, 12, 20).
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local Builder = require(script.Parent:WaitForChild("World"):WaitForChild("Builder"))

local LobbyWorld = {}

local S = Builder.S
local G = 12 -- ground top

LobbyWorld.Ground = G
LobbyWorld.RailZ = 20
LobbyWorld.CartZ = { 24, 27, 30, 33 } -- the 4 queue sidings (cart centers)
LobbyWorld.CartX = 20
LobbyWorld.Spawn = Vector3.new(20, G, 39)
LobbyWorld.TungSpot = Vector3.new(12, 18, -36)
LobbyWorld.EmoteStage = Vector3.new(39, G + 0.5, 49)
LobbyWorld.Paintings = {
	{ ending = "dawn", z = 45.5 },
	{ ending = "endless", z = 49 },
	{ ending = "sahur", z = 52.5 },
}
-- the main menu camera path over the night valley (blocks)
LobbyWorld.MenuPath = {
	Vector3.new(112, 34, -14),
	Vector3.new(146, 29, 4),
	Vector3.new(176, 25, 30),
	Vector3.new(214, 31, 36),
	Vector3.new(230, 36, 0),
	Vector3.new(196, 40, -30),
	Vector3.new(150, 38, -34),
}
LobbyWorld.MenuLook = Vector3.new(205, 22, 14) -- the clock tower

local function tag(inst: Instance, name: string)
	CollectionService:AddTag(inst, name)
end

local function rails(parent: Instance, a: Vector3, b: Vector3)
	for _, side in { -0.35, 0.35 } do
		Builder.slab(parent, "Rail", a, b, 0.08, 0.1, "rail", side, 0, { query = false })
	end
	local length = (b - a).Magnitude
	local dir = (b - a).Unit
	for k = 0, math.floor(length / 1.5) do
		local c = a + dir * (k * 1.5)
		Builder.slab(
			parent,
			"Sleeper",
			c - dir * 0.15,
			c + dir * 0.15,
			1.1,
			0.06,
			"oak_planks",
			0,
			-0.04,
			{ query = false }
		)
	end
end

local function lantern(parent: Instance, x: number, z: number, h: number?)
	local height = h or 2.5
	Builder.box(parent, "LanternPost", x - 0.1, G, z - 0.1, 0.2, height, 0.2, "oak_log")
	local lamp = Builder.box(
		parent,
		"Lantern",
		x - 0.25,
		G + height,
		z - 0.25,
		0.5,
		0.6,
		0.5,
		"torch",
		{ decor = true, color = "#FFC060", material = "Neon" }
	)
	Builder.light(lamp, "#FFB050", 22, 1.4, "Lamp")
end

local function poster(parent: Instance, x: number, z: number, text: string, color: string)
	local board = Builder.box(parent, "Poster", x, G + 1.2, z, 2.4, 1.6, 0.1, "white", {
		color = color,
		noTexture = true,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(300, 200)
	gui.LightInfluence = 1
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -20, 1, -20)
	label.Position = UDim2.fromOffset(10, 10)
	label.Text = text
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.Arcade
	label.TextColor3 = Color3.fromRGB(40, 26, 14)
	label.Parent = gui
end

local function station(parent: Instance)
	local folder = Builder.folder(parent, "Station")
	-- ground and the platform
	Builder.box(folder, "Ground", -44, G - 2, -52, 150, 2, 114, "grass")
	Builder.box(folder, "Platform", 8, G, 35, 26, 0.25, 8, "stone")
	Builder.box(
		folder,
		"PlatformEdge",
		8,
		G,
		34.6,
		26,
		0.3,
		0.4,
		"cobblestone",
		{ color = "#E8C040" }
	)
	for x = 9, 33, 4 do
		lantern(folder, x, 35.4)
	end
	-- ticket booth
	local booth = Builder.model(folder, "TicketBooth")
	Builder.box(booth, "Base", 3, G, 36, 5, 3, 4, "oak_planks")
	Builder.box(booth, "Window", 3.5, G + 1.2, 39.95, 4, 1.2, 0.1, "glass", { transparency = 0.4 })
	Builder.box(booth, "Roof", 2.5, G + 3, 35.5, 6, 0.4, 5, "bricks", { color = "#7A3A2A" })
	Builder.sign(
		booth,
		"StationSign",
		CFrame.new(Builder.studs(5.5, G + 3.8, 40.1)) * CFrame.Angles(0, math.pi, 0),
		Vector3.new(5 * S, 0.8 * S, 0.1 * S),
		"LAST STOP"
	)
	local lamp =
		Builder.box(booth, "Lamp", 5.3, G + 2.5, 40.2, 0.4, 0.4, 0.3, "torch", { decor = true })
	Builder.light(lamp, "#FFC070", 16, 1, "Lamp")
	-- notice boards with lore posters (they face the platform, south)
	local boards = Builder.model(folder, "NoticeBoards")
	Builder.box(boards, "Board", 11.5, G, 42.5, 10, 3.4, 0.3, "oak_planks")
	poster(boards, 12, 42.8, "MISSING:\nBallerina Cappuccina", "#F2E6D0")
	poster(boards, 15, 42.8, "Do not go out after dark", "#E8D8B0")
	poster(boards, 18, 42.8, "Lost: one clock.\nAsk Lirili", "#F0E0C0")
	-- the main line and the rails into the tunnel
	local track = Builder.folder(folder, "Track")
	rails(track, Vector3.new(2, G + 0.1, 20.5), Vector3.new(96, G + 0.1, 20.5))
	for i, z in LobbyWorld.CartZ do
		local zc = z + 0.5
		rails(track, Vector3.new(14, G + 0.1, zc), Vector3.new(34, G + 0.1, zc))
		rails(track, Vector3.new(34, G + 0.1, zc), Vector3.new(40, G + 0.1, 20.5))
		local bumper = Builder.box(track, "Bumper" .. i, 13, G, z - 0.25, 0.5, 0.8, 1.5, "oak_log")
		bumper.Color = Color3.fromHex("#8A2A20")
	end
	-- the anchors the lobby cutscene (CS-00) is framed on
	local anchors = Builder.folder(folder, "Anchors")
	Builder.marker(anchors, "Anchor_Lobby_Platform", 20, G, 20, 90)
	Builder.marker(anchors, "Anchor_Lobby_Tunnel", 48, G, 20, 90)
end

local function tunnelHill(parent: Instance)
	local folder = Builder.folder(parent, "TunnelHill")
	-- the hill around the tunnel: stepped blocks, the tunnel stays open at z 18.5-22.5
	local steps = { { 0, 4 }, { 3, 7 }, { 6, 10 }, { 9, 12 } }
	for _, s in steps do
		local inset, h = s[1], s[2]
		Builder.box(
			folder,
			"HillN",
			46 + inset,
			G,
			2 + inset,
			56 - inset * 2,
			h,
			16.5 - inset,
			"grass"
		)
		Builder.box(folder, "HillS", 46 + inset, G, 22.5, 56 - inset * 2, h, 18 - inset, "grass")
	end
	Builder.box(folder, "HillTop", 46, G + 4, 18.5, 56, 8, 4, "grass")
	-- inside: stone walls and the wall lamps (CS-00 puts them out one by one)
	Builder.box(folder, "TunnelFloor", 46, G - 0.2, 18.5, 56, 0.2, 4, "gravel")
	Builder.box(folder, "WallN", 46, G, 18.3, 56, 4, 0.2, "stone")
	Builder.box(folder, "WallS", 46, G, 22.5, 56, 4, 0.2, "stone")
	Builder.box(folder, "Ceiling", 46, G + 4, 18.5, 56, 0.2, 4, "stone")
	for x = 50, 94, 4 do
		for _, z in { 18.5, 22.3 } do
			local lamp = Builder.box(
				folder,
				"TunnelLamp",
				x,
				G + 2.4,
				z,
				0.3,
				0.3,
				0.2,
				"torch",
				{ decor = true, color = "#FFC060", material = "Neon" }
			)
			Builder.light(lamp, "#FFB050", 12, 0.9, "TunnelLamp")
		end
	end
	-- the mouth: an oak frame
	Builder.box(folder, "FrameL", 45.5, G, 17.8, 0.6, 4.6, 0.7, "oak_log")
	Builder.box(folder, "FrameR", 45.5, G, 22.5, 0.6, 4.6, 0.7, "oak_log")
	Builder.box(folder, "FrameTop", 45.5, G + 4, 17.8, 0.6, 0.7, 5.4, "oak_log")
	-- the far end is black: a dark curtain hides the valley from inside the tunnel
	Builder.box(folder, "TunnelEnd", 101.6, G, 18.5, 0.4, 4, 4, "black", { noTexture = true })
end

local function memeCorner(parent: Instance)
	local folder = Builder.folder(parent, "MemeCorner")
	local stage =
		Builder.box(folder, "EmoteStage", 36, G, 46, 6, 0.5, 6, "oak_planks", { color = "#B07A48" })
	stage:SetAttribute("Block", "oak_planks")
	for _, c in { { 36, 46 }, { 41.6, 46 }, { 36, 51.6 }, { 41.6, 51.6 } } do
		Builder.box(folder, "StageLight", c[1], G + 0.5, c[2], 0.4, 3, 0.4, "oak_log")
		local bulb = Builder.box(
			folder,
			"Bulb",
			c[1] + 0.05,
			G + 3.5,
			c[2] + 0.05,
			0.3,
			0.3,
			0.3,
			"torch",
			{ decor = true, color = "#FF60D0", material = "Neon" }
		)
		Builder.light(bulb, "#FF60D0", 14, 1.2)
	end
	Builder.sign(
		folder,
		"StageSign",
		CFrame.new(Builder.studs(39, G + 4.2, 52.2)) * CFrame.Angles(0, math.pi, 0),
		Vector3.new(5 * S, 0.8 * S, 0.1 * S),
		"EMOTE STAGE"
	)
	-- the big "6 7" sign
	local sign = Builder.sign(
		folder,
		"SixSevenSign",
		CFrame.new(Builder.studs(39, G + 6, 55)) * CFrame.Angles(0, math.pi, 0),
		Vector3.new(6 * S, 2.4 * S, 0.2 * S),
		Strings.Lobby.SixSevenSign
	)
	sign.Color = Color3.fromHex("#2A2A3A")
	local label = sign:FindFirstChildOfClass("SurfaceGui")
	local text = label and label:FindFirstChildOfClass("TextLabel")
	if text then
		text.TextColor3 = Color3.fromHex("#FF9A3C")
		text.Font = Enum.Font.FredokaOne
	end
	Builder.box(folder, "SignPostL", 36.5, G, 54.9, 0.3, 4.8, 0.3, "oak_log")
	Builder.box(folder, "SignPostR", 41.2, G, 54.9, 0.3, 4.8, 0.3, "oak_log")
	-- the aura board (SurfaceGui filled by AuraBoard)
	local board =
		Builder.box(folder, "AuraBoard", 45, G, 44, 0.3, 4, 6, "oak_planks", { color = "#3A2A1A" })
	tag(board, "AuraBoard")
end

local function endingsWall(parent: Instance)
	local folder = Builder.folder(parent, "EndingsWall")
	Builder.box(folder, "Wall", 0, G, 44, 0.6, 4, 10, "bricks", { color = "#6A4A3A" })
	for _, p in LobbyWorld.Paintings do
		Builder.box(folder, "Frame", 0.6, G + 1, p.z - 1.3, 0.2, 2.2, 2.6, "oak_log")
		local canvas =
			Builder.box(folder, "Painting", 0.8, G + 1.25, p.z - 1.05, 0.08, 1.7, 2.1, "black", {
				noTexture = true,
				color = "#202028",
			})
		canvas:SetAttribute("Ending", p.ending)
		tag(canvas, "EndingPainting")
		local light =
			Builder.box(folder, "PaintingLamp", 1.2, G + 3.4, p.z - 0.15, 0.3, 0.2, 0.3, "torch", {
				decor = true,
			})
		local l = Builder.light(light, "#FFE0A0", 10, 0, "PaintingLamp")
		l.Enabled = false
		light:SetAttribute("Ending", p.ending)
	end
end

local function tungHill(parent: Instance)
	local folder = Builder.folder(parent, "TungHill")
	for i = 0, 5 do
		Builder.box(
			folder,
			"Hill",
			0 + i,
			G + i,
			-46 + i,
			24 - i * 2,
			1,
			18 - i * 2,
			if i == 5 then "grass" else "dirt"
		)
	end
	Builder.marker(
		folder,
		"TungSpot",
		LobbyWorld.TungSpot.X,
		LobbyWorld.TungSpot.Y,
		LobbyWorld.TungSpot.Z,
		180
	)
end

-- a far valley for the menu: coarse terrain columns, a village with warm windows, the tower
local function valley(parent: Instance)
	local folder = Builder.folder(parent, "Valley")
	local rng = Random.new(1717)
	for x = 102, 246, 6 do
		for z = -46, 70, 6 do
			local villageArea = x > 160 and x < 222 and z > -8 and z < 40
			local h = if villageArea
				then 0
				else math.floor(
					2
						+ 3 * math.noise(x / 40, z / 40, 0.3)
						+ 4 * math.max(0, (x - 220) / 30)
						+ rng:NextNumber() * 1.5
				)
			h = math.max(h, 0)
			Builder.box(
				folder,
				"Land",
				x,
				G - 4,
				z,
				6,
				4 + h,
				6,
				if h > 4 then "stone" else "grass"
			)
			if not villageArea and rng:NextNumber() < 0.18 then
				-- a blocky tree
				local tx, tz = x + 2.5, z + 2.5
				Builder.box(folder, "Trunk", tx, G + h, tz, 1, 3, 1, "oak_log")
				Builder.box(folder, "Leaves", tx - 1, G + h + 2.5, tz - 1, 3, 2, 3, "leaves")
			end
		end
	end
	-- the village: small houses with warm windows
	local houses = {
		{ 168, 4 },
		{ 176, 16 },
		{ 170, 28 },
		{ 186, 30 },
		{ 196, 22 },
		{ 214, 26 },
		{ 186, 0 },
		{ 214, 4 },
	}
	for i, h in houses do
		local house = Builder.model(folder, "House" .. i)
		Builder.box(house, "Walls", h[1], G, h[2], 5, 3, 5, "oak_planks")
		Builder.box(
			house,
			"Roof",
			h[1] - 0.5,
			G + 3,
			h[2] - 0.5,
			6,
			1,
			6,
			"bricks",
			{ color = "#7A3A2A" }
		)
		Builder.box(
			house,
			"Roof2",
			h[1] + 0.5,
			G + 4,
			h[2] + 0.5,
			4,
			1,
			4,
			"bricks",
			{ color = "#7A3A2A" }
		)
		local window =
			Builder.box(house, "Window", h[1] + 2, G + 1.2, h[2] - 0.05, 1, 1, 0.1, "glass", {
				color = "#FFC060",
				material = "Neon",
				decor = true,
			})
		Builder.light(window, "#FFB050", 18, 1.2)
	end
	-- the clock tower on the horizon
	local tower = Builder.model(folder, "ClockTower")
	Builder.box(tower, "Body", 202, G, 11, 6, 22, 6, "cobblestone")
	Builder.box(tower, "Top", 201.5, G + 22, 10.5, 7, 1, 7, "oak_planks")
	Builder.box(tower, "Spire", 203, G + 23, 12, 4, 4, 4, "bricks", { color = "#7A3A2A" })
	local face = Builder.part(
		tower,
		"ClockFace",
		CFrame.new(Builder.studs(205, G + 17, 10.9)) * CFrame.Angles(0, math.rad(90), 0),
		Vector3.new(0.2 * S, 4 * S, 4 * S),
		"white",
		{ shape = "Cylinder", color = "#F0E6C8", material = "Neon" }
	)
	Builder.light(face, "#FFE0A0", 30, 1)
end

local function lighting()
	Lighting.ClockTime = 18.4
	Lighting.Brightness = 1.6
	Lighting.Ambient = Color3.fromRGB(70, 60, 80)
	Lighting.OutdoorAmbient = Color3.fromRGB(90, 80, 110)
	Lighting.FogStart = 0
	Lighting.FogEnd = 1400
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.36
	atmosphere.Haze = 2
	atmosphere.Color = Color3.fromRGB(200, 150, 140)
	atmosphere.Decay = Color3.fromRGB(80, 60, 110)
	atmosphere.Glare = 0.3
	atmosphere.Parent = Lighting
end

function LobbyWorld.build(): Folder
	local old = workspace:FindFirstChild("LobbyMap")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "LobbyMap"
	station(root)
	tunnelHill(root)
	memeCorner(root)
	endingsWall(root)
	tungHill(root)
	valley(root)
	lighting()
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.CFrame = CFrame.new(
		Builder.studs(LobbyWorld.Spawn.X, G, LobbyWorld.Spawn.Z) + Vector3.new(0, 1.6, 0)
	)
	spawn.Parent = root
	root.Parent = workspace
	return root
end

return LobbyWorld
