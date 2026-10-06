--!strict
-- Grow / Shrink (A-GIALLINO_GROW 1 -> 12 with a Bloom flash, A-GIALLINO_FALL_SMALL 12 -> 1).
-- Uses Model:ScaleTo, so the whole model (lights, faces) scales around its pivot.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Debris = require(script.Parent.Debris)
local PoseMath = require(script.Parent.Parent.PoseMath)

local Scale = {}

export type Params = {
	from: number?, -- default: current scale
	to: number,
	duration: number?,
	easing: string?,
	bloomFlash: boolean?,
}

local function flash()
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "FX_GrowFlash"
	bloom.Intensity = 3
	bloom.Size = 56
	bloom.Threshold = 0.4
	bloom.Parent = Lighting
	local tween = TweenService:Create(
		bloom,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Intensity = 0,
		}
	)
	tween.Completed:Once(function()
		bloom:Destroy()
	end)
	tween:Play()
end

function Scale.run(model: Model, params: Params)
	local from = params.from or model:GetScale()
	local to = params.to
	local duration = params.duration or 2
	if params.bloomFlash then
		flash()
	end
	local elapsed = 0
	local finished = Instance.new("BindableEvent")
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt * Debris.timeScale
		local a = PoseMath.ease(params.easing or "SineInOut", math.clamp(elapsed / duration, 0, 1))
		if model.Parent then
			model:ScaleTo(math.max(from + (to - from) * a, 0.01))
		end
		if elapsed >= duration then
			connection:Disconnect()
			finished:Fire()
		end
	end)
	finished.Event:Wait()
	finished:Destroy()
end

return Scale
