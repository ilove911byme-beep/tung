--!strict
-- CS-10 "Night in seconds" (lock, ~30 s), cutscenes.md — the birth of Negatino. The sun drops
-- in three seconds, a grass block flashes red and the signs rewrite themselves to SAY YES,
-- Giallino's face breaks while he stutters about where you hid, he darkens to blue and
-- stretches into Negatino, the lamps go out in a circle, and only the player's lantern burns.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local S = 4
local function slot(x: number, z: number): Vector3
	return Vector3.new(x * S, 12 * S, z * S)
end

local FORM_AT = B(76.2, 15, 80, 270)

local data: Types.Cutscene = {
	id = "CS_10",
	title = "Night in Seconds",
	noSkip = true,
	grade = "DUSK",
	clockTime = 18.3,
	actors = {
		{ id = "Giallino", model = "Giallino", at = FORM_AT, face = "happy" },
		{ id = "Negatino", model = "Negatino", at = FORM_AT, face = "neutral", visible = false },
		{ id = "Lantern", model = "HandLantern", at = B(73.4, 12.9, 80.6), footsteps = false },
	},
	players = {
		mode = "slots",
		anchor = "Anchor_Origin",
		slots = {
			slot(72.6, 79),
			slot(72.6, 81),
			slot(71.4, 77.6),
			slot(71.4, 82.4),
			slot(70.6, 80),
			slot(73.4, 78.2),
		},
		yaw = -90,
	},
	hideNpcs = { "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 30,
			shots = {
				shot({
					-- WIDE time-lapse: the sun literally falls behind the hills in 3 s, the light goes out in a wave
					n = "1",
					t0 = 0,
					t1 = 4,
					camera = {
						shot = "WIDE",
						from = B(97, 22, 101),
						lookAt = B(40, 22, 78),
						fov = 62,
					},
					cues = {
						cue({ music = "SILENCE", musicFade = 0.5 }),
						cue({ clockTo = 21.5, clockTime = 3 }),
						cue({ sfx = "negatino_signature", sfxVolume = 0.5, sfxSpeed = 0.4 }),
					},
				}),
				shot({
					-- ECU on a grass block -> GLITCH CUT: the grass flashes red, the signs rewrite to SAY YES
					n = "2",
					t0 = 4,
					t1 = 8,
					grade = "NIGHT",
					gradeTime = 0.5,
					transitionIn = { kind = "GLITCH_CUT", seconds = 0.25 },
					camera = {
						shot = "ECU",
						from = B(75, 13.3, 73.8),
						lookAt = B(75, 12.9, 71.3),
						fov = 40,
					},
					cues = {
						cue({ world = "blockRecolor", worldParams = { duration = 0.7 } }),
						cue({ at = 0.9, world = "signSwap", worldParams = { text = "SAY YES" } }),
						cue({ at = 0.9, sfx = "glitch_burst", sfxVolume = 0.8 }),
					},
				}),
				shot({
					-- CLOSE on Giallino, HANDHELD: the face breaks (screen_static), the voice stutters
					n = "3",
					t0 = 8,
					t1 = 14,
					camera = {
						shot = "CLOSE",
						from = B(73.2, 15.1, 80),
						lookAt = { actor = "Giallino" },
						fov = 46,
						moves = { move({ kind = "HANDHELD", amount = 0.12 }) },
					},
					cues = {
						cue({ actor = "Giallino", anim = "A-GIALLINO_IDLE" }),
						cue({ actor = "Giallino", face = "screen_static", faceFor = 0.4 }),
						cue({ at = 0.5, line = "CS10_GIALLINO_WHY" }),
						cue({ at = 2.6, actor = "Giallino", face = "screen_static", faceFor = 0.2 }),
						cue({ at = 4.4, actor = "Giallino", face = "screen_static", faceFor = 0.3 }),
					},
				}),
				shot({
					-- MED: his light darkens to blue, the cube stretches and dims (A-TRANSFORM_NEGATINO)
					n = "4",
					t0 = 14,
					t1 = 20,
					grade = "NIGHT_DEEP",
					gradeTime = 4,
					camera = {
						shot = "MED",
						from = B(71.4, 14.6, 82.2),
						lookAt = B(76.2, 15.4, 80),
						fov = 52,
					},
					cues = {
						cue({ actor = "Giallino", stopAnim = "A-GIALLINO_IDLE" }),
						cue({ actor = "Giallino", face = "neutral" }),
						cue({ actor = "Giallino", anim = "A-TRANSFORM_NEGATINO" }),
						cue({ at = 0.3, sfx = "negatino_signature", sfxVolume = 0.9 }),
						cue({ at = 3.2, actor = "Giallino", visible = false }),
						cue({ at = 3.2, actor = "Negatino", visible = true }),
						cue({
							at = 3.2,
							actor = "Negatino",
							anim = "A-GIALLINO_IDLE",
							animSpeed = 0.5,
						}),
					},
				}),
				shot({
					-- LOW: Negatino over the square, his mouth a flat line; the lamps go out one by one in a circle
					n = "5",
					t0 = 20,
					t1 = 26,
					camera = {
						shot = "LOW",
						low = true,
						from = B(73.4, 12.6, 80.4),
						lookAt = { actor = "Negatino" },
						fov = 58,
						moves = { move({ kind = "ORBIT", angle = -20 }) },
					},
					cues = {
						cue({
							actor = "Negatino",
							moveTo = B(78, 17.5, 80, 270),
							moveTime = 4,
							moveEasing = "SineInOut",
						}),
						cue({
							at = 0.3,
							world = "lightsOut",
							worldParams = {
								tag = "Lamp",
								stagger = 0.08,
								center = Vector3.new(80 * 4, 12 * 4, 80 * 4),
							},
						}),
						cue({ at = 1.0, line = "CS10_NEGATINO" }),
					},
				}),
				shot({
					-- CLOSE on the player's lantern, the only light left: it flickers but keeps burning
					n = "6",
					t0 = 26,
					t1 = 30,
					camera = {
						shot = "CLOSE",
						from = B(72.6, 13.3, 81.4),
						lookAt = { actor = "Lantern" },
						fov = 40,
						moves = { move({ kind = "DOLLY_IN", amount = 0.12 }) },
					},
					cues = {
						cue({ actor = "Lantern", light = { glow = 0.4, time = 0.1 } }),
						cue({ at = 0.3, actor = "Lantern", light = { glow = 1.8, time = 0.15 } }),
						cue({ at = 0.9, actor = "Lantern", light = { glow = 0.6, time = 0.1 } }),
						cue({ at = 1.2, actor = "Lantern", light = { glow = 1.6, time = 0.3 } }),
						cue({ at = 0.6, sfx = "heartbeat_loop", sfxVolume = 0.8 }),
					},
				}),
			},
		},
	},
}

return data
