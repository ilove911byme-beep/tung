--!strict
-- HealthAndDeath (brief, gameplay system 13 + 14):
--   100 HP as 10 hearts. HP 0 -> Downed: crawl, 30 s bleed-out; a teammate holds E for 3 s to
--   revive for free (+30 HP). Bleed-out -> Dead: death screen with "REVIVE - 45 R$" and
--   "Spectate" (free respawn at the next checkpoint). Whole party dead -> PartyWiped (the
--   ChapterManager restarts from the last checkpoint). Solo: Revive or free "Retry from checkpoint".
--   No damage in cutscenes. Fall damage for parkour drops.
-- The Revive developer product is granted ONLY inside the single ProcessReceipt handler: the
-- PurchaseId is remembered so a receipt is never granted twice, PurchaseGranted is returned only
-- after the revive happened, and a player who is no longer dead still gets full HP.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Strings = require(Shared:WaitForChild("Strings"))

local AchievementService = require(script.Parent.AchievementService)
local AuraService = require(script.Parent.AuraService)
local Hud = require(script.Parent.Hud)

local HealthService = {}

local wipedEvent = Instance.new("BindableEvent")
HealthService.PartyWiped = wipedEvent.Event
local retryEvent = Instance.new("BindableEvent")
HealthService.RetryRequested = retryEvent.Event -- solo "Retry from checkpoint"
local downedEvent = Instance.new("BindableEvent")
HealthService.PlayerDowned = downedEvent.Event -- (player)

local grantedReceipts: { [string]: boolean } = {}
local bleedTokens: { [Player]: number } = {}
local died: { [number]: boolean } = {} -- for NO_DEATHS
local wipeFired = false
local fallStart: { [Player]: number } = {}

