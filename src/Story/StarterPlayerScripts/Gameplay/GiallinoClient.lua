--!strict
-- The Giallino companion (brief, gameplay system 7): a local glowing block that follows the
-- player, with a face and idle chatter that depend on the server-owned mood
-- (Happy 100-70, Off 69-40, Broken 39-10, Hostile <10). Lines get corrupted as the mood breaks.
-- Visible while workspace attribute CompanionVisible is true and the player is not in a cutscene.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))
local FaceController = require(Shared:WaitForChild("Visual"):WaitForChild("FaceController"))
local GiallinoLines = require(Shared:WaitForChild("StoryData"):WaitForChild("GiallinoLines"))
local GiallinoText = require(Shared:WaitForChild("GiallinoText"))
local PoseAnimator = require(Shared:WaitForChild("Visual"):WaitForChild("PoseAnimator"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Subtitles = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Subtitles"))

local GiallinoClient = {}

local player = Players.LocalPlayer
local model: Model? = nil
local animator: PoseAnimator.PoseAnimator? = nil
local position: CFrame? = nil
local nextChat = os.clock() + 40
local currentFace = ""

local FACE_BY_TIER =
	{ Happy = "happy", Off = "smile_crooked", Broken = "neutral", Hostile = "angry" }

local function tier(): string
	local mood = (player:GetAttribute("GiallinoMood") :: number?) or 100
	return Config.moodTier(mood)
end

local function ensureModel(): Model?
	if model and model.Parent then
		return model
	end
	local templates = ReplicatedStorage:FindFirstChild("RigTemplates")
	local template = templates and templates:FindFirstChild("Giallino")
	if not template or not template:IsA("Model") then
		return nil
	end
	local m = template:Clone()
	m.Name = "GiallinoCompanion"
	for _, d in m:GetDescendants() do
		if d:IsA("BillboardGui") then
			d.Enabled = false
		elseif d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CastShadow = false
		end
	end
	m:ScaleTo(0.75) -- smaller beside the camera so it does not block the view
	m.Parent = workspace
	model = m
	local a = PoseAnimator.new(m)
	a:play("A-GIALLINO_IDLE")
	animator = a
	currentFace = ""
	return m
end

local function setVisible(visible: boolean)
	local m = model
	if not m then
		return
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = if visible then 0 else 1
		elseif d:IsA("SurfaceGui") or d:IsA("Light") then
			(d :: any).Enabled = visible
		end
	end
end

local function say(text: string)
	Subtitles.show("Giallino", GiallinoText.corrupt(text, tier()), function(index)
		if index % 2 == 1 then
			local broken = ((player:GetAttribute("GiallinoMood") :: number?) or 100) < 40
			Audio.play(
				if broken then "giallino_blip_broken" else "giallino_blip",
				nil,
				{ volume = 0.22 }
			)
		end
	end)
end

function GiallinoClient.init()
	Remotes.get(Remotes.Names.GiallinoSay).OnClientEvent:Connect(function(text: string)
		if typeof(text) == "string" then
			say(text)
		end
	end)
	RunService.RenderStepped:Connect(function(dt: number)
		local wanted = workspace:GetAttribute("CompanionVisible") == true
			and not player:GetAttribute("InCutscene")
			and player:GetAttribute("LifeState") ~= "Dead"
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not wanted or not root or not root:IsA("BasePart") then
			setVisible(false)
			return
		end
		local m = ensureModel()
		if not m then
			return
		end
		setVisible(true)
		local camera = workspace.CurrentCamera
		local look = camera.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		flat = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.new(0, 0, -1)
		local right = flat:Cross(Vector3.yAxis)
		local bob = math.sin(os.clock() * 2) * 0.25
		local goalPos = root.Position + right * 4.5 + Vector3.new(0, 3 + bob, 0) - flat * 1.5
		local goal = CFrame.lookAt(goalPos, root.Position + Vector3.new(0, 2, 0) + flat * 4)
		position = if position then position:Lerp(goal, math.clamp(dt * 4, 0, 1)) else goal
		m:PivotTo(
			(position :: CFrame) * (if animator then animator:getRootOffset() else CFrame.identity)
		)
		if animator then
			animator:step()
		end
		local face = FACE_BY_TIER[tier()] or "happy"
		if face ~= currentFace then
			currentFace = face
			FaceController.set(m, face)
		end
		if os.clock() >= nextChat then
			nextChat = os.clock() + math.random(35, 70)
			local pool = GiallinoLines[tier()]
			if pool and #pool > 0 then
				say(pool[math.random(1, #pool)])
			end
		end
	end)
end

return GiallinoClient
