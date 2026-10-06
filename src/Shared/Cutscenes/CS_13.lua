--!strict
-- CS-13 "The great light" (~10 s), cutscenes.md — the chase begins. Giallino bursts out of the
-- bell tower huge (A-GIALLINO_GROW), pieces of the roof fly; his happy face the size of a house:
-- "NOBODY LEAVES."; the players run -> BLEND into control.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local N = Kit.MAX_PLAYERS

local actors: { Types.ActorSpec } = {
	Kit.actor({ id = "Giallino", model = "Giallino", at = B(80, 38, 66, 180), face = "happy" }),
}
for _, s in
	Kit.standIns(N, function(i)
		return B(71.5 + (i % 2), 12, 82.5 + math.floor((i - 1) / 2) * 1.1, 180)
	end)
do
	table.insert(actors, s)
end

local data: Types.Cutscene = {
	id = "CS_13",
	title = "The Great Light",
	noSkip = false,
	grade = "NIGHT",
	clockTime = 1.6,
	actors = actors,
	players = { mode = "hide" },
	hideNpcs = { "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 10,
			shots = {
				shot({
					-- LOW, the bell tower: Giallino breaks out of it huge, pieces of the roof fly
					n = "1",
					t0 = 0,
					t1 = 4,
					camera = {
						shot = "LOW",
						low = true,
						from = B(80.4, 12.8, 80),
						lookAt = B(80, 44, 66),
						fov = 66,
						shake = 0.3,
					},
					transitionIn = { kind = "FADE_WHITE", seconds = 0.6 },
					cues = {
						cue({ actor = "Giallino", anim = "A-GIALLINO_GROW" }),
						cue({
							actor = "Giallino",
							moveTo = B(80, 52, 70, 180),
							moveTime = 2.4,
							moveEasing = "QuadOut",
						}),
						cue({ actor = "Giallino", light = { glow = 6 } }),
						cue({
							world = "debrisBurst",
							worldParams = { at = Vector3.new(80 * 4, 41 * 4, 66 * 4), count = 34 },
						}),
						cue({ sfx = "explosion_boom", sfxVolume = 1 }),
						cue({ at = 0.2, sfx = "block_break_wood", sfxVolume = 1, sfxSpeed = 0.6 }),
					},
				}),
				shot({
					-- CLOSE: the happy face, but the size of a house
					n = "2",
					t0 = 4,
					t1 = 7,
					camera = {
						shot = "CLOSE",
						from = B(80, 52, 88),
						lookAt = { actor = "Giallino" },
						fov = 55,
						moves = { move({ kind = "DOLLY_IN", amount = 0.1 }) },
					},
					cues = { cue({ at = 0.2, line = "CS13_GIALLINO" }) },
				}),
				shot({
					-- WIDE: the players run -> BLEND into gameplay
					n = "3",
					t0 = 7,
					t1 = 10,
					camera = {
						shot = "WIDE",
						from = B(76, 17, 96),
						lookAt = B(72, 13, 84),
						fov = 60,
					},
					transitionOut = { kind = "BLEND", seconds = 0.6 },
					cues = Kit.cues(
						{ cue({ sfx = "heartbeat_loop", sfxVolume = 1 }) },
						Kit.forPlayers(N, function()
							return cue({ anim = "A-RUN" })
						end),
						Kit.forPlayers(N, function(i)
							return cue({
								moveTo = B(73 + (i % 3), 12, 94 + math.floor((i - 1) / 3), 180),
								moveTime = 3,
								moveEasing = "Linear",
							})
						end)
					),
				}),
			},
		},
	},
}

return data
