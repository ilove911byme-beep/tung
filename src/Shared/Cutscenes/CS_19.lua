--!strict
-- CS-19 "Cave-in" (~8 s), cutscenes.md: the ceiling falls in blocks, Crudelino is pinned and his
-- red light blinks from under the rocks; POV toward the crumbling platforms that lead up ->
-- BLEND into control (the escape climb).
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local data: Types.Cutscene = {
	id = "CS_19",
	title = "Cave-in",
	noSkip = false,
	grade = "CAVE",
	actors = {
		{ id = "Crudelino", model = "Crudelino", at = B(133.5, -23.4, 18.5, 0), face = "angry" },
	},
	players = { mode = "keep" },
	hideNpcs = { "Crudelino" },
	entry = "main",
	segments = {
		main = {
			length = 8,
			shots = {
				shot({
					-- WIDE: the ceiling comes down in blocks, Crudelino is pinned, his light blinks
					n = "1",
					t0 = 0,
					t1 = 4,
					camera = {
						shot = "WIDE",
						from = B(140, -20.5, 28),
						lookAt = B(133.5, -23, 18.5),
						fov = 62,
						shake = 0.35,
					},
					cues = {
						cue({
							world = "debrisBurst",
							worldParams = {
								at = Vector3.new(133.5 * 4, -12 * 4, 18.5 * 4),
								count = 40,
								down = true,
							},
						}),
						cue({
							at = 0.2,
							world = "debrisBurst",
							worldParams = {
								at = Vector3.new(128 * 4, -12 * 4, 24 * 4),
								count = 20,
								down = true,
							},
						}),
						cue({ sfx = "explosion_boom", sfxVolume = 1, sfxSpeed = 0.5 }),
						cue({ at = 0.6, sfx = "block_break_stone", sfxVolume = 1, sfxSpeed = 0.6 }),
						cue({
							at = 1.0,
							actor = "Crudelino",
							moveTo = B(133.5, -24.6, 18.5, 0),
							moveTime = 0.4,
							moveEasing = "QuadIn",
						}),
						cue({ at = 1.4, actor = "Crudelino", light = { glow = 0.2, time = 0.1 } }),
						cue({ at = 1.8, actor = "Crudelino", light = { glow = 3, time = 0.1 } }),
						cue({ at = 2.4, actor = "Crudelino", light = { glow = 0.2, time = 0.1 } }),
						cue({ at = 3.0, actor = "Crudelino", light = { glow = 2.5, time = 0.1 } }),
					},
				}),
				shot({
					-- POV: ahead, the crumbling platforms lead up -> BLEND into control
					n = "2",
					t0 = 4,
					t1 = 8,
					camera = {
						shot = "POV",
						from = B(134.5, -23.4, 26),
						lookAt = B(135.5, -14, 21),
						fov = 64,
						moves = { move({ kind = "HANDHELD", amount = 0.12 }) },
					},
					transitionOut = { kind = "BLEND", seconds = 0.6 },
					cues = { cue({ music = "music_chase", musicVolume = 0.5, musicFade = 1 }) },
				}),
			},
		},
	},
}

return data
