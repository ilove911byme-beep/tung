--!strict
-- Low-level building helpers for the MapBuilder. Coordinates are in BLOCKS (map.md: 1 block =
-- 4 studs, x west->east, y up, z north->south); box() takes the min corner and the size.
-- Every Part gets the palette look from Shared/World/Blocks: a Texture per face (tiled every
-- 4 studs so a merged Part still reads as single blocks) when the TextureIds entry is filled,
-- otherwise the fallback material + color. Parts carry the attribute Block for Footsteps.
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local World = Shared:WaitForChild("World")
local Blocks = require(World:WaitForChild("Blocks"))
local TextureIds = require(World:WaitForChild("TextureIds"))

local Builder = {}

export type Opts = {
	color: string?, -- tint / override the block color
	transparency: number?,
	collide: boolean?,
	query: boolean?,
	shadow: boolean?,
	tags: { string }?,
	attrs: { [string]: any }?,
	noTexture: boolean?,
	material: string?,
	shape: string?, -- "Block" | "Cylinder" | "Ball"
	decor: boolean?, -- no collision, no queries, no shadow (grass, flowers)
}

export type Rect = { x: number, z: number, w: number, d: number, key: string }

local S = Config.World.StudsPerBlock
Builder.S = S
Builder.partCount = 0

local FACES = {
	{ face = Enum.NormalId.Top, slot = "top" },
	{ face = Enum.NormalId.Bottom, slot = "bottom" },
	{ face = Enum.NormalId.Front, slot = "side" },
	{ face = Enum.NormalId.Back, slot = "side" },
	{ face = Enum.NormalId.Left, slot = "side" },
	{ face = Enum.NormalId.Right, slot = "side" },
}

local function material(name: string): Enum.Material
	local ok, value = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	if ok and value then
		return value
	end
	return Enum.Material.SmoothPlastic
end

--- Studs position of a block coordinate.
function Builder.studs(x: number, y: number, z: number): Vector3
	return Vector3.new(x * S, y * S, z * S)
end

function Builder.block(name: string): Blocks.BlockDef
	local def = Blocks[name]
	assert(def, "unknown block " .. name)
	return def
end

local function addTextures(part: BasePart, def: Blocks.BlockDef, transparency: number)
	for _, f in FACES do
		local key = (def :: any)[f.slot] :: string?
		local id = key and TextureIds[key]
		if id and id ~= "" then
			local t = Instance.new("Texture")
			t.Name = key :: string
			t.Texture = id
			t.Face = f.face
			t.StudsPerTileU = S
			t.StudsPerTileV = S
			t.Transparency = transparency
			t.Parent = part
		end
	end
end

--- A Part with the block's look at a CFrame (studs) and size (studs).
function Builder.part(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	blockName: string,
	opts: Opts?
): Part
	local o: Opts = opts or {}
	local def = Builder.block(blockName)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = material(o.material or def.material)
	p.Color = Color3.fromHex(o.color or def.color)
	local transparency = o.transparency or def.transparency or 0
	p.Transparency = transparency
	local collide = if o.collide ~= nil then o.collide else def.collide ~= false
	if o.decor then
		collide = false
		p.CanQuery = false
		p.CastShadow = false
		p.CanTouch = false
	end
	p.CanCollide = collide
	if o.query ~= nil then
		p.CanQuery = o.query
	end
	if o.shadow ~= nil then
		p.CastShadow = o.shadow
	end
	if o.shape == "Cylinder" then
		p.Shape = Enum.PartType.Cylinder
	elseif o.shape == "Ball" then
		p.Shape = Enum.PartType.Ball
	end
	p:SetAttribute("Block", def.footstep)
	if not o.noTexture then
		addTextures(p, def, transparency)
	end
	local light = def.light
	if light then
		Builder.light(p, light.color, light.range, light.brightness)
	end
	if o.tags then
		for _, tag in o.tags do
			CollectionService:AddTag(p, tag)
		end
	end
	if o.attrs then
		for k, v in o.attrs do
			p:SetAttribute(k, v)
		end
	end
	p.Parent = parent
	Builder.partCount += 1
	return p
end

