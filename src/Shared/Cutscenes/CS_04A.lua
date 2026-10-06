--!strict
-- CS-04A "Open" (~10 s), cutscenes.md, if the party voted to open the door. Over a player's
-- shoulder the door creaks open; outside only fog, a bat mark on the ground and, far away by
-- the hill, a wooden figure that looks back and fades into the fog; WHIP back: Giallino right
-- in the face. World blocks (map.md). The real door is hidden by the chapter during this.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

-- the door rig: hinge at the south edge of the tavern door (z 84.5), the panel reaches north
local DOOR: Types.Point =
	{ anchor = "Anchor_Origin", offset = Vector3.new(70 * 4, 12 * 4, 84.5 * 4), yaw = 90 }

local data: Types.Cutscene = {
	id = "CS_04A",
	title = "Open",
	noSkip = false,
	grade = "NIGHT",
	clockTime = 23.5,
	actors = {
		{ id = "Door", model = "Door", at = DOOR, footsteps = false },
		{ id = "P1", model = "@Player1", at = B(68.6, 12, 84, 90), footsteps = false },
		{ id = "Mark", model = "BatMark", at = B(73, 12, 84.4, 160), footsteps = false },
		{ id = "TungTung", model = "TungTung", at = B(80, 12, 106, 180), face = "sad" },
		{
			id = "Giallino",
			model = "Giallino",
			at = B(69.4, 13.9, 84, 90),
			face = "shocked",
			visible = false,
		},
	},
	players = { mode = "hide" },
	hideNpcs = { "TungTung", "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 10,
			shots = {
				shot({
					-- OTS over the player's shoulder: the door opens slowly (A-DOOR_OPEN_SLOW), creak
					n = "1",
					t0 = 0,
					t1 = 3,
					camera = {
						shot = "OTS",
						from = { actor = "P1", part = "Head", offset = Vector3.new(1.4, 0.6, 3.2) },
						lookAt = B(70.4, 13.1, 84),
						fov = 55,
						moves = { move({ kind = "DOLLY_IN", amount = 0.1 }) },
					},
					cues = {
						cue({ actor = "Door", anim = "A-DOOR_OPEN_SLOW" }),
						cue({ at = 0.2, sfx = "door_open", sfxVolume = 0.9, sfxSpeed = 0.7 }),
					},
				}),
				shot({
					-- WIDE, the street in fog: nobody. A bat mark on the ground. Far away by the hill a
					-- wooden figure walks off, looks back (A-TUNG_LOOK_BACK) and vanishes in the fog
					n = "2",
					t0 = 3,
					t1 = 6,
					camera = {
						shot = "WIDE",
						from = B(71.2, 13.8, 84.2),
						lookAt = B(79, 14, 104),
						fov = 58,
					},
					cues = {
						cue({ sfx = "amb_wind_loop", sfxVolume = 0.8 }),
						cue({ actor = "TungTung", anim = "A-WALK" }),
						cue({
							actor = "TungTung",
							moveTo = B(80, 12, 109, 180),
							moveTime = 1.0,
							moveEasing = "Linear",
						}),
						cue({ at = 1.0, actor = "TungTung", stopAnim = "A-WALK" }),
						cue({ at = 1.0, actor = "TungTung", anim = "A-TUNG_LOOK_BACK" }),
						cue({ at = 2.2, actor = "TungTung", anim = "A-WALK" }),
						cue({
							at = 2.2,
							actor = "TungTung",
							moveTo = B(80, 12, 112, 180),
							moveTime = 0.8,
							moveEasing = "Linear",
						}),
						cue({ at = 2.9, actor = "TungTung", visible = false }),
					},
				}),
				shot({
					-- WHIP back: Giallino right in the face, shocked -> happy (jumpscare)
					n = "3",
					t0 = 6,
					t1 = 7,
					camera = {
						shot = "CLOSE",
						from = B(71.4, 13.9, 84),
						lookAt = { actor = "Giallino" },
						fov = 60,
						moves = { move({ kind = "WHIP" }) },
					},
					cues = {
						cue({ actor = "Giallino", visible = true, light = { glow = 2 } }),
						cue({
							actor = "Giallino",
							moveTo = B(70.9, 13.9, 84, 90),
							moveTime = 0.2,
							moveEasing = "QuadOut",
						}),
						cue({ sfx = "jumpscare_stinger", sfxVolume = 1 }),
						cue({ at = 0.55, actor = "Giallino", face = "happy" }),
					},
				}),
				shot({
					-- CLOSE: "I said don't. You didn't say yes. Why?"
					n = "4",
					t0 = 7,
					t1 = 10,
					camera = {
						shot = "CLOSE",
						from = B(71.9, 13.95, 84.15),
						lookAt = { actor = "Giallino" },
						fov = 45,
						moves = { move({ kind = "DOLLY_IN", amount = 0.12 }) },
					},
					cues = { cue({ at = 0.1, line = "CS04A_GIALLINO_WHY" }) },
				}),
			},
		},
	},
}

return data
