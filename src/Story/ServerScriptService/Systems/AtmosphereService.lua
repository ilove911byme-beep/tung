--!strict
-- Day / night and atmosphere (brief, gameplay system 8): ClockTime tweens, fog, Atmosphere and
-- sky presets on the server (they replicate), plus scripted glitch effects that the clients play
-- (block recolor, sky flicker, sign text swap, lights out).
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Hud = require(script.Parent.Hud)

local AtmosphereService = {}

type Preset = {
	clock: number,
	brightness: number,
	ambient: Color3,
	outdoor: Color3,
	fogEnd: number,
	fogColor: Color3,
	density: number,
	haze: number,
	color: Color3,
	timeOfDay: string,
}

local rgb = Color3.fromRGB

local PRESETS: { [string]: Preset } = {
	day = {
		clock = 13,
		brightness = 2.2,
		ambient = rgb(110, 110, 120),
		outdoor = rgb(128, 128, 140),
		fogEnd = 900,
		fogColor = rgb(190, 210, 235),
		density = 0.25,
		haze = 0.6,
		color = rgb(200, 215, 235),
		timeOfDay = "Day",
	},
	dusk = {
		clock = 17.8,
		brightness = 1.6,
		ambient = rgb(110, 80, 70),
		outdoor = rgb(140, 100, 90),
		fogEnd = 600,
		fogColor = rgb(240, 160, 110),
		density = 0.32,
		haze = 1.6,
		color = rgb(255, 190, 140),
		timeOfDay = "Day",
	},
	night = {
		clock = 0.2,
		brightness = 0.6,
		ambient = rgb(28, 30, 48),
		outdoor = rgb(36, 40, 64),
		fogEnd = 120,
		fogColor = rgb(18, 20, 36),
		density = 0.45,
		haze = 2,
		color = rgb(50, 58, 90),
		timeOfDay = "Night",
	},
	night_deep = {
		clock = 0.5,
		brightness = 0.3,
		ambient = rgb(14, 14, 22),
		outdoor = rgb(20, 20, 30),
		fogEnd = 60,
		fogColor = rgb(8, 8, 14),
		density = 0.6,
		haze = 2.6,
		color = rgb(30, 30, 44),
		timeOfDay = "Night",
	},
	dawn = {
		clock = 6.3,
		brightness = 1.8,
		ambient = rgb(120, 100, 110),
		outdoor = rgb(150, 120, 130),
		fogEnd = 500,
		fogColor = rgb(250, 200, 200),
		density = 0.2,
		haze = 0.8,
		color = rgb(255, 200, 190),
		timeOfDay = "Day",
	},
	cave = {
		clock = 0,
		brightness = 0,
		ambient = rgb(18, 26, 20),
		outdoor = rgb(18, 26, 20),
		fogEnd = 140,
		fogColor = rgb(10, 16, 12),
		density = 0.45,
		haze = 1.4,
		color = rgb(30, 50, 35),
		timeOfDay = "Night",
	},
	finale = {
		clock = 23.5,
		brightness = 0.5,
		ambient = rgb(40, 20, 30),
		outdoor = rgb(60, 30, 40),
		fogEnd = 90,
		fogColor = rgb(40, 10, 20),
		density = 0.55,
		haze = 2.4,
		color = rgb(90, 40, 60),
		timeOfDay = "Night",
	},
}

local function atmosphere(): Atmosphere
	local a = Lighting:FindFirstChildOfClass("Atmosphere")
	if a then
		return a
	end
	local new = Instance.new("Atmosphere")
	new.Parent = Lighting
	return new
end

local current = "day"

--- Switches to a preset over `time` seconds.
function AtmosphereService.preset(name: string, time: number?)
	local p = PRESETS[name]
	assert(p, "unknown atmosphere preset " .. name)
	current = name
	local t = time or 2
	local info = TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local clock = p.clock
	-- tween the clock the short way forward
	if t > 0 then
		TweenService:Create(Lighting, info, {
			ClockTime = clock,
			Brightness = p.brightness,
			Ambient = p.ambient,
			OutdoorAmbient = p.outdoor,
			FogEnd = p.fogEnd,
			FogColor = p.fogColor,
		}):Play()
		TweenService
			:Create(atmosphere(), info, { Density = p.density, Haze = p.haze, Color = p.color })
			:Play()
	else
		Lighting.ClockTime = clock
		Lighting.Brightness = p.brightness
		Lighting.Ambient = p.ambient
		Lighting.OutdoorAmbient = p.outdoor
		Lighting.FogEnd = p.fogEnd
		Lighting.FogColor = p.fogColor
		local a = atmosphere()
		a.Density = p.density
		a.Haze = p.haze
		a.Color = p.color
	end
	workspace:SetAttribute("TimeOfDay", p.timeOfDay)
end

function AtmosphereService.current(): string
	return current
end

function AtmosphereService.clock(clockTime: number, time: number?)
	if time and time > 0 then
		TweenService:Create(Lighting, TweenInfo.new(time), { ClockTime = clockTime }):Play()
	else
		Lighting.ClockTime = clockTime
	end
end

--- Fog distance override (Chapters 4 and 6: fog almost at arm's length).
function AtmosphereService.fog(fogEnd: number, time: number?)
	TweenService:Create(Lighting, TweenInfo.new(time or 2), { FogEnd = fogEnd }):Play()
end

--- Glitch effects played by the clients: "blockRecolor", "skyFlicker", "signSwap", "lightsOut".
function AtmosphereService.glitch(kind: string, params: { [string]: any }?)
	Hud.worldFx(kind, params or {})
end

function AtmosphereService.init()
	Lighting.GlobalShadows = true
	AtmosphereService.preset("day", 0)
end

return AtmosphereService
