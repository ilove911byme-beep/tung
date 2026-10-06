--!strict
-- Studio-only chat commands (/help prints them):
--   /cs CS_xx         play any cutscene for everybody (also "CS-05"); /cs list prints the ids
--   /fx <Effect>      run a special effect on the test dummy for the player who typed it
--   /chapter N [step] run the story from chapter N (optionally from a named step)
--   /down /kill /revive   Downed / Dead / revive yourself (tests CS-DOWN, CS-DEAD, CS-REVIVE)
--   /mood N           set Giallino's mood (companion face and chatter follow)
--   /park             build the ParkourKit test segment next to the spawn and track you on it
--   /qte tap|hold|choice|party   run a test QTE
--   /ach <id>         award an achievement (toast test)
--   /flags            print the story flags
--   /tp <spot>        teleport to a screenshot spot (/tp alone lists them) or to a map point
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CutsceneLibrary = require(Shared:WaitForChild("CutsceneLibrary"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local MapData = require(Shared:WaitForChild("World"):WaitForChild("MapData"))

local SSS = script.Parent.Parent
local CutsceneService = require(SSS:WaitForChild("Services"):WaitForChild("CutsceneService"))
local Systems = SSS:WaitForChild("Systems")
local AchievementService = require(Systems:WaitForChild("AchievementService"))
local HealthService = require(Systems:WaitForChild("HealthService"))
local ParkourService = require(Systems:WaitForChild("ParkourService"))
local QTEService = require(Systems:WaitForChild("QTEService"))
local StoryFlags = require(Systems:WaitForChild("StoryFlags"))
local ChapterManager = require(SSS:WaitForChild("Story"):WaitForChild("ChapterManager"))
local MapBuilder = require(SSS:WaitForChild("World"):WaitForChild("MapBuilder"))

local DebugCommands = {}

local ALIASES = {
	"/cs",
	"/fx",
	"/chapter",
	"/down",
	"/kill",
	"/revive",
	"/mood",
	"/park",
	"/qte",
	"/ach",
	"/flags",
	"/tp",
	"/help",
}

local EFFECTS = {
	PixelDissolve = true,
	PixelAssemble = true,
	LastPixel = true,
	Shatter = true,
	Melt = true,
	Grow = true,
	Shrink = true,
	WallBreak = true,
	RootsBridge = true,
	Bloom = true,
	TimeFreeze = true,
	TimeResume = true,
}

-- every ParkourKit block kind once, in a short loop next to the test spawn
local TEST_PARKOUR: ParkourService.SegmentDef = {
	id = "TestParkour",
	killY = -3,
	fall = "return",
	blocks = {
		{ kind = "start", at = { 0, 0, 0 }, size = { 3, 1, 3 } },
		{ kind = "block", at = { 0, 0, -3 } },
		{ kind = "block", at = { 0, 1, -5 } },
		{ kind = "collapse", at = { 0, 1, -7 } },
		{ kind = "block", at = { 0, 1, -9 } },
		{ kind = "fake", at = { 0, 1, -11 } },
		{ kind = "block", at = { 1, 1, -11 } },
		{ kind = "checkpoint", at = { 3, 1, -11 }, size = { 2, 1, 2 } },
		{ kind = "moving", at = { 6, 1, -11 }, move = { 0, 0, 3 }, period = 4 },
		{ kind = "lava", at = { 8, 0, -9 }, size = { 3, 1, 3 } },
		{ kind = "block", at = { 9, 1, -11 } },
		{ kind = "ladder", at = { 11, 2, -11 }, size = { 1, 3, 1 } },
		{ kind = "block", at = { 11, 4, -13 } },
		{ kind = "vine", at = { 11, 5, -15 }, size = { 1, 3, 1 } },
		{ kind = "finish", at = { 11, 7, -17 }, size = { 3, 1, 3 } },
	},
}

local testSegment: ParkourService.Segment? = nil

local function playerRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function buildPark(player: Player)
	local old = testSegment
	if old then
		old:destroy()
	end
	local root = playerRoot(player)
	if not root then
		return
	end
	local origin = CFrame.new(root.Position + Vector3.new(0, -root.Size.Y / 2 - 3.5, -12))
	local segment = ParkourService.build(TEST_PARKOUR, workspace, origin)
	testSegment = segment
	segment.Fell:Connect(function(p: Player)
		print(string.format("[DebugCommands] %s fell (%d)", p.Name, segment:falls(p)))
	end)
	segment.Finished:Connect(function(p: Player, clean: boolean)
		print(string.format("[DebugCommands] %s finished, clean=%s", p.Name, tostring(clean)))
	end)
	segment:track({ player }, true)
end

local function runCutscene(arg: string)
	if arg == "" or string.lower(arg) == "list" then
		print("[DebugCommands] cutscenes: " .. table.concat(CutsceneLibrary.list(), ", "))
		return
	end
	if not CutsceneLibrary.get(arg) then
		warn("[DebugCommands] no cutscene " .. arg)
		return
	end
	if CutsceneService.isPlaying() then
		warn("[DebugCommands] a cutscene is already playing")
		return
	end
	task.spawn(function()
		local result = CutsceneService.play(arg)
		print(
			string.format(
				"[DebugCommands] %s done. choice=%s skipped=%s",
				arg,
				tostring(result.choice),
				tostring(result.skipped)
			)
		)
	end)
end

local function handle(player: Player, text: string)
	local words = string.split(text, " ")
	local command = string.lower(words[1] or "")
	local arg = words[2] or ""
	if command == "/cs" then
		runCutscene(arg)
	elseif command == "/fx" then
		if not EFFECTS[arg] then
			local names = {}
			for name in EFFECTS do
				table.insert(names, name)
			end
			table.sort(names)
			print("[DebugCommands] effects: " .. table.concat(names, ", "))
			return
		end
		Remotes.get(Remotes.Names.DebugFx):FireClient(player, arg)
	elseif command == "/chapter" then
		local n = tonumber(arg) or 1
		if ChapterManager.isRunning() then
			warn("[DebugCommands] the story is already running")
			return
		end
		local step = words[3]
		task.spawn(ChapterManager.run, n, step)
	elseif command == "/down" then
		HealthService.down(player)
	elseif command == "/kill" then
		HealthService.down(player)
		task.delay(0.5, function()
			HealthService.damage(player, 1000, "debug")
		end)
	elseif command == "/revive" then
		HealthService.revive(player, 100, 2)
	elseif command == "/mood" then
		local value = tonumber(arg)
		if value then
			StoryFlags.addMood(value - StoryFlags.get().giallinoMood)
			workspace:SetAttribute("CompanionVisible", true)
		end
	elseif command == "/park" then
		buildPark(player)
	elseif command == "/qte" then
		local kind = if arg == "" then "tap" else arg
		task.spawn(function()
			local spec: QTEService.Spec =
				{ type = kind :: any, duration = 4, presses = 8, answer = "A", label = "TEST" }
			if kind == "party" then
				print(
					"[DebugCommands] party QTE: "
						.. tostring(QTEService.party(Players:GetPlayers(), spec))
				)
			else
				local results = QTEService.run({ player }, spec)
				print("[DebugCommands] QTE result: " .. tostring(results[player]))
			end
		end)
	elseif command == "/ach" then
		AchievementService.award(player, arg)
	elseif command == "/flags" then
		for key, value in StoryFlags.get() :: any do
			print(string.format("  %s = %s", tostring(key), tostring(value)))
		end
	elseif command == "/tp" then
		local spot = MapData.ScreenshotSpots[string.lower(arg)]
		local root = playerRoot(player)
		if not root then
			return
		end
		if spot then
			local pos = Vector3.new(spot.x, spot.y, spot.z) * Config.World.StudsPerBlock
			local r = math.rad(spot.yaw or 0)
			root.CFrame = CFrame.lookAt(pos, pos + Vector3.new(math.sin(r), 0, -math.cos(r)))
		elseif MapData.Points[arg] then
			root.CFrame = MapBuilder.point(arg) + Vector3.new(0, 3, 0)
		else
			local names = {}
			for name in MapData.ScreenshotSpots do
				table.insert(names, name)
			end
			table.sort(names)
			print(
				"[DebugCommands] /tp "
					.. table.concat(names, " | ")
					.. "  (or any MapData.Points name)"
			)
		end
	elseif command == "/help" then
		print("[DebugCommands] " .. table.concat(ALIASES, " "))
	end
end

function DebugCommands.init()
	if not RunService:IsStudio() or not Config.Debug.EnableChatCommands then
		return
	end
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		for _, alias in ALIASES do
			local command = Instance.new("TextChatCommand")
			command.Name = "Debug" .. string.sub(alias, 2)
			command.PrimaryAlias = alias
			command.Triggered:Connect(function(source: TextSource, text: string)
				local player = Players:GetPlayerByUserId(source.UserId)
				if player then
					handle(player, text)
				end
			end)
			command.Parent = TextChatService
		end
	else
		local function hook(player: Player)
			player.Chatted:Connect(function(message)
				if string.sub(message, 1, 1) == "/" then
					handle(player, message)
				end
			end)
		end
		Players.PlayerAdded:Connect(hook)
		for _, p in Players:GetPlayers() do
			hook(p)
		end
	end
end

return DebugCommands
