--!strict
-- Layout of Brainrot Valley from map.md + map_layout.png, in BLOCKS (1 block = 4 studs; x west
-- -> east, z north -> south, y up, ground surface y = 12). Plain data shared by the server
-- MapBuilder (which builds it) and the chapter scripts (which look up points by name).
-- Where map.md and the layout picture disagree, the picture's position wins (e.g. Trippi
-- Troppi's house is in the north-west of the village, not at the river).

export type House = {
	id: string,
	x: number, -- min corner
	z: number,
	w: number, -- size along x
	d: number, -- size along z
	height: number, -- wall height in blocks (per floor 4)
	floors: number?,
	door: "N" | "S" | "E" | "W",
	roof: string, -- roof color (hex)
	doorColor: string,
	wall: string?, -- wall block (default oak_planks)
	trim: string?, -- corner pillars (default oak_log)
	doorAt: number?, -- door center along its wall (default: middle)
	doorWidth: number?, -- blocks (default 1)
	doorHeight: number?, -- blocks (default 2)
}

export type Spot = { x: number, y: number, z: number, yaw: number? }

local MapData = {}

MapData.Size = 160
MapData.Ground = 12
MapData.WaterY = 10
MapData.TerrainBase = 4 -- surface terrain goes down to here; the mine lies below

-- the river (water x 112..116, sand banks 110..112 / 116..118) and its bridge
MapData.River = { x0 = 112, x1 = 116, bank = 2, bedY = 8 }
MapData.Bridge = { x0 = 108, x1 = 120, z0 = 80, z1 = 83 }

MapData.Village = { x0 = 55, x1 = 108, z0 = 55, z1 = 108 }
MapData.Square = { x0 = 72.5, x1 = 87.5, z0 = 72.5, z1 = 87.5 }
MapData.Fields = { x0 = 58, x1 = 68, z0 = 98, z1 = 106, canalZ = 102 }
MapData.Forest = { x0 = 15, x1 = 55, z0 = 105, z1 = 150 }
MapData.Gorge = { x0 = 20, x1 = 50, z0 = 138, z1 = 144, depth = 10 }
MapData.TungHill = { x = 80, z = 126, radius = 9.5, height = 6 }
MapData.Plateau = { z0 = 18, z1 = 45, x0 = 105, height = 6 } -- north-east hill with the mine
MapData.Airstrip = { x0 = 128, x1 = 132, z0 = 92, z1 = 132 }
MapData.Tunnel = { x0 = 0, x1 = 23, z0 = 78, z1 = 83, y0 = 12, y1 = 16 }
MapData.Rails = { x0 = 2, x1 = 52, z = 80.5 }

-- dirt paths: {x0, x1, z0, z1}
MapData.Paths = {
	{ 49, 72.5, 79, 82 }, -- station -> square
	{ 87.5, 112, 80, 83 }, -- square -> bridge
	{ 120, 124, 80, 83 }, -- bridge -> hangar
	{ 79, 82, 55, 62.5 }, -- north road to the tower
	{ 79, 82, 69.5, 72.5 }, -- tower -> square
	{ 79, 82, 87.5, 118 }, -- square -> Tung Tung's hill
	{ 73, 76, 87.5, 93 }, -- square -> shop
	{ 82, 90, 92, 95 }, -- well lane
	{ 60, 79, 96, 98 }, -- fields lane
	{ 119, 125, 31, 40 }, -- mine approach
}

