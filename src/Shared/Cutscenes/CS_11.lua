--!strict
-- CS-11 "The square on fire" (~14 s), cutscenes.md — Negatino defeated. The four braziers burn,
-- their beams meet in the middle and strike him; he cracks into blue sparks (A-SHATTER), the
-- color comes back to the screen and the braziers' light is warm.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local S = 4
local function bowl(x: number, z: number): Vector3
	return Vector3.new(x * S, 13.4 * S, z * S)
end
local CENTER = Vector3.new(80 * S, 17 * S, 80 * S)

local data: Types.Cutscene = {
	id = "CS_11",
	title = "The Square on Fire",
	noSkip = false,
	grade = "NIGHT_DEEP",
	clockTime = 23,
	actors = {
		{ id = "Negatino", model = "Negatino", at = B(80, 17, 80, 270), face = "angry" },
	},
	players = { mode = "keep" },
	entry = "main",
	segments = {
		main = {
			length = 14,
			shots = {
				shot({
					-- WIDE: all four braziers burn, their beams meet in the middle
					n = "1",
					t0 = 0,
					t1 = 4,
					camera = {
						shot = "WIDE",
						from = B(92, 21, 92),
						lookAt = B(80, 14, 80),
						fov = 62,
					},
					cues = {
						cue({ music = "SILENCE", musicFade = 1 }),
						cue({ sfx = "negatino_signature", sfxVolume = 0.5, sfxSpeed = 1.6 }),
						cue({
							at = 0.5,
							world = "convergeBeams",
							worldParams = {
								from = { bowl(74, 74), bowl(86, 74), bowl(74, 86), bowl(86, 86) },
								to = CENTER,
								duration = 7,
							},
						}),
					},
				}),
				shot({
					-- CLOSE on Negatino: the beams hit him and he cracks into blue sparks
					n = "2",
					t0 = 4,
					t1 = 8,
					camera = {
						shot = "CLOSE",
						from = B(80, 16.6, 85.4),
						lookAt = { actor = "Negatino" },
						fov = 48,
						shake = 0.2,
					},
					cues = {
						cue({ actor = "Negatino", face = "shocked" }),
						cue({
							at = 1.2,
							actor = "Negatino",
							anim = "A-SHATTER",
							effectParams = { color = Color3.fromRGB(70, 110, 255) },
						}),
						cue({
							at = 1.2,
							sfx = "negatino_signature",
							sfxVolume = 0.9,
							sfxSpeed = 0.6,
						}),
					},
				}),
				shot({
					-- MED on the players: the color returns, the braziers' light is warm
					n = "3",
					t0 = 8,
					t1 = 14,
					grade = "NIGHT",
					gradeTime = 3,
					camera = {
						shot = "MED",
						from = B(84.5, 14.2, 80.5),
						lookAt = { players = true },
						fov = 55,
						moves = { move({ kind = "DOLLY_OUT", amount = 0.15 }) },
					},
					cues = {
						cue({ at = 0.5, sfx = "clue_found", sfxVolume = 0.8 }),
						cue({ at = 1.0, world = "lightsOn", worldParams = { tag = "Lamp" } }),
					},
				}),
			},
		},
	},
}

return data
