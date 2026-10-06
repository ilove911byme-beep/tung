--!strict
-- Cutscene actors: local copies of the rigs the server put in ReplicatedStorage.CutsceneRuntime,
-- placed at anchor points, moved by cues (moveTo / orbit / tour), animated by PoseAnimator on the
-- shared server clock, and destroyed after the cutscene.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local FaceController = require(Shared:WaitForChild("Visual"):WaitForChild("FaceController"))
local PoseAnimator = require(Shared:WaitForChild("Visual"):WaitForChild("PoseAnimator"))
local PoseMath = require(Shared:WaitForChild("Visual"):WaitForChild("PoseMath"))
local Types = require(Shared:WaitForChild("Types"))

local Footsteps = require(script.Parent.Parent:WaitForChild("Audio"):WaitForChild("Footsteps"))
local Points = require(script.Parent:WaitForChild("Points"))

local Actors = {}

type Motion = {
	kind: "move" | "orbit" | "tour",
	start: number,
	duration: number,
	from: CFrame,
	to: CFrame?,
	easing: string?,
	-- orbit
	center: Vector3?,
	radius: number?,
	height: number?,
	period: number?,
	startAngle: number?,
	direction: number?,
	faceCenter: boolean?,
	-- tour
	tour: Types.TourSpec?,
	heads: { BasePart }?,
	tourStep: number?,
}

export type Actor = {
	id: string,
	model: Model,
	animator: PoseAnimator.PoseAnimator,
	rootHeight: number,
	baseCf: CFrame,
	motion: Motion?,
	visibleState: boolean,
	original: { [BasePart]: number },
	guis: { [Instance]: boolean },
	lastAnimScale: number,
	external: boolean, -- the local player's own character: not cloned, moved or destroyed
	driven: boolean, -- external actors are only posed after a cue animates them
	ride: Types.RideSpec?,
}

export type Registry = {
	byId: { [string]: Actor },
	folder: Folder,
	clock: () -> number,
}

local function actorFolder(): Folder
	local folder = workspace:FindFirstChild("CutsceneActors")
	if folder and folder:IsA("Folder") then
		return folder
	end
	local f = Instance.new("Folder")
	f.Name = "CutsceneActors"
	f.Parent = workspace
	return f
end

function Actors.lookup(registry: Registry): Points.ActorLookup
	return function(id: string): Model?
		local a = registry.byId[id]
		return a and a.model
	end
end

local function setVisible(actor: Actor, visible: boolean)
	actor.visibleState = visible
	for part, base in actor.original do
		part.Transparency = if visible then base else 1
	end
	for gui, enabled in actor.guis do
		(gui :: any).Enabled = visible and enabled
	end
end

function Actors.setVisible(actor: Actor, visible: boolean)
	setVisible(actor, visible)
end

--- Spawns every actor of a cutscene. Waits briefly for the server copies to replicate.
export type SpawnOptions = { models: { [string]: string }? }

