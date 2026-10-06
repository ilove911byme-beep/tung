--!strict
-- Builds the placeholder character and prop rigs from Shared/RigSpecs into ServerStorage.Models
-- (one folder, so they can later be swapped for Creator Store meshes) and mirrors them to
-- ReplicatedStorage.RigTemplates for the client-only service cutscenes.
--   humanoid: Parts joined by Motor6Ds with an anchored HumanoidRootPart
--   cube:     Giallino and his forms, one glowing block (Totale has a face on every side)
--   custom:   props with joints (door, minecart, gears, sign, lever); first part is the root
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RigSpecs = require(Shared:WaitForChild("RigSpecs"))
local UITheme = require(Shared:WaitForChild("UITheme"))

local RigFactory = {}

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function angles(t: { number }?): CFrame
	if not t then
		return CFrame.identity
	end
	return CFrame.Angles(math.rad(t[1]), math.rad(t[2]), math.rad(t[3]))
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

local function shape(name: string?): Enum.PartType
	if name == "Cylinder" then
		return Enum.PartType.Cylinder
	elseif name == "Ball" then
		return Enum.PartType.Ball
	end
	return Enum.PartType.Block
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

-- Accessories are welded to their host part. Ones that start invisible (BoardInHand, Knife,
-- Tear...) keep BaseTransparency so cutscene showPart / hidePart cues know their real look.
local function addAccessories(
	model: Model,
	def: RigSpecs.CharacterDef,
	parts: { [string]: BasePart }
)
	local list: { RigSpecs.AccessoryDef } = def.accessories or {}
	for _, acc in list do
		local host = parts[acc.part]
		assert(host, model.Name .. ": accessory host missing " .. acc.part)
		local p = newPart(acc.name, v3(acc.size), Color3.fromHex(acc.color))
		p.Shape = shape(acc.shape)
		p.Size = v3(acc.size)
		p.Material = material(acc.material, Enum.Material.SmoothPlastic)
		p.Transparency = acc.transparency or 0
		p:SetAttribute("BaseTransparency", 0)
		local offset = CFrame.new(v3(acc.offset)) * angles(acc.rot)
		p.CFrame = host.CFrame * offset
		local weld = Instance.new("Weld")
		weld.Name = acc.name .. "Weld"
		weld.Part0 = host
		weld.Part1 = p
		weld.C0 = offset
		weld.Parent = p
		p.Parent = model
	end
end

-- Places every Part1 from its joint so the rig starts in its rest pose, creating the Motor6Ds.
local function buildJoints(
	parts: { [string]: BasePart },
	joints: { RigSpecs.JointDef },
	rootName: string
)
	local placed: { [string]: boolean } = { [rootName] = true }
	local pending = table.clone(joints)
	while #pending > 0 do
		local progressed = false
		for i = #pending, 1, -1 do
			local j = pending[i]
			if placed[j.part0] then
				local p0 = parts[j.part0]
				local p1 = parts[j.part1]
				assert(p0 and p1, "joint " .. j.name .. " names a missing part")
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
		assert(progressed, "rig has a joint whose parent is never placed")
	end
end

local function buildHumanoid(id: string, def: RigSpecs.CharacterDef): Model
	local skel = RigSpecs.skeleton
	local model = Instance.new("Model")
	model.Name = id
	local parts: { [string]: BasePart } = {}
	for name, partDef in skel.parts do
		local p = newPart(name, v3(partDef.size), colorFor(def, name))
		if name == "HumanoidRootPart" then
			p.Transparency = 1
			p.Anchored = true
			p.Massless = false
		elseif name == "Head" and def.headMaterial then
			p.Material = material(def.headMaterial, Enum.Material.SmoothPlastic)
		end
		parts[name] = p
	end
	local root = parts.HumanoidRootPart
	root.CFrame = CFrame.new(0, skel.rootHeight, 0)
	buildJoints(parts, skel.joints, "HumanoidRootPart")
	for _, p in parts do
		p.Parent = model
	end
	addAccessories(model, def, parts)
	parts.Head:SetAttribute("FaceStyle", def.faceStyle or "villager")
	model.PrimaryPart = root
	model:SetAttribute("RootHeight", skel.rootHeight)
	if not def.noTag then
		nameTag(parts.Head, def.displayName, 1.6)
	end
	return model
end

-- Giallino Totale: three more screens (right, back, left), each a transparent panel in its own
-- sub-model so FaceController can drive it separately.
local SIDE_FACES = {
	{ name = "FaceRight", yaw = -90, face = "smile_crooked" },
	{ name = "FaceBack", yaw = 180, face = "neutral" },
	{ name = "FaceLeft", yaw = 90, face = "angry" },
}

