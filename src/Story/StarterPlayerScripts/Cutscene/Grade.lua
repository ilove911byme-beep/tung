--!strict
-- Color grades for cutscenes (Shared/Grades): tweened ColorCorrection, Bloom, Atmosphere and
-- Lighting values, plus the screen overlays a preset asks for (grain, vignette, 4:3, glitch).
-- begin() remembers the gameplay lighting, finish() tweens back to it. All changes are local.
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Grades = require(Shared:WaitForChild("Grades"))

local Overlay = require(script.Parent:WaitForChild("Overlay"))

local Grade = {}

type Snapshot = {
	clockTime: number,
	exposure: number,
	ambient: Color3,
	outdoorAmbient: Color3,
	atmosphere: { density: number, haze: number, color: Color3, decay: Color3, glare: number }?,
}

local snapshot: Snapshot? = nil
local cc: ColorCorrectionEffect? = nil
local bloom: BloomEffect? = nil
local dof: DepthOfFieldEffect? = nil
local blur: BlurEffect? = nil
local atmosphere: Atmosphere? = nil
local createdAtmosphere = false

local function tween(inst: Instance, time: number, goal: { [string]: any })
	if time <= 0 then
		for k, v in goal do
			(inst :: any)[k] = v
		end
		return
	end
	TweenService
		:Create(inst, TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), goal)
		:Play()
end

local function effect<T>(className: string, name: string): T
	local inst = Instance.new(className :: any)
	inst.Name = name
	inst.Parent = Lighting
	return (inst :: any) :: T
end

function Grade.begin()
	if snapshot then
		return
	end
	local existing = Lighting:FindFirstChildOfClass("Atmosphere")
	snapshot = {
		clockTime = Lighting.ClockTime,
		exposure = Lighting.ExposureCompensation,
		ambient = Lighting.Ambient,
		outdoorAmbient = Lighting.OutdoorAmbient,
		atmosphere = if existing
			then {
				density = existing.Density,
				haze = existing.Haze,
				color = existing.Color,
				decay = existing.Decay,
				glare = existing.Glare,
			}
			else nil,
	}
	if existing then
		atmosphere = existing
		createdAtmosphere = false
	else
		local a = Instance.new("Atmosphere")
		a.Name = "CS_Atmosphere"
		a.Density = 0
		a.Haze = 0
		a.Parent = Lighting
		atmosphere = a
		createdAtmosphere = true
	end
	local c = effect("ColorCorrectionEffect", "CS_Grade") :: ColorCorrectionEffect
	cc = c
	local b = effect("BloomEffect", "CS_Bloom") :: BloomEffect
	b.Intensity = 0
	bloom = b
	local d = effect("DepthOfFieldEffect", "CS_DOF") :: DepthOfFieldEffect
	d.Enabled = false
	d.InFocusRadius = 6
	d.FarIntensity = 0.55
	d.NearIntensity = 0.6
	dof = d
	local bl = effect("BlurEffect", "CS_Blur") :: BlurEffect
	bl.Size = 0
	blur = bl
end

--- Applies a preset over `time` seconds.
function Grade.apply(name: string, time: number?)
	if name == "KEEP" then
		return -- service cutscenes keep whatever look the chapter has
	end
	local def = Grades[name]
	if not def then
		warn("[Grade] unknown grade " .. name)
		return
	end
	local t = time or 1
	local c, b, a = cc, bloom, atmosphere
	if c then
		tween(c, t, {
			Brightness = def.brightness,
			Contrast = def.contrast,
			Saturation = def.saturation,
			TintColor = def.tint,
		})
	end
	if b then
		tween(
			b,
			t,
			{ Intensity = def.bloomIntensity, Size = def.bloomSize, Threshold = def.bloomThreshold }
		)
	end
	if a then
		tween(a, t, {
			Density = def.atmosphereDensity,
			Haze = def.atmosphereHaze,
			Color = def.atmosphereColor,
			Decay = def.atmosphereDecay,
			Glare = def.atmosphereGlare,
		})
	end
	local lighting: { [string]: any } = { ExposureCompensation = def.exposure }
	local snap = snapshot
	if def.ambient then
		lighting.Ambient = def.ambient
		lighting.OutdoorAmbient = def.ambient
	elseif snap then
		lighting.Ambient = snap.ambient
		lighting.OutdoorAmbient = snap.outdoorAmbient
	end
	tween(Lighting, t, lighting)
	Overlay.setGrain(def.grain)
	Overlay.setVignette(def.vignette)
	Overlay.setPillarbox(def.pillarbox, t)
	Overlay.setGlitch(def.glitch)
end

--- Time of day for the cutscene (e.g. the CS-03 time-lapse tweens it).
function Grade.setClock(clockTime: number, time: number?)
	tween(Lighting, time or 0, { ClockTime = clockTime })
end

--- Depth of field for RACK focus. nil focus = off.
function Grade.setFocus(focus: number?)
	local d = dof
	if not d then
		return
	end
	if focus then
		d.Enabled = true
		d.FocusDistance = focus
	else
		d.Enabled = false
	end
end

--- Short blur pulse (WHIP pans).
function Grade.blurPulse(size: number, time: number)
	local bl = blur
	if bl then
		bl.Size = size
		tween(bl, time, { Size = 0 })
	end
end

--- Back to the gameplay look, then removes the cutscene effects.
function Grade.finish(time: number?)
	local t = time or 1
	local snap = snapshot
	if not snap then
		return
	end
	snapshot = nil
	tween(Lighting, t, {
		ClockTime = snap.clockTime,
		ExposureCompensation = snap.exposure,
		Ambient = snap.ambient,
		OutdoorAmbient = snap.outdoorAmbient,
	})
	local a = atmosphere
	if a then
		if createdAtmosphere then
			tween(a, t, { Density = 0, Haze = 0 })
		elseif snap.atmosphere then
			local s = snap.atmosphere
			tween(a, t, {
				Density = s.density,
				Haze = s.haze,
				Color = s.color,
				Decay = s.decay,
				Glare = s.glare,
			})
		end
	end
	local c, b, d, bl = cc, bloom, dof, blur
	if c then
		tween(
			c,
			t,
			{ Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }
		)
	end
	if b then
		tween(b, t, { Intensity = 0 })
	end
	Overlay.setGrain(false)
	Overlay.setVignette(false)
	Overlay.setPillarbox(false, t)
	Overlay.setGlitch(false)
	local created = createdAtmosphere
	task.delay(t + 0.1, function()
		if snapshot then
			return -- a new cutscene started meanwhile and reuses nothing from here
		end
		local effects: { Instance? } = { c, b, d, bl }
		for i = 1, 4 do
			local inst = effects[i]
			if inst then
				inst:Destroy()
			end
		end
		if created and a then
			a:Destroy()
		end
	end)
	cc, bloom, dof, blur, atmosphere = nil, nil, nil, nil, nil
end

return Grade
