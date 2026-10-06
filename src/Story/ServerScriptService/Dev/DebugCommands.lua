--!strict
-- Studio-only chat commands:
--   /cs CS_xx      play any cutscene for everybody (also "CS-05"); /cs list prints the ids
--   /fx <Effect>   run a special effect on the test dummy for the player who typed it
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CutsceneLibrary = require(Shared:WaitForChild("CutsceneLibrary"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local CutsceneService =
	require(script.Parent.Parent:WaitForChild("Services"):WaitForChild("CutsceneService"))

local DebugCommands = {}

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

local function handle(player: Player, text: string)
	local words = string.split(text, " ")
	local command = string.lower(words[1] or "")
	local arg = words[2] or ""
	if command == "/cs" then
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
	end
end

function DebugCommands.init()
	if not RunService:IsStudio() or not Config.Debug.EnableChatCommands then
		return
	end
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		for _, alias in { "/cs", "/fx" } do
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
