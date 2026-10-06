--!strict
-- Loads cutscene data modules from Shared/Cutscenes (id = file name, e.g. "CS_05").
-- "CS-05" and "cs_05" are accepted too. Data is validated once when first loaded.
local Types = require(script.Parent.Types)

local CutsceneLibrary = {}

local folder = script.Parent:WaitForChild("Cutscenes")
local cache: { [string]: Types.Cutscene } = {}

function CutsceneLibrary.normalizeId(id: string): string
	return string.upper((string.gsub(id, "-", "_")))
end

local function validate(data: Types.Cutscene)
	assert(data.segments[data.entry], data.id .. ": entry segment missing")
	local actorIds: { [string]: boolean } = {}
	for _, actor in data.actors do
		actorIds[actor.id] = true
	end
	for key, seg in data.segments do
		assert(#seg.shots > 0, string.format("%s/%s has no shots", data.id, key))
		local lastEnd = 0
		for _, shot in seg.shots do
			assert(
				shot.t1 > shot.t0,
				string.format("%s/%s shot %s: t1 <= t0", data.id, key, shot.n)
			)
			assert(
				shot.t0 >= lastEnd - 1e-6,
				string.format("%s/%s shot %s overlaps", data.id, key, shot.n)
			)
			lastEnd = shot.t1
			local cues = shot.cues
			if cues then
				for _, cue in cues do
					if cue.actor then
						assert(
							actorIds[cue.actor],
							string.format(
								"%s shot %s: unknown actor %s",
								data.id,
								shot.n,
								cue.actor
							)
						)
					end
				end
			end
		end
		assert(
			lastEnd <= seg.length + 1e-6,
			string.format("%s/%s shots run past the segment length", data.id, key)
		)
		if seg.next then
			assert(
				data.segments[seg.next],
				string.format("%s/%s: next segment %s missing", data.id, key, seg.next)
			)
		end
		if seg.vote then
			for _, option in seg.vote.options do
				if option.next then
					assert(
						data.segments[option.next],
						string.format("%s: vote option %s -> missing segment", data.id, option.id)
					)
				end
			end
		end
	end
end

function CutsceneLibrary.get(id: string): Types.Cutscene?
	local key = CutsceneLibrary.normalizeId(id)
	local cached = cache[key]
	if cached then
		return cached
	end
	local module = folder:FindFirstChild(key)
	if not module or not module:IsA("ModuleScript") then
		return nil
	end
	local data = (require :: any)(module) :: Types.Cutscene
	validate(data)
	cache[key] = data
	return data
end

function CutsceneLibrary.list(): { string }
	local out = {}
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			table.insert(out, child.Name)
		end
	end
	table.sort(out)
	return out
end

return CutsceneLibrary