local function humanoidOf(player: Player): (Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	return humanoid, if root and root:IsA("BasePart") then root else nil
end

local function stateOf(player: Player): string
	return (player:GetAttribute("LifeState") :: string?) or "Alive"
end

local function setHp(player: Player, hp: number)
	local value = math.clamp(hp, 0, Config.Health.MaxHealth)
	player:SetAttribute("HP", value)
	local humanoid = humanoidOf(player)
	if humanoid then
		humanoid.Health = math.max(value, 1) -- the Humanoid itself never dies
	end
end

local function setMovement(player: Player, state: string)
	local humanoid = humanoidOf(player)
	if not humanoid then
		return
	end
	if state == "Downed" then
		humanoid.WalkSpeed = 3
		humanoid.JumpHeight = 0
		humanoid.JumpPower = 0
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpHeight = 7.2
		humanoid.JumpPower = 50
	end
end

local function removePrompt(player: Player)
	local _, root = humanoidOf(player)
	local prompt = root and root:FindFirstChild("RevivePrompt")
	if prompt then
		prompt:Destroy()
	end
end

local function setCharacterVisible(player: Player, visible: boolean)
	local character = player.Character
	if not character then
		return
	end
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Transparency = if visible
				then (d:GetAttribute("BaseTransparency") :: number?) or 0
				else 1
		elseif d:IsA("Decal") then
			d.Transparency = if visible then 0 else 1
		end
	end
end

local function alive(): { Player }
	local out = {}
	for _, p in Players:GetPlayers() do
		if stateOf(p) == "Alive" then
			table.insert(out, p)
		end
	end
	return out
end

local function checkWipe()
	if wipeFired then
		return
	end
	local all = Players:GetPlayers()
	if #all == 0 then
		return
	end
	for _, p in all do
		if stateOf(p) ~= "Dead" then
			return
		end
	end
	wipeFired = true
	wipedEvent:Fire()
end

function HealthService.state(player: Player): string
	return stateOf(player)
end

function HealthService.alivePlayers(): { Player }
	return alive()
end

function HealthService.hp(player: Player): number
	return (player:GetAttribute("HP") :: number?) or Config.Health.MaxHealth
end

local function goDead(player: Player)
	if stateOf(player) == "Dead" then
		return
	end
	removePrompt(player)
	player:SetAttribute("LifeState", "Dead")
	died[player.UserId] = true
	local _, root = humanoidOf(player)
	if root then
		root.Anchored = true
	end
	-- the client plays CS-DEAD (pixel dissolve) first, then the body disappears for everyone
	task.delay(2.2, function()
		if stateOf(player) == "Dead" then
			setCharacterVisible(player, false)
		end
	end)
	Remotes.get(Remotes.Names.DeathScreen):FireClient(player, true, #Players:GetPlayers() == 1)
	checkWipe()
end

function HealthService.down(player: Player)
	if stateOf(player) ~= "Alive" or player:GetAttribute("InCutscene") then
		return
	end
	setHp(player, 0)
	player:SetAttribute("LifeState", "Downed")
	player:SetAttribute("DownedUntil", workspace:GetServerTimeNow() + Config.Health.DownedSeconds)
	setMovement(player, "Downed")
	downedEvent:Fire(player)
	local _, root = humanoidOf(player)
	if root then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "RevivePrompt"
		prompt.ActionText = Strings.Health.HoldToRevive
		prompt.ObjectText = player.DisplayName
		prompt.HoldDuration = Config.Health.ReviveHoldSeconds
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = root
		prompt.Triggered:Connect(function(by: Player)
			if by == player or stateOf(by) ~= "Alive" or stateOf(player) ~= "Downed" then
				return
			end
			HealthService.revive(player, Config.Health.ReviveHealth, 1)
			AuraService.add(by, 100)
			if AchievementService.count(by, "revives") >= 5 then
				AchievementService.award(by, "HERO_REVIVE")
			end
		end)
	end
	bleedTokens[player] = (bleedTokens[player] or 0) + 1
	local token = bleedTokens[player]
	task.delay(Config.Health.DownedSeconds, function()
		if bleedTokens[player] == token and stateOf(player) == "Downed" then
			goDead(player)
		end
	end)
	-- if nobody else is standing, the party can still be wiped once everyone bleeds out
end

--- Applies damage (ignored during cutscenes, invulnerability, or when not alive).
function HealthService.damage(player: Player, amount: number, source: string?)
	if stateOf(player) ~= "Alive" or player:GetAttribute("InCutscene") then
		return
	end
	local invulnerable = player:GetAttribute("InvulnerableUntil") :: number?
	if invulnerable and workspace:GetServerTimeNow() < invulnerable then
		return
	end
	if player:GetAttribute("HidingIn") and source ~= "hidecheck" then
		return
	end
	local hp = HealthService.hp(player) - amount
	if hp <= 0 then
		HealthService.down(player)
	else
		setHp(player, hp)
		player:SetAttribute("LastHurt", workspace:GetServerTimeNow())
	end
end

function HealthService.heal(player: Player, amount: number)
	if stateOf(player) == "Alive" then
		setHp(player, HealthService.hp(player) + amount)
	end
end

--- Back on their feet where they are (teammate revive or the paid revive).
function HealthService.revive(player: Player, hp: number, invulnerableSeconds: number?)
	bleedTokens[player] = (bleedTokens[player] or 0) + 1
	removePrompt(player)
	local wasDead = stateOf(player) == "Dead"
	player:SetAttribute("LifeState", "Alive")
	player:SetAttribute("DownedUntil", nil)
	player:SetAttribute("Spectating", nil)
	setHp(player, hp)
	setMovement(player, "Alive")
	local _, root = humanoidOf(player)
	if root then
		root.Anchored = false
	end
	if wasDead then
		setCharacterVisible(player, true)
		Remotes.get(Remotes.Names.DeathScreen):FireClient(player, false, false)
	end
	if invulnerableSeconds then
		player:SetAttribute("InvulnerableUntil", workspace:GetServerTimeNow() + invulnerableSeconds)
	end
	wipeFired = false
end

--- Puts a player at a CFrame with a fresh character state (checkpoints / restarts).
function HealthService.respawn(player: Player, at: CFrame)
	bleedTokens[player] = (bleedTokens[player] or 0) + 1
	player:SetAttribute("LifeState", "Alive")
	player:SetAttribute("DownedUntil", nil)
	player:SetAttribute("Spectating", nil)
	player:SetAttribute("HidingIn", nil)
	player:LoadCharacterAsync()
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if root then
		character:PivotTo(at)
	end
	setHp(player, Config.Health.MaxHealth)
	Remotes.get(Remotes.Names.DeathScreen):FireClient(player, false, false)
	wipeFired = false
end

--- Checkpoint reached: dead / spectating players come back for free.
function HealthService.respawnDead(at: CFrame)
	for i, p in Players:GetPlayers() do
		if stateOf(p) == "Dead" then
			task.spawn(HealthService.respawn, p, at * CFrame.new((i - 1) * 3, 0, 0))
		end
	end
end

--- Party wipe / retry: everybody back at the checkpoint with full HP.
function HealthService.resetAll(at: CFrame)
	for i, p in Players:GetPlayers() do
		task.spawn(HealthService.respawn, p, at * CFrame.new((i - 1) * 3, 0, 0))
	end
end

--- Grants the paid revive. Returns true when the player got it (also when no longer dead).
local function grantRevive(player: Player): boolean
	local humanoid = humanoidOf(player)
	if not humanoid then
		return false
	end
	if stateOf(player) == "Dead" then
		HealthService.revive(
			player,
			Config.Health.ProductReviveHealth,
			Config.Revive.InvulnerableSeconds
		)
		player:SetAttribute("Revived", workspace:GetServerTimeNow()) -- client plays CS-REVIVE
	else
		-- a teammate was faster: never waste the purchase, give full HP instead
		if stateOf(player) == "Downed" then
			HealthService.revive(
				player,
				Config.Health.ProductReviveHealth,
				Config.Revive.InvulnerableSeconds
			)
		else
			setHp(player, Config.Health.ProductReviveHealth)
		end
	end
	return true
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local purchaseId = tostring(receipt.PurchaseId)
	if grantedReceipts[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if receipt.ProductId ~= Config.Revive.ProductId then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, granted = pcall(grantRevive, player)
	if ok and granted then
		grantedReceipts[purchaseId] = true
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function setupCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	humanoid.BreakJointsOnDeath = false
	humanoid.MaxHealth = Config.Health.MaxHealth
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.UseJumpPower = false
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") then
			d:SetAttribute("BaseTransparency", d.Transparency)
		end
	end
	if stateOf(player) ~= "Dead" then
		setHp(player, HealthService.hp(player))
	end
	-- fall damage: drops of more than 3.5 blocks hurt
	humanoid.StateChanged:Connect(function(_, new)
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			return
		end
		if new == Enum.HumanoidStateType.Freefall then
			fallStart[player] = root.Position.Y
		elseif new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			local startY = fallStart[player]
			fallStart[player] = nil
			if startY and not workspace:GetAttribute("NoFallDamage") then
				local drop = startY - root.Position.Y
				if drop > 14 then
					HealthService.damage(player, if drop > 30 then 45 else 25, "fall")
				end
			end
		end
	end)
end

function HealthService.init()
	MarketplaceService.ProcessReceipt = processReceipt
	local function onPlayer(player: Player)
		player:SetAttribute("LifeState", "Alive")
		player:SetAttribute("HP", Config.Health.MaxHealth)
		player:SetAttribute("Aura", 0)
		player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)
		if player.Character then
			task.spawn(setupCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		bleedTokens[p] = nil
		task.defer(checkWipe)
	end)
	Remotes.get(Remotes.Names.DeathChoice).OnServerEvent
		:Connect(function(player: Player, choice: unknown)
			if stateOf(player) ~= "Dead" then
				return
			end
			if choice == "revive" then
				if Config.Revive.ProductId ~= 0 then
					MarketplaceService:PromptProductPurchase(player, Config.Revive.ProductId)
				elseif RunService:IsStudio() then
					-- no product yet: simulate the receipt so the flow can be tested in Studio
					print("[HealthService] Revive ProductId is 0, simulating a purchase in Studio")
					processReceipt({
						PurchaseId = "studio-" .. player.UserId .. "-" .. os.clock(),
						ProductId = 0,
						PlayerId = player.UserId,
					})
				end
			elseif choice == "spectate" then
				player:SetAttribute("Spectating", true)
			elseif choice == "retry" and #Players:GetPlayers() == 1 then
				retryEvent:Fire()
			end
		end)
end

--- True when nobody died this game (NO_DEATHS).
function HealthService.nobodyDied(player: Player): boolean
	return not died[player.UserId]
end

function HealthService.toast(text: string)
	Hud.toast(nil, "info", { text = text })
end

return HealthService
