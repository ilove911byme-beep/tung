--!strict
-- CS-08 "Falsino melts" (~12 s), cutscenes.md: the cube cracks and melts into a yellow puddle
-- (A-FALSINO_MELT), Giallino's happy face looks up from the puddle with a laugh stretched down
-- in pitch, the puddle steams away and Falsino's voice comes out of the steam.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local data: Types.Cutscene = {
	id = "CS_08",
	title = "Falsino Melts",
	noSkip = false,
	grade = "DUSK",
	clockTime = 16,
	actors = {
		{ id = "Falsino", model = "Falsino", at = B(76.5, 12.5, 80, 270), face = "smile_crooked" },
	},
	players = { mode = "keep" },
	hideNpcs = { "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 12,
			shots = {
				shot({
					-- MED: the cube cracks, yellow liquid runs out of the cracks, it sinks into a puddle
					n = "1",
					t0 = 0,
					t1 = 5,
					camera = {
						shot = "MED",
						from = B(72.6, 13.8, 81.6),
						lookAt = B(76.5, 12.7, 80),
						fov = 50,
					},
					cues = {
						cue({ music = "SILENCE", musicFade = 1.5 }),
						cue({ actor = "Falsino", face = "shocked" }),
						cue({ actor = "Falsino", anim = "A-FALSINO_MELT" }),
						cue({ at = 0.3, sfx = "glitch_burst", sfxVolume = 0.4, sfxSpeed = 0.6 }),
					},
				}),
				shot({
					-- CLOSE on the puddle: Giallino's happy face is reflected in it; a slow, low laugh
					n = "2",
					t0 = 5,
					t1 = 9,
					camera = {
						shot = "CLOSE",
						high = true,
						from = B(75.6, 13.6, 80.4),
						lookAt = B(76.5, 12.1, 80),
						fov = 40,
						moves = { move({ kind = "DOLLY_IN", amount = 0.12 }) },
					},
					cues = {
						cue({ actor = "Falsino", face = "happy" }),
						cue({ at = 0.4, sfx = "giallino_blip_1", sfxSpeed = 0.5, sfxVolume = 0.8 }),
						cue({ at = 0.9, sfx = "giallino_blip_3", sfxSpeed = 0.45, sfxVolume = 0.8 }),
						cue({ at = 1.4, sfx = "giallino_blip_2", sfxSpeed = 0.4, sfxVolume = 0.8 }),
					},
				}),
				shot({
					-- WIDE: the puddle steams away in yellow vapour; Falsino's voice from the steam
					n = "3",
					t0 = 9,
					t1 = 12,
					camera = {
						shot = "WIDE",
						from = B(70.5, 15, 84),
						lookAt = B(76.5, 13.5, 80),
						fov = 56,
					},
					cues = {
						cue({
							actor = "Falsino",
							effect = "PixelDissolve",
							effectParams = { duration = 2.4, color = Color3.fromRGB(255, 216, 58) },
						}),
						cue({ at = 0.2, line = "CS08_FALSINO" }),
					},
				}),
			},
		},
	},
}

return data
