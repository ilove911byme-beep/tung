--!strict
-- CS-04 "The first knock" (lock, ~26 s), cutscenes.md. Inside the tavern by the fire: the lamp
-- flickers out, a yellow square light passes the window, three seconds of total silence, three
-- knocks shake the door, the narrator over black, and Giallino whispering right into the
-- camera. Choice 2-2 follows (chapter script). World blocks (map.md); the tavern spans
-- x 61.5-70.5, z 74.5-85.5, fireplace on the west wall, door on the east wall at z 84.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local S = 4
local function slot(x: number, z: number): Vector3
	return Vector3.new(x * S, 12 * S, z * S)
end

local data: Types.Cutscene = {
	id = "CS_04",
	title = "The First Knock",
	noSkip = true,
	grade = "NIGHT",
	clockTime = 23,
	actors = {
		{
			id = "Giallino",
			model = "Giallino",
			at = B(65.6, 13.7, 79.5, 90),
			face = "happy",
			visible = false,
		},
		{
			id = "Outside",
			model = "Giallino",
			at = B(74, 14.4, 80, 270),
			face = "off",
			visible = false,
		},
	},
	players = {
		mode = "slots",
		anchor = "Anchor_Origin",
		-- around the fireplace, facing west (yaw 90 = turned left from north)
		slots = {
			slot(65.2, 78.2),
			slot(65.2, 80.2),
			slot(66.4, 77.4),
			slot(66.4, 81),
			slot(67.4, 78.6),
			slot(67.4, 80.4),
		},
		yaw = 90,
	},
	hideNpcs = { "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 26,
			shots = {
				shot({
					-- WIDE inside the tavern, the players by the fire; the flame leans as if in a draft
					n = "1",
					t0 = 0,
					t1 = 5,
					camera = {
						shot = "WIDE",
						from = B(69.3, 15.2, 75.9),
						lookAt = B(64, 12.9, 79.2),
						fov = 66,
						moves = { move({ kind = "DOLLY_IN", amount = 0.06 }) },
					},
					cues = {
						cue({ music = "SILENCE", musicFade = 1 }),
						cue({ sfx = "amb_fireplace_loop", sfxVolume = 0.6 }),
					},
				}),
				shot({
					-- CLOSE on the lamp: it flickers and goes out (click)
					n = "2",
					t0 = 5,
					t1 = 8,
					camera = {
						shot = "CLOSE",
						from = B(64.6, 18.1, 81.6),
						lookAt = B(66, 19.4, 80),
						fov = 42,
					},
					cues = {
						cue({
							at = 1.0,
							world = "lampFlicker",
							worldParams = { tag = "TavernLamp" },
						}),
					},
				}),
				shot({
					-- MED on the window, RACK from the frame to the street: a yellow square light
					-- passes for a split second
					n = "3",
					t0 = 8,
					t1 = 11,
					camera = {
						shot = "MED",
						from = B(67.4, 13.8, 80.3),
						lookAt = B(70.5, 13.6, 80),
						fov = 46,
						rack = {
							from = B(70.4, 13.6, 80),
							to = B(74, 14.2, 80),
							at = 0.6,
							time = 0.6,
						},
					},
					cues = {
						cue({ at = 1.3, actor = "Outside", visible = true, light = { glow = 2.5 } }),
						cue({
							at = 1.3,
							actor = "Outside",
							moveTo = B(74, 14.4, 82, 270),
							moveTime = 0.5,
							moveEasing = "Linear",
						}),
						cue({ at = 1.75, actor = "Outside", visible = false }),
					},
				}),
				shot({
					-- WIDE, static, 3 s of total silence; nobody moves
					n = "4",
					t0 = 11,
					t1 = 15,
					camera = {
						shot = "WIDE",
						from = B(62.6, 14.6, 83.6),
						lookAt = B(68, 13, 79),
						fov = 62,
					},
					cues = {
						cue({ at = 0.3, world = "silence", worldParams = { duration = 3.4 } }),
					},
				}),
				shot({
					-- HANDHELD CLOSE on the door: it jolts from three knocks
					n = "5",
					t0 = 15,
					t1 = 20,
					camera = {
						shot = "CLOSE",
						from = B(67.8, 13.4, 82.4),
						lookAt = B(70.3, 13.1, 84),
						fov = 48,
						shake = 0.25,
						moves = { move({ kind = "HANDHELD", amount = 0.25 }) },
					},
					cues = {
						cue({ at = 0.8, sfx = "knock_tung_x3", sfxVolume = 1 }),
						cue({
							at = 0.8,
							world = "doorShake",
							worldParams = { tag = "TavernDoor", knocks = 3, gap = 0.7 },
						}),
						cue({ at = 3.4, line = "CS04_TUNG_KNOCK" }),
					},
					transitionOut = { kind = "FADE_BLACK", seconds = 0.3 },
				}),
				shot({
					-- the narrator over a black frame
					n = "6",
					t0 = 20,
					t1 = 23,
					camera = {
						shot = "WIDE",
						from = B(66, 14, 82),
						lookAt = B(70.4, 13, 84),
						fov = 60,
					},
					transitionIn = { kind = "FADE_BLACK", seconds = 2.2 },
					cues = { cue({ at = 0.1, line = "CS04_NARR" }) },
				}),
				shot({
					-- ECU: Giallino right against the camera, the face fills the screen, whispering
					n = "7",
					t0 = 23,
					t1 = 26,
					camera = {
						shot = "ECU",
						from = { actor = "Giallino", offset = Vector3.new(0, 0, -3.4) },
						lookAt = { actor = "Giallino" },
						fov = 52,
						moves = { move({ kind = "DOLLY_IN", amount = 0.15 }) },
					},
					cues = {
						cue({ actor = "Giallino", visible = true, light = { glow = 0.8 } }),
						cue({ at = 0.1, line = "CS04_GIALLINO_DONT" }),
					},
				}),
			},
		},
	},
}

return data
