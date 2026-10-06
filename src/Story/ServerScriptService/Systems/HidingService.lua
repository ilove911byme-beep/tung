--!strict
-- Hiding spots (wardrobes, beds, barrels): Parts tagged "HidingSpot" with attribute SpotName
-- ("In the wardrobe", "Under the bed", "Behind the barrels"). While hiding is enabled a prompt
-- lets a player hide: the character is anchored inside the spot and threats ignore it.
-- check() runs the "hold your breath" QTE for everyone hiding; failing reveals you (20 damage).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local HealthService = require(script.Parent.HealthService)
local QTEService = require(script.Parent.QTEService)
local StoryFlags = require(script.Parent.StoryFlags)

local HidingService = {}

local enabled = false
local occupied: { [BasePart]: Player } = {}
local returnTo: { [Player]: CFrame } = {}

local function spotName(spot: BasePart): string
	return (spot:GetAttribute("SpotName") :: string?) or spot.Name
end

function HidingService.hide(player: Player, spot: BasePart)
	if
		occupied[spot]
		or player:GetAttribute("HidingIn")
		or player:GetAttribute("LifeState") ~= "Alive"
	then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not root or not root:IsA("BasePart") then
		return
	end
	occupied[spot] = player
	returnTo[player] = root.CFrame
	character:PivotTo(spot.CFrame)
	root.Anchored = true
	player:SetAttribute("HidingIn", spotName(spot))
	StoryFlags.get().hidingSpots[tostring(player.UserId)] = spotName(spot)
end

function HidingService.unhide(player: Player)
	local name = player:GetAttribute("HidingIn")
	if not name then
		return
	end
	for spot, p in occupied do
		if p == player then
			occupied[spot] = nil
		end
	end
	player:SetAttribute("HidingIn", nil)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character and root and root:IsA("BasePart") then
		root.Anchored = false
		local back = returnTo[player]
		if back then
			character:PivotTo(back)
		end
	end
	returnTo[player] = nil
end

function HidingService.unhideAll()
	for _, p in Players:GetPlayers() do
		HidingService.unhide(p)
	end
end

function HidingService.setEnabled(on: boolean)
	enabled = on
	for _, spot in CollectionService:GetTagged("HidingSpot") do
		local prompt = spot:FindFirstChild("HidePrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = on
		end
	end
	if not on then
		HidingService.unhideAll()
	end
end

function HidingService.hiddenPlayers(): { Player }
	local out = {}
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("HidingIn") then
			table.insert(out, p)
		end
	end
	return out
end

--- "Hold your breath": QTE for every hidden player; failures are found (20 damage).
--- Returns the players who failed.
function HidingService.check(damage: number?): { Player }
	local hidden = HidingService.hiddenPlayers()
	if #hidden == 0 then
		return {}
	end
	local results =
		QTEService.run(hidden, { type = "hold", duration = 5, label = Strings.Prompts.HoldBreath })
	local failed = {}
	for p, ok in results do
		if not ok then
			table.insert(failed, p)
			HidingService.unhide(p)
			HealthService.damage(p, damage or 20, "hidecheck")
		end
	end
	return failed
end

local function setupSpot(spot: Instance)
	if not spot:IsA("BasePart") or spot:FindFirstChild("HidePrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HidePrompt"
	prompt.ActionText = Strings.Prompts.Hide
	prompt.ObjectText = spotName(spot)
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Enabled = enabled
	prompt.Parent = spot
	prompt.Triggered:Connect(function(player: Player)
		if not enabled then
			return
		end
		if player:GetAttribute("HidingIn") then
			HidingService.unhide(player)
		else
			HidingService.hide(player, spot)
		end
	end)
end

function HidingService.init()
	for _, spot in CollectionService:GetTagged("HidingSpot") do
		setupSpot(spot)
	end
	CollectionService:GetInstanceAddedSignal("HidingSpot"):Connect(setupSpot)
	Players.PlayerRemoving:Connect(function(p: Player)
		for spot, who in occupied do
			if who == p then
				occupied[spot] = nil
			end
		end
	end)
end

return HidingService
