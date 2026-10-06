--!strict
-- Local life of the map (all purely visual, so it runs on the client):
--  * the flat clouds drift east and wrap around the valley (map.md section 1)
--  * models tagged "Spin" turn (the mill wings): attributes SpinAxis ("X"/"Y"/"Z"), SpinSpeed
--  * villager NPCs (tag "NPC") breathe with A-IDLE_BREATH when they are near the camera, walk
--    with A-WALK while the server sets their attribute Walking, loop the animation in Anim
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FaceController = require(Shared:WaitForChild("Visual"):WaitForChild("FaceController"))
local PoseAnimator = require(Shared:WaitForChild("Visual"):WaitForChild("PoseAnimator"))

local MapClient = {}

local WORLD = Config.World.SizeBlocks * Config.World.StudsPerBlock
local CLOUD_SPEED = 1.2 -- studs per second
local NPC_RANGE = 160

type Spinner = { model: Model, base: CFrame, axis: Vector3, speed: number }

local spinners: { [Model]: Spinner } = {}
local npcAnimators: { [Model]: PoseAnimator.PoseAnimator } = {}

local function addSpinner(inst: Instance)
	if not inst:IsA("Model") or spinners[inst] then
		return
	end
	local axisName = inst:GetAttribute("SpinAxis")
	local axis = if axisName == "X"
		then Vector3.xAxis
		elseif axisName == "Y" then Vector3.yAxis
		else Vector3.zAxis
	spinners[inst] = {
		model = inst,
		base = inst:GetPivot(),
		axis = axis,
		speed = math.rad((inst:GetAttribute("SpinSpeed") :: number?) or 20),
	}
end

local function refreshNpc(model: Model, a: PoseAnimator.PoseAnimator)
	local walking = model:GetAttribute("Walking") == true
	local anim = model:GetAttribute("Anim")
	if walking then
		a:play("A-WALK")
	else
		a:stop("A-WALK")
	end
	local current = model:GetAttribute("_PlayingAnim")
	if current ~= anim then
		if typeof(current) == "string" then
			a:stop(current)
		end
		if typeof(anim) == "string" then
			a:play(anim, { restart = true })
		end
		model:SetAttribute("_PlayingAnim", anim)
	end
end

-- pixel faces for server models (villagers, bosses): DefaultFace, then the attribute Face
local function addFace(inst: Instance)
	if not inst:IsA("Model") or inst:GetAttribute("_FaceHooked") then
		return
	end
	local model = inst
	model:SetAttribute("_FaceHooked", true)
	local function apply()
		local face = model:GetAttribute("Face") or model:GetAttribute("DefaultFace")
		if typeof(face) == "string" and FaceController.get(model) then
			FaceController.set(model, face)
		end
	end
	model:GetAttributeChangedSignal("Face"):Connect(apply)
	apply()
end

local function addNpc(inst: Instance)
	addFace(inst)
	if inst:IsA("Model") and not npcAnimators[inst] then
		local model = inst
		local a = PoseAnimator.new(model)
		a:play("A-IDLE_BREATH", { startClock = os.clock() - math.random() * 3 })
		npcAnimators[model] = a
		model:GetAttributeChangedSignal("Walking"):Connect(function()
			refreshNpc(model, a)
		end)
		model:GetAttributeChangedSignal("Anim"):Connect(function()
			refreshNpc(model, a)
		end)
		refreshNpc(model, a)
	end
end

function MapClient.init()
	for _, m in CollectionService:GetTagged("Spin") do
		addSpinner(m)
	end
	CollectionService:GetInstanceAddedSignal("Spin"):Connect(addSpinner)
	CollectionService:GetInstanceRemovedSignal("Spin"):Connect(function(inst)
		spinners[inst :: any] = nil
	end)
	for _, m in CollectionService:GetTagged("NPC") do
		addNpc(m)
	end
	for _, m in CollectionService:GetTagged("Faced") do
		addFace(m)
	end
	CollectionService:GetInstanceAddedSignal("Faced"):Connect(addFace)
	CollectionService:GetInstanceAddedSignal("NPC"):Connect(addNpc)
	CollectionService:GetInstanceRemovedSignal("NPC"):Connect(function(inst)
		local a = npcAnimators[inst :: any]
		if a then
			a:destroy()
			npcAnimators[inst :: any] = nil
		end
	end)
	local started = os.clock()
	RunService.RenderStepped:Connect(function(dt: number)
		local t = os.clock() - started
		for _, c in CollectionService:GetTagged("Cloud") do
			if c:IsA("BasePart") then
				local p = c.Position + Vector3.new(CLOUD_SPEED * dt, 0, 0)
				if p.X > WORLD + 200 then
					p -= Vector3.new(WORLD + 400, 0, 0)
				end
				c.CFrame = CFrame.new(p)
			end
		end
		for model, s in spinners do
			if model.Parent then
				model:PivotTo(s.base * CFrame.fromAxisAngle(s.axis, t * s.speed))
			end
		end
		local camera = workspace.CurrentCamera
		local camPos = camera and camera.CFrame.Position or Vector3.zero
		for model, a in npcAnimators do
			local pivot = model:GetPivot().Position
			if
				model.Parent
				and (pivot - camPos).Magnitude < NPC_RANGE
				and not model:GetAttribute("ServerAnimated")
			then
				a:step()
			end
		end
	end)
end

return MapClient
