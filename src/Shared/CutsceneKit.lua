--!strict
-- Helpers for the cutscene data files (Shared/Cutscenes): typed wrappers (so the type checker
-- validates every entry on its own) and points in WORLD BLOCKS (map.md coordinates) through
-- Anchor_Origin, so a shot can be written straight from the map.
local Types = require(script.Parent.Types)

local Kit = {}

local S = 4 -- studs per block (Config.World.StudsPerBlock)

function Kit.cue(c: Types.Cue): Types.Cue
	return c
end

function Kit.shot(s: Types.Shot): Types.Shot
	return s
end

function Kit.move(m: Types.CameraMoveSpec): Types.CameraMoveSpec
	return m
end

function Kit.actor(a: Types.ActorSpec): Types.ActorSpec
	return a
end

--- A point at world block (x, y, z). `face` = compass direction the point faces
--- (0 north, 90 east, 180 south, 270 west), like Anchors.
function Kit.B(x: number, y: number, z: number, face: number?): Types.Point
	return {
		anchor = "Anchor_Origin",
		offset = Vector3.new(x * S, y * S, z * S),
		yaw = if face then -face else nil,
	}
end

--- Stand-in actors @Player1..@PlayerN (copies of the party's avatars). `place(i)` gives each
--- one's start point; `ride(i)` optionally seats it on another actor.
function Kit.standIns(
	n: number,
	place: (number) -> Types.Point,
	ride: ((number) -> Types.RideSpec?)?
): { Types.ActorSpec }
	local out: { Types.ActorSpec } = {}
	for i = 1, n do
		table.insert(out, {
			id = "P" .. i,
			model = "@Player" .. i,
			at = place(i),
			ride = if ride then ride(i) else nil,
			footsteps = false,
		})
	end
	return out
end

--- One cue per stand-in (same fields, actor id filled in).
function Kit.forPlayers(n: number, make: (number) -> Types.Cue): { Types.Cue }
	local out: { Types.Cue } = {}
	for i = 1, n do
		local c = make(i)
		c.actor = "P" .. i
		table.insert(out, c)
	end
	return out
end

--- Concatenates cue lists.
function Kit.cues(...: { Types.Cue }): { Types.Cue }
	local out: { Types.Cue } = {}
	for _, list in { ... } do
		for _, c in list do
			table.insert(out, c)
		end
	end
	return out
end

Kit.MAX_PLAYERS = 6

return Kit
