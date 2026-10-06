--!strict
-- Pure animation mixer (no Roblox APIs). Keeps the list of playing animations and computes the
-- pose of every joint at the current clock time. PoseAnimator applies the result to Motor6Ds;
-- tools/anim_preview runs this same code with the Luau CLI.
-- Rules: for each joint the most recently started animation that has a track for it wins;
-- when the owner changes the joint crossfades (angles the short way). Non-looping animations
-- hold their last pose until stopped or overridden.
local PoseMath = require(script.Parent.PoseMath)

type Pose = PoseMath.Pose

export type AnimData = {
	id: string,
	length: number,
	loop: boolean,
	continueYaw: boolean?,
	effect: { kind: string, at: number, params: { [string]: any }? }?,
}

export type Loaded = {
	data: AnimData,
	tracks: { [string]: { PoseMath.FullKey } },
	scale: { PoseMath.ScalarKey }?,
}

export type PlayOptions = {
	speed: number?,
	startClock: number?,
	fade: number?,
	restart: boolean?,
	effectParams: { [string]: any }?,
}

export type Playing = {
	id: string,
	loaded: Loaded,
	startClock: number,
	speed: number,
	order: number,
	fade: number,
	yawOffset: number,
	effectFired: boolean,
	effectParams: { [string]: any }?,
}

type JointState = {
	current: Pose,
	owner: Playing?,
	fadeFrom: Pose,
	fadeStart: number,
	fadeTime: number,
}

export type EffectRequest = { kind: string, params: { [string]: any } }

local PoseMixer = {}
PoseMixer.__index = PoseMixer

export type PoseMixer = typeof(setmetatable(
	{} :: {
		loader: (string) -> Loaded,
		clock: () -> number,
		joints: { [string]: JointState },
		playing: { Playing },
		order: number,
		scale: number,
	},
	PoseMixer
))

local function zeroPose(): Pose
	return { rot = { 0, 0, 0 }, pos = { 0, 0, 0 } }
end

local function clonePose(p: Pose): Pose
	return { rot = { p.rot[1], p.rot[2], p.rot[3] }, pos = { p.pos[1], p.pos[2], p.pos[3] } }
end

function PoseMixer.new(
	jointNames: { string },
	loader: (string) -> Loaded,
	clock: () -> number
): PoseMixer
	local joints: { [string]: JointState } = {}
	for _, name in jointNames do
		joints[name] = {
			current = zeroPose(),
			owner = nil,
			fadeFrom = zeroPose(),
			fadeStart = 0,
			fadeTime = 0,
		}
	end
	if not joints.Root then
		joints.Root = {
			current = zeroPose(),
			owner = nil,
			fadeFrom = zeroPose(),
			fadeStart = 0,
			fadeTime = 0,
		}
	end
	return setmetatable({
		loader = loader,
		clock = clock,
		joints = joints,
		playing = {},
		order = 0,
		scale = 1,
	}, PoseMixer)
end

local function find(self: PoseMixer, id: string): (Playing?, number?)
	for i, p in self.playing do
		if p.id == id then
			return p, i
		end
	end
	return nil, nil
end

local function elapsedOf(p: Playing, now: number): number
	return (now - p.startClock) * p.speed
end

--- Starts an animation. If it is already playing (and restart is not set) only its speed
--- changes, keeping its current position.
function PoseMixer.play(self: PoseMixer, id: string, opts: PlayOptions?)
	local o: PlayOptions = opts or {}
	local now = self.clock()
	local existing, index = find(self, id)
	if existing and not o.restart then
		local newSpeed = o.speed or existing.speed
		if newSpeed ~= existing.speed then
			local elapsed = elapsedOf(existing, now)
			existing.speed = newSpeed
			existing.startClock = now - elapsed / math.max(newSpeed, 1e-3)
		end
		return
	end
	if existing and index then
		table.remove(self.playing, index)
	end
	local loaded = self.loader(id)
	self.order += 1
	local yawOffset = 0
	if loaded.data.continueYaw then
		yawOffset = self.joints.Root.current.rot[2] % 360
	end
	table.insert(self.playing, {
		id = id,
		loaded = loaded,
		startClock = o.startClock or now,
		speed = o.speed or 1,
		order = self.order,
		fade = o.fade or 0.25,
		yawOffset = yawOffset,
		effectFired = false,
		effectParams = o.effectParams,
	})
end

--- Stops one animation, or all with "*" / nil.
function PoseMixer.stop(self: PoseMixer, id: string?)
	if id == nil or id == "*" then
		table.clear(self.playing)
		return
	end
	local _, index = find(self, id)
	if index then
		table.remove(self.playing, index)
	end
end

function PoseMixer.isPlaying(self: PoseMixer, id: string): boolean
	return (find(self, id)) ~= nil
end

local function ownerFor(self: PoseMixer, jointName: string): Playing?
	local best: Playing? = nil
	for _, p in self.playing do
		if p.loaded.tracks[jointName] and (best == nil or p.order > best.order) then
			best = p
		end
	end
	return best
end

local function sample(p: Playing, jointName: string, now: number): Pose
	local data = p.loaded.data
	local t = PoseMath.localTime(data.length, data.loop, elapsedOf(p, now))
	local pose = PoseMath.sampleTrack(p.loaded.tracks[jointName], t)
	if jointName == "Root" and p.yawOffset ~= 0 then
		pose.rot[2] += p.yawOffset
	end
	return pose
end

--- Computes all joint poses for the current clock time. Returns the poses (joint -> pose)
--- and the effects whose start time was reached during this step.
function PoseMixer.step(self: PoseMixer): ({ [string]: Pose }, { EffectRequest })
	local now = self.clock()
	local out: { [string]: Pose } = {}
	for name, joint in self.joints do
		local owner = ownerFor(self, name)
		if owner ~= joint.owner then
			joint.fadeFrom = clonePose(joint.current)
			joint.fadeStart = now
			joint.fadeTime = if owner then owner.fade else 0.25
			joint.owner = owner
		end
		local target = if owner then sample(owner, name, now) else zeroPose()
		local pose = target
		if joint.fadeTime > 0 then
			local a = (now - joint.fadeStart) / joint.fadeTime
			if a < 1 then
				pose = PoseMath.blend(joint.fadeFrom, target, PoseMath.ease("SineInOut", a))
			end
		end
		joint.current = clonePose(pose)
		out[name] = pose
	end

	local scaleOwner: Playing? = nil
	for _, p in self.playing do
		if p.loaded.scale and (scaleOwner == nil or p.order > scaleOwner.order) then
			scaleOwner = p
		end
	end
	if scaleOwner then
		local data = scaleOwner.loaded.data
		local t = PoseMath.localTime(data.length, data.loop, elapsedOf(scaleOwner, now))
		self.scale = PoseMath.sampleScalar(scaleOwner.loaded.scale :: { PoseMath.ScalarKey }, t)
	end

	local effects: { EffectRequest } = {}
	for _, p in self.playing do
		local effect = p.loaded.data.effect
		if effect and not p.effectFired and elapsedOf(p, now) >= effect.at then
			p.effectFired = true
			local params: { [string]: any } = {}
			local base = effect.params
			if base then
				for k, v in base do
					params[k] = v
				end
			end
			local extra = p.effectParams
			if extra then
				for k, v in extra do
					params[k] = v
				end
			end
			table.insert(effects, { kind = effect.kind, params = params })
		end
	end
	return out, effects
end

return PoseMixer
