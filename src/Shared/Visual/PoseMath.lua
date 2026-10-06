--!strict
-- Pure keyframe math for PoseAnimator. No Roblox APIs here, so tools/anim_preview can run the
-- exact same code with the Luau CLI to check the animations outside Studio.
-- A pose is rot = {pitch, yaw, roll} degrees and pos = {x, y, z} studs.

export type Key = { t: number, rot: { number }?, pos: { number }?, ease: string? }
export type FullKey = { t: number, rot: { number }, pos: { number }, ease: string? }
export type ScalarKey = { t: number, v: number, ease: string? }
export type Pose = { rot: { number }, pos: { number } }

local PoseMath = {}

local HALF_PI = math.pi / 2

--- Easing curves (names match Types.EasingName). Default is SineInOut, as cutscenes.md says.
function PoseMath.ease(name: string?, a: number): number
	if a <= 0 then
		return 0
	elseif a >= 1 then
		return 1
	end
	if name == nil or name == "SineInOut" then
		return -(math.cos(math.pi * a) - 1) / 2
	elseif name == "Linear" then
		return a
	elseif name == "Constant" then
		return 0
	elseif name == "SineIn" then
		return 1 - math.cos(a * HALF_PI)
	elseif name == "SineOut" then
		return math.sin(a * HALF_PI)
	elseif name == "QuadIn" then
		return a * a
	elseif name == "QuadOut" then
		return 1 - (1 - a) * (1 - a)
	elseif name == "QuadInOut" then
		if a < 0.5 then
			return 2 * a * a
		end
		return 1 - ((-2 * a + 2) ^ 2) / 2
	elseif name == "CubicIn" then
		return a * a * a
	elseif name == "CubicOut" then
		return 1 - (1 - a) ^ 3
	elseif name == "CubicInOut" then
		if a < 0.5 then
			return 4 * a * a * a
		end
		return 1 - ((-2 * a + 2) ^ 3) / 2
	elseif name == "BackOut" then
		local c1 = 1.70158
		local c3 = c1 + 1
		return 1 + c3 * (a - 1) ^ 3 + c1 * (a - 1) ^ 2
	elseif name == "ExpoOut" then
		return 1 - 2 ^ (-10 * a)
	end
	return -(math.cos(math.pi * a) - 1) / 2
end

local function copy3(v: { number }?): { number }
	if v then
		return { v[1] or 0, v[2] or 0, v[3] or 0 }
	end
	return { 0, 0, 0 }
end

--- Sorts keys by time and fills missing rot/pos with the previous key's value.
function PoseMath.normalizeTrack(keys: { Key }): { FullKey }
	local sorted = table.clone(keys)
	table.sort(sorted, function(a, b)
		return a.t < b.t
	end)
	local out: { FullKey } = {}
	local lastRot = { 0, 0, 0 }
	local lastPos = { 0, 0, 0 }
	for _, k in sorted do
		local rot = if k.rot then copy3(k.rot) else copy3(lastRot)
		local pos = if k.pos then copy3(k.pos) else copy3(lastPos)
		table.insert(out, { t = k.t, rot = rot, pos = pos, ease = k.ease })
		lastRot = rot
		lastPos = pos
	end
	return out
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

--- Interpolates between two angles in degrees along the shortest way.
function PoseMath.lerpAngle(a: number, b: number, t: number): number
	local d = ((b - a + 180) % 360) - 180
	return a + d * t
end

--- Samples a normalized track at time t. The ease of a key shapes the segment that ENDS at it.
function PoseMath.sampleTrack(keys: { FullKey }, t: number): Pose
	local n = #keys
	if n == 0 then
		return { rot = { 0, 0, 0 }, pos = { 0, 0, 0 } }
	end
	if t <= keys[1].t or n == 1 then
		return { rot = copy3(keys[1].rot), pos = copy3(keys[1].pos) }
	end
	local last = keys[n]
	if t >= last.t then
		return { rot = copy3(last.rot), pos = copy3(last.pos) }
	end
	for i = 1, n - 1 do
		local k0 = keys[i]
		local k1 = keys[i + 1]
		if t >= k0.t and t < k1.t then
			local span = k1.t - k0.t
			local a = if span > 0 then (t - k0.t) / span else 1
			local e = PoseMath.ease(k1.ease, a)
			return {
				rot = {
					lerp(k0.rot[1], k1.rot[1], e),
					lerp(k0.rot[2], k1.rot[2], e),
					lerp(k0.rot[3], k1.rot[3], e),
				},
				pos = {
					lerp(k0.pos[1], k1.pos[1], e),
					lerp(k0.pos[2], k1.pos[2], e),
					lerp(k0.pos[3], k1.pos[3], e),
				},
			}
		end
	end
	return { rot = copy3(last.rot), pos = copy3(last.pos) }
end

function PoseMath.sampleScalar(keys: { ScalarKey }, t: number): number
	local n = #keys
	if n == 0 then
		return 1
	end
	if t <= keys[1].t or n == 1 then
		return keys[1].v
	end
	if t >= keys[n].t then
		return keys[n].v
	end
	for i = 1, n - 1 do
		local k0 = keys[i]
		local k1 = keys[i + 1]
		if t >= k0.t and t < k1.t then
			local span = k1.t - k0.t
			local a = if span > 0 then (t - k0.t) / span else 1
			return lerp(k0.v, k1.v, PoseMath.ease(k1.ease, a))
		end
	end
	return keys[n].v
end

--- Time inside an animation. Looping animations wrap, others clamp and report finished.
function PoseMath.localTime(length: number, loop: boolean, elapsed: number): (number, boolean)
	if elapsed < 0 then
		return 0, false
	end
	if loop then
		if length <= 0 then
			return 0, false
		end
		return elapsed % length, false
	end
	if elapsed >= length then
		return length, true
	end
	return elapsed, false
end

--- Blends two poses (angles along the shortest way).
function PoseMath.blend(a: Pose, b: Pose, t: number): Pose
	return {
		rot = {
			PoseMath.lerpAngle(a.rot[1], b.rot[1], t),
			PoseMath.lerpAngle(a.rot[2], b.rot[2], t),
			PoseMath.lerpAngle(a.rot[3], b.rot[3], t),
		},
		pos = {
			lerp(a.pos[1], b.pos[1], t),
			lerp(a.pos[2], b.pos[2], t),
			lerp(a.pos[3], b.pos[3], t),
		},
	}
end

PoseMath.ZERO =
	table.freeze({ rot = table.freeze({ 0, 0, 0 }), pos = table.freeze({ 0, 0, 0 }) }) :: Pose

return PoseMath
