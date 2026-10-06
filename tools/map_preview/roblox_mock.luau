-- Minimal Roblox runtime for running server build code (MapBuilder, RigFactory) in the Luau
-- CLI. Only what the builders use: Instance tree, attributes, tags, Vector3 / CFrame math,
-- Color3, Enum proxies, Random, math.noise. Not a general emulator.

------------------------------------------------------------------ Vector3
local Vector3 = {}
local V3 = {}
V3.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	elseif k == "Unit" then
		local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		return Vector3.new(v.X / m, v.Y / m, v.Z / m)
	end
	return V3[k]
end
function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
V3.__add = function(a, b)
	return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3.__sub = function(a, b)
	return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then
		return Vector3.new(a * b.X, a * b.Y, a * b.Z)
	elseif type(b) == "number" then
		return Vector3.new(a.X * b, a.Y * b, a.Z * b)
	end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then
		return Vector3.new(a.X / b, a.Y / b, a.Z / b)
	end
	return Vector3.new(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__unm = function(a)
	return Vector3.new(-a.X, -a.Y, -a.Z)
end
V3.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
function V3.Cross(a, b)
	return Vector3.new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end
function V3.Dot(a, b)
	return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end
function V3.Lerp(a, b, t)
	return a + (b - a) * t
end
Vector3.zero = Vector3.new(0, 0, 0)
Vector3.one = Vector3.new(1, 1, 1)
Vector3.xAxis = Vector3.new(1, 0, 0)
Vector3.yAxis = Vector3.new(0, 1, 0)
Vector3.zAxis = Vector3.new(0, 0, 1)

local Vector2 = {}
function Vector2.new(x, y)
	return { X = x or 0, Y = y or 0 }
end

------------------------------------------------------------------ CFrame (position + rows)
local CFrame = {}
local CF = {}
local function cf(px, py, pz, r)
	return setmetatable({ p = Vector3.new(px, py, pz), r = r }, CF)
end
local IDENT = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local function matmul(a, b)
	local o = {}
	for i = 0, 2 do
		for j = 0, 2 do
			o[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[3 + j + 1] + a[i * 3 + 3] * b[6 + j + 1]
		end
	end
	return o
end
local function rotv(r, v)
	return Vector3.new(
		r[1] * v.X + r[2] * v.Y + r[3] * v.Z,
		r[4] * v.X + r[5] * v.Y + r[6] * v.Z,
		r[7] * v.X + r[8] * v.Y + r[9] * v.Z
	)
end
CF.__index = function(c, k)
	if k == "Position" then
		return c.p
	elseif k == "LookVector" then
		return Vector3.new(-c.r[3], -c.r[6], -c.r[9])
	elseif k == "RightVector" then
		return Vector3.new(c.r[1], c.r[4], c.r[7])
	elseif k == "UpVector" then
		return Vector3.new(c.r[2], c.r[5], c.r[8])
	elseif k == "Rotation" then
		return cf(0, 0, 0, c.r)
	elseif k == "X" then
		return c.p.X
	elseif k == "Y" then
		return c.p.Y
	elseif k == "Z" then
		return c.p.Z
	end
	return CF[k]
end
function CFrame.new(x, y, z, ...)
	if type(x) == "table" then
		return cf(x.X, x.Y, x.Z, IDENT)
	end
	return cf(x or 0, y or 0, z or 0, IDENT)
end
local function rx(a)
	local c, s = math.cos(a), math.sin(a)
	return { 1, 0, 0, 0, c, -s, 0, s, c }
end
local function ry(a)
	local c, s = math.cos(a), math.sin(a)
	return { c, 0, s, 0, 1, 0, -s, 0, c }
end
local function rz(a)
	local c, s = math.cos(a), math.sin(a)
	return { c, -s, 0, s, c, 0, 0, 0, 1 }
end
function CFrame.Angles(a, b, c)
	return cf(0, 0, 0, matmul(matmul(rx(a), ry(b)), rz(c)))
end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
function CFrame.fromAxisAngle(axis, a)
	local u = axis.Unit
	local c, s, t = math.cos(a), math.sin(a), 1 - math.cos(a)
	local x, y, z = u.X, u.Y, u.Z
	return cf(0, 0, 0, {
		t * x * x + c, t * x * y - s * z, t * x * z + s * y,
		t * x * y + s * z, t * y * y + c, t * y * z - s * x,
		t * x * z - s * y, t * y * z + s * x, t * z * z + c,
	})
end
function CFrame.lookAt(pos, target, up)
	up = up or Vector3.yAxis
	local look = (target - pos)
	if look.Magnitude < 1e-9 then
		return cf(pos.X, pos.Y, pos.Z, IDENT)
	end
	look = look.Unit
	local right = look:Cross(up)
	if right.Magnitude < 1e-6 then
		right = look:Cross(Vector3.zAxis)
	end
	right = right.Unit
	local upv = right:Cross(look)
	local back = -look
	return cf(pos.X, pos.Y, pos.Z, { right.X, upv.X, back.X, right.Y, upv.Y, back.Y, right.Z, upv.Z, back.Z })
end
CFrame.identity = CFrame.new()
CF.__mul = function(a, b)
	if getmetatable(b) == CF then
		local p = a.p + rotv(a.r, b.p)
		return cf(p.X, p.Y, p.Z, matmul(a.r, b.r))
	end
	return a.p + rotv(a.r, b)
end
CF.__add = function(a, v)
	return cf(a.p.X + v.X, a.p.Y + v.Y, a.p.Z + v.Z, a.r)
end
CF.__sub = function(a, v)
	return cf(a.p.X - v.X, a.p.Y - v.Y, a.p.Z - v.Z, a.r)
end
function CF.Inverse(c)
	local r = c.r
	local t = { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
	local p = rotv(t, -c.p)
	return cf(p.X, p.Y, p.Z, t)
end
function CF.Lerp(a, b, t)
	local p = a.p:Lerp(b.p, t)
	return cf(p.X, p.Y, p.Z, if t < 0.5 then a.r else b.r)
end
function CF.GetComponents(c)
	return c.p.X, c.p.Y, c.p.Z, table.unpack(c.r)
end

------------------------------------------------------------------ Color3, UDim2, Enum
local Color3 = {}
function Color3.new(r, g, b)
	return { R = r or 0, G = g or 0, B = b or 0 }
end
function Color3.fromRGB(r, g, b)
	return Color3.new(r / 255, g / 255, b / 255)
end
function Color3.fromHex(h)
	h = string.gsub(h, "#", "")
	return Color3.fromRGB(tonumber(string.sub(h, 1, 2), 16), tonumber(string.sub(h, 3, 4), 16), tonumber(string.sub(h, 5, 6), 16))
end
local UDim2 = {
	new = function(...)
		return { ... }
	end,
	fromOffset = function(...)
		return { ... }
	end,
	fromScale = function(...)
		return { ... }
	end,
}
local UDim = {
	new = function(...)
		return { ... }
	end,
}
local ColorSequence = {
	new = function(...)
		return { ... }
	end,
}
local NumberSequence = ColorSequence
local NumberRange = ColorSequence

local function enumProxy(path)
	return setmetatable({ Name = path }, {
		__index = function(t, k)
			local child = enumProxy(path .. "." .. k)
			rawset(t, k, child)
			return child
		end,
		__tostring = function()
			return path
		end,
	})
end
local Enum = enumProxy("Enum")

------------------------------------------------------------------ Random, math.noise
local Random = {}
Random.__index = Random
function Random.new(seed)
	return setmetatable({ s = (seed or 1) % 2147483647 + 1 }, Random)
end
function Random:_next()
	self.s = (self.s * 48271) % 2147483647
	return self.s / 2147483647
end
function Random:NextNumber(a, b)
	local r = self:_next()
	if a then
		return a + (b - a) * r
	end
	return r
end
function Random:NextInteger(a, b)
	return math.min(b, a + math.floor(self:_next() * (b - a + 1)))
end

local perm = {}
do
	local rng = Random.new(42)
	local p = {}
	for i = 0, 255 do
		p[i] = i
	end
	for i = 255, 1, -1 do
		local j = rng:NextInteger(0, i)
		p[i], p[j] = p[j], p[i]
	end
	for i = 0, 511 do
		perm[i] = p[i % 256]
	end
end
local function fade(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end
local function grad(h, x, y, z)
	h = h % 16
	local u = if h < 8 then x else y
	local v = if h < 4 then y elseif h == 12 or h == 14 then x else z
	return (if h % 2 == 0 then u else -u) + (if math.floor(h / 2) % 2 == 0 then v else -v)
end
local function noise(x, y, z)
	y = y or 0
	z = z or 0
	local X, Y, Z = math.floor(x) % 256, math.floor(y) % 256, math.floor(z) % 256
	x, y, z = x - math.floor(x), y - math.floor(y), z - math.floor(z)
	local u, v, w = fade(x), fade(y), fade(z)
	local A = perm[X] + Y
	local AA, AB = perm[A] + Z, perm[A + 1] + Z
	local B = perm[X + 1] + Y
	local BA, BB = perm[B] + Z, perm[B + 1] + Z
	local function lerp(t, a, b)
		return a + t * (b - a)
	end
	return lerp(
		w,
		lerp(v, lerp(u, grad(perm[AA], x, y, z), grad(perm[BA], x - 1, y, z)), lerp(u, grad(perm[AB], x, y - 1, z), grad(perm[BB], x - 1, y - 1, z))),
		lerp(
			v,
			lerp(u, grad(perm[AA + 1], x, y, z - 1), grad(perm[BA + 1], x - 1, y, z - 1)),
			lerp(u, grad(perm[AB + 1], x, y - 1, z - 1), grad(perm[BB + 1], x - 1, y - 1, z - 1))
		)
	) * 0.5
end

------------------------------------------------------------------ Instances
local BASES = {
	Part = { "BasePart", "PVInstance" },
	WedgePart = { "BasePart", "PVInstance" },
	TrussPart = { "BasePart", "PVInstance" },
	SpawnLocation = { "Part", "BasePart", "PVInstance" },
	Model = { "PVInstance" },
	PointLight = { "Light" },
	SpotLight = { "Light" },
	SurfaceLight = { "Light" },
	Motor6D = { "JointInstance" },
	Weld = { "JointInstance" },
	ModuleScript = { "LuaSourceContainer" },
	SurfaceGui = { "LayerCollector", "GuiBase" },
	BillboardGui = { "LayerCollector", "GuiBase" },
	TextLabel = { "GuiObject", "GuiBase" },
}
local Inst = {}
local tags = {}
local function newInstance(class)
	local self = {
		__class = class,
		__props = { Name = class, ClassName = class },
		__children = {},
		__attrs = {},
		__parent = nil,
	}
	return setmetatable(self, Inst)
end
Inst.__index = function(self, k)
	local m = rawget(Inst, k)
	if m then
		return m
	end
	if k == "Parent" then
		return rawget(self, "__parent")
	end
	local v = self.__props[k]
	if v ~= nil then
		return v
	end
	for _, c in self.__children do
		if c.__props.Name == k then
			return c
		end
	end
	if k == "Size" then
		return Vector3.new(4, 1, 2)
	elseif k == "CFrame" then
		return CFrame.new()
	elseif k == "Transparency" then
		return 0
	elseif k == "Position" then
		return (self.__props.CFrame or CFrame.new()).Position
	end
	return nil
end
Inst.__newindex = function(self, k, v)
	if k == "Parent" then
		local old = rawget(self, "__parent")
		if old then
			local list = old.__children
			for i, c in list do
				if c == self then
					table.remove(list, i)
					break
				end
			end
		end
		rawset(self, "__parent", v)
		if v then
			table.insert(v.__children, self)
		end
		return
	end
	if k == "Position" then
		local c = self.__props.CFrame or CFrame.new()
		self.__props.CFrame = cf(v.X, v.Y, v.Z, c.r)
		return
	end
	if k == "Shape" then
		self.__props.Shape = tostring(v)
		return
	end
	self.__props[k] = v
end
Inst.__tostring = function(self)
	return self.__props.Name
end
function Inst:IsA(class)
	if self.__class == class or class == "Instance" then
		return true
	end
	for _, b in BASES[self.__class] or {} do
		if b == class then
			return true
		end
	end
	return false
end
function Inst:GetChildren()
	return table.clone(self.__children)
end
function Inst:GetDescendants()
	local out = {}
	local function walk(n)
		for _, c in n.__children do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function Inst:FindFirstChild(name, recursive)
	for _, c in self.__children do
		if c.__props.Name == name then
			return c
		end
	end
	if recursive then
		for _, c in self.__children do
			local f = c:FindFirstChild(name, true)
			if f then
				return f
			end
		end
	end
	return nil
end
function Inst:WaitForChild(name)
	local c = self:FindFirstChild(name)
	if not c then
		error("WaitForChild: missing " .. name .. " under " .. self.__props.Name)
	end
	return c
end
function Inst:FindFirstChildOfClass(class)
	for _, c in self.__children do
		if c.__class == class then
			return c
		end
	end
	return nil
end
function Inst:FindFirstAncestorOfClass(class)
	local p = rawget(self, "__parent")
	while p do
		if p.__class == class then
			return p
		end
		p = rawget(p, "__parent")
	end
	return nil
end
function Inst:SetAttribute(k, v)
	self.__attrs[k] = v
end
function Inst:GetAttribute(k)
	return self.__attrs[k]
end
function Inst:Destroy()
	self.Parent = nil
end
function Inst:Clone()
	local c = newInstance(self.__class)
	for k, v in self.__props do
		c.__props[k] = v
	end
	for k, v in self.__attrs do
		c.__attrs[k] = v
	end
	for _, ch in self.__children do
		ch:Clone().Parent = c
	end
	return c
end
function Inst:GetPivot()
	local pp = self.__props.PrimaryPart
	if pp then
		return pp.CFrame
	end
	return self.__props.CFrame or CFrame.new()
end
function Inst:PivotTo(target)
	local pivot = self:GetPivot()
	local delta = target * pivot:Inverse()
	for _, d in self:GetDescendants() do
		if d:IsA("BasePart") then
			d.__props.CFrame = delta * (d.__props.CFrame or CFrame.new())
		end
	end
	if self:IsA("BasePart") then
		self.__props.CFrame = target
	end
end
function Inst:ScaleTo() end
function Inst:GetPropertyChangedSignal()
	return { Connect = function() end }
end

local Instance = {
	new = function(class, parent)
		local i = newInstance(class)
		if parent then
			i.Parent = parent
		end
		return i
	end,
}

local CollectionService = {
	AddTag = function(_, inst, tag)
		tags[tag] = tags[tag] or {}
		tags[tag][inst] = true
	end,
	RemoveTag = function(_, inst, tag)
		if tags[tag] then
			tags[tag][inst] = nil
		end
	end,
	HasTag = function(_, inst, tag)
		return tags[tag] ~= nil and tags[tag][inst] == true
	end,
	GetTagged = function(_, tag)
		local out = {}
		for i in tags[tag] or {} do
			table.insert(out, i)
		end
		return out
	end,
	GetInstanceAddedSignal = function()
		return { Connect = function() end }
	end,
}

local DataModel = newInstance("DataModel")
local workspace = newInstance("Workspace")
workspace.Name = "Workspace"
workspace.Parent = DataModel
local services = { Workspace = workspace, CollectionService = CollectionService }
local RunService = {
	IsStudio = function()
		return true
	end,
	IsServer = function()
		return true
	end,
	IsClient = function()
		return false
	end,
}
services.RunService = RunService
function DataModel:GetService(name)
	if services[name] then
		return services[name]
	end
	local s = newInstance(name)
	s.Name = name
	s.Parent = DataModel
	services[name] = s
	return s
end
local game = DataModel

local function warn(...)
	print("WARN", ...)
end

return {
	Vector3 = Vector3,
	Vector2 = Vector2,
	CFrame = CFrame,
	Color3 = Color3,
	UDim2 = UDim2,
	UDim = UDim,
	Enum = Enum,
	Random = Random,
	Instance = Instance,
	game = game,
	workspace = workspace,
	warn = warn,
	tags = tags,
	newInstance = newInstance,
	ColorSequence = ColorSequence,
	NumberSequence = NumberSequence,
	NumberRange = NumberRange,
	noise = noise,
}
