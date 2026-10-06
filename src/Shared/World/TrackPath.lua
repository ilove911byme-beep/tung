--!strict
-- The minecart loop (MapData.Track) as a polyline in studs, shared by the server (QTE timing)
-- and MinecartClient (carts drawn locally from the same server clock). Distances are in blocks.
local MapData = require(script.Parent.MapData)

local S = 4

local TrackPath = {}

local points: { Vector3 } = {}
local lengths: { number } = { 0 }
for i, p in MapData.Track.path do
	points[i] = Vector3.new(p[1] + 0.5, MapData.Track.y, p[2] + 0.5)
	if i > 1 then
		lengths[i] = lengths[i - 1] + (points[i] - points[i - 1]).Magnitude
	end
end

TrackPath.length = lengths[#points]
TrackPath.speed = 3.5 -- blocks per second
TrackPath.gap = 1.6 -- blocks between two carts

--- Position (studs, on the rails) and direction at a distance along the loop (blocks).
function TrackPath.at(dist: number): (Vector3, Vector3)
	local d = math.clamp(dist, 0, TrackPath.length)
	for i = 1, #points - 1 do
		if d <= lengths[i + 1] then
			local a, b = points[i], points[i + 1]
			local t = (d - lengths[i]) / math.max(lengths[i + 1] - lengths[i], 1e-6)
			return a:Lerp(b, t) * S, (b - a).Unit
		end
	end
	return points[#points] * S, (points[#points] - points[#points - 1]).Unit
end

--- Distance along the loop of path vertex i (blocks).
function TrackPath.vertex(i: number): number
	return lengths[i]
end

--- Distance along the loop of the point on the path closest to a cell (blocks).
function TrackPath.project(x: number, z: number): number
	local q = Vector3.new(x + 0.5, MapData.Track.y, z + 0.5)
	local best, bestD = 0, math.huge
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local ab = b - a
		local t = math.clamp((q - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
		local dd = (a + ab * t - q).Magnitude
		if dd < bestD then
			bestD = dd
			best = lengths[i] + ab.Magnitude * t
		end
	end
	return best
end

--- Where cart `seat` (1 = lead) is `elapsed` seconds after the start, for `riders` carts.
function TrackPath.seatDistance(seat: number, riders: number, elapsed: number): number
	local lead0 = (riders - 1) * TrackPath.gap
	return lead0 - (seat - 1) * TrackPath.gap + math.max(elapsed, 0) * TrackPath.speed
end

--- Seconds after the start when the lead cart reaches `dist`.
function TrackPath.leadTime(dist: number, riders: number): number
	return (dist - (riders - 1) * TrackPath.gap) / TrackPath.speed
end

return TrackPath
