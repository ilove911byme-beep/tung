--!strict
-- CS-09C "The accusation" — Cappuccino Assassino (~25 s, tragic), cutscenes.md. Same staging: Cappuccino is led to the barn, says he was only looking for his sister and gives the players Ballerina's pointe shoe.
-- World blocks: the barn spans x 99.5-108.5, z 64.5-71.5, its gate is on the west wall at z 68.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

-- the two gate wings: hinges at the ends of the opening, panels reaching to the middle
local GATE_N: Types.Point =
	{ anchor = "Anchor_Origin", offset = Vector3.new(99.5 * 4, 12 * 4, 66.5 * 4), yaw = -90 }
local GATE_S: Types.Point =
	{ anchor = "Anchor_Origin", offset = Vector3.new(99.5 * 4, 12 * 4, 69.5 * 4), yaw = 90 }

local ACCUSED = "Cappuccino"

local data: Types.Cutscene = {
	id = "CS_09C",
	title = "The Accusation",
	noSkip = false,
	grade = "DUSK",
	clockTime = 17.2,
	actors = {
		{ id = ACCUSED, model = ACCUSED, at = B(91.5, 12, 70.5, 90), face = "sad" },
		{ id = "Tralalero", model = "Tralalero", at = B(89.5, 12, 69.2, 90), face = "angry" },
		{ id = "Chimpanzini", model = "Chimpanzini", at = B(89.4, 12, 71.6, 90), face = "angry" },
		{
			id = "GlorboFruttodrillo",
			model = "GlorboFruttodrillo",
			at = B(88, 12, 70.4, 90),
			face = "angry",
		},
		{ id = "GateN", model = "Gate", at = GATE_N, footsteps = false },
		{ id = "GateS", model = "Gate", at = GATE_S, footsteps = false },
		{ id = "Giallino", model = "Giallino", at = B(104, 22, 68, 270), face = "happy" },
	},
	players = { mode = "hide" },
	hideNpcs = { ACCUSED, "Tralalero", "Chimpanzini", "GlorboFruttodrillo", "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 25,
			shots = {
				shot({
					-- WIDE: the villagers lead Cappuccino to the barn; he does not resist
					n = "1",
					t0 = 0,
					t1 = 5,
					camera = {
						shot = "WIDE",
						from = B(90.5, 15.5, 61.5),
						lookAt = B(96.5, 13, 69),
						fov = 58,
					},
					cues = {
						cue({ music = "music_tragic", musicVolume = 0.35, musicFade = 2 }),
						cue({ actor = "GateN", anim = "A-DOOR_OPEN_FAST" }),
						cue({ actor = "GateS", anim = "A-DOOR_OPEN_FAST" }),
						cue({ actor = ACCUSED, anim = "A-WALK_DEFEATED" }),
						cue({
							actor = ACCUSED,
							moveTo = B(98.2, 12, 68.2, 90),
							moveTime = 4.8,
							moveEasing = "Linear",
						}),
						cue({ actor = "Tralalero", anim = "A-WALK" }),
						cue({
							actor = "Tralalero",
							moveTo = B(95.6, 12, 67, 90),
							moveTime = 4.4,
							moveEasing = "Linear",
						}),
						cue({ actor = "Chimpanzini", anim = "A-WALK" }),
						cue({
							actor = "Chimpanzini",
							moveTo = B(95.4, 12, 69.6, 90),
							moveTime = 4.4,
							moveEasing = "Linear",
						}),
						cue({ actor = "GlorboFruttodrillo", anim = "A-WALK" }),
						cue({
							actor = "GlorboFruttodrillo",
							moveTo = B(94, 12, 68.4, 90),
							moveTime = 4.6,
							moveEasing = "Linear",
						}),
						cue({ at = 0.5, sfx = "npc_hum_no", sfxSpeed = 0.7, sfxVolume = 0.6 }),
						cue({ at = 4.4, actor = "Tralalero", stopAnim = "A-WALK" }),
						cue({ at = 4.4, actor = "Chimpanzini", stopAnim = "A-WALK" }),
						cue({ at = 4.6, actor = "GlorboFruttodrillo", stopAnim = "A-WALK" }),
						cue({ at = 4.8, actor = ACCUSED, stopAnim = "A-WALK_DEFEATED" }),
					},
				}),
				shot({
					-- CLOSE on Cappuccino: he looks at the players, sad
					n = "2",
					t0 = 5,
					t1 = 10,
					camera = {
						shot = "CLOSE",
						from = B(95.4, 13.9, 68.1),
						lookAt = { actor = ACCUSED, part = "Head" },
						fov = 44,
					},
					cues = {
						cue({ actor = ACCUSED, faceToward = B(95, 13, 68) }),
						cue({ at = 0.4, line = "CS09_CAPPUCCINO_SISTER" }),
						cue({ at = 0.4, actor = ACCUSED, face = "crying" }),
					},
				}),
				shot({
					-- ECU on the hands: he gives the players Ballerina's pointe shoe (A-GIVE_ITEM)
					n = "3",
					t0 = 10,
					t1 = 15,
					camera = {
						shot = "ECU",
						from = B(96.6, 13.1, 67.2),
						lookAt = { actor = ACCUSED, part = "RightHand" },
						fov = 36,
					},
					cues = {
						cue({
							actor = ACCUSED,
							effect = "ShowPart",
							effectParams = { part = "Shoe" },
						}),
						cue({ actor = ACCUSED, anim = "A-GIVE_ITEM" }),
						cue({
							at = 1.2,
							actor = ACCUSED,
							effect = "HidePart",
							effectParams = { part = "Shoe" },
						}),
					},
				}),
				shot({
					-- MED: the barn gate closes on Cappuccino; the katana stays leaning outside
					n = "4",
					t0 = 15,
					t1 = 20,
					camera = {
						shot = "MED",
						from = B(95, 13.6, 70.5),
						lookAt = B(99.5, 13.3, 68),
						fov = 52,
					},
					cues = {
						cue({ actor = ACCUSED, faceToward = B(99, 13, 68) }),
						cue({ actor = ACCUSED, moveTo = B(101.2, 12, 68, 270), moveTime = 1.4 }),
						cue({ actor = ACCUSED, anim = "A-WALK_DEFEATED" }),
						cue({ at = 1.4, actor = ACCUSED, stopAnim = "A-WALK_DEFEATED" }),
						cue({ at = 1.6, actor = "GateN", anim = "A-DOOR_CLOSE" }),
						cue({ at = 1.6, actor = "GateS", anim = "A-DOOR_CLOSE" }),
						cue({ at = 2.7, sfx = "door_close", sfxVolume = 1, sfxSpeed = 0.7 }),
						cue({ at = 0.3, sfx = "npc_hum_no", sfxVolume = 0.4, sfxSpeed = 0.6 }),
					},
				}),
				shot({
					-- WIDE: Giallino above the barn, happy
					n = "5",
					t0 = 20,
					t1 = 25,
					camera = {
						shot = "WIDE",
						low = true,
						from = B(93, 13.2, 74),
						lookAt = { actor = "Giallino" },
						fov = 58,
						moves = { move({ kind = "CRANE_UP", amount = 6 }) },
					},
					cues = {
						cue({ actor = "Giallino", anim = "A-GIALLINO_IDLE" }),
						cue({ actor = "Giallino", light = { glow = 2 } }),
						cue({ at = 0.5, line = "CS09_GIALLINO_GOODSHORT" }),
					},
					transitionOut = { kind = "FADE_BLACK", seconds = 1 },
				}),
			},
		},
	},
}

return data
