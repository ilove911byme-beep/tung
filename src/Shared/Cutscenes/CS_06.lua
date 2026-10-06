--!strict
-- CS-06 "Broken from the inside" (~38 s), cutscenes.md. Morning: the players leave the inn, a
-- scream, the crowd at Ballerina's house (the door lies broken OUTSIDE), Tralalero panics,
-- Giallino floats above the crowd and blames Tung Tung, the villagers point at the hill, and
-- aside, Cappuccino Assassino kneels with the pointe shoe, sobbing, then speaks only to the
-- players. World blocks (map.md); Ballerina's door is on her west wall at x 91.5, z 76.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local N = Kit.MAX_PLAYERS

local CROWD = {
	{ id = "Tralalero", x = 88.6, z = 77.4 },
	{ id = "Chimpanzini", x = 87.8, z = 74.6 },
	{ id = "TrippiTroppi", x = 86.6, z = 76.2 },
	{ id = "BonecaAmbalabu", x = 86.4, z = 78.6 },
	{ id = "LaVacaSaturno", x = 88.9, z = 79.6 },
	{ id = "GlorboFruttodrillo", x = 87.2, z = 73.2 },
	{ id = "Strawberry", x = 85.3, z = 74.4 },
	{ id = "Banana", x = 85.2, z = 79.4 },
}

local actors: { Types.ActorSpec } = {
	Kit.actor({ id = "Giallino", model = "Giallino", at = B(92, 22, 70, 270), face = "happy" }),
	Kit.actor({
		id = "Cappuccino",
		model = "Cappuccino",
		at = B(99.6, 12, 80.8, 300),
		face = "crying",
	}),
}
local hide: { string } = { "Giallino", "Cappuccino" }
for _, c in CROWD do
	table.insert(actors, { id = c.id, model = c.id, at = B(c.x, 12, c.z, 90), face = "scared" })
	table.insert(hide, c.id)
end
for _, s in
	Kit.standIns(N, function(i)
		return B(69.6, 12, 84 + ((i - 1) % 2) * 0.5, 90)
	end)
do
	table.insert(actors, s)
end

local function crowdCues(make: (string) -> Types.Cue): { Types.Cue }
	local out: { Types.Cue } = {}
	for _, c in CROWD do
		local q = make(c.id)
		q.actor = c.id
		table.insert(out, q)
	end
	return out
end

