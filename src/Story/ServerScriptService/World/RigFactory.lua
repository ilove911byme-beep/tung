--!strict
-- Builds the placeholder character rigs from Shared/RigSpecs into ServerStorage.Models
-- (one folder, so they can later be swapped for Creator Store meshes). Humanoid rigs are Parts
-- joined by Motor6Ds with an anchored HumanoidRootPart; Giallino is one glowing block.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RigSpecs = require(Shared:WaitForChild("RigSpecs"))
local UITheme = require(Shared:WaitForChild("UITheme"))

local RigFactory = {}

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function material(name: string?, fallback: Enum.Material): Enum.Material
	if name then
		local ok, value = pcall(function()
			return (Enum.Material :: any)[name]
		end)
		if ok and value then
			return value
		end
	end
	return fallback
end

local function newPart(name: string, size: Vector3, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	return p
end

local function nameTag(adornee: BasePart, text: string, height: number): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(220, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 60
	gui.LightInfluence = 0
	gui.Adornee = adornee
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = UITheme.Fonts.Body
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = UITheme.Colors.Text
	label.TextStrokeTransparency = 0.4
	label.Parent = gui
	gui.Parent = adornee
	return gui
end

local function colorFor(def: RigSpecs.CharacterDef, partName: string): Color3
	local hex = def.colors[partName] or def.colors["*"] or "#CCCCCC"
	return Color3.fromHex(hex)
end

local function buildHumanoid(id: string, def: RigSpecs.CharacterDef): Model
	local skel = RigSpecs.skeleton
	local model = Instance.new("Model")
	model.Name = id
	local parts: { [string]: Part } = {}
	for name, partDef in skel.parts do
		local p = newPart(name, v3(partDef.size), colorFor(def, name))
		if name == "HumanoidRootPart" then
			p.Transparency = 1
			p.Anchored = true
			p.Massless = false
		end
		parts[name] = p
	end
	local root = parts.HumanoidRootPart
	root.CFrame = CFrame.new(0, skel.rootHeight, 0)
	-- place every part from its joint so the rig starts in its rest pose
	local placed: { [string]: boolean } = { HumanoidRootPart = true }
	local pending = table.clone(skel.joints)
	while #pending > 0 do
		local progressed = false
		for i = #pending, 1, -1 do
			local j = pending[i]
			if placed[j.part0] then
				local p0 = parts[j.part0]
				local p1 = parts[j.part1]
				local c0 = CFrame.new(v3(j.c0))
				local c1 = CFrame.new(v3(j.c1))
				p1.CFrame = p0.CFrame * c0 * c1:Inverse()
				local motor = Instance.new("Motor6D")
				motor.Name = j.name
				motor.Part0 = p0
				motor.Part1 = p1
				motor.C0 = c0
				motor.C1 = c1
				motor.Parent = p0
				placed[j.part1] = true
				table.remove(pending, i)
				progressed = true
			end
		end
		assert(progressed, "RigSpecs skeleton has a joint whose parent is never placed")
	end
	for _, p in parts do
		p.Parent = model
	end
	local accessories: { RigSpecs.AccessoryDef } = def.accessories or {}
	for _, acc in accessories do
		local host = parts[acc.part]
		assert(host, id .. ": accessory host missing " .. acc.part)
		local p = newPart(acc.name, v3(acc.size), Color3.fromHex(acc.color))
		p.Material = material(acc.material, Enum.Material.SmoothPlastic)
		p.Transparency = acc.transparency or 0
		p.CFrame = host.CFrame * CFrame.new(v3(acc.offset))
		local weld = Instance.new("Weld")
		weld.Name = acc.name .. "Weld"
		weld.Part0 = host
		weld.Part1 = p
		weld.C0 = CFrame.new(v3(acc.offset))
		weld.Parent = p
		p.Parent = model
	end
	parts.Head:SetAttribute("FaceStyle", def.faceStyle)
	model.PrimaryPart = root
	model:SetAttribute("CharacterId", id)
	model:SetAttribute("RootHeight", skel.rootHeight)
	nameTag(parts.Head, def.displayName, 1.6)
	return model
end

local function buildCube(id: string, def: RigSpecs.CharacterDef): Model
	local model = Instance.new("Model")
	model.Name = id
	local s = def.cubeSize or 4
	local body = newPart("Body", Vector3.new(s, s, s), colorFor(def, "Body"))
	body.Material = material(def.material, Enum.Material.Neon)
	body.Anchored = true
	body.Massless = false
	body.CFrame = CFrame.new(0, 0, 0)
	body:SetAttribute("FaceStyle", def.faceStyle)
	body.Parent = model

	local glow = Instance.new("PointLight")
	glow.Name = "Glow"
	glow.Color = body.Color
	glow.Range = 16
	glow.Brightness = 1.6
	glow.Shadows = true
	glow.Parent = body

	local spot = Instance.new("SpotLight")
	spot.Name = "Spot"
	spot.Color = Color3.fromRGB(255, 226, 140)
	spot.Face = Enum.NormalId.Front
	spot.Angle = 70
	spot.Range = 24
	spot.Brightness = 4
	spot.Shadows = true
	spot.Enabled = false
	spot.Parent = body

	model.PrimaryPart = body
	model:SetAttribute("CharacterId", id)
	model:SetAttribute("RootHeight", 0)
	nameTag(body, def.displayName, s * 0.5 + 1)
	return model
end

--- Builds every rig from RigSpecs into ServerStorage.Models (replacing old copies).
function RigFactory.buildAll(): Folder
	local folder = ServerStorage:FindFirstChild("Models")
	if not folder then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "Models"
		newFolder.Parent = ServerStorage
		folder = newFolder
	end
	assert(folder and folder:IsA("Folder"), "ServerStorage.Models must be a Folder")
	for id, def in RigSpecs.characters do
		local old = folder:FindFirstChild(id)
		if old then
			old:Destroy()
		end
		local model = if def.kind == "cube" then buildCube(id, def) else buildHumanoid(id, def)
		model.Parent = folder
	end
	return folder
end

return RigFactory