MapData.Houses = {
	{
		id = "Tavern",
		x = 61.5,
		z = 74.5,
		w = 9,
		d = 11,
		height = 8,
		floors = 2,
		door = "E",
		doorAt = 84,
		roof = "#6A3A22",
		doorColor = "#5A3418",
	},
	{
		id = "BallerinaHouse",
		x = 91.5,
		z = 72.5,
		w = 7,
		d = 7,
		height = 4,
		door = "W",
		roof = "#C86A8A",
		doorColor = "#F2A7C3",
	},
	{
		id = "Bakery",
		x = 89.5,
		z = 84.5,
		w = 7,
		d = 9,
		height = 5,
		door = "W",
		roof = "#8A4A2A",
		doorColor = "#6A3A1A",
		wall = "bricks",
	},
	{
		id = "Shop",
		x = 66,
		z = 88.5,
		w = 7,
		d = 7,
		height = 4,
		door = "N",
		roof = "#C8A030",
		doorColor = "#E0C040",
	},
	{
		id = "LiriliWorkshop",
		x = 85.5,
		z = 60.5,
		w = 7,
		d = 7,
		height = 4,
		door = "S",
		roof = "#6A4A8A",
		doorColor = "#8A6AAA",
	},
	{
		id = "Barn",
		x = 99.5,
		z = 64.5,
		w = 9,
		d = 7,
		height = 6,
		door = "W",
		doorWidth = 3,
		doorHeight = 3,
		roof = "#7A2A22",
		doorColor = "#5A1A12",
	},
	{
		id = "Hangar",
		x = 118.5,
		z = 81.5,
		w = 11,
		d = 9,
		height = 6,
		door = "S",
		doorWidth = 5,
		doorHeight = 4,
		roof = "#4A5A3A",
		doorColor = "#5A6A4A",
		wall = "cobblestone",
	},
	{
		id = "Mill",
		x = 99,
		z = 99,
		w = 5,
		d = 5,
		height = 7,
		door = "N",
		roof = "#6A4A2A",
		doorColor = "#6A4A2A",
		wall = "cobblestone",
	},
	{
		id = "TrippiHouse",
		x = 57,
		z = 62,
		w = 5,
		d = 5,
		height = 4,
		door = "E",
		roof = "#D8703A",
		doorColor = "#F08A50",
	},
	{
		id = "UdinHouse",
		x = 57,
		z = 70,
		w = 5,
		d = 5,
		height = 4,
		door = "E",
		roof = "#6A4A90",
		doorColor = "#9A70C0",
	},
	{
		id = "BonecaHouse",
		x = 98,
		z = 57,
		w = 5,
		d = 5,
		height = 4,
		door = "S",
		roof = "#3E7A2E",
		doorColor = "#5EA04E",
	},
	{
		id = "VacaHouse",
		x = 96,
		z = 92,
		w = 5,
		d = 5,
		height = 4,
		door = "W",
		roof = "#3A3A3A",
		doorColor = "#F4F4F4",
	},
	{
		id = "FrigoHouse",
		x = 67,
		z = 100,
		w = 5,
		d = 5,
		height = 4,
		door = "N",
		roof = "#8AA0B0",
		doorColor = "#C9A06A",
	},
	{
		id = "GlorboHouse",
		x = 87,
		z = 100,
		w = 5,
		d = 5,
		height = 4,
		door = "N",
		roof = "#2A6A2A",
		doorColor = "#D84040",
	},
	{
		id = "TungHut",
		x = 78,
		z = 124,
		w = 4,
		d = 4,
		height = 3,
		door = "S",
		roof = "#5A3A22",
		doorColor = "#8A5A30",
	},
} :: { House }

MapData.Tower = { x = 76.5, z = 62.5, w = 7, d = 7, height = 30 } -- top at y 42
MapData.Station = { x = 49.5, z = 75, w = 6, d = 10 }
MapData.Well = { x = 82.5, z = 91.5 }
MapData.Fountain = { x = 77.5, z = 96.5 }
MapData.NoticeBoard = { x = 75, z = 71 }
MapData.PatapimTree = { x = 33.5, z = 126.5 } -- 3x3 trunk min corner
MapData.MineDoor = { x = 122, z = 30 }

-- the four braziers of the Negatino fight (square corners)
MapData.Braziers = {
	{ x = 74, z = 74 },
	{ x = 86, z = 74 },
	{ x = 74, z = 86 },
	{ x = 86, z = 86 },
}

