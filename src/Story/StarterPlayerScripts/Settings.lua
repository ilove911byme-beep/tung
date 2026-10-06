--!strict
-- Client settings (session only, no DataStore). The SETTINGS page of the main menu (Phase 5.5)
-- writes these; audio, subtitles, voices and camera shake read them.
local Settings = {}

export type Values = {
	musicVolume: number,
	ambienceVolume: number,
	sfxVolume: number,
	voiceVolume: number,
	subtitles: boolean,
	voices: boolean,
	cameraShake: boolean,
	graphics: "low" | "high",
}

local values: Values = {
	musicVolume = 0.8,
	ambienceVolume = 0.8,
	sfxVolume = 1,
	voiceVolume = 1,
	subtitles = true,
	voices = true,
	cameraShake = true,
	graphics = "high",
}

local changed = Instance.new("BindableEvent")
Settings.Changed = changed.Event -- (key, value)

function Settings.get(): Values
	return values
end

function Settings.set(key: string, value: any)
	(values :: any)[key] = value
	changed:Fire(key, value)
end

return Settings
