--!strict
-- Villager NPCs placed by the MapBuilder (workspace.NPCs, tag NPC, attribute CharacterId):
-- show / hide, place, walk (server moves the pivot; the client plays A-WALK while the model
-- has the attribute Walking), loop animations (attribute Anim), talk prompts and the intro
-- chant the first time a villager speaks (voice_lines.md).
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local VoiceLines = require(Shared:WaitForChild("VoiceLines"))

local DialogueService = require(script.Parent.DialogueService)

local NpcService = {}

local hiddenFolder: Folder? = nil
local chanted: { [string]: boolean } = {}

local function hidden(): Folder
	local f = hiddenFolder
	if f and f.Parent then
		return f
	end
	local folder = Instance.new("Folder")
	folder.Name = "HiddenNPCs"
	folder.Parent = ServerStorage
	hiddenFolder = folder
	return folder
end

local function visibleFolder(): Instance
	local f = workspace:FindFirstChild("NPCs")
	if not f then
		local folder = Instance.new("Folder")
		folder.Name = "NPCs"
		folder.Parent = workspace
		f = folder
	end
	return f :: Instance
end

--- The NPC model (visible or hidden).
function NpcService.get(id: string): Model?
	for _, folder in { visibleFolder(), hidden() } do
		for _, m in folder:GetChildren() do
			if m:IsA("Model") and m:GetAttribute("CharacterId") == id then
				return m
			end
		end
	end
	return nil
end

function NpcService.show(id: string, visible: boolean)
	local m = NpcService.get(id)
	if m then
		m.Parent = if visible then visibleFolder() else hidden()
		if visible then
			CollectionService:AddTag(m, "NPC")
		end
	end
end

local function rootHeight(m: Model): number
	return (m:GetAttribute("RootHeight") :: number?) or 0
end

--- Puts the NPC on a ground CFrame (its root height is added).
function NpcService.place(id: string, ground: CFrame)
	local m = NpcService.get(id)
	if m then
		m:SetAttribute("Walking", nil)
		m:PivotTo(ground * CFrame.new(0, rootHeight(m), 0))
	end
end

--- Back to the spot the map put it on.
function NpcService.home(id: string)
	local m = NpcService.get(id)
	if not m then
		return
	end
	local x, y, z = m:GetAttribute("HomeX"), m:GetAttribute("HomeY"), m:GetAttribute("HomeZ")
	if typeof(x) == "number" and typeof(y) == "number" and typeof(z) == "number" then
		local pos = Vector3.new(x, y, z) * 4
		local yaw = math.rad((m:GetAttribute("HomeYaw") :: number?) or 0)
		NpcService.place(
			id,
			CFrame.lookAt(pos, pos + Vector3.new(math.sin(yaw), 0, -math.cos(yaw)))
		)
	end
end

--- Walks the NPC to a ground position (yields). speed in studs per second.
function NpcService.walkTo(id: string, target: Vector3, speed: number?)
	local m = NpcService.get(id)
	if not m then
		return
	end
	local start = m:GetPivot()
	local h = rootHeight(m)
	local from = start.Position
	local to = Vector3.new(target.X, target.Y + h, target.Z)
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if flat.Magnitude < 0.1 then
		return
	end
	local facing = CFrame.lookAt(Vector3.zero, flat.Unit).Rotation
	local duration = (to - from).Magnitude / (speed or 8)
	m:SetAttribute("Walking", true)
	local t0 = os.clock()
	while true do
		local a = math.clamp((os.clock() - t0) / duration, 0, 1)
		m:PivotTo(CFrame.new(from:Lerp(to, a)) * facing)
		if a >= 1 or not m.Parent then
			break
		end
		task.wait()
	end
	m:SetAttribute("Walking", nil)
end

--- A looping animation on the NPC (client side), nil to stop.
function NpcService.setAnim(id: string, anim: string?)
	local m = NpcService.get(id)
	if m then
		m:SetAttribute("Anim", anim)
	end
end

--- Plays the villager's intro chant once per server (the first time they speak).
function NpcService.chant(id: string, players: { Player }?)
	if chanted[id] then
		return
	end
	chanted[id] = true
	local lineId = "CHANT_" .. string.upper(id)
	if VoiceLines.get(lineId) then
		DialogueService.say(lineId, players)
	end
end

--- A "Talk" prompt on the NPC's head. handler(player) runs for alive players.
function NpcService.talkPrompt(
	id: string,
	actionText: string,
	handler: (Player) -> ()
): ProximityPrompt?
	local m = NpcService.get(id)
	local head = m and (m:FindFirstChild("Head") or m.PrimaryPart)
	if not head then
		return nil
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = (m :: Model):GetAttribute("DisplayName") :: string? or id
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = head
	local busy = false
	prompt.Triggered:Connect(function(player: Player)
		if busy or player:GetAttribute("LifeState") ~= "Alive" then
			return
		end
		busy = true
		prompt.Enabled = false
		local ok, err = pcall(function()
			handler(player)
		end)
		if not ok then
			warn("[NpcService] talk handler failed: " .. tostring(err))
		end
		busy = false
		if prompt.Parent then
			prompt.Enabled = true
		end
	end)
	return prompt
end

function NpcService.all(): { Model }
	local out = {}
	for _, m in visibleFolder():GetChildren() do
		if m:IsA("Model") then
			table.insert(out, m)
		end
	end
	return out
end

function NpcService.init()
	hidden()
end

return NpcService
