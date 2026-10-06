--!strict
-- Effect registry: Effects.run(kind, model, params). PoseAnimator calls this for animations
-- with an `effect` field (e.g. A-PIXEL_DISSOLVE); cutscene cues call it directly.
local Bloom = require(script.Bloom)
local Melt = require(script.Melt)
local PixelAssemble = require(script.PixelAssemble)
local PixelDissolve = require(script.PixelDissolve)
local RootsBridge = require(script.RootsBridge)
local Scale = require(script.Scale)
local Shatter = require(script.Shatter)
local TimeFreeze = require(script.TimeFreeze)
local WallBreak = require(script.WallBreak)

local Effects = {}

Effects.Kinds = {
	"PixelDissolve",
	"PixelAssemble",
	"LastPixel",
	"Shatter",
	"Melt",
	"Grow",
	"Shrink",
	"WallBreak",
	"RootsBridge",
	"Bloom",
	"TimeFreeze",
	"TimeResume",
}

local activeFreeze: TimeFreeze.Handle? = nil

--- Runs an effect. `target` is the model (or nil for effects placed by position).
--- Yields until the effect finishes for the effects that have a duration.
function Effects.run(kind: string, target: Instance?, params: { [string]: any }?)
	local p: { [string]: any } = params or {}
	if kind == "PixelDissolve" then
		assert(target, "PixelDissolve needs a model")
		PixelDissolve.run(target, p :: any)
	elseif kind == "PixelAssemble" then
		assert(target, "PixelAssemble needs a model")
		PixelAssemble.run(target, p :: any)
	elseif kind == "LastPixel" then
		local at: Vector3 = p.at
			or (if target and target:IsA("BasePart") then target.Position else Vector3.zero)
		PixelDissolve.lastPixel(at, p.duration)
	elseif kind == "Shatter" then
		assert(target, "Shatter needs a model")
		Shatter.run(target, p :: any)
	elseif kind == "Melt" then
		assert(target, "Melt needs a model")
		Melt.run(target, p :: any)
	elseif kind == "Grow" or kind == "Shrink" then
		assert(target and target:IsA("Model"), kind .. " needs a Model")
		local to = p.to or (if kind == "Grow" then 12 else 1)
		Scale.run(target, {
			from = p.from,
			to = to,
			duration = p.duration,
			easing = p.easing,
			bloomFlash = p.bloomFlash,
		})
	elseif kind == "WallBreak" then
		assert(target, "WallBreak needs a model")
		WallBreak.run(target, p :: any)
	elseif kind == "RootsBridge" then
		RootsBridge.run(p :: any)
	elseif kind == "Bloom" then
		assert(target, "Bloom needs a model")
		Bloom.run(target, p :: any)
	elseif kind == "TimeFreeze" then
		if activeFreeze then
			activeFreeze:resume()
		end
		activeFreeze = TimeFreeze.freeze(p :: any)
	elseif kind == "TimeResume" then
		if activeFreeze then
			activeFreeze:resume()
			activeFreeze = nil
		end
	else
		warn("[Effects] unknown effect " .. kind)
	end
end

return Effects
