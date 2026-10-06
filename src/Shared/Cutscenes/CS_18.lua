--!strict
-- CS-18 "Bombardiro's last run" (~26 s, tragic), cutscenes.md: only if Bombardiro is free, after
-- the 3rd hit. He comes round over the hole for the last time, drops his bomb, Crudelino is
-- stunned and shoots a red beam into the sky; it hits Bombardiro's wing, he spirals down and
-- lies at the edge of the hole, and closes his eyes. (He lives in the good and secret endings.)
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, B = Kit.cue, Kit.shot, Kit.B

local data: Types.Cutscene = {
	id = "CS_18",
	title = "Bombardiro's Last Run",
	noSkip = false,
	grade = "CAVE",
	clockTime = 5,
	actors = {
		{ id = "Bombardiro", model = "Bombardiro", at = B(112, 36, 20.5, 90), face = "happy" },
		{
			id = "Bomb",
			model = "Bomb",
			at = B(135.5, 30, 20.5),
			visible = false,
			footsteps = false,
		},
		{ id = "Crudelino", model = "Crudelino", at = B(134.5, -23.6, 20.5, 0), face = "angry" },
	},
	players = { mode = "keep" },
	hideNpcs = { "Bombardiro", "Crudelino" },
	entry = "main",
	segments = {
		main = {
			length = 26,
			shots = {
				shot({
					-- LOW from the cave up through the hole: Bombardiro comes round for the third time
					n = "1",
					t0 = 0,
					t1 = 5,
					camera = {
						shot = "LOW",
						low = true,
						from = B(135.5, -22.5, 21),
						lookAt = B(135.5, 30, 20.5),
						fov = 64,
					},
					cues = {
						cue({ actor = "Bombardiro", anim = "A-FLY" }),
						cue({
							actor = "Bombardiro",
							moveTo = B(158, 36, 20.5, 90),
							moveTime = 5,
							moveEasing = "Linear",
						}),
						cue({ at = 0.4, line = "CS18_BOMBARDIRO_ONEMORE" }),
						cue({ at = 2.4, actor = "Bomb", visible = true }),
						cue({
							at = 2.4,
							actor = "Bomb",
							moveTo = B(135.5, 4, 20.5),
							moveTime = 2.6,
							moveEasing = "QuadIn",
						}),
					},
				}),
				shot({
					-- WIDE: the bomb falls, Crudelino is stunned (dust and blocks, no fire)
					n = "2",
					t0 = 5,
					t1 = 9,
					camera = {
						shot = "WIDE",
						from = B(126.5, -20, 27.5),
						lookAt = B(134.5, -23, 20.5),
						fov = 60,
						shake = 0.2,
					},
					cues = {
						cue({
							actor = "Bomb",
							moveTo = B(134.5, -23.2, 20.5),
							moveTime = 0.8,
							moveEasing = "QuadIn",
						}),
						cue({ at = 0.8, actor = "Bomb", visible = false }),
						cue({ at = 0.8, sfx = "explosion_boom", sfxVolume = 1 }),
						cue({
							at = 0.8,
							effect = "DirtBurst",
							effectAt = B(134.5, -25, 20.5),
							effectParams = { count = 40, radius = 4 },
						}),
						cue({
							at = 0.8,
							world = "debrisBurst",
							worldParams = {
								at = Vector3.new(134.5 * 4, -24 * 4, 20.5 * 4),
								count = 16,
							},
						}),
						cue({ at = 0.9, actor = "Crudelino", face = "shocked" }),
						cue({
							at = 0.9,
							actor = "Crudelino",
							anim = "A-CRUDELINO_DASH",
							animSpeed = 0.6,
						}),
					},
				}),
				shot({
					-- CLOSE on Crudelino: he "looks" up and throws a red beam into the sky
					n = "3",
					t0 = 9,
					t1 = 13,
					camera = {
						shot = "CLOSE",
						low = true,
						from = B(131.5, -24.2, 22.5),
						lookAt = { actor = "Crudelino" },
						fov = 50,
					},
					cues = {
						cue({ actor = "Crudelino", face = "angry" }),
						cue({ actor = "Crudelino", faceToward = B(135.5, 40, 20.5) }),
						cue({
							at = 1.2,
							world = "beam",
							worldParams = {
								at = Vector3.new(134.5 * 4, -24 * 4, 20.5 * 4),
								duration = 3.5,
								color = Color3.fromRGB(255, 40, 30),
								width = 3,
							},
						}),
						cue({ at = 1.2, sfx = "crudelino_signature", sfxVolume = 1 }),
					},
				}),
				shot({
					-- WIDE outside the cave: the beam hits Bombardiro's wing, he spirals down
					n = "4",
					t0 = 13,
					t1 = 18,
					camera = {
						shot = "WIDE",
						from = B(152, 27, 35),
						lookAt = B(140, 26, 22),
						fov = 60,
					},
					cues = {
						cue({
							actor = "Bombardiro",
							moveTo = B(138, 32, 21.5, 270),
							moveTime = 0.05,
						}),
						cue({ at = 0.3, actor = "Bombardiro", face = "shocked" }),
						cue({
							at = 0.3,
							actor = "Bombardiro",
							effect = "HidePart",
							effectParams = { part = "WingR" },
						}),
						cue({
							at = 0.3,
							world = "debrisBurst",
							worldParams = {
								at = Vector3.new(138 * 4, 32 * 4, 21.5 * 4),
								count = 10,
								colors = { Color3.fromRGB(138, 144, 152) },
							},
						}),
						cue({
							at = 0.4,
							actor = "Bombardiro",
							moveTo = B(139.5, 18.8, 24.6, 200),
							moveTime = 4,
							moveEasing = "QuadIn",
						}),
						cue({ at = 0.6, sfx = "explosion_boom", sfxVolume = 0.6, sfxSpeed = 0.4 }),
					},
				}),
				shot({
					-- MED: Bombardiro lies at the edge of the hole, his wing broken, tired
					n = "5",
					t0 = 18,
					t1 = 22,
					camera = {
						shot = "MED",
						from = B(141.6, 19.6, 27.6),
						lookAt = { actor = "Bombardiro", part = "Head" },
						fov = 50,
					},
					cues = {
						cue({ actor = "Bombardiro", stopAnim = "A-FLY" }),
						cue({ actor = "Bombardiro", anim = "A-LIE_DOWN" }),
						cue({ actor = "Bombardiro", face = "tired" }),
						cue({ at = 0.6, line = "CS18_BOMBARDIRO_TUNNEL" }),
						cue({ music = "music_tragic", musicVolume = 0.3, musicFade = 1 }),
					},
				}),
				shot({
					-- CLOSE: his eyes close; silence; then the ceiling starts to crumble
					n = "6",
					t0 = 22,
					t1 = 26,
					camera = {
						shot = "CLOSE",
						from = B(140.6, 19.4, 25.9),
						lookAt = { actor = "Bombardiro", part = "Head" },
						fov = 40,
					},
					cues = {
						cue({ at = 0.4, actor = "Bombardiro", face = "eyes_closed" }),
						cue({ at = 0.5, music = "SILENCE", musicFade = 1 }),
						cue({ at = 2.8, sfx = "block_break_stone", sfxVolume = 1, sfxSpeed = 0.5 }),
					},
				}),
			},
		},
	},
}

return data
