--!strict
-- Server helpers for the HUD remotes: objectives, timers, toasts, boss cards, memory pages.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local Hud = {}

local currentObjective = ""
local currentTimer = 0

local function all(): { Player }
	return Players:GetPlayers()
end

function Hud.objective(text: string)
	currentObjective = text
	local remote = Remotes.get(Remotes.Names.Objective)
	for _, p in all() do
		remote:FireClient(p, text)
	end
end

function Hud.timer(endsAt: number)
	currentTimer = endsAt
	local remote = Remotes.get(Remotes.Names.Timer)
	for _, p in all() do
		remote:FireClient(p, endsAt)
	end
end

function Hud.toast(players: { Player }?, kind: string, data: any)
	local remote = Remotes.get(Remotes.Names.Toast)
	local list: { Player } = players or all()
	for _, p in list do
		remote:FireClient(p, kind, data)
	end
end

function Hud.bossCard(title: string, subtitle: string, signature: string)
	local remote = Remotes.get(Remotes.Names.BossCard)
	for _, p in all() do
		remote:FireClient(p, title, subtitle, signature)
	end
end

function Hud.memoryPage(pageId: string)
	local remote = Remotes.get(Remotes.Names.MemoryPage)
	for _, p in all() do
		remote:FireClient(p, pageId)
	end
end

function Hud.worldFx(kind: string, params: any?)
	local remote = Remotes.get(Remotes.Names.WorldFx)
	for _, p in all() do
		remote:FireClient(p, kind, params)
	end
end

--- A WorldFx effect for some players only (blindness, color drain near Negatino...).
function Hud.worldFxFor(players: { Player }, kind: string, params: any?)
	local remote = Remotes.get(Remotes.Names.WorldFx)
	for _, p in players do
		remote:FireClient(p, kind, params)
	end
end

function Hud.giallinoSay(text: string, players: { Player }?)
	local remote = Remotes.get(Remotes.Names.GiallinoSay)
	local list: { Player } = players or all()
	for _, p in list do
		remote:FireClient(p, text)
	end
end

--- Late joiners get the current objective and timer.
function Hud.init()
	Players.PlayerAdded:Connect(function(p)
		task.wait(3)
		Remotes.get(Remotes.Names.Objective):FireClient(p, currentObjective)
		Remotes.get(Remotes.Names.Timer):FireClient(p, currentTimer)
	end)
end

return Hud
