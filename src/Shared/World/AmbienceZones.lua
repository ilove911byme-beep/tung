--!strict
-- Ambience by zone and time of day (roblox_horror_prompt.md, AmbienceDirector).
-- Boxes are in BLOCKS (map.md coordinates). The first matching zone wins, "Outdoors" is the
-- fallback. River water and the tavern fireplace are 3D loops on tagged Parts instead
-- (CollectionService tag "AmbienceEmitter", attribute Sound = name), see AmbienceDirector.

export type Layer = { sound: string, volume: number }
export type OneShot = { sounds: { string }, min: number, max: number, volume: number }

export type Zone = {
	id: string,
	min: { number }?, -- {x, y, z} blocks
	max: { number }?,
	center: { number }?, -- {x, z} blocks, used with radius
	radius: number?,
	maxY: number?, -- circle zones only: below this height (blocks)
	day: { Layer },
	night: { Layer },
	dayOneShots: { OneShot }?,
	nightOneShots: { OneShot }?,
	rain: boolean, -- amb_rain_loop allowed when workspace attribute Rain = true
}

local CAVE_EERIE: OneShot = {
	sounds = { "cave_eerie_1", "cave_eerie_2", "cave_eerie_3", "cave_eerie_4" },
	min = 40,
	max = 90,
	volume = 0.5,
}

local OWL: OneShot = { sounds = { "owl_hoot" }, min = 25, max = 60, volume = 0.45 }

local OUTDOOR_DAY = {
	{ sound = "amb_birds_loop", volume = 0.35 },
	{ sound = "amb_wind_loop", volume = 0.15 },
}

local OUTDOOR_NIGHT = {
	{ sound = "amb_crickets_loop", volume = 0.35 },
	{ sound = "ambience_night_loop", volume = 0.45 },
}

local Zones: { Zone } = {
	{
		id = "LavaCave", -- underground E, Gear 2
		min = { 96, -30, 36 },
		max = { 120, -10, 60 },
		day = {
			{ sound = "ambience_cave_loop", volume = 0.4 },
			{ sound = "amb_lava_loop", volume = 0.6 },
		},
		night = {
			{ sound = "ambience_cave_loop", volume = 0.4 },
			{ sound = "amb_lava_loop", volume = 0.6 },
		},
		dayOneShots = { CAVE_EERIE },
		nightOneShots = { CAVE_EERIE },
		rain = false,
	},
	{
		id = "Mineshaft", -- underground A-H (north-east), below the surface
		min = { 95, -40, 0 },
		max = { 160, 9, 70 },
		day = { { sound = "ambience_cave_loop", volume = 0.55 } },
		night = { { sound = "ambience_cave_loop", volume = 0.55 } },
		dayOneShots = { CAVE_EERIE },
		nightOneShots = { CAVE_EERIE },
		rain = false,
	},
	{
		id = "Tavern", -- the fireplace loop is a 3D emitter inside
		min = { 61.5, 11, 74.5 },
		max = { 70.5, 21, 85.5 },
		day = { { sound = "amb_birds_loop", volume = 0.08 } },
		night = { { sound = "ambience_night_loop", volume = 0.15 } },
		rain = false,
	},
	{
		id = "Mountains", -- west ridge, wind louder
		min = { 0, 0, 0 },
		max = { 25, 80, 160 },
		day = {
			{ sound = "amb_wind_loop", volume = 0.55 },
			{ sound = "amb_birds_loop", volume = 0.15 },
		},
		night = {
			{ sound = "amb_wind_loop", volume = 0.5 },
			{ sound = "ambience_night_loop", volume = 0.35 },
		},
		nightOneShots = { OWL },
		rain = true,
	},
	{
		id = "TungHill", -- hill +6 blocks, wind louder
		center = { 80, 126 },
		radius = 12,
		maxY = 40,
		day = {
			{ sound = "amb_wind_loop", volume = 0.5 },
			{ sound = "amb_birds_loop", volume = 0.25 },
		},
		night = {
			{ sound = "amb_wind_loop", volume = 0.45 },
			{ sound = "amb_crickets_loop", volume = 0.25 },
			{ sound = "ambience_night_loop", volume = 0.4 },
		},
		nightOneShots = { OWL },
		rain = true,
	},
	{
		id = "Outdoors",
		day = OUTDOOR_DAY,
		night = OUTDOOR_NIGHT,
		nightOneShots = { OWL },
		rain = true,
	},
}

return Zones
