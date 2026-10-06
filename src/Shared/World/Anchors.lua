--!strict
-- Camera anchors from map.md section 6. Coordinates are in BLOCKS (1 block = 4 studs):
-- x west->east, y height (ground surface = 12), z north->south. yaw is the direction the
-- anchor faces: 0 = north (-Z), 90 = east (+X), 180 = south (+Z), 270 = west (-X).
-- Cutscene cameras and actors are placed relative to these, so the MapBuilder (Phase 2) and
-- the Studio test stage both create invisible Parts from this table, and code that needs an
-- anchor resolves it from here (works even when the Part is not streamed in).
local Config = require(script.Parent.Parent.Config)

export type AnchorDef = { x: number, y: number, z: number, yaw: number }

local Anchors = {}

Anchors.Defs = {
	Anchor_Tunnel_Exit = { x = 22, y = 12, z = 80, yaw = 90 },
	Anchor_Valley_Orbit_Center = { x = 80, y = 40, z = 80, yaw = 0 },
	Anchor_Station = { x = 52, y = 12, z = 80, yaw = 90 },
	Anchor_Square_Center = { x = 80, y = 12, z = 80, yaw = 270 }, -- faces the tavern
	Anchor_Sahur_Table = { x = 80, y = 12, z = 80, yaw = 180 },
	Anchor_Tavern_Interior = { x = 66, y = 12, z = 80, yaw = 90 },
	Anchor_Tavern_Window = { x = 70.5, y = 13.5, z = 80, yaw = 90 }, -- east wall, looks at the square
	Anchor_Tavern_Door = { x = 70.5, y = 12, z = 84, yaw = 90 },
	Anchor_Ballerina_House = { x = 95, y = 12, z = 76, yaw = 270 },
	Anchor_Clock_Tower_Base = { x = 80, y = 12, z = 69.5, yaw = 180 },
	Anchor_Clock_Tower_Stairs = { x = 80, y = 12, z = 66, yaw = 180 },
	Anchor_Clock_Tower_Top = { x = 80, y = 42, z = 66, yaw = 180 },
	Anchor_Clock_Face = { x = 80, y = 36, z = 69.5, yaw = 180 },
	Anchor_Lirili_Workshop = { x = 89, y = 12, z = 64, yaw = 180 },
	Anchor_Barn = { x = 104, y = 12, z = 68, yaw = 270 },
	Anchor_Tung_Hill = { x = 80, y = 18, z = 126, yaw = 0 },
	Anchor_Forest_Gorge = { x = 35, y = 12, z = 141, yaw = 180 },
	Anchor_Patapim = { x = 35, y = 12, z = 128, yaw = 0 },
	Anchor_Mine_Door = { x = 122, y = 12, z = 30, yaw = 180 },
	Anchor_Mine_Track = { x = 122, y = -2, z = 30, yaw = 90 },
	Anchor_Lirili_Lab = { x = 140, y = -12, z = 40, yaw = 270 },
	Anchor_Crudelino_Cave = { x = 135, y = -25, z = 20, yaw = 0 },
	Anchor_Cave_SkyHole = { x = 135, y = 12, z = 20, yaw = 0 },
	Anchor_Finale_Sky = { x = 102, y = 30, z = 45, yaw = 225 },
	Anchor_Bombardiro_Hangar = { x = 124, y = 12, z = 86, yaw = 270 },
} :: { [string]: AnchorDef }

local function defToCFrame(def: AnchorDef): CFrame
	local s = Config.World.StudsPerBlock
	local pos = Vector3.new(def.x * s, def.y * s, def.z * s)
	local yaw = math.rad(def.yaw)
	-- yaw 0 = -Z, 90 = +X
	local dir = Vector3.new(math.sin(yaw), 0, -math.cos(yaw))
	return CFrame.lookAt(pos, pos + dir)
end

--- CFrame of an anchor. A Part named like the anchor under workspace.Anchors wins over the
--- table, so a level designer can nudge one in Studio.
function Anchors.get(name: string): CFrame
	local folder = workspace:FindFirstChild("Anchors")
	local part = folder and folder:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		return part.CFrame
	end
	local def = Anchors.Defs[name]
	if not def then
		error(string.format("[Anchors] unknown anchor '%s'", name))
	end
	return defToCFrame(def)
end

function Anchors.exists(name: string): boolean
	return Anchors.Defs[name] ~= nil
end

--- Creates invisible anchored Parts for every anchor (used by MapBuilder / test stage).
function Anchors.createParts(parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Anchors"
	for name, def in Anchors.Defs do
		local part = Instance.new("Part")
		part.Name = name
		part.Size = Vector3.new(1, 1, 2)
		part.CFrame = defToCFrame(def)
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 1
		part.Parent = folder
	end
	folder.Parent = parent
	return folder
end

return Anchors
