--!strict
-- Computes the cutscene camera for a shot at time t: shot types (WIDE..ECU, OTS, POV, LOW,
-- HIGH) give the default framing and FOV, moves (DOLLY, PAN, ORBIT, CRANE, HANDHELD) animate it.
-- WHIP and BLEND are applied by the engine on top (they need the previous camera), RACK focus
-- is computed here and applied through the Grade controller's DepthOfField.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PoseMath = require(Shared:WaitForChild("Visual"):WaitForChild("PoseMath"))
local Types = require(Shared:WaitForChild("Types"))

local Settings = require(script.Parent.Parent:WaitForChild("Settings"))
local Points = require(script.Parent:WaitForChild("Points"))

local CameraRig = {}

local NO_MOVES: { Types.CameraMoveSpec } = {}

CameraRig.ShotFov = {
	WIDE = 70,
	MED = 55,
	CLOSE = 45,
	ECU = 32,
	OTS = 55,
	POV = 65,
	LOW = 55,
	HIGH = 55,
} :: { [string]: number }

-- distance in front of the subject when a shot has no explicit `from`
CameraRig.ShotDistance = {
	WIDE = 26,
	MED = 9,
	CLOSE = 5.5,
	ECU = 2.8,
	OTS = 8,
	POV = 6,
	LOW = 7,
	HIGH = 10,
} :: { [string]: number }

export type Frame = {
	cframe: CFrame,
	fov: number,
	focus: number?, -- DOF focus distance when racking
	target: Vector3,
}

local function flatUnit(v: Vector3): Vector3
	local flat = Vector3.new(v.X, 0, v.Z)
	if flat.Magnitude < 1e-4 then
		return Vector3.new(0, 0, -1)
	end
	return flat.Unit
end

local function rotateY(v: Vector3, degrees: number): Vector3
	return CFrame.fromAxisAngle(Vector3.yAxis, math.rad(degrees)):VectorToWorldSpace(v)
end

local function moveAlpha(move: Types.CameraMoveSpec, alpha: number): number
	local from = move.from or 0
	local to = move.to or 1
	local a = math.clamp((alpha - from) / math.max(to - from, 1e-3), 0, 1)
	return PoseMath.ease(move.easing or "SineInOut", a)
end

function CameraRig.hasMove(cam: Types.CameraSpec, kind: string): boolean
	for _, m in cam.moves or NO_MOVES do
		if m.kind == kind then
			return true
		end
	end
	return false
end

--- Camera for a shot `t` seconds in (shot length `duration`). nil if the subject is missing.
function CameraRig.evaluate(
	cam: Types.CameraSpec,
	t: number,
	duration: number,
	actors: Points.ActorLookup
): Frame?
	local targetCf = Points.resolve(cam.lookAt, actors)
	if not targetCf then
		return nil
	end
	local target = targetCf.Position
	local fromPos: Vector3
	if cam.from then
		local p = Points.position(cam.from, actors)
		if not p then
			return nil
		end
		fromPos = p
	else
		local distance = cam.distance or CameraRig.ShotDistance[cam.shot] or 8
		local dir = rotateY(flatUnit(targetCf.LookVector), cam.side or 0)
		local height = cam.height or 0
		if cam.low or cam.shot == "LOW" then
			height -= distance * 0.38
		end
		if cam.high or cam.shot == "HIGH" then
			height += distance * 0.75
		end
		fromPos = target + dir * distance + Vector3.new(0, height, 0)
	end

	local alpha = math.clamp(t / math.max(duration, 1e-3), 0, 1)
	local pan = 0
	local shake = cam.shake or 0
	for _, move in cam.moves or NO_MOVES do
		local a = moveAlpha(move, alpha)
		local kind = move.kind
		if kind == "DOLLY_IN" then
			fromPos = fromPos:Lerp(target, (move.amount or 0.3) * a)
		elseif kind == "DOLLY_OUT" then
			fromPos = target + (fromPos - target) * (1 + (move.amount or 0.3) * a)
		elseif kind == "ORBIT" then
			fromPos = target + rotateY(fromPos - target, (move.angle or 60) * a)
		elseif kind == "CRANE_UP" then
			fromPos += Vector3.new(0, (move.amount or 8) * a, 0)
		elseif kind == "CRANE_DOWN" then
			fromPos -= Vector3.new(0, (move.amount or 8) * a, 0)
		elseif kind == "PAN_L" then
			pan += (move.angle or 20) * a
		elseif kind == "PAN_R" then
			pan -= (move.angle or 20) * a
		elseif kind == "HANDHELD" then
			shake += move.amount or 0.12
		end
	end
	if (fromPos - target).Magnitude < 0.05 then
		fromPos = target + Vector3.new(0, 0, 0.05)
	end
	local cf = CFrame.lookAt(fromPos, target)
		* CFrame.Angles(0, math.rad(pan), math.rad(cam.roll or 0))
	if shake > 0 and Settings.get().cameraShake then
		local n1 = math.noise(t * 1.3, 0.1)
		local n2 = math.noise(t * 1.1, 4.7)
		local n3 = math.noise(t * 0.9, 9.3)
		cf = cf
			* CFrame.new(n1 * shake, n2 * shake, 0)
			* CFrame.Angles(n2 * shake * 0.06, n3 * shake * 0.08, n1 * shake * 0.03)
	end

	local focus: number? = nil
	local rack = cam.rack
	if rack then
		local a =
			PoseMath.ease("SineInOut", math.clamp((t - (rack.at or 0)) / (rack.time or 1.2), 0, 1))
		local p0 = Points.position(rack.from, actors)
		local p1 = Points.position(rack.to, actors)
		if p0 and p1 then
			local d0 = (p0 - fromPos).Magnitude
			local d1 = (p1 - fromPos).Magnitude
			focus = d0 + (d1 - d0) * a
		end
	end

	return {
		cframe = cf,
		fov = cam.fov or CameraRig.ShotFov[cam.shot] or 55,
		focus = focus,
		target = target,
	}
end

return CameraRig