-- Memory Pages M2-M12 (M1 is in the lobby place)
MapData.MemoryPages = {
	M2 = { x = 56, y = 12, z = 74 },
	M3 = { x = 80, y = 13, z = 80 },
	M4 = { x = 63.9, y = 12, z = 77.1 }, -- tucked behind the tavern fireplace
	M5 = { x = 94.5, y = 12.5, z = 73.2 }, -- Ballerina's mirror
	M6 = { x = 80.8, y = 18, z = 125.6 }, -- Tung Tung's hut on the hill
	M7 = { x = 84.6, y = 34, z = 66 }, -- clock tower balcony roof
	M8 = { x = 35, y = 12.6, z = 128 }, -- Patapim's hollow
	M9 = { x = 120.5, y = 12, z = 31 }, -- mine entrance
	M10 = { x = 141, y = -12, z = 42 }, -- Lirili's lab
	M11 = { x = 128, y = -25, z = 13 }, -- Crudelino's cave
	M12 = { x = 80, y = 42, z = 66 }, -- top of the clock tower
} :: { [string]: Spot }

-- Villagers placed by the map (tag NPC, attribute CharacterId). Chapters move / hide them.
MapData.NPCs = {
	{ id = "Chimpanzini", x = 69.5, y = 12, z = 91.8, yaw = 0 },
	{ id = "Tralalero", x = 82, y = 12, z = 96, yaw = 270 },
	{ id = "Ballerina", x = 95, y = 12, z = 81, yaw = 180 },
	{ id = "Patapim", x = 35, y = 12, z = 132, yaw = 180 },
	{ id = "Bombardiro", x = 124, y = 12, z = 92, yaw = 180 },
	{ id = "Cappuccino", x = 73, y = 12, z = 70, yaw = 135 },
	{ id = "TungTung", x = 80, y = 18, z = 130, yaw = 0 },
	{ id = "TrippiTroppi", x = 63, y = 12, z = 64.5, yaw = 90 },
	{ id = "UdinDinDinDun", x = 63, y = 12, z = 72.5, yaw = 90 },
	{ id = "BonecaAmbalabu", x = 100.5, y = 12, z = 63.5, yaw = 180 },
	{ id = "LaVacaSaturno", x = 94, y = 12, z = 94.5, yaw = 270 },
	{ id = "FrigoCamelo", x = 69.5, y = 12, z = 98.5, yaw = 0 },
	{ id = "GlorboFruttodrillo", x = 89.5, y = 12, z = 98.5, yaw = 0 },
	{ id = "Strawberry", x = 78.5, y = 12, z = 103, yaw = 90 },
	{ id = "Banana", x = 82.5, y = 12, z = 103, yaw = 270 },
}

