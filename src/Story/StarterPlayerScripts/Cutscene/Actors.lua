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
function Actors.spawn(runtime: Instance, data: Types.Cutscene, clock: () -> number): Registry
	local registry: Registry = { byId = {}, folder = actorFolder(), clock = clock }
	for _, spec in data.actors do
		local template = runtime:WaitForChild(spec.model, 5)
		if not template or not template:IsA("Model") then
			warn(string.format("[Actors] %s: model %s did not arrive", data.id, spec.model))
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
			FaceController.set(model, spec.face or "neutral")
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
	for _, actor in registry.byId do
		if actor.model.Parent then
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
end

function Actors.cleanup(registry: Registry)
	for _, actor in registry.byId do
		Footsteps.untrack(actor.model)
		actor.animator:destroy()
		actor.model:Destroy()
	end
	table.clear(registry.byId)
end

return Actors