--- Spawns every actor of a cutscene. Waits briefly for the server copies to replicate.
--- opts.models remaps model names (CS-DEAD: "Giallino" -> the current form). The model
--- "@LocalPlayer" is the local player's own character.
function Actors.spawn(
	runtime: Instance,
	data: Types.Cutscene,
	clock: () -> number,
	opts: SpawnOptions?
): Registry
	local registry: Registry = { byId = {}, folder = actorFolder(), clock = clock }
	local remap = if opts and opts.models then opts.models else {}
	for _, spec in data.actors do
		local modelName = remap[spec.model] or spec.model
		if modelName == "@LocalPlayer" then
			local character = game:GetService("Players").LocalPlayer.Character
			if character then
				local own: Actor = {
					id = spec.id,
					model = character,
					animator = PoseAnimator.new(character, clock),
					rootHeight = 0,
					baseCf = character:GetPivot(),
					motion = nil,
					visibleState = true,
					original = {},
					guis = {},
					lastAnimScale = 1,
					external = true,
					driven = false,
					ride = nil,
				}
				registry.byId[spec.id] = own
			end
			continue
		end
		local standIn = string.match(modelName, "^@Player(%d)$")
		local template: Instance? = nil
		if standIn then
			template = Actors.standIn(tonumber(standIn) :: number)
			if not template then
				continue -- fewer players than stand-in slots
			end
		else
			template = runtime:WaitForChild(modelName, 5)
		end
		if not template or not template:IsA("Model") then
			warn(string.format("[Actors] %s: model %s did not arrive", data.id, modelName))
			continue
		end
		local model = template:Clone()
		model.Name = spec.id
		for _, d in model:GetDescendants() do
			if d:IsA("BillboardGui") and d.Name == "NameTag" then
				d.Enabled = false -- no name tags in cinematics
			end
		end
		model.Parent = registry.folder
		local rootHeight = model:GetAttribute("RootHeight")
		local actor: Actor = {
			id = spec.id,
			model = model,
			animator = PoseAnimator.new(model, clock),
			rootHeight = if typeof(rootHeight) == "number" then rootHeight else 0,
			baseCf = CFrame.identity,
			motion = nil,
			visibleState = true,
			original = {},
			guis = {},
			lastAnimScale = 1,
			external = false,
			driven = true,
			ride = spec.ride,
		}
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				actor.original[d] = d.Transparency
			elseif d:IsA("SurfaceGui") or (d:IsA("BillboardGui") and d.Name ~= "NameTag") then
				actor.guis[d] = d.Enabled
			end
		end
		registry.byId[spec.id] = actor
		local at = Points.resolve(spec.at, Actors.lookup(registry))
		if at then
			actor.baseCf = at * CFrame.new(0, actor.rootHeight, 0)
			model:PivotTo(actor.baseCf)
		end
		local face = FaceController.get(model)
		if face then
			-- the face gui is created now, so register it for visibility changes
			actor.guis[face.gui] = true
			local default = model:GetAttribute("DefaultFace")
			FaceController.set(
				model,
				spec.face or (if typeof(default) == "string" then default else "neutral")
			)
		end
		-- extra faces (Giallino Totale's other sides)
		for _, sub in model:GetDescendants() do
			if sub:IsA("Model") then
				local subFace = sub:GetAttribute("DefaultFace")
				if typeof(subFace) == "string" then
					local f = FaceController.get(sub)
					if f then
						actor.guis[f.gui] = true
						FaceController.set(sub, subFace)
					end
				end
			end
		end
		if spec.visible == false then
			setVisible(actor, false)
		end
		if spec.footsteps ~= false and model:FindFirstChild("HumanoidRootPart") then
			Footsteps.track(model)
		end
	end
	return registry
end

--- A cutscene copy of the n-th party member's avatar (players sorted by UserId), ready to be
--- posed: anchored root, no collisions, no scripts, Humanoid kept for clothing. nil if no such
--- player.
function Actors.standIn(n: number): Model?
	local list = game:GetService("Players"):GetPlayers()
	table.sort(list, function(a, b)
		return a.UserId < b.UserId
	end)
	local player = list[n]
	local character = player and player.Character
	if not character then
		return nil
	end
	local wasArchivable = character.Archivable
	character.Archivable = true
	local copy = character:Clone()
	character.Archivable = wasArchivable
	if not copy then
		return nil
	end
	for _, d in copy:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("Sound") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.LocalTransparencyModifier = 0
			d.Anchored = d.Name == "HumanoidRootPart"
		elseif d:IsA("Decal") then
			d.LocalTransparencyModifier = 0
		end
	end
	local humanoid = copy:FindFirstChildOfClass("Humanoid")
	local root = copy:FindFirstChild("HumanoidRootPart")
	if humanoid then
		humanoid.EvaluateStateMachine = false
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			animator:Destroy()
		end
	end
	if root and root:IsA("BasePart") then
		copy.PrimaryPart = root
		local hip = if humanoid then humanoid.HipHeight else 2
		copy:SetAttribute("RootHeight", hip + root.Size.Y / 2)
	end
	copy:SetAttribute("StandInFor", player.UserId)
	return copy
end

--- Starts / stops riding (minecarts).
function Actors.setRide(actor: Actor, ride: Types.RideSpec?)
	actor.ride = ride
	actor.motion = nil
end

function Actors.get(registry: Registry, id: string): Actor?
	return registry.byId[id]
end

--- Glides to a point (ground point for rigs; their root height is added).
function Actors.moveTo(
	registry: Registry,
	actor: Actor,
	point: Types.Point,
	duration: number,
	easing: string?,
	start: number
)
	local target = Points.resolve(point, Actors.lookup(registry))
	if not target then
		return
	end
	actor.motion = {
		kind = "move",
		start = start,
		duration = math.max(duration, 0.01),
		from = actor.baseCf,
		to = target * CFrame.new(0, actor.rootHeight, 0),
		easing = easing,
	}
end

function Actors.orbit(registry: Registry, actor: Actor, spec: Types.OrbitSpec, start: number)
	local center = Points.position(spec.center, Actors.lookup(registry))
	if not center then
		return
	end
	local rel = actor.baseCf.Position - center
	local startAngle = if spec.startAngle
		then math.rad(spec.startAngle)
		else math.atan2(rel.Z, rel.X)
	actor.motion = {
		kind = "orbit",
		start = start,
		duration = math.huge,
		from = actor.baseCf,
		center = center,
		radius = spec.radius,
		height = spec.height,
		period = spec.period,
		startAngle = startAngle,
		direction = if spec.clockwise then -1 else 1,
		faceCenter = spec.faceCenter ~= false,
	}
end

--- Visits every player's face in turn (CS-02 shot 3), in `duration` seconds.
function Actors.tour(actor: Actor, spec: Types.TourSpec, start: number, duration: number)
	local heads = Points.playerHeads()
	if #heads == 0 then
		return
	end
	actor.motion = {
		kind = "tour",
		start = start,
		duration = duration,
		from = actor.baseCf,
		tour = spec,
		heads = heads,
		tourStep = 0,
	}
end

local function lights(actor: Actor): (PointLight?, SpotLight?)
	local glow = actor.model:FindFirstChild("Glow", true)
	local spot = actor.model:FindFirstChild("Spot", true)
	return (if glow and glow:IsA("PointLight") then glow else nil),
		(if spot and spot:IsA("SpotLight") then spot else nil)
end

function Actors.light(actor: Actor, cue: Types.LightCue)
	local glow, spot = lights(actor)
	local time = cue.time or 0
	if glow and cue.glow then
		if time > 0 then
			game:GetService("TweenService")
				:Create(glow, TweenInfo.new(time), { Brightness = cue.glow })
				:Play()
		else
			glow.Brightness = cue.glow
		end
	end
	if spot and cue.spot ~= nil then
		spot.Enabled = cue.spot
	end
end

local function tourTarget(head: BasePart, spec: Types.TourSpec): CFrame
	local look = Vector3.new(head.CFrame.LookVector.X, 0, head.CFrame.LookVector.Z)
	look = if look.Magnitude > 1e-3 then look.Unit else Vector3.new(0, 0, -1)
	local pos = head.Position + look * spec.distance + Vector3.new(0, spec.height or 0, 0)
	return CFrame.lookAt(pos, head.Position)
end

local function updateMotion(actor: Actor, now: number)
	local m = actor.motion
	if not m then
		return
	end
	if m.kind == "move" and m.to then
		local a =
			PoseMath.ease(m.easing or "SineInOut", math.clamp((now - m.start) / m.duration, 0, 1))
		actor.baseCf = m.from:Lerp(m.to, a)
		if a >= 1 then
			actor.motion = nil
		end
	elseif m.kind == "orbit" and m.center and m.radius and m.period then
		local angle = (m.startAngle or 0)
			+ (m.direction or 1) * (now - m.start) / m.period * math.pi * 2
		local pos = m.center
			+ Vector3.new(math.cos(angle) * m.radius, m.height or 0, math.sin(angle) * m.radius)
		local cf: CFrame
		if m.faceCenter then
			cf = CFrame.lookAt(pos, m.center + Vector3.new(0, 2.5, 0))
		else
			local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle)) * (m.direction or 1)
			cf = CFrame.lookAt(pos, pos + tangent)
		end
		-- ease into the circle during the first second
		local blend = math.clamp((now - m.start) / 1, 0, 1)
		actor.baseCf = if blend < 1 then m.from:Lerp(cf, PoseMath.ease("SineInOut", blend)) else cf
	elseif m.kind == "tour" and m.heads and m.tour then
		local heads = m.heads
		local n = #heads
		local slot = m.duration / n
		local elapsed = now - m.start
		local index = math.clamp(math.floor(elapsed / slot) + 1, 1, n)
		local head = heads[index]
		if not head.Parent then
			return
		end
		local localT = elapsed - (index - 1) * slot
		local target = tourTarget(head, m.tour)
		local from = if index == 1 then m.from else tourTarget(heads[index - 1], m.tour)
		local a = PoseMath.ease("QuadInOut", math.clamp(localT / (slot * 0.45), 0, 1))
		actor.baseCf = from:Lerp(target, a)
		if (m.tourStep or 0) < index and localT >= slot * 0.45 then
			m.tourStep = index
			if m.tour.anim then
				actor.animator:play(m.tour.anim, { restart = true, startClock = now })
			end
		end
		if elapsed >= m.duration then
			actor.baseCf = target
			actor.motion = nil
		end
	end
