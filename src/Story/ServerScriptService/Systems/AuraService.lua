--!strict
-- AURA meme (brief <memes>): brave actions "+100 AURA", failures "-50 AURA". Session only;
-- the totals are player attributes ("Aura") for the leaderboard on the ending screen.
local Players = game:GetService("Players")

local Hud = require(script.Parent.Hud)

local AuraService = {}

function AuraService.add(player: Player, amount: number)
	local total = (player:GetAttribute("Aura") :: number?) or 0
	player:SetAttribute("Aura", total + amount)
	Hud.toast({ player }, "aura", { amount = amount })
end

function AuraService.addAll(amount: number, players: { Player }?)
	for _, p in players or Players:GetPlayers() do
		AuraService.add(p, amount)
	end
end

function AuraService.board(): { { name: string, aura: number } }
	local out = {}
	for _, p in Players:GetPlayers() do
		table.insert(out, { name = p.DisplayName, aura = (p:GetAttribute("Aura") :: number?) or 0 })
	end
	table.sort(out, function(a, b)
		return a.aura > b.aura
	end)
	return out
end

return AuraService
