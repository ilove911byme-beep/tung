--!strict
-- Footsteps for every character: players (Humanoid) and cutscene actors (Footsteps.track).
-- The block under the feet picks the set: grass/dirt -> grass, stone/cobble/bricks -> stone,
-- planks/logs -> wood, gravel/path -> gravel, sand -> sand. Parts built by the MapBuilder carry
-- the attribute Block (map.md palette name); otherwise the Roblox material decides.
-- The step rate follows the walking speed. Roblox's default running sound is disabled by the
-- RbxCharacterSounds script in StarterPlayerScripts.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))

local Footsteps = {}

local BY_BLOCK: { [string]: string } = {
	grass = "grass",
	grass_top = "grass",
	dirt = "grass",
	dirt_path = "gravel",
	gravel = "gravel",
	stone = "stone",
	cobblestone = "stone",
	mossy_cobblestone = "stone",
	bricks = "stone",
	coal_ore = "stone",
	iron_ore = "stone",
	gold_ore = "stone",
	glowstone_ore = "stone",
	oak_planks = "wood",
	oak_log = "wood",
	pale_log = "wood",
	hay = "grass",
	sand = "sand",
	leaves = "grass",
}

local BY_MATERIAL: { [Enum.Material]: string } = {
	[Enum.Material.Grass] = "grass",
	[Enum.Material.Ground] = "grass",
	[Enum.Material.LeafyGrass] = "grass",
	[Enum.Material.Mud] = "grass",
	[Enum.Material.Fabric] = "grass",
	[Enum.Material.Slate] = "stone",
	[Enum.Material.Cobblestone] = "stone",
	[Enum.Material.Brick] = "stone",
	[Enum.Material.Concrete] = "stone",
	[Enum.Material.Rock] = "stone",
	[Enum.Material.Basalt] = "stone",
	[Enum.Material.Granite] = "stone",
	[Enum.Material.Marble] = "stone",
	[Enum.Material.Metal] = "stone",
	[Enum.Material.WoodPlanks] = "wood",
	[Enum.Material.Wood] = "wood",
	[Enum.Material.Pebble] = "gravel",
	[Enum.Material.Sand] = "sand",
	[Enum.Material.Sandstone] = "sand",
}

type Walker = { root: BasePart, humanoid: Humanoid?, lastPos: Vector3, nextStep: number }

local walkers: { [Model]: Walker } = {}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function surfaceUnder(walker: Walker, model: Model): string?
	local origin = walker.root.Position
	rayParams.FilterDescendantsInstances = { model }
	local hit = workspace:Raycast(origin, Vector3.new(0, -6, 0), rayParams)
	if not hit then
		return nil
	end
	local inst = hit.Instance
	local blockName = inst:GetAttribute("Block")
	if typeof(blockName) == "string" and BY_BLOCK[blockName] then
		return BY_BLOCK[blockName]
	end
	return BY_MATERIAL[hit.Material] or "stone"
end

--- Registers a model (e.g. a cutscene actor) whose root is moved by code.
function Footsteps.track(model: Model)
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		walkers[model] = {
			root = root,
			humanoid = model:FindFirstChildOfClass("Humanoid"),
			lastPos = root.Position,
			nextStep = 0,
		}
	end
end

function Footsteps.untrack(model: Model)
	walkers[model] = nil
end

local function onCharacter(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if root then
		Footsteps.track(character)
	end
	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			walkers[character] = nil
		end
	end)
end

local function step(dt: number)
	local now = os.clock()
	for model, w in walkers do
		if not w.root.Parent then
			walkers[model] = nil
			continue
		end
		local pos = w.root.Position
		local delta = Vector3.new(pos.X - w.lastPos.X, 0, pos.Z - w.lastPos.Z)
		w.lastPos = pos
		local speed = if dt > 0 then delta.Magnitude / dt else 0
		local humanoid = w.humanoid
		if humanoid then
			if humanoid.FloorMaterial == Enum.Material.Air or humanoid.Health <= 0 then
				continue
			end
			speed =
				Vector3.new(w.root.AssemblyLinearVelocity.X, 0, w.root.AssemblyLinearVelocity.Z).Magnitude
		end
		if speed > 1.5 and now >= w.nextStep then
			local set = surfaceUnder(w, model)
			if set then
				Audio.play(
					"step_" .. set,
					w.root,
					{ volume = 0.45, rollOffMax = 50, speed = 0.95 + math.random() * 0.1 }
				)
			end
			w.nextStep = now + math.clamp(5.4 / speed, 0.22, 0.7)
		end
	end
end

function Footsteps.init()
	local function hook(player: Player)
		if player.Character then
			task.spawn(onCharacter, player.Character)
		end
		player.CharacterAdded:Connect(onCharacter)
	end
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
	RunService.Heartbeat:Connect(step)
end

return Footsteps
