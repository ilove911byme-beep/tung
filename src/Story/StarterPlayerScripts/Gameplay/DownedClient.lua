--!strict
-- Client side of Downed / Dead / revive:
--  * every Downed character (yours and teammates') plays A-PLAYER_DOWN then A-PLAYER_CRAWL
--  * your own fall plays CS-DOWN, your death CS-DEAD, the paid revive CS-REVIVE (local cutscenes)
--  * the reviver plays A-PLAYER_REVIVE_HELP while holding the prompt
--  * your own revive prompt is hidden from you
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))
local PoseAnimator = require(Shared:WaitForChild("Visual"):WaitForChild("PoseAnimator"))

local CutsceneEngine =
	require(script.Parent.Parent:WaitForChild("Cutscene"):WaitForChild("CutsceneEngine"))
local Overlay = require(script.Parent.Parent:WaitForChild("Cutscene"):WaitForChild("Overlay"))

local DownedClient = {}

local player = Players.LocalPlayer
local animators: { [Model]: PoseAnimator.PoseAnimator } = {}
local heartbeat: Sound? = nil

local DOWNED_RED = Color3.fromRGB(150, 10, 10)

local function animatorFor(character: Model): PoseAnimator.PoseAnimator
	local a = animators[character]
	if not a then
		a = PoseAnimator.new(character)
		animators[character] = a
	end
	return a
end

local function setAnimate(character: Model, enabled: boolean)
	local animate = character:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then
		animate.Enabled = enabled
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator and not enabled then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0.2)
		end
	end
end

local function formModel(): string
	local chapter = (workspace:GetAttribute("Chapter") :: number?) or 1
	if chapter >= 6 then
		return "GiallinoTotale"
	elseif chapter == 5 then
		return "Crudelino"
	elseif chapter == 4 then
		return "Negatino"
	elseif chapter == 3 then
		return "Falsino"
	end
	return "Giallino"
end

local function onState(p: Player)
	local character = p.Character
	if not character then
		return
	end
	local state = p:GetAttribute("LifeState")
	local a = animatorFor(character)
	if state == "Downed" then
		a:play("A-PLAYER_DOWN", { restart = true })
		task.delay(1.0, function()
			if p:GetAttribute("LifeState") == "Downed" then
				a:play("A-PLAYER_CRAWL")
			end
		end)
		if p == player then
			setAnimate(character, false)
			CutsceneEngine.playLocal("CS_DOWN")
			heartbeat = Audio.loop("heartbeat_loop", nil, { volume = 0.7, fadeIn = 0.5 })
			-- the red edges stay while you crawl (CS-DOWN's own vignette ends with the cutscene)
			task.delay(2.4, function()
				if p:GetAttribute("LifeState") == "Downed" and not CutsceneEngine.isPlaying() then
					Overlay.setVignette(true, DOWNED_RED)
				end
			end)
		end
	elseif state == "Dead" then
		if p == player then
			Audio.stop(heartbeat, 0.5)
			heartbeat = nil
			CutsceneEngine.playLocal("CS_DEAD", { models = { Giallino = formModel() } })
		end
	else
		a:stop("*")
		if p == player then
			if not CutsceneEngine.isPlaying() then
				Overlay.setVignette(false)
			end
			Audio.stop(heartbeat, 0.5)
			heartbeat = nil
			setAnimate(character, true)
		end
	end
end

local function hook(p: Player)
	p:GetAttributeChangedSignal("LifeState"):Connect(function()
		onState(p)
	end)
	p.CharacterAdded:Connect(function(character)
		animators[character] = nil
	end)
	if p == player then
		p:GetAttributeChangedSignal("Revived"):Connect(function()
			CutsceneEngine.playLocal("CS_REVIVE")
		end)
	end
end

function DownedClient.init()
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
	RunService.RenderStepped:Connect(function()
		for character, a in animators do
			if character.Parent then
				a:step()
			else
				animators[character] = nil
			end
		end
	end)
	-- hide my own revive prompt
	ProximityPromptService.PromptShown:Connect(function(prompt)
		if
			prompt.Name == "RevivePrompt"
			and player.Character
			and prompt:IsDescendantOf(player.Character)
		then
			prompt.Enabled = false
		end
	end)
	-- reviver pose while holding
	ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
		if prompt.Name == "RevivePrompt" and player.Character then
			animatorFor(player.Character):play("A-PLAYER_REVIVE_HELP", { restart = true })
		end
	end)
	ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt)
		if prompt.Name == "RevivePrompt" and player.Character then
			animatorFor(player.Character):stop("A-PLAYER_REVIVE_HELP")
		end
	end)
end

return DownedClient
