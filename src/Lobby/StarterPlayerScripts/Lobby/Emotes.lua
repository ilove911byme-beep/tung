--!strict
-- Lobby emotes (brief, <memes>): the server keeps the chosen emote in the player attribute
-- "Emote"; every client animates every emoting avatar locally with the PoseAnimator (Motor6D
-- offsets, so no uploaded animations). The bat swing gets a little wooden bat in the hand.
-- Moving ends your own emote.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PoseAnimator = require(Shared:WaitForChild("Visual"):WaitForChild("PoseAnimator"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Emotes = {}

Emotes.List = { "A-EMOTE_67", "A-EMOTE_AURA", "A-EMOTE_BRAINROT", "A-EMOTE_BAT" }

type State = {
	animator: PoseAnimator.PoseAnimator,
	character: Model,
	playing: string?,
	bat: BasePart?,
}

local states: { [Player]: State } = {}
local localPlayer = Players.LocalPlayer
local stopSent = false

local function removeBat(state: State)
	if state.bat then
		state.bat:Destroy()
		state.bat = nil
	end
end

local function addBat(state: State)
	local hand = state.character:FindFirstChild("RightHand")
		or state.character:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then
		return
	end
	local bat = Instance.new("Part")
	bat.Name = "EmoteBat"
	bat.Size = Vector3.new(0.45, 0.45, 3.4)
	bat.Color = Color3.fromRGB(150, 105, 60)
	bat.Material = Enum.Material.Wood
	bat.CanCollide = false
	bat.CanQuery = false
	bat.Massless = true
	bat.CFrame = hand.CFrame * CFrame.new(0, -0.3, -1.5)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = bat
	weld.Parent = bat
	bat.Parent = state.character
	state.bat = bat
end

local function refresh(player: Player)
	local character = player.Character
	local emote = player:GetAttribute("Emote")
	local state = states[player]
	if state and (state.character ~= character or state.playing ~= emote) then
		-- back to the rest pose, then (maybe) start the new emote
		removeBat(state)
		state.animator:destroy()
		states[player] = nil
	end
	if player == localPlayer then
		stopSent = typeof(emote) ~= "string"
	end
	if not character or typeof(emote) ~= "string" or states[player] then
		return
	end
	local s: State = {
		animator = PoseAnimator.new(character),
		character = character,
		playing = emote,
		bat = nil,
	}
	states[player] = s
	s.animator:play(emote, { restart = true })
	if emote == "A-EMOTE_BAT" then
		addBat(s)
	end
end

local function watch(player: Player)
	player:GetAttributeChangedSignal("Emote"):Connect(function()
		refresh(player)
	end)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		refresh(player)
	end)
	refresh(player)
end

--- Asks the server for an emote ("" stops).
function Emotes.play(id: string)
	Remotes.get(Remotes.Names.LobbyEmote):FireServer(id)
end

function Emotes.init()
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(p: Player)
		local s = states[p]
		if s then
			removeBat(s)
			s.animator:destroy()
		end
		states[p] = nil
	end)
	RunService.RenderStepped:Connect(function()
		for _, state in states do
			if state.character.Parent then
				state.animator:step()
			end
		end
	end)
	RunService.Heartbeat:Connect(function()
		local character = localPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.MoveDirection.Magnitude > 0.1 and not stopSent then
			if typeof(localPlayer:GetAttribute("Emote")) == "string" then
				stopSent = true
				Emotes.play("")
			end
		end
	end)
end

return Emotes