-- Named interaction / gameplay points (workspace.Map.Points.<name>). Chapters attach prompts
-- or spawn things here; y is the floor the point stands on.
MapData.Points = {
	-- chapter 1
	ShopCounter = { x = 69.5, y = 12, z = 90.2, yaw = 180 },
	BreadShelf = { x = 92, y = 12, z = 89, yaw = 90 },
	TutorialStart = { x = 104, y = 12, z = 72, yaw = 90 },
	TavernEntrance = { x = 72, y = 12, z = 82.5, yaw = 270 },
	-- chapter 2 (tavern)
	Fireplace = { x = 63.4, y = 12, z = 79, yaw = 90 },
	TavernDoorInside = { x = 69, y = 12, z = 84, yaw = 90 },
	Crate1 = { x = 65, y = 12, z = 77, yaw = 0 },
	Crate2 = { x = 66.5, y = 12, z = 77, yaw = 0 },
	Crate3 = { x = 68, y = 12, z = 77, yaw = 0 },
	TavernWindow1 = { x = 70.4, y = 13, z = 77, yaw = 90 },
	TavernWindow2 = { x = 70.4, y = 13, z = 80, yaw = 90 },
	TavernWindow3 = { x = 62, y = 13, z = 82, yaw = 270 },
	TavernWindow4 = { x = 66, y = 13, z = 85.2, yaw = 180 },
	BallerinaDoor = { x = 91.6, y = 12, z = 76, yaw = 270 },
	-- chapter 3 clues
	ClueFootprints = { x = 89, y = 12, z = 77, yaw = 90 },
	ClueWellSign = { x = 84, y = 12, z = 91, yaw = 180 },
	ClueBakeryGlass = { x = 93, y = 19.2, z = 89, yaw = 0 },
	ClueFloorboard = { x = 96, y = 12, z = 77, yaw = 0 },
	ClueMusicBox = { x = 88, y = 12, z = 62, yaw = 180 },
	ClueCodeBoard = { x = 86.2, y = 13, z = 64, yaw = 90 },
	ClueCaveMap = { x = 119.7, y = 13, z = 86, yaw = 90 },
	ClueHollowShard = { x = 35, y = 12.5, z = 129.4, yaw = 180 },
	FakeBat = { x = 101.5, y = 12, z = 105.5, yaw = 180 },
	FakeNote = { x = 75.5, y = 12.5, z = 71.6, yaw = 180 },
	SecretChest = { x = 97, y = 17.5, z = 93, yaw = 270 },
	RooftopStart = { x = 89, y = 12, z = 92, yaw = 90 },
	FalsinoArena = { x = 80, y = 12, z = 80, yaw = 0 },
	BarnCell = { x = 104, y = 12, z = 68, yaw = 270 },
	BarnGate = { x = 99.6, y = 12, z = 68, yaw = 270 },
	-- chapter 4
	OilSpot1 = { x = 60, y = 12, z = 88, yaw = 0 },
	OilSpot2 = { x = 98, y = 12, z = 84, yaw = 0 },
	OilSpot3 = { x = 84, y = 12, z = 58, yaw = 0 },
	OilSpot4 = { x = 74, y = 12, z = 104, yaw = 0 },
	ChaseStart = { x = 72, y = 12, z = 82, yaw = 180 },
	ForestEntrance = { x = 56, y = 12, z = 112, yaw = 225 },
	ForestParkour = { x = 45, y = 12, z = 120, yaw = 225 },
	GorgeNorth = { x = 35, y = 12, z = 137, yaw = 180 },
	GorgeSouth = { x = 35, y = 12, z = 145, yaw = 180 },
	GorgeDetour = { x = 16, y = 12, z = 141, yaw = 180 },
	ForestExit = { x = 50, y = 12, z = 152, yaw = 90 },
	-- chapter 5 (mine)
	MineKeypad = { x = 123.6, y = 13, z = 30.6, yaw = 180 },
	MineInside = { x = 122, y = 12, z = 28, yaw = 0 },
	MineShaftBottom = { x = 122, y = -2, z = 27, yaw = 180 },
	MinecartStart = { x = 122, y = -2, z = 31, yaw = 90 },
	TrackEnd = { x = 146, y = -2, z = 50, yaw = 180 },
	LabEntrance = { x = 146.5, y = -12, z = 47, yaw = 0 },
	LiriliFrozen = { x = 140, y = -12, z = 39, yaw = 180 },
	Lever1 = { x = 125, y = -13, z = 52.5, yaw = 90 },
	Lever2 = { x = 125, y = -13, z = 51, yaw = 90 },
	Lever3 = { x = 125, y = -13, z = 49.5, yaw = 90 },
	Lever4 = { x = 125, y = -13, z = 54, yaw = 90 },
	LeverGear = { x = 131, y = -14, z = 52, yaw = 270 },
	LavaStart = { x = 116.5, y = -20, z = 49, yaw = 270 },
	LavaGear = { x = 100, y = -20, z = 49, yaw = 90 },
	LavaSecretPath = { x = 117, y = -20, z = 41, yaw = 270 },
	MazeStart = { x = 145, y = -16, z = 26, yaw = 90 },
	MazeGear = { x = 155, y = -16, z = 14, yaw = 0 },
	CaveArena = { x = 134, y = -25, z = 20, yaw = 0 },
	CaveExitTop = { x = 135, y = 18, z = 24, yaw = 180 },
	Flare1 = { x = 126, y = -25, z = 12, yaw = 0 },
	Flare2 = { x = 142, y = -25, z = 12, yaw = 0 },
	Flare3 = { x = 126, y = -25, z = 28, yaw = 0 },
	Flare4 = { x = 142, y = -25, z = 28, yaw = 0 },
	Stalactite1 = { x = 130, y = -12, z = 16, yaw = 0 },
	Stalactite2 = { x = 139, y = -12, z = 17, yaw = 0 },
	Stalactite3 = { x = 134, y = -12, z = 26, yaw = 0 },
	-- chapter 6 (finale)
	FinaleStart = { x = 118, y = 18, z = 34, yaw = 225 },
	TowerDoor = { x = 80, y = 12, z = 70, yaw = 180 },
	TowerTopRoom = { x = 80, y = 34, z = 66, yaw = 180 },
	GearSocket1 = { x = 78.5, y = 35, z = 64, yaw = 0 },
	GearSocket2 = { x = 80, y = 35, z = 64, yaw = 0 },
	GearSocket3 = { x = 81.5, y = 35, z = 64, yaw = 0 },
	-- endings
	DawnSquare = { x = 80, y = 12, z = 84, yaw = 0 },
} :: { [string]: Spot }

