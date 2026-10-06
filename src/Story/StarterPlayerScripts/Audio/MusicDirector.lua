--!strict
-- One music state at a time with 2 s crossfades (brief, MusicDirector). Gameplay sets a state
-- (server -> MusicState remote, or MusicDirector.setState); cutscenes can override it with a
-- specific track or "SILENCE" and clear the override afterwards.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local MusicDirector = {}

-- state -> track (nil = silence)
MusicDirector.States = {
	lobby = "music_lobby",
	day = "music_day_village", -- Ch1, Ch3
	dusk = "dusk_piano_theme", -- CS-03
	night = "music_night", -- Ch2, Ch4
	investigation = "music_investigation",
	chase = "music_chase",
	boss = "music_boss", -- Falsino / Negatino / Crudelino
	cave = "music_cave",
	finale = "music_finale",
	ending = "music_ending_dawn", -- Dawn / Sahur, one-shot
	silence = false,
} :: { [string]: string | false }

local ONE_SHOTS = { music_lullaby_stop = true, music_ending_dawn = true, ending_dawn = true }
local DEFAULT_FADE = 2
local DEFAULT_VOLUME = 0.5

type Playing = { name: string?, sound: Sound? }

local stateName = "silence"
local overrideTrack: string? = nil -- track name or "SILENCE"
local playing: Playing = { name = nil, sound = nil }

local function switchTo(track: string?, fade: number, volume: number?)
	if playing.name == track and track ~= nil and not ONE_SHOTS[track] then
		if playing.sound and volume then
			Audio.fadeTo(playing.sound, volume, fade)
		end
		return
	end
	Audio.stop(playing.sound, fade)
	playing = { name = track, sound = nil }
	if not track then
		return
	end
	local target = volume or DEFAULT_VOLUME
	local sound =
		Audio.create(track, nil, { volume = 0, looped = not ONE_SHOTS[track], group = "Music" })
	if sound then
		sound:Play()
		Audio.fadeTo(sound, target, math.max(fade, 0.05))
		playing.sound = sound
	end
end

local function currentTarget(): string?
	if overrideTrack then
		return if overrideTrack == "SILENCE" then nil else overrideTrack
	end
	local track = MusicDirector.States[stateName]
	if typeof(track) == "string" then
		return track
	end
	return nil
end

--- Gameplay music state (keys of MusicDirector.States).
function MusicDirector.setState(state: string, fade: number?)
	if MusicDirector.States[state] == nil then
		warn("[MusicDirector] unknown state " .. state)
		return
	end
	stateName = state
	if not overrideTrack then
		switchTo(currentTarget(), fade or DEFAULT_FADE)
	end
end

--- Cutscene override: a track name or "SILENCE".
function MusicDirector.override(track: string, fade: number?, volume: number?)
	overrideTrack = track
	switchTo(currentTarget(), fade or DEFAULT_FADE, volume)
end

--- Back to the gameplay state.
function MusicDirector.clearOverride(fade: number?)
	if overrideTrack == nil then
		return
	end
	overrideTrack = nil
	switchTo(currentTarget(), fade or DEFAULT_FADE)
end

function MusicDirector.state(): string
	return stateName
end

function MusicDirector.init()
	Remotes.get(Remotes.Names.MusicState).OnClientEvent:Connect(function(state: string)
		if typeof(state) == "string" then
			MusicDirector.setState(state)
		end
	end)
end

return MusicDirector
