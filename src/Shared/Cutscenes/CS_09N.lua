--!strict
-- CS-09N "The accusation" — "We are not sure yet" (~25 s), cutscenes.md: nobody is locked away.
-- The villagers walk off unhappy, Cappuccino nods to the players from the shadows, and Giallino:
-- "…Not sure? That's not a yes." with the mood-drop sound. World blocks (map.md).
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local CROWD = {
	{ id = "Tralalero", from = { 85.5, 77 }, to = { 82, 96 } },
	{ id = "Chimpanzini", from = { 84.5, 79.5 }, to = { 70, 90 } },
	{ id = "GlorboFruttodrillo", from = { 86.5, 82 }, to = { 89.5, 99 } },
	{ id = "LaVacaSaturno", from = { 87.5, 78.5 }, to = { 94.5, 94 } },
	{ id = "TrippiTroppi", from = { 85, 75 }, to = { 63, 65 } },
}

local actors: { Types.ActorSpec } = {
	Kit.actor({
		id = "Cappuccino",
		model = "Cappuccino",
		at = B(91.2, 12, 71.2, 225),
		face = "neutral",
	}),
	Kit.actor({ id = "Giallino", model = "Giallino", at = B(84, 15.5, 80, 270), face = "happy" }),
}
local hide: { string } = { "Cappuccino", "Giallino" }
for _, c in CROWD do
	table.insert(
		actors,
		{ id = c.id, model = c.id, at = B(c.from[1], 12, c.from[2], 270), face = "angry" }
	)
	table.insert(hide, c.id)
end

local walkOff: { Types.Cue } = {}
for i, c in CROWD do
	table.insert(walkOff, cue({ at = 0.3 * i, actor = c.id, anim = "A-WALK" }))
	table.insert(
		walkOff,
		cue({
			at = 0.3 * i,
			actor = c.id,
			moveTo = B(c.to[1], 12, c.to[2]),
			moveTime = 7,
			moveEasing = "Linear",
		})
	)
end

local data: Types.Cutscene = {
	id = "CS_09N",
	title = "Not Sure",
	noSkip = false,
	grade = "DUSK",
	clockTime = 17.2,
	actors = actors,
	players = { mode = "hide" },
	hideNpcs = hide,
	entry = "main",
	segments = {
		main = {
			length = 25,
			shots = {
				shot({
					-- WIDE: nobody is locked away; the villagers grumble and walk off
					n = "1",
					t0 = 0,
					t1 = 7,
					camera = {
						shot = "WIDE",
						from = B(78, 16, 70),
						lookAt = B(85, 13, 80),
						fov = 60,
					},
					cues = Kit.cues({
						cue({ music = "SILENCE", musicFade = 1 }),
						cue({ sfx = "npc_hum_no", sfxVolume = 0.7, sfxSpeed = 0.8 }),
						cue({ at = 1.0, sfx = "npc_hum_no", sfxVolume = 0.6, sfxSpeed = 0.7 }),
					}, walkOff),
				}),
				shot({
					-- MED, in the shadow by Ballerina's house: Cappuccino nods to the players
					n = "2",
					t0 = 7,
					t1 = 13,
					camera = {
						shot = "MED",
						from = B(88.6, 13.8, 74.4),
						lookAt = { actor = "Cappuccino", part = "Head" },
						fov = 46,
					},
					cues = {
						cue({ actor = "Cappuccino", faceToward = B(88, 13, 75) }),
						cue({
							at = 1.6,
							actor = "Cappuccino",
							anim = "A-GIALLINO_BOW",
							animSpeed = 0.6,
						}),
					},
				}),
				shot({
					-- CLOSE on Giallino: the smile holds a little too long
					n = "3",
					t0 = 13,
					t1 = 20,
					camera = {
						shot = "CLOSE",
						from = B(80.6, 15.6, 80),
						lookAt = { actor = "Giallino" },
						fov = 44,
						moves = { move({ kind = "DOLLY_IN", amount = 0.15 }) },
					},
					cues = {
						cue({ actor = "Giallino", anim = "A-GIALLINO_IDLE" }),
						cue({ at = 1.2, line = "CS09_GIALLINO_NOTSURE" }),
						cue({ at = 4.4, actor = "Giallino", face = "screen_static", faceFor = 0.1 }),
						cue({ at = 4.4, sfx = "giallino_mood_drop", sfxVolume = 0.6 }),
					},
				}),
				shot({
					-- WIDE: the empty square at dusk
					n = "4",
					t0 = 20,
					t1 = 25,
					camera = {
						shot = "WIDE",
						from = B(92, 20, 92),
						lookAt = B(80, 13, 80),
						fov = 58,
						moves = { move({ kind = "CRANE_UP", amount = 8 }) },
					},
					transitionOut = { kind = "FADE_BLACK", seconds = 1.2 },
				}),
			},
		},
	},
}

return data
