--!strict
-- Plays code-only keyframe animations (Shared/Animations/A_*.lua) on rigs built from Parts
-- joined by Motor6Ds: every frame each joint's C0 = baseC0 * offset(pos, rot), using the pure
-- PoseMixer for layering and crossfades. The pseudo-joint "Root" moves the whole model relative
-- to its placement (getRootOffset) and the optional scale track resizes it (getScale).
-- Time comes from a clock function; with the shared server clock all clients see the same frame.
local AnimationLibrary = require(script.Parent.Parent.AnimationLibrary)
local PoseMath = require(script.Parent.PoseMath)
local PoseMixer = require(script.Parent.PoseMixer)

export type PlayOptions = PoseMixer.PlayOptions
export type EffectRunner = (model: Model, kind: string, params: { [string]: any }) -> ()

local PoseAnimator = {}
PoseAnimator.__index = PoseAnimator

export type PoseAnimator = typeof(setmetatable(
	{} :: {
		model: Model,
		mixer: PoseMixer.PoseMixer,
		motors: { [string]: { motor: Motor6D, base: CFrame } },
		rootOffset: CFrame,
		destroyed: boolean,
	},
	PoseAnimator
))

local effectRunner: EffectRunner? = nil

--- Animations with an `effect` field (e.g. A-PIXEL_DISSOLVE) call this when the effect time is
--- reached. The client registers the Effects module here.
function PoseAnimator.setEffectRunner(runner: EffectRunner)
	effectRunner = runner
end

local function loader(id: string): PoseMixer.Loaded
	return AnimationLibrary.get(id) :: any
end

function PoseAnimator.new(model: Model, clock: (() -> number)?): PoseAnimator
	local motors: { [string]: { motor: Motor6D, base: CFrame } } = {}
	local names: { string } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") then
			motors[d.Name] = { motor = d, base = d.C0 }
			table.insert(names, d.Name)
		end
	end
	-- R15 player characters: our RootJoint (waist bend) is R15's "Waist"; R15's real "Root"
	-- motor (HumanoidRootPart -> LowerTorso) then takes the Root track instead of the pivot.
	local waist = motors.Waist
	if not motors.RootJoint and waist then
		motors.RootJoint = waist
		local anyMotors: any = motors
		anyMotors.Waist = nil
		local index = table.find(names, "Waist")
		if index then
			table.remove(names, index)
		end
		table.insert(names, "RootJoint")
	end
	if not motors.Root then
		table.insert(names, "Root")
	end
	return setmetatable({
		model = model,
		mixer = PoseMixer.new(names, loader, clock or os.clock),
		motors = motors,
		rootOffset = CFrame.identity,
		destroyed = false,
	}, PoseAnimator)
end

function PoseAnimator.play(self: PoseAnimator, id: string, opts: PlayOptions?)
	self.mixer:play(id, opts)
end

function PoseAnimator.stop(self: PoseAnimator, id: string?)
	self.mixer:stop(id)
end

function PoseAnimator.isPlaying(self: PoseAnimator, id: string): boolean
	return self.mixer:isPlaying(id)
end

local function toCFrame(pose: PoseMath.Pose): CFrame
	return CFrame.new(pose.pos[1], pose.pos[2], pose.pos[3])
		* CFrame.Angles(math.rad(pose.rot[1]), math.rad(pose.rot[2]), math.rad(pose.rot[3]))
end

--- Advances all joints to the current clock time. Call once per frame.
function PoseAnimator.step(self: PoseAnimator)
	if self.destroyed then
		return
	end
	local poses, effects = self.mixer:step()
	for name, pose in poses do
		local m = self.motors[name]
		if m then
			m.motor.C0 = m.base * toCFrame(pose)
		elseif name == "Root" then
			self.rootOffset = toCFrame(pose)
		end
	end
	local runner = effectRunner
	if runner then
		for _, e in effects do
			task.spawn(runner, self.model, e.kind, e.params)
		end
	end
end

function PoseAnimator.getRootOffset(self: PoseAnimator): CFrame
	return self.rootOffset
end

function PoseAnimator.getScale(self: PoseAnimator): number
	return self.mixer.scale
end

--- Puts every joint back to its rest pose and stops updating.
function PoseAnimator.destroy(self: PoseAnimator)
	self.destroyed = true
	self.mixer:stop("*")
	for _, m in self.motors do
		if m.motor.Parent then
			m.motor.C0 = m.base
		end
	end
end

return PoseAnimator
