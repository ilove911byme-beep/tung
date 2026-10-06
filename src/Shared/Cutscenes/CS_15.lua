--!strict
-- CS-15 "Door 67" (~8 s), cutscenes.md: the digits 6... 7 light up on the keypad, the mine door
-- swings open, cold wind blows out and something yellow flickers deep inside.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local data: Types.Cutscene = {
	id = "CS_15",
	title = "Door 67",
	noSkip = false,
	grade = "NIGHT",
	clockTime = 4.5,
	actors = {
		{
			id = "Flicker",
			model = "Giallino",
			at = B(122, 13.2, 25.6, 180),
			face = "off",
			visible = false,
		},
	},
	players = { mode = "keep" },
	entry = "main",
	segments = {
		main = {
			length = 8,
			shots = {
				shot({
					-- ECU on the keypad: the digits come up, 6... 7, clicks
					n = "1",
					t0 = 0,
					t1 = 4,
					camera = {
						shot = "ECU",
						from = B(123.6, 13.25, 31.6),
						lookAt = B(123.6, 13.25, 30.5),
						fov = 36,
					},
					cues = {
						cue({
							at = 0.4,
							world = "keypadDigits",
							worldParams = { text = "67", gap = 1.2 },
						}),
					},
				}),
				shot({
					-- WIDE: the gates part, cold wind blows out, something yellow flickers in the depth
					n = "2",
					t0 = 4,
					t1 = 8,
					camera = {
						shot = "WIDE",
						from = B(122, 14, 37),
						lookAt = B(122, 13.4, 29),
						fov = 55,
						moves = { move({ kind = "DOLLY_IN", amount = 0.2 }) },
					},
					cues = {
						cue({ world = "doorOpen", worldParams = { tag = "MineDoor", time = 2 } }),
						cue({ sfx = "door_open", sfxVolume = 1, sfxSpeed = 0.6 }),
						cue({ at = 0.4, sfx = "ambience_cave_loop", sfxVolume = 0.7 }),
						cue({ at = 0.4, sfx = "amb_wind_loop", sfxVolume = 0.8 }),
						cue({ at = 1.6, actor = "Flicker", visible = true, light = { glow = 2 } }),
						cue({ at = 1.9, actor = "Flicker", visible = false }),
						cue({ at = 2.5, actor = "Flicker", visible = true }),
						cue({ at = 2.7, actor = "Flicker", visible = false }),
					},
				}),
			},
		},
	},
}

return data