end

--- Moves and animates every actor. Call once per frame.
function Actors.update(registry: Registry)
	local now = registry.clock()
	-- riders last, so they follow the ridden actor's pose of this frame
	local riders: { Actor } = {}
	for _, actor in registry.byId do
		if actor.ride and not actor.external then
			table.insert(riders, actor)
			continue
		end
		if actor.external then
			if actor.driven then
				actor.animator:step()
			end
		elseif actor.model.Parent then
			updateMotion(actor, now)
			actor.animator:step()
			-- scale tracks (A-GIALLINO_GROW...) only touch the model when they change, so the
			-- Grow/Shrink effects can also scale an actor
			local scale = actor.animator:getScale()
			if math.abs(scale - actor.lastAnimScale) > 1e-4 then
				actor.lastAnimScale = scale
				actor.model:ScaleTo(math.max(scale, 0.01))
			end
			actor.model:PivotTo(actor.baseCf * actor.animator:getRootOffset())
		end
	end
	for _, actor in riders do
		local ride = actor.ride :: Types.RideSpec
		local mount = registry.byId[ride.actor]
		if mount and mount.model.Parent and actor.model.Parent then
			actor.baseCf = mount.model:GetPivot()
				* CFrame.new(ride.offset)
				* CFrame.Angles(0, math.rad(ride.yaw or 0), 0)
			actor.animator:step()
			actor.model:PivotTo(actor.baseCf * actor.animator:getRootOffset())
		end
	end
end

function Actors.cleanup(registry: Registry)
	for _, actor in registry.byId do
		if actor.external then
			-- leave the pose alone unless the cutscene animated it (DownedClient owns it)
			if actor.driven then
				actor.animator:destroy()
			end
		else
			Footsteps.untrack(actor.model)
			actor.animator:destroy()
			actor.model:Destroy()
		end
	end
	table.clear(registry.byId)
end

return Actors