local function buildCube(id: string, def: RigSpecs.CharacterDef): Model
	local model = Instance.new("Model")
	model.Name = id
	local s = def.cubeSize or 4
	local stretch = def.cubeStretch or { 1, 1, 1 }
	local size = Vector3.new(s * stretch[1], s * stretch[2], s * stretch[3])
	local body = newPart("Body", size, colorFor(def, "Body"))
	body.Material = material(def.material, Enum.Material.Neon)
	body.Anchored = true
	body.Massless = false
	body.CFrame = CFrame.new(0, 0, 0)
	body:SetAttribute("FaceStyle", def.faceStyle or "screen")
	body.Parent = model

	local glowDef = def.glow
	local glow = Instance.new("PointLight")
	glow.Name = "Glow"
	glow.Color = if glowDef then Color3.fromHex(glowDef.color) else body.Color
	glow.Range = if glowDef then glowDef.range else 16
	glow.Brightness = if glowDef then glowDef.brightness else 1.6
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

	if def.multiFace then
		for _, side in SIDE_FACES do
			local sub = Instance.new("Model")
			sub.Name = side.name
			local panel = newPart("Panel", Vector3.new(size.X, size.Y, 0.05), body.Color)
			panel.Transparency = 1
			local offset = CFrame.Angles(0, math.rad(side.yaw), 0)
				* CFrame.new(0, 0, -size.Z / 2 - 0.03)
			panel.CFrame = body.CFrame * offset
			panel:SetAttribute("FaceStyle", "screen")
			local weld = Instance.new("Weld")
			weld.Part0 = body
			weld.Part1 = panel
			weld.C0 = offset
			weld.Parent = panel
			panel.Parent = sub
			sub:SetAttribute("DefaultFace", side.face)
			sub.Parent = model
		end
	end

	local parts: { [string]: BasePart } = { Body = body }
	addAccessories(model, def, parts)
	model.PrimaryPart = body
	model:SetAttribute("RootHeight", 0)
	if not def.noTag then
		nameTag(body, def.displayName, size.Y * 0.5 + 1)
	end
	return model
end

local function buildCustom(id: string, def: RigSpecs.CharacterDef): Model
	local model = Instance.new("Model")
	model.Name = id
	local list = def.parts
	assert(list and #list > 0, id .. ": custom rig needs parts")
	local parts: { [string]: BasePart } = {}
	local rootName = list[1].name
	for i, partDef in list do
		local p = newPart(partDef.name, v3(partDef.size), Color3.fromHex(partDef.color))
		p.Shape = shape(partDef.shape)
		p.Size = v3(partDef.size)
		p.Material = material(partDef.material, Enum.Material.SmoothPlastic)
		p.Transparency = partDef.transparency or 0
		if i == 1 then
			p.Anchored = true
			p.Massless = false
			p.CFrame = CFrame.new(0, def.rootHeight or 0, 0)
		end
		parts[partDef.name] = p
	end
	buildJoints(parts, def.joints or {}, rootName)
	for _, p in parts do
		p.Parent = model
	end
	local glowDef = def.glow
	if glowDef then
		local glow = Instance.new("PointLight")
		glow.Name = "Glow"
		glow.Color = Color3.fromHex(glowDef.color)
		glow.Range = glowDef.range
		glow.Brightness = glowDef.brightness
		glow.Parent = parts[rootName]
	end
	addAccessories(model, def, parts)
	model.PrimaryPart = parts[rootName]
	model:SetAttribute("RootHeight", def.rootHeight or 0)
	return model
end

--- Builds every rig from RigSpecs into ServerStorage.Models (replacing old copies) and mirrors
--- the folder to ReplicatedStorage.RigTemplates.
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
		local model
		if def.kind == "cube" then
			model = buildCube(id, def)
		elseif def.kind == "custom" then
			model = buildCustom(id, def)
		else
			model = buildHumanoid(id, def)
		end
		model:SetAttribute("CharacterId", id)
		model:SetAttribute("DisplayName", def.displayName)
		model:SetAttribute("DefaultFace", def.face or "neutral")
		local scale = def.scale
		if scale and scale ~= 1 then
			model:ScaleTo(scale)
			model:SetAttribute("RootHeight", (model:GetAttribute("RootHeight") :: number) * scale)
		end
		model.Parent = folder
	end
	local mirror = ReplicatedStorage:FindFirstChild("RigTemplates")
	if mirror then
		mirror:Destroy()
	end
	local copy = folder:Clone()
	copy.Name = "RigTemplates"
	copy.Parent = ReplicatedStorage
	return folder
end

return RigFactory