local data: Types.Cutscene = {
	id = "CS_06",
	title = "Broken from the Inside",
	noSkip = false,
	grade = "DAWN",
	clockTime = 6.4,
	actors = actors,
	players = { mode = "hide" },
	hideNpcs = hide,
	entry = "main",
	segments = {
		main = {
			length = 38,
			shots = {
				shot({
					-- WIDE, morning fog: the players step out of the inn; a scream in the distance
					n = "1",
					t0 = 0,
					t1 = 4,
					camera = {
						shot = "WIDE",
						from = B(78, 15, 90.6),
						lookAt = B(71, 13, 84),
						fov = 60,
					},
					cues = Kit.cues(
						{
							cue({ music = "SILENCE", musicFade = 1 }),
							cue({ at = 1.2, line = "CS06_TRALALERO_SCREAM" }),
						},
						Kit.forPlayers(N, function(i)
							return cue({ at = (i - 1) * 0.25, anim = "A-WALK" })
						end),
						Kit.forPlayers(N, function(i)
							local col = (i - 1) % 3
							local row = math.floor((i - 1) / 3)
							return cue({
								at = (i - 1) * 0.25,
								moveTo = B(72.6 + row * 0.9, 12, 82.8 + col * 0.9, 90),
								moveTime = 2.4,
								moveEasing = "Linear",
							})
						end),
						Kit.forPlayers(N, function(i)
							return cue({
								at = 2.4 + (i - 1) * 0.25,
								stopAnim = "A-WALK",
								faceToward = B(92, 13, 76),
							})
						end)
					),
				}),
				shot({
					-- MED, Ballerina's house: the door is broken OUTWARD, splinters on the street,
					-- the villagers crowd around
					n = "2",
					t0 = 4,
					t1 = 9,
					camera = {
						shot = "MED",
						from = B(84.4, 14.6, 81.6),
						lookAt = B(91, 13, 76),
						fov = 52,
						moves = { move({ kind = "DOLLY_IN", amount = 0.08 }) },
					},
					cues = crowdCues(function(id)
						return cue({
							at = if id == "Tralalero" then 0 else 0.5,
							anim = "A-IDLE_BREATH",
						})
					end),
				}),
				shot({
					-- CLOSE on Tralalero (A-PANIC_ARMS), scared
					n = "3",
					t0 = 9,
					t1 = 13,
					camera = {
						shot = "CLOSE",
						from = B(86.2, 13.9, 77.8),
						lookAt = { actor = "Tralalero", part = "Head" },
						fov = 46,
					},
					cues = {
						cue({ actor = "Tralalero", faceToward = B(85, 13, 77.6) }),
						cue({ actor = "Tralalero", anim = "A-PANIC_ARMS" }),
						cue({ at = 0.2, line = "CS06_TRALALERO_GONE" }),
					},
				}),
				shot({
					-- WIDE: Giallino floats down over the crowd, everybody looks up
					n = "4",
					t0 = 13,
					t1 = 18,
					camera = {
						shot = "WIDE",
						low = true,
						from = B(81.6, 13.2, 82.6),
						lookAt = B(88.4, 15.6, 76),
						fov = 60,
					},
					cues = Kit.cues(
						{
							cue({ actor = "Tralalero", stopAnim = "A-PANIC_ARMS" }),
							cue({ actor = "Giallino", anim = "A-GIALLINO_IDLE" }),
							cue({
								actor = "Giallino",
								moveTo = B(88.4, 17.4, 76.2, 270),
								moveTime = 2.2,
								moveEasing = "QuadOut",
							}),
							cue({ actor = "Giallino", light = { glow = 2, spot = true } }),
							cue({ at = 2.0, line = "CS06_GIALLINO_TUNG" }),
						},
						crowdCues(function()
							return cue({ at = 0.4, anim = "A-LOOK_UP" })
						end)
					),
				}),
				shot({
					-- MED, the crowd murmurs; someone points at the hill where Tung Tung's hut stands
					n = "5",
					t0 = 18,
					t1 = 22,
					camera = {
						shot = "MED",
						from = B(85.6, 14.2, 71.2),
						lookAt = B(87.6, 13.2, 77),
						fov = 52,
					},
					cues = Kit.cues(
						{
							cue({ sfx = "npc_hum_question", sfxSpeed = 0.7, sfxVolume = 0.7 }),
							cue({ at = 1.2, sfx = "npc_hum_no", sfxSpeed = 0.6, sfxVolume = 0.6 }),
							cue({ at = 0.3, actor = "Chimpanzini", faceToward = B(80, 16, 126) }),
							cue({ at = 0.5, actor = "Chimpanzini", anim = "A-POINT" }),
							cue({ at = 1.4, actor = "Strawberry", faceToward = B(80, 16, 126) }),
							cue({ at = 2.2, actor = "Banana", faceToward = B(80, 16, 126) }),
						},
						crowdCues(function()
							return cue({ at = 0.1, stopAnim = "A-LOOK_UP" })
						end)
					),
				}),
				shot({
					-- MED, static, away from the crowd: Cappuccino Assassino on his knees holds the pointe
					-- shoe, shoulders shaking, crying; he hides it in his cloak when he notices the camera
					n = "6",
					t0 = 22,
					t1 = 30,
					camera = {
						shot = "MED",
						from = B(97, 13.4, 83.4),
						lookAt = B(99.6, 12.7, 80.8),
						fov = 48,
					},
					cues = {
						cue({ music = "music_tragic", musicVolume = 0.25, musicFade = 3 }),
						cue({
							actor = "Cappuccino",
							effect = "ShowPart",
							effectParams = { part = "Shoe" },
						}),
						cue({ actor = "Cappuccino", anim = "A-KNEEL_HOLD_ITEM" }),
						cue({ at = 1.9, actor = "Cappuccino", anim = "A-SOB_QUIET" }),
						cue({ at = 1.9, sfx = "amb_wind_loop", sfxVolume = 0.4 }),
						cue({ at = 6.0, actor = "Cappuccino", face = "neutral" }),
						cue({ at = 6.0, actor = "Cappuccino", faceToward = B(97, 13, 83.4) }),
						cue({ at = 6.4, actor = "Cappuccino", stopAnim = "A-SOB_QUIET" }),
						cue({
							at = 6.5,
							actor = "Cappuccino",
							effect = "HidePart",
							effectParams = { part = "Shoe" },
						}),
					},
				}),
				shot({
					-- OTS from behind Cappuccino onto the players: he speaks only to them
					n = "7",
					t0 = 30,
					t1 = 38,
					camera = {
						shot = "OTS",
						from = {
							actor = "Cappuccino",
							part = "Head",
							offset = Vector3.new(1.3, 0.5, 3.4),
						},
						lookAt = B(85.8, 13.4, 82),
						fov = 50,
					},
					cues = Kit.cues(
						{
							cue({ actor = "Cappuccino", stopAnim = "*" }),
							cue({
								actor = "Cappuccino",
								moveTo = B(88.4, 12, 82.2, 270),
								moveTime = 0.05,
							}),
							cue({ at = 0.6, line = "CS06_CAPPUCCINO" }),
						},
						Kit.forPlayers(N, function(i)
							local col = (i - 1) % 3
							local row = math.floor((i - 1) / 3)
							return cue({
								moveTo = B(85.8 - row * 0.9, 12, 81 + col * 0.9, 90),
								moveTime = 0.05,
							})
						end)
					),
					transitionOut = { kind = "FADE_BLACK", seconds = 1.2 },
				}),
			},
		},
	},
}

return data
