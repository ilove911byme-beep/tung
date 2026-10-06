--!strict
-- CS-14 "Patapim's roots" (~30 s, tragic), cutscenes.md — only if the riddle was solved. The
-- players are stuck at the gorge with Giallino's light behind them; Brr Brr Patapim rises out
-- of the ground, gives his roots to bridge the gorge, his leaves turn yellow and fall, he
-- kneels and dries into an ordinary dead tree while the players run across.
-- World blocks: the gorge spans z 138-144 (x 20-50); the players stand on the north edge.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local N = Kit.MAX_PLAYERS
local EDGE_N = B(35, 12, 137.7)
local EDGE_S = B(35, 12, 144.3)

local actors: { Types.ActorSpec } = {
	Kit.actor({ id = "Patapim", model = "Patapim", at = B(35, 12, 136.6, 0), face = "tired" }),
	Kit.actor({ id = "Giallino", model = "Giallino", at = B(36, 34, 112, 180), face = "happy" }),
}
for _, s in
	Kit.standIns(N, function(i)
		return B(33.2 + ((i - 1) % 3) * 1.8, 12, 133.4 - math.floor((i - 1) / 3) * 1.4, 180)
	end)
do
	table.insert(actors, s)
end

local data: Types.Cutscene = {
	id = "CS_14",
	title = "Patapim's Roots",
	noSkip = false,
	grade = "NIGHT",
	clockTime = 2,
	actors = actors,
	players = { mode = "hide" },
	hideNpcs = { "Patapim", "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 30,
			shots = {
				shot({
					-- WIDE, the forest: the players run up against the gorge, Giallino's light behind them
					n = "1",
					t0 = 0,
					t1 = 5,
					camera = {
						shot = "WIDE",
						from = B(43, 17, 146),
						lookAt = B(35, 13, 134),
						fov = 60,
					},
					cues = Kit.cues(
						{
							cue({ actor = "Patapim", visible = false }),
							cue({ actor = "Giallino", anim = "A-GIALLINO_GROW", animSpeed = 4 }),
							cue({ actor = "Giallino", light = { glow = 6, spot = true } }),
							cue({ music = "SILENCE", musicFade = 2 }),
						},
						Kit.forPlayers(N, function()
							return cue({ anim = "A-IDLE_BREATH" })
						end)
					),
				}),
				shot({
					-- MED: Brr Brr Patapim rises out of the ground (A-PATAPIM_RISE), tired
					n = "2",
					t0 = 5,
					t1 = 10,
					camera = {
						shot = "MED",
						from = B(35, 14.2, 132.4),
						lookAt = { actor = "Patapim", part = "Head" },
						fov = 52,
					},
					cues = {
						cue({ actor = "Patapim", visible = true }),
						cue({ actor = "Patapim", anim = "A-PATAPIM_RISE" }),
						cue({ at = 2.4, line = "CS14_PATAPIM_BEHIND" }),
					},
				}),
				shot({
					-- WIDE: roots burst out of the ground and weave a bridge over the gorge (A-ROOTS_BRIDGE)
					n = "3",
					t0 = 10,
					t1 = 17,
					camera = {
						shot = "WIDE",
						from = B(43.5, 18, 140.5),
						lookAt = B(35, 11, 141),
						fov = 58,
					},
					cues = {
						cue({
							actor = "Patapim",
							anim = "A-ROOTS_BRIDGE",
							effectParams = {
								fromPoint = EDGE_N,
								toPoint = EDGE_S,
								count = 6,
								width = 7,
								growTime = 0.4,
								stagger = 0.4,
							},
						}),
						cue({ at = 0.6, sfx = "block_break_wood", sfxVolume = 0.9, sfxSpeed = 0.7 }),
						cue({ at = 1.6, sfx = "block_break_wood", sfxVolume = 0.9, sfxSpeed = 0.8 }),
						cue({ at = 2.6, sfx = "block_break_wood", sfxVolume = 0.9, sfxSpeed = 0.6 }),
						cue({ at = 2.0, line = "CS14_PATAPIM_ROOTS" }),
					},
				}),
				shot({
					-- CLOSE: his leaves turn yellow and fall; he slowly sinks to his knees (A-KNEEL_SLOW)
					n = "4",
					t0 = 17,
					t1 = 23,
					camera = {
						shot = "CLOSE",
						from = B(35.2, 14.6, 133.6),
						lookAt = { actor = "Patapim", part = "Head" },
						fov = 44,
						moves = { move({ kind = "DOLLY_IN", amount = 0.1 }) },
					},
					cues = {
						cue({
							actor = "Patapim",
							effect = "Wither",
							effectParams = { duration = 6 },
						}),
						cue({ actor = "Patapim", anim = "A-KNEEL_SLOW" }),
						cue({ at = 0.6, line = "CS14_PATAPIM_REMEMBER" }),
						cue({ at = 4.0, actor = "Patapim", face = "eyes_closed" }),
					},
				}),
				shot({
					-- WIDE: Patapim stiffens into an ordinary dry tree; the players run over the bridge
					n = "5",
					t0 = 23,
					t1 = 30,
					camera = {
						shot = "WIDE",
						from = B(26, 16, 141),
						lookAt = B(35, 12.5, 140),
						fov = 58,
					},
					cues = Kit.cues(
						{ cue({ actor = "Patapim", face = "off" }) },
						Kit.forPlayers(N, function()
							return cue({ anim = "A-RUN" })
						end),
						Kit.forPlayers(N, function(i)
							return cue({
								at = (i - 1) * 0.35,
								moveTo = B(
									34.2 + ((i - 1) % 3) * 0.8,
									12,
									147 + math.floor((i - 1) / 3)
								),
								moveTime = 3.6,
								moveEasing = "Linear",
							})
						end)
					),
					transitionOut = { kind = "FADE_BLACK", seconds = 1 },
				}),
			},
		},
	},
}

return data
