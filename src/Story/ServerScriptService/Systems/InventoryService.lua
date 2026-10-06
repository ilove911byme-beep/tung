--!strict
-- Server-validated inventory: max 4 slots per player, items stack (Shared/StoryData/Items).
-- Using an item goes through handlers that the chapters register (bandage heals by default).
-- Owning a lantern gives the character a light; LanternFuel drains only when a chapter asks.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Items = require(Shared:WaitForChild("StoryData"):WaitForChild("Items"))
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))

local Hud = require(script.Parent.Hud)

export type Slot = { id: string, count: number }
export type UseHandler = (player: Player, itemId: string) -> boolean -- true = consume one

local InventoryService = {}

local inventories: { [Player]: { Slot } } = {}
local handlers: { [string]: UseHandler } = {}
local limiter = RateLimiter.new(0.25)
local drainEnabled = false

local function slotsOf(player: Player): { Slot }
	local inv = inventories[player]
	if not inv then
		inv = {}
		inventories[player] = inv
	end
	return inv
end

local function updateLantern(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local has = InventoryService.has(player, "lantern")
		or InventoryService.has(player, "glowing_lantern")
	local bright = InventoryService.has(player, "glowing_lantern")
	player:SetAttribute("HasLantern", has)
	local light = root:FindFirstChild("LanternLight")
	if has then
		if not light then
			local l = Instance.new("PointLight")
			l.Name = "LanternLight"
			l.Color = Color3.fromRGB(255, 190, 110)
			l.Shadows = true
			l.Parent = root
			light = l
		end
		local fuel = (player:GetAttribute("LanternFuel") :: number?) or 100
		local pl = light :: PointLight
		pl.Range = (if bright then 22 else 16) * math.clamp(fuel / 60, 0.25, 1)
		pl.Brightness = if fuel > 0 then (if bright then 2.4 else 1.8) else 0
	elseif light then
		light:Destroy()
	end
end

local function sync(player: Player)
	Remotes.get(Remotes.Names.InventoryUpdate):FireClient(player, slotsOf(player))
	updateLantern(player)
end

--- Adds items. Returns how many did not fit (0 = all added).
function InventoryService.add(player: Player, itemId: string, count: number?): number
	local def = Items[itemId]
	assert(def, "unknown item " .. itemId)
	local left = count or 1
	local inv = slotsOf(player)
	for _, slot in inv do
		if slot.id == itemId and slot.count < def.stack then
			local add = math.min(def.stack - slot.count, left)
			slot.count += add
			left -= add
		end
	end
	while left > 0 and #inv < Config.Inventory.MaxSlots do
		local add = math.min(def.stack, left)
		table.insert(inv, { id = itemId, count = add })
		left -= add
	end
	if left > 0 then
		Hud.toast({ player }, "info", { text = Strings.Items.InventoryFull })
	end
	sync(player)
	return left
end

function InventoryService.count(player: Player, itemId: string): number
	local n = 0
	for _, slot in slotsOf(player) do
		if slot.id == itemId then
			n += slot.count
		end
	end
	return n
end

function InventoryService.has(player: Player, itemId: string): boolean
	return InventoryService.count(player, itemId) > 0
end

--- Party-wide count (shared objectives like "6 wood").
function InventoryService.partyCount(itemId: string): number
	local n = 0
	for _, p in Players:GetPlayers() do
		n += InventoryService.count(p, itemId)
	end
	return n
end

function InventoryService.remove(player: Player, itemId: string, count: number?): boolean
	local need = count or 1
	if InventoryService.count(player, itemId) < need then
		return false
	end
	local inv = slotsOf(player)
	for i = #inv, 1, -1 do
		local slot = inv[i]
		if slot.id == itemId and need > 0 then
			local take = math.min(slot.count, need)
			slot.count -= take
			need -= take
			if slot.count <= 0 then
				table.remove(inv, i)
			end
		end
	end
	sync(player)
	return true
end

--- Removes items of a kind from the whole party (e.g. used wood).
function InventoryService.removeFromParty(itemId: string, count: number): number
	local left = count
	for _, p in Players:GetPlayers() do
		local take = math.min(InventoryService.count(p, itemId), left)
		if take > 0 then
			InventoryService.remove(p, itemId, take)
			left -= take
		end
	end
	return count - left
end

--- "Fanum tax": Chimpanzini takes one random item. Returns the item id taken.
function InventoryService.takeRandom(player: Player): string?
	local inv = slotsOf(player)
	local candidates = {}
	for _, slot in inv do
		if slot.id ~= "truth_gear" and slot.id ~= "name_board" then
			table.insert(candidates, slot.id)
		end
	end
	if #candidates == 0 then
		return nil
	end
	local id = candidates[math.random(1, #candidates)]
	InventoryService.remove(player, id, 1)
	return id
end

function InventoryService.slots(player: Player): { Slot }
	return table.clone(slotsOf(player))
end

function InventoryService.clear(player: Player)
	inventories[player] = {}
	sync(player)
end

--- Chapters register what an item does when used (return true to consume it).
function InventoryService.onUse(itemId: string, handler: UseHandler)
	handlers[itemId] = handler
end

function InventoryService.setFuelDrain(enabled: boolean)
	drainEnabled = enabled
end

function InventoryService.refuel(player: Player, amount: number)
	local fuel = (player:GetAttribute("LanternFuel") :: number?) or 100
	player:SetAttribute("LanternFuel", math.clamp(fuel + amount, 0, 100))
	updateLantern(player)
end

function InventoryService.snapshot(): { [number]: { Slot } }
	local out = {}
	for p, inv in inventories do
		local copy = {}
		for _, s in inv do
			table.insert(copy, { id = s.id, count = s.count })
		end
		out[p.UserId] = copy
	end
	return out
end

function InventoryService.restore(snapshot: { [number]: { Slot } })
	for _, p in Players:GetPlayers() do
		local saved = snapshot[p.UserId]
		if saved then
			local copy = {}
			for _, s in saved do
				table.insert(copy, { id = s.id, count = s.count })
			end
			inventories[p] = copy
			sync(p)
		end
	end
end

function InventoryService.init()
	Remotes.get(Remotes.Names.UseItem).OnServerEvent
		:Connect(function(player: Player, index: unknown)
			if typeof(index) ~= "number" or not limiter:allow(player) then
				return
			end
			if player:GetAttribute("InCutscene") or player:GetAttribute("LifeState") ~= "Alive" then
				return
			end
			local slot = slotsOf(player)[math.floor(index)]
			if not slot then
				return
			end
			local handler = handlers[slot.id]
			if handler and handler(player, slot.id) then
				InventoryService.remove(player, slot.id, 1)
			end
		end)
	Players.PlayerAdded:Connect(function(p: Player)
		p:SetAttribute("LanternFuel", 100)
		p.CharacterAdded:Connect(function()
			task.wait(0.5)
			sync(p)
		end)
	end)
	for _, p in Players:GetPlayers() do
		p:SetAttribute("LanternFuel", 100)
	end
	Players.PlayerRemoving:Connect(function(p)
		inventories[p] = nil
	end)
	-- lantern fuel drain (Chapter 4: "lanterns use fuel")
	task.spawn(function()
		while true do
			task.wait(1)
			if drainEnabled then
				for _, p in Players:GetPlayers() do
					if p:GetAttribute("HasLantern") then
						local fuel = (p:GetAttribute("LanternFuel") :: number?) or 100
						p:SetAttribute("LanternFuel", math.max(0, fuel - 1.2))
						updateLantern(p)
					end
				end
			end
		end
	end)
end

return InventoryService
