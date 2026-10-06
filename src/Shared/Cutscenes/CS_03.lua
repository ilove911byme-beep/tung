--!strict
-- CS-03 "The bell rings by itself" (~20 s), cutscenes.md, after the parkour tutorial.
-- Sunset time-lapse, the bell swings with nobody there, Tralalero and Chimpanzini freeze
-- (the apple drops), the villagers run home and the shutters close one after another, and
-- Giallino sends the players to the inn. World blocks (map.md).
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local data: Types.Cutscene = {
	id = "CS_03",
	title = "The Bell Rings by Itself",
	noSkip = false,
	grade = "DUSK",
	clockTime = 17.5,
	actors = {
		{ id = "Tralalero", model = "Tralalero", at = B(78, 12, 76.5, 0), face = "neutral" },
		{ id = "Chimpanzini", model = "Chimpanzini", at = B(81.6, 12, 77, 0), face = "neutral" },
		{ id = "Giallino", model = "Giallino", at = B(80, 15, 79.2, 180), face = "happy" },
	},
	players = { mode = "hide" },
	hideNpcs = { "Tralalero", "Chimpanzini", "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 20,
			shots = {
				shot({
					-- WIDE: the sun touches the hills, sky time-lapse 17.5 -> 18.6, shadows stretch
					n = "1",
					t0 = 0,
					t1 = 5,
					camera = {
						shot = "WIDE",
						from = B(98, 22, 102),
						lookAt = B(40, 22, 78),
						fov = 62,
						moves = { move({ kind = "PAN_L", angle = 8 }) },
					},
					cues = {
						cue({ clockTo = 18.6, clockTime = 5 }),
						cue({ sfx = "amb_wind_loop", sfxVolume = 0.7 }),
						cue({ music = "SILENCE", musicFade = 2 }),
					},
				}),
				shot({
					-- LOW on the clock tower: the hands stand still, the bell swings by itself x3
					n = "2",
					t0 = 5,
					t1 = 9,
					camera = {
						shot = "LOW",
						low = true,
						from = B(80.3, 12.6, 75),
						lookAt = B(80, 35, 69.5),
						fov = 55,
						moves = { move({ kind = "DOLLY_IN", amount = 0.08 }) },
					},
					cues = {
						cue({ at = 0.2, world = "bellSwing", worldParams = { times = 3 } }),
						cue({ at = 0.4, sfx = "village_bell", sfxSpeed = 0.8, sfxVolume = 0.9 }),
						cue({ at = 1.6, sfx = "village_bell", sfxSpeed = 0.8, sfxVolume = 0.9 }),
						cue({ at = 2.8, sfx = "village_bell", sfxSpeed = 0.8, sfxVolume = 0.9 }),
					},
				}),
				shot({
					-- MED: Tralalero and Chimpanzini freeze and stare at the tower, scared;
					-- Chimpanzini drops his apple
					n = "3",
					t0 = 9,
					t1 = 13,
					camera = {
						shot = "MED",
						from = B(79.8, 13.9, 71.8),
						lookAt = B(79.8, 13.4, 76.8),
						fov = 50,
					},
					cues = {
						cue({ actor = "Tralalero", face = "scared" }),
						cue({ actor = "Chimpanzini", face = "scared" }),
						cue({ actor = "Tralalero", anim = "A-GASP" }),
						cue({
							at = 0.5,
							actor = "Chimpanzini",
							anim = "A-DROP_ITEM",
							effectParams = { part = "Apple" },
						}),
						cue({ at = 0.6, line = "CS03_TRALALERO" }),
					},
				}),
				shot({
					-- WIDE: the villagers run home, doors slam, shutters close one after another
					n = "4",
					t0 = 13,
					t1 = 17,
					camera = {
						shot = "WIDE",
						from = B(93, 24, 95),
						lookAt = B(78, 12, 80),
						fov = 60,
					},
					cues = {
						cue({ actor = "Tralalero", anim = "A-RUN" }),
						cue({
							actor = "Tralalero",
							moveTo = B(83, 12, 97, 180),
							moveTime = 3.6,
							moveEasing = "Linear",
						}),
						cue({ at = 0.2, actor = "Chimpanzini", anim = "A-RUN" }),
						cue({
							at = 0.2,
							actor = "Chimpanzini",
							moveTo = B(69.5, 12, 88.4, 180),
							moveTime = 3.2,
							moveEasing = "Linear",
						}),
						cue({ at = 0.4, world = "shutters", worldParams = { stagger = 0.06 } }),
						cue({ at = 0.5, sfx = "door_close", sfxVolume = 0.8 }),
						cue({ at = 1.4, sfx = "door_close", sfxVolume = 0.7, sfxSpeed = 0.9 }),
						cue({ at = 2.3, sfx = "door_close", sfxVolume = 0.8, sfxSpeed = 1.1 }),
						cue({ at = 3.3, actor = "Tralalero", visible = false }),
						cue({ at = 3.3, actor = "Chimpanzini", visible = false }),
					},
				}),
				shot({
					-- CLOSE on Giallino, the light behind him goes out; happy face, lower voice
					n = "5",
					t0 = 17,
					t1 = 20,
					camera = {
						shot = "CLOSE",
						from = B(80, 15.2, 82.4),
						lookAt = { actor = "Giallino" },
						fov = 45,
						moves = { move({ kind = "DOLLY_IN", amount = 0.1 }) },
					},
					cues = {
						cue({ clockTo = 19, clockTime = 3 }),
						cue({ actor = "Giallino", anim = "A-GIALLINO_IDLE" }),
						cue({ at = 0.2, line = "CS03_GIALLINO_INSIDE" }),
					},
				}),
			},
		},
	},
}

return data
