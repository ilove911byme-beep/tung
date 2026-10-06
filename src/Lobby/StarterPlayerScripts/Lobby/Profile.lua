--!strict
-- What this client knows about itself in the lobby: owned achievements (badges + the last story
-- run), the last ending (menu meta effect), the chapter picked in CHAPTERS. Sends the settings
-- and the chapter to the server, which hands them to the Story place in the TeleportData.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Settings = require(script.Parent.Parent:WaitForChild("Settings"))

local Profile = {}

local owned: { [string]: boolean } = {}
local lastEnding: string? = nil
local chapter = 1
local changed = Instance.new("BindableEvent")
Profile.Changed = changed.Event

local ENDINGS: { [string]: string } =
	{ dawn = "ENDING_DAWN", endless = "ENDING_ENDLESS_NIGHT", sahur = "ENDING_SAHUR" }

function Profile.owns(id: string): boolean
	return owned[id] == true
end

function Profile.ownsEnding(ending: string): boolean
	local id = ENDINGS[ending]
	return id ~= nil and owned[id] == true
end

--- Single chapters can be replayed once any ending is owned (no DataStore: badges only).
function Profile.anyEnding(): boolean
	for _, id in ENDINGS do
		if owned[id] then
			return true
		end
	end
	return false
end

function Profile.lastEnding(): string?
	return lastEnding
end

function Profile.chapter(): number
	return chapter
end

function Profile.send()
	Remotes.get(Remotes.Names.LobbyProfile):FireServer(Settings.get(), chapter)
end

function Profile.setChapter(n: number)
	chapter = if n == 1 or Profile.anyEnding() then math.clamp(n, 1, 6) else 1
	Profile.send()
	changed:Fire()
end

function Profile.init()
	Remotes.get(Remotes.Names.LobbyOwned).OnClientEvent
		:Connect(function(list: { string }, ending: string?)
			owned = {}
			for _, id in list do
				owned[id] = true
			end
			lastEnding = ending
			changed:Fire()
		end)
	-- sliders fire many changes: send once they settle (the server rate-limits the remote)
	local token = 0
	Settings.Changed:Connect(function()
		token += 1
		local mine = token
		task.delay(0.8, function()
			if mine == token then
				Profile.send()
			end
		end)
	end)
	Profile.send()
end

return Profile
