--!strict
-- What the everyday items do when used from the inventory: food and bandages heal. (Chapter
-- items like flares and stones register their own handlers while their chapter needs them.)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local HealthService = require(script.Parent.HealthService)
local Hud = require(script.Parent.Hud)
local InventoryService = require(script.Parent.InventoryService)

local ItemUse = {}

local HEAL: { [string]: number } = {
	bread = 25,
	apple = 15,
	bandage = 40,
}

function ItemUse.init()
	for id, amount in HEAL do
		InventoryService.onUse(id, function(player: Player): boolean
			if
				HealthService.state(player) ~= "Alive"
				or HealthService.hp(player) >= Config.Health.MaxHealth
			then
				return false
			end
			HealthService.heal(player, amount)
			Hud.worldFxFor({ player }, "sfx", { name = "xp_orb_pickup", volume = 0.6 })
			return true
		end)
	end
end

return ItemUse
