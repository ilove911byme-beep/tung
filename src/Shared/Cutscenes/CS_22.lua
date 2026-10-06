--!strict
-- CS-22 "The hands" (~20 s), cutscenes.md, after the party QTE of phase 4: the three Truth Gears
-- slide into their sockets and start turning (A-GEARS_TURN); outside, Giallino Totale clings
-- to the clock hands, which creak forward while he screams in every voice; his cracked face:
-- "Please. Don't make me alone again."
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local data: Types.Cutscene = {
	id = "CS_22",
	title = "The Hands",
	noSkip = false,
	grade = "GLITCH",
	clockTime = 5,
	actors = {
		{ id = "Gears", model = "Gears", at = B(80, 35.2, 65.6, 270), footsteps = false },
		{
			id = "Totale",
			model = "GiallinoTotale",
			at = B(80, 36, 72.4, 0),
			face = "screen_static",
		},
	},
	players = { mode = "keep" },
	hideNpcs = { "GiallinoTotale" },
	entry = "main",
	segments = {
		main = {
			length = 20,
			shots = {
				shot({
					-- ECU, the mechanism: three gears slide into the sockets and start turning
					n = "1",
					t0 = 0,
					t1 = 6,
					camera = {
						shot = "ECU",
						from = B(80.6, 35.6, 67.4),
						lookAt = B(80, 35.3, 64.6),
						fov = 42,
					},
					cues = {
						cue({
							actor = "Gears",
							moveTo = B(80, 35.2, 64.6, 270),
							moveTime = 1.6,
							moveEasing = "QuadOut",
						}),
						cue({ at = 1.7, actor = "Gears", anim = "A-GEARS_TURN" }),
						cue({ at = 1.7, sfx = "clock_time_stop", sfxVolume = 0.9, sfxSpeed = 1.4 }),
						cue({ at = 1.7, sfx = "lever_click", sfxVolume = 0.8 }),
					},
				}),
				shot({
					-- WIDE, the clock face: Giallino Totale stuck to the hands, they creak forward; he
					-- screams in every voice
					n = "2",
					t0 = 6,
					t1 = 12,
					camera = {
						shot = "WIDE",
						from = B(84, 34, 86),
						lookAt = B(80, 36, 70.5),
						fov = 56,
						shake = 0.2,
					},
					cues = {
						cue({ actor = "Totale", anim = "A-SCALE_6" }),
						cue({ actor = "Totale", light = { glow = 4 } }),
						cue({ world = "clockHands", worldParams = { turns = 1, duration = 5.6 } }),
						cue({ sfx = "falsino_signature", sfxVolume = 0.8 }),
						cue({ at = 0.3, sfx = "negatino_signature", sfxVolume = 0.8 }),
						cue({ at = 0.6, sfx = "crudelino_signature", sfxVolume = 0.9 }),
						cue({ at = 0.9, sfx = "giallino_mood_drop", sfxVolume = 0.8 }),
						cue({ at = 1.0, actor = "Totale", anim = "A-CRUDELINO_DASH" }),
					},
				}),
				shot({
					-- CLOSE on Giallino's face: cracks all over the cube, the light blinks
					n = "3",
					t0 = 12,
					t1 = 20,
					camera = {
						shot = "CLOSE",
						from = B(80, 36.2, 84),
						lookAt = { actor = "Totale" },
						fov = 40,
						moves = { move({ kind = "DOLLY_IN", amount = 0.15 }) },
					},
					cues = {
						cue({ actor = "Totale", face = "sad" }),
						cue({ actor = "Totale", light = { glow = 0.5, time = 0.1 } }),
						cue({ at = 0.4, actor = "Totale", light = { glow = 4, time = 0.1 } }),
						cue({ at = 1.2, actor = "Totale", light = { glow = 1, time = 0.1 } }),
						cue({ at = 1.6, actor = "Totale", light = { glow = 4, time = 0.2 } }),
						cue({ at = 0.8, line = "CS22_TOTALE_PLEASE" }),
						cue({ at = 4.5, actor = "Totale", face = "screen_static", faceFor = 0.3 }),
					},
				}),
			},
		},
	},
}

return data