-- Minecart loop under the north-east hill (Y -2), in order; forks branch off to dead ends.
MapData.Track = {
	y = -2,
	path = {
		{ 122, 31 },
		{ 152, 31 },
		{ 152, 44 },
		{ 128, 44 },
		{ 128, 50 },
		{ 146, 50 },
	},
	forks = { -- branch off path[at] to a dead end
		{ at = 2, to = { 158, 31 } },
		{ at = 3, to = { 158, 44 } },
		{ at = 4, to = { 122, 44 } },
	},
	beams = { { 137, 31 }, { 152, 37 }, { 140, 44 }, { 137, 50 } },
}

-- Rooms of the mine (min corner, size; y = floor)
MapData.Caves = {
	Adit = { x = 118, z = 24, w = 9, d = 11, y = -2, h = 5 },
	Lab = { x = 134, z = 35, w = 12, d = 10, y = -12, h = 7 },
	Levers = { x = 124, z = 48, w = 8, d = 8, y = -14, h = 6 },
	Lava = { x = 98, z = 40, w = 20, d = 18, y = -24, h = 16 },
	Maze = { x = 144, z = 12, w = 13, d = 15, y = -16, h = 3 },
	Cave = { x = 125, z = 10, w = 18, d = 20, y = -25, h = 14 },
}
MapData.LavaLevel = -22 -- lava surface (top of the lava part)
MapData.SkyHole = { x = 133, z = 18, w = 5, d = 5 }

-- /tp spots for the screenshot check (brief, Phase 2)
MapData.ScreenshotSpots = {
	station = { x = 56, y = 14, z = 86, yaw = 60 },
	square = { x = 92, y = 18, z = 92, yaw = 315 },
	tavern = { x = 74, y = 13, z = 88, yaw = 300 },
	tower = { x = 80, y = 14, z = 78, yaw = 0 },
	fields = { x = 72, y = 14, z = 110, yaw = 300 },
	river = { x = 108, y = 14, z = 90, yaw = 30 },
	hill = { x = 80, y = 20, z = 115, yaw = 180 },
	forest = { x = 50, y = 14, z = 120, yaw = 240 },
	gorge = { x = 30, y = 14, z = 135, yaw = 180 },
	mine = { x = 122, y = 13, z = 40, yaw = 0 },
	lab = { x = 140, y = -11, z = 44, yaw = 0 },
	lava = { x = 116, y = -19, z = 49, yaw = 270 },
	cave = { x = 140, y = -23, z = 28, yaw = 315 },
	sky = { x = 80, y = 60, z = 140, yaw = 0 },
}

return MapData
