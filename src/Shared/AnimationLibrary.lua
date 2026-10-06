--!strict
-- Loads animation data modules from Shared/Animations. Id "A-BALLERINA_DANCE" lives in the
-- file A_BALLERINA_DANCE.lua. Tracks are normalized once and cached.
local Types = require(script.Parent.Types)
local PoseMath = require(script.Parent.Visual.PoseMath)

export type Loaded = {
	data: Types.AnimationData,
	tracks: { [string]: { PoseMath.FullKey } },
	scale: { PoseMath.ScalarKey }?,
}

local AnimationLibrary = {}

local folder = script.Parent:WaitForChild("Animations")
local cache: { [string]: Loaded } = {}

function AnimationLibrary.fileName(id: string): string
	return (string.gsub(id, "-", "_"))
end

function AnimationLibrary.get(id: string): Loaded
	local cached = cache[id]
	if cached then
		return cached
	end
	local module = folder:FindFirstChild(AnimationLibrary.fileName(id))
	if not module or not module:IsA("ModuleScript") then
		error(string.format("[AnimationLibrary] unknown animation '%s'", id))
	end
	local data = (require :: any)(module) :: Types.AnimationData
	local tracks: { [string]: { PoseMath.FullKey } } = {}
	for joint, keys in data.tracks do
		tracks[joint] = PoseMath.normalizeTrack(keys :: any)
	end
	local loaded: Loaded = { data = data, tracks = tracks, scale = data.scale :: any }
	cache[id] = loaded
	return loaded
end

function AnimationLibrary.exists(id: string): boolean
	return folder:FindFirstChild(AnimationLibrary.fileName(id)) ~= nil
end

return AnimationLibrary
