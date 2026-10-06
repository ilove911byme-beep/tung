--!strict
-- CS-20 "Giallino Totale" (lock, ~34 s), cutscenes.md: the party climbs out of the mine under a
-- sky of static; a giant cracked cube-sun rises over the valley turning its four faces (Giallino,
-- Falsino, Negatino, Crudelino); "I was the light..."; Glitchling shadows crawl from every house
-- to the tower; a small voice: "Take me to your world, [Name]."; WHIP to the clock tower.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local N = Kit.MAX_PLAYERS
local DOORS = {
	{ 70.5, 84 },
	{ 91.5, 76 },
	{ 69.5, 88.5 },
	{ 89, 67.5 },
	{ 59.5, 67 },
	{ 59.5, 75 },
	{ 100.5, 62 },
	{ 96, 94.5 },
}

local actors: { Types.ActorSpec } = {
	Kit.actor({ id = "Totale", model = "GiallinoTotale", at = B(102, 16, 45, 60), face = "happy" }),
}
for i, d in DOORS do
	table.insert(actors, {
		id = "Shadow" .. i,
		model = "GlitchlingRig",
		at = B(d[1], 12, d[2]),
		visible = false,
		footsteps = false,
	})
end
for _, s in
	Kit.standIns(N, function(i)
		return B(134.6 + (i % 2), 18, 22.6, 180)
	end)
do
	table.insert(actors, s)
end

local crawl: { Types.Cue } = {}
for i, _ in DOORS do
	table.insert(crawl, cue({ at = 0.2 * i, actor = "Shadow" .. i, visible = true }))
	table.insert(crawl, cue({ at = 0.2 * i, actor = "Shadow" .. i, faceToward = B(80, 12, 71) }))
	table.insert(
		crawl,
		cue({
			at = 0.2 * i,
			actor = "Shadow" .. i,
			moveTo = B(80 + (i - 4.5) * 0.8, 12, 72),
			moveTime = 5.5,
			moveEasing = "Linear",
		})
	)
end

local data: Types.Cutscene = {
	id = "CS_20",
	title = "Giallino Totale",
	noSkip = true,
	grade = "GLITCH",
	clockTime = 4,
	actors = actors,
	players = { mode = "hide" },
	hideNpcs = { "GiallinoTotale" },
	entry = "main",
	segments = {
		main = {
			length = 34,
			shots = {
				shot({
					-- WIDE: the players climb out of the mine; the sky is static
					n = "1",
					t0 = 0,
					t1 = 5,
					camera = {
						shot = "WIDE",
						from = B(129.5, 21, 31),
						lookAt = B(135, 18.8, 23),
						fov = 60,
					},
					cues = Kit.cues(
						{
							cue({ music = "SILENCE", musicFade = 1 }),
							cue({ sfx = "glitch_burst", sfxVolume = 0.5 }),
							cue({ at = 2.6, sfx = "glitch_burst", sfxVolume = 0.4, sfxSpeed = 0.8 }),
							cue({ world = "skyFlicker", worldParams = { duration = 5 } }),
						},
						Kit.forPlayers(N, function(i)
							return cue({ at = (i - 1) * 0.3, anim = "A-WALK" })
						end),
						Kit.forPlayers(N, function(i)
							return cue({
								at = (i - 1) * 0.3,
								moveTo = B(133 + (i - 1) * 0.9, 18, 27.5, 225),
								moveTime = 3,
							})
						end),
						Kit.forPlayers(N, function(i)
							return cue({ at = 3 + (i - 1) * 0.3, stopAnim = "A-WALK" })
						end)
					),
				}),
				shot({
					-- CRANE UP: the giant cracked cube-sun rises over the valley, its faces in turn
					n = "2",
					t0 = 5,
					t1 = 12,
					grade = "NIGHT_DEEP",
					gradeTime = 2,
					camera = {
						shot = "WIDE",
						from = B(132, 19.5, 31),
						lookAt = { actor = "Totale" },
						fov = 66,
						moves = { move({ kind = "CRANE_UP", amount = 30 }) },
					},
					cues = {
						cue({ actor = "Totale", anim = "A-TOTALE_SIZE" }),
						cue({ actor = "Totale", anim = "A-TOTALE_ROTATE" }),
						cue({ actor = "Totale", light = { glow = 5 } }),
						cue({
							actor = "Totale",
							moveTo = B(102, 40, 45, 60),
							moveTime = 6.5,
							moveEasing = "SineOut",
						}),
						cue({ at = 0.4, sfx = "falsino_signature", sfxVolume = 0.7 }),
						cue({ at = 0.5, sfx = "negatino_signature", sfxVolume = 0.7 }),
						cue({ at = 0.6, sfx = "crudelino_signature", sfxVolume = 0.7 }),
						cue({ at = 0.7, sfx = "giallino_boot", sfxVolume = 0.7, sfxSpeed = 0.5 }),
					},
				}),
				shot({
					-- CLOSE on the face of Giallino
					n = "3",
					t0 = 12,
					t1 = 18,
					camera = {
						shot = "CLOSE",
						from = { actor = "Totale", offset = Vector3.new(0, 0, -150) },
						lookAt = { actor = "Totale" },
						fov = 40,
						moves = { move({ kind = "DOLLY_IN", amount = 0.08 }) },
					},
					cues = {
						cue({ actor = "Totale", stopAnim = "A-TOTALE_ROTATE" }),
						cue({ at = 0.6, line = "CS20_TOTALE_LIGHT" }),
						cue({ at = 0.6, music = "music_finale", musicVolume = 0.3, musicFade = 3 }),
					},
				}),
				shot({
					-- WIDE: Glitchling shadows crawl out of every house toward the tower
					n = "4",
					t0 = 18,
					t1 = 24,
					camera = {
						shot = "WIDE",
						from = B(97, 30, 101),
						lookAt = B(80, 12.5, 77),
						fov = 60,
					},
					cues = crawl,
				}),
				shot({
					-- ECU on the face; the voice becomes small, like a child's; sad for one second
					n = "5",
					t0 = 24,
					t1 = 30,
					camera = {
						shot = "ECU",
						from = { actor = "Totale", offset = Vector3.new(0, 0, -112) },
						lookAt = { actor = "Totale" },
						fov = 30,
					},
					cues = {
						cue({ at = 0.4, line = "CS20_TOTALE_WORLD" }),
						cue({ at = 2.6, actor = "Totale", face = "sad", faceFor = 1 }),
					},
				}),
				shot({
					-- WHIP to the clock tower in the distance -> BLEND into control
					n = "6",
					t0 = 30,
					t1 = 34,
					camera = {
						shot = "WIDE",
						from = B(130, 21, 31),
						lookAt = B(80, 36, 66),
						fov = 50,
						moves = { move({ kind = "WHIP" }) },
					},
					transitionOut = { kind = "BLEND", seconds = 0.6 },
					cues = { cue({ at = 0.3, sfx = "heartbeat_loop", sfxVolume = 0.9 }) },
				}),
			},
		},
	},
}

return data
