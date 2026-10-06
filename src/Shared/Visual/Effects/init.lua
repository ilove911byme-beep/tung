--!strict
-- Effect registry: Effects.run(kind, model, params). PoseAnimator calls this for animations
-- with an `effect` field (e.g. A-PIXEL_DISSOLVE); cutscene cues call it directly.
local Bloom = require(script.Bloom)
local Debris = require(script.Debris)
local Melt = require(script.Melt)
local Morph = require(script.Morph)
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
	"DropItem",
	"ShowPart",
	"HidePart",
	"Transform",
	"Wither",
	"DirtBurst",
}

-- a named part of a model (accessories such as "Apple", "Knife", "BoardInHand")
local function namedPart(target: Instance?, name: string?): BasePart?
	if not target or not name then
		return nil
	end
	local p = target:FindFirstChild(name, true)
	return if p and p:IsA("BasePart") then p else nil
end

-- A-DROP_ITEM: a copy of the held part falls to the floor with a bounce; the original hides.
local function dropItem(target: Instance?, p: { [string]: any })
	local part = namedPart(target, p.part or "Apple")
	if not part then
		return
	end
	local copy = part:Clone()
	for _, c in copy:GetChildren() do
		if c:IsA("JointInstance") or c:IsA("WeldConstraint") then
			c:Destroy()
		end
	end
	copy.Transparency = part.Transparency
	copy.Parent = Debris.container()
	part.Transparency = 1
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { target :: Instance, copy }
	local hit = workspace:Raycast(part.Position, Vector3.new(0, -40, 0), params)
	local floorY = if hit then hit.Position.Y + part.Size.Y / 2 else part.Position.Y - 4
	Debris.add(copy, {
		vel = Vector3.new(math.random() - 0.5, 2, math.random() - 0.5),
		spin = 4,
		gravity = 60,
		floorY = floorY,
		bounce = 0.35,
		life = p.life or 20,
		fadeFrom = (p.life or 20) - 1,
	})
end

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
	elseif kind == "Transform" then
		assert(target, "Transform needs a model")
		Morph.transform(target, p :: any)
	elseif kind == "Wither" then
		assert(target, "Wither needs a model")
		Morph.wither(target, p :: any)
	elseif kind == "DirtBurst" then
		Morph.dirtBurst(target, p :: any)
	elseif kind == "DropItem" then
		dropItem(target, p)
	elseif kind == "ShowPart" or kind == "HidePart" then
		local part = namedPart(target, p.part)
		if part then
			local base = part:GetAttribute("BaseTransparency")
			part.Transparency = if kind == "HidePart"
				then 1
				elseif typeof(base) == "number" then base
				else 0
		end
	else
		warn("[Effects] unknown effect " .. kind)
	end
end

return Effects