--- An axis-aligned box: min corner (x, y, z) and size (sx, sy, sz), all in blocks.
function Builder.box(
	parent: Instance,
	name: string,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	blockName: string,
	opts: Opts?
): Part
	local size = Vector3.new(sx * S, sy * S, sz * S)
	local center = Vector3.new((x + sx / 2) * S, (y + sy / 2) * S, (z + sz / 2) * S)
	return Builder.part(parent, name, CFrame.new(center), size, blockName, opts)
end

--- A slab between two points (blocks): floors / walls of sloped tunnels. `up` is the extra
--- offset (blocks) along the slab's up vector, `side` along its right vector.
function Builder.slab(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	width: number,
	thickness: number,
	blockName: string,
	side: number?,
	up: number?,
	opts: Opts?
): Part
	local pa = a * S
	local pb = b * S
	local mid = (pa + pb) / 2
	local cf = CFrame.lookAt(mid, pb)
	cf = cf * CFrame.new((side or 0) * S, (up or 0) * S, 0)
	local length = (pb - pa).Magnitude
	return Builder.part(
		parent,
		name,
		cf,
		Vector3.new(width * S, thickness * S, length),
		blockName,
		opts
	)
end

function Builder.light(
	part: BasePart,
	hex: string,
	range: number,
	brightness: number,
	tag: string?
): PointLight
	local l = Instance.new("PointLight")
	l.Color = Color3.fromHex(hex)
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = part
	if tag then
		CollectionService:AddTag(part, tag)
	end
	return l
end

function Builder.model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function Builder.folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

--- Invisible anchored marker (interaction points, NPC spots, effect origins).
function Builder.marker(
	parent: Instance,
	name: string,
	x: number,
	y: number,
	z: number,
	yaw: number?,
	attrs: { [string]: any }?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = Vector3.new(2, 2, 2)
	local pos = Builder.studs(x, y, z) + Vector3.new(0, 1, 0)
	local r = math.rad(yaw or 0)
	p.CFrame = CFrame.lookAt(pos, pos + Vector3.new(math.sin(r), 0, -math.cos(r)))
	if attrs then
		for k, v in attrs do
			p:SetAttribute(k, v)
		end
	end
	p.Parent = parent
	return p
end

--- A sign with text on its front (south by default). Tagged "Sign" so CS-10 can rewrite it.
function Builder.sign(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	text: string,
	opts: Opts?
): Part
	local board = Builder.part(parent, name, cf, size, "oak_planks", opts)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(200 * size.X / size.Y, 200)
	gui.LightInfluence = 1
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.Arcade
	label.TextColor3 = Color3.fromRGB(40, 26, 14)
	label.Parent = gui
	CollectionService:AddTag(board, "Sign")
	return board
end

--- Greedy 2D merge of a w x d grid. key(i, j) returns a string (cells with equal keys merge)
--- or nil (empty). i, j are 0-based offsets; returned rects use the same offsets.
function Builder.greedy2D(w: number, d: number, key: (number, number) -> string?): { Rect }
	local keys: { [number]: string } = {}
	for j = 0, d - 1 do
		for i = 0, w - 1 do
			local k = key(i, j)
			if k then
				keys[j * w + i] = k
			end
		end
	end
	local used: { [number]: boolean } = {}
	local rects: { Rect } = {}
	for j = 0, d - 1 do
		for i = 0, w - 1 do
			local idx = j * w + i
			local k = keys[idx]
			if k and not used[idx] then
				local rw = 1
				while i + rw < w and not used[idx + rw] and keys[idx + rw] == k do
					rw += 1
				end
				local rd = 1
				local growing = true
				while growing and j + rd < d do
					for di = 0, rw - 1 do
						local n = (j + rd) * w + i + di
						if used[n] or keys[n] ~= k then
							growing = false
							break
						end
					end
					if growing then
						rd += 1
					end
				end
				for dj = 0, rd - 1 do
					for di = 0, rw - 1 do
						used[(j + dj) * w + i + di] = true
					end
				end
				table.insert(rects, { x = i, z = j, w = rw, d = rd, key = k })
			end
		end
	end
	return rects
end

return Builder
