--!strict
-- CS-16 "Frozen Lirili" + FLASHBACK (lock, ~95 s, tragic) — the main lore cutscene.
--   Part A (present, CAVE): the lab where time stands still, an orbit around Lirili frozen
--     mid-step, only her eyes move to the players.
--   Part B (FLASHBACK, sepia 4:3): forty days ago a little light falls into the mine, Lirili
--     kneels beside it, a montage of family days (words and clocks, the cuckoo clock, dancing
--     with Ballerina, the long sahur table), the old game's YES / NO screen, Ballerina taken
--     while Lirili watches from her window, Lirili at the lever, Giallino huge in the doorway,
--     her clock raised: "I'm just... stopping." and the white wave that freezes time.
--   Part C (present): her last words; her frozen tear -> RACK to the empty gear sockets.
-- World blocks: the lab spans x 134-146, z 35-45, floor -12; the mechanism is on its north side.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local LAB_FLOOR = -12
local FROZEN = B(140, LAB_FLOOR, 39.4, 0) -- facing the clock mechanism (north)

local TABLE_GUESTS = {
	{ id = "Tralalero", x = 78.4, z = 75.9 },
	{ id = "Chimpanzini", x = 81.6, z = 77.4 },
	{ id = "TungTung", x = 78.4, z = 81.9 },
	{ id = "Bombardiro", x = 81.6, z = 83.4 },
}

local actors: { Types.ActorSpec } = {
	Kit.actor({ id = "Lirili", model = "Lirili", at = FROZEN, face = "crying" }),
	Kit.actor({
		id = "LiriliPast",
		model = "Lirili",
		at = B(138.5, -25, 23, 225),
		face = "neutral",
		visible = false,
	}),
	Kit.actor({
		id = "Little",
		model = "Giallino",
		at = B(134, -13, 20, 90),
		face = "scared",
		visible = false,
	}),
	Kit.actor({
		id = "BigGiallino",
		model = "Giallino",
		at = B(146.5, LAB_FLOOR + 2.4, 43, 270),
		face = "screen_static",
		visible = false,
	}),
	Kit.actor({
		id = "BallerinaPast",
		model = "Ballerina",
		at = B(80, 12, 70.5, 180),
		face = "happy",
		visible = false,
	}),
	Kit.actor({
		id = "Cuckoo",
		model = "CuckooClock",
		at = B(87.2, 13.4, 66.2, 0),
		visible = false,
		footsteps = false,
	}),
	Kit.actor({
		id = "Lever",
		model = "Lever",
		at = B(144.6, LAB_FLOOR, 37.5, 270),
		footsteps = false,
	}),
}
for _, g in TABLE_GUESTS do
	table.insert(actors, {
		id = g.id,
		model = g.id,
		at = B(g.x, 12, g.z, if g.x < 80 then 90 else 270),
		face = "happy",
		visible = false,
	})
end

local function guests(make: (string) -> Types.Cue): { Types.Cue }
	local out: { Types.Cue } = {}
	for _, g in TABLE_GUESTS do
		local c = make(g.id)
		c.actor = g.id
		table.insert(out, c)
	end
	return out
end

local data: Types.Cutscene = {
	id = "CS_16",
	title = "Frozen Lirili",
	noSkip = true,
	grade = "CAVE",
	actors = actors,
	players = { mode = "hide" },
	hideNpcs = { "Tralalero", "Chimpanzini", "TungTung", "Bombardiro", "Ballerina", "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 95,
			shots = {
				-------------------------------------------------- Part A: the lab, now
				shot({
					-- WIDE, the lab: gears hang in the air, drops of water frozen, the dust does not fall
					n = "1",
					t0 = 0,
					t1 = 6,
					camera = {
						shot = "WIDE",
						from = B(145, -8.8, 44.2),
						lookAt = B(139.5, -10.4, 38),
						fov = 62,
						moves = { move({ kind = "DOLLY_IN", amount = 0.12 }) },
					},
					cues = {
						cue({ music = "SILENCE", musicFade = 1 }),
						cue({
							effect = "TimeFreeze",
							effectParams = {
								centerPoint = B(140, -10, 39),
								radius = 26,
								motes = 70,
							},
						}),
						cue({ actor = "Lirili", anim = "A-FROZEN_STEP" }),
						cue({
							actor = "Lirili",
							effect = "ShowPart",
							effectParams = { part = "Tear" },
						}),
						cue({ at = 0.5, sfx = "clock_time_stop", sfxVolume = 0.35, sfxSpeed = 0.6 }),
					},
				}),
				shot({
					-- ORBIT around Lirili: frozen mid-step, her trunk reaching for the clocks, a frozen
					-- tear on her cheek; very slow ticking
					n = "2",
					t0 = 6,
					t1 = 12,
					camera = {
						shot = "MED",
						from = B(140.4, -9.9, 43.6),
						lookAt = { actor = "Lirili", part = "Head" },
						fov = 50,
						moves = { move({ kind = "ORBIT", angle = 110, easing = "SineInOut" }) },
					},
					cues = {
						cue({ sfx = "lever_click", sfxVolume = 0.5, sfxSpeed = 0.3 }),
						cue({ at = 2.5, sfx = "lever_click", sfxVolume = 0.5, sfxSpeed = 0.3 }),
						cue({ at = 5.0, sfx = "lever_click", sfxVolume = 0.5, sfxSpeed = 0.3 }),
					},
				}),
				shot({
					-- CLOSE: only her eyes slowly move to the players
					n = "3",
					t0 = 12,
					t1 = 18,
					camera = {
						shot = "CLOSE",
						from = B(141.6, -9.7, 42.4),
						lookAt = { actor = "Lirili", part = "Head" },
						fov = 40,
					},
					cues = {
						cue({ at = 0.6, actor = "Lirili", eyeOffset = Vector2.new(1, 0) }),
						cue({ at = 1.4, actor = "Lirili", eyeOffset = Vector2.new(2, 1) }),
						cue({ at = 2.0, line = "CS16_LIRILI_FOUND" }),
					},
					transitionOut = { kind = "FADE_WHITE", seconds = 1 },
				}),
				-------------------------------------------------- Part B: the flashback
				shot({
					-- WIDE, deep in the mine forty days ago: a little yellow cube falls from the roof,
					-- hits the stone, its face flickers scared
					n = "4",
					t0 = 18,
					t1 = 26,
					grade = "FLASHBACK",
					gradeTime = 0.3,
					transitionIn = { kind = "FADE_WHITE", seconds = 1 },
					camera = {
						shot = "WIDE",
						from = B(128, -21, 26.5),
						lookAt = B(134, -22.5, 20),
						fov = 58,
					},
					cues = {
						cue({ actor = "Lirili", visible = false }),
						cue({ music = "music_flashback", musicVolume = 0.4, musicFade = 2 }),
						cue({ at = 0.8, actor = "Little", visible = true, light = { glow = 1.5 } }),
						cue({
							at = 0.8,
							actor = "Little",
							moveTo = B(134, -24.5, 20, 90),
							moveTime = 1.6,
							moveEasing = "QuadIn",
						}),
						cue({
							at = 2.4,
							sfx = "block_break_stone",
							sfxVolume = 0.6,
							sfxSpeed = 1.4,
						}),
						cue({
							at = 2.4,
							actor = "Little",
							moveTo = B(134.4, -23.9, 20.2, 120),
							moveTime = 0.25,
							moveEasing = "QuadOut",
						}),
						cue({
							at = 2.65,
							actor = "Little",
							moveTo = B(134.6, -24.5, 20.3, 140),
							moveTime = 0.25,
							moveEasing = "QuadIn",
						}),
						cue({ at = 2.9, actor = "Little", face = "scared" }),
						cue({ at = 3.0, line = "CS16_LIRILI_FORTY" }),
					},
				}),
				shot({
					-- MED: Lirili sits down beside it (A-KNEEL_SOFT), holds out her trunk; the cube hides,
					-- then carefully touches it
					n = "5",
					t0 = 26,
					t1 = 33,
					camera = {
						shot = "MED",
						from = B(132, -23.3, 24.8),
						lookAt = B(135.3, -24, 21),
						fov = 50,
					},
					cues = {
						cue({ actor = "LiriliPast", visible = true }),
						cue({
							actor = "LiriliPast",
							moveTo = B(136.4, -25, 21.6, 225),
							moveTime = 1.2,
						}),
						cue({ actor = "LiriliPast", anim = "A-WALK" }),
						cue({ at = 1.2, actor = "LiriliPast", stopAnim = "A-WALK" }),
						cue({ at = 1.3, actor = "LiriliPast", anim = "A-KNEEL_SOFT" }),
						cue({
							at = 1.6,
							actor = "Little",
							moveTo = B(133.4, -24.5, 19.4, 140),
							moveTime = 0.6,
						}),
						cue({ at = 0.8, line = "CS16_LIRILI_TOMORROW" }),
						cue({
							at = 4.2,
							actor = "Little",
							moveTo = B(135.3, -24.3, 20.7, 45),
							moveTime = 1.6,
							moveEasing = "SineInOut",
						}),
						cue({ at = 5.6, actor = "Little", face = "happy" }),
					},
				}),
				shot({
					-- MONTAGE (cut every 2 s): Lirili teaches it words and clocks
					n = "6a",
					t0 = 33,
					t1 = 35,
					camera = {
						shot = "MED",
						from = B(87.5, 13.8, 64.8),
						lookAt = B(89.8, 13.4, 63),
						fov = 52,
					},
					cues = {
						cue({ clockTo = 14, clockTime = 0.05 }),
						cue({ line = "CS16_LIRILI_FAMILY" }),
						cue({ actor = "LiriliPast", stopAnim = "*" }),
						cue({
							actor = "LiriliPast",
							moveTo = B(90.6, 12, 62.8, 270),
							moveTime = 0.05,
						}),
						cue({ actor = "LiriliPast", anim = "A-HOLD_UP" }),
						cue({ actor = "LiriliPast", face = "happy" }),
						cue({ actor = "Little", moveTo = B(89, 13.4, 63, 90), moveTime = 0.05 }),
						cue({ actor = "Little", anim = "A-GIALLINO_INSPECT" }),
					},
				}),
				shot({
					-- it laughs at the cuckoo clock
					n = "6b",
					t0 = 35,
					t1 = 37,
					camera = {
						shot = "MED",
						from = B(88.8, 13.8, 63.4),
						lookAt = B(87.4, 13.9, 66),
						fov = 50,
					},
					cues = {
						cue({ actor = "Cuckoo", visible = true }),
						cue({
							actor = "Little",
							moveTo = B(87.6, 13.6, 64.8, 180),
							moveTime = 0.05,
						}),
						cue({ at = 0.3, sfx = "giallino_blip_2", sfxVolume = 0.6 }),
						cue({ at = 0.4, actor = "Little", anim = "A-GIALLINO_SPIN_HAPPY" }),
					},
				}),
				shot({
					-- it dances with Ballerina on the square
					n = "6c",
					t0 = 37,
					t1 = 39,
					camera = {
						shot = "WIDE",
						from = B(74.5, 14.5, 66),
						lookAt = B(80, 13.4, 70.5),
						fov = 55,
					},
					cues = {
						cue({ actor = "BallerinaPast", visible = true }),
						cue({ actor = "BallerinaPast", anim = "A-BALLERINA_DANCE" }),
						cue({
							actor = "Little",
							orbit = {
								center = B(80, 12, 70.5),
								radius = 4,
								height = 5,
								period = 3,
								faceCenter = true,
							},
						}),
					},
				}),
				shot({
					-- it sits on the sahur table among the villagers, happy
					n = "6d",
					t0 = 39,
					t1 = 42,
					camera = {
						shot = "WIDE",
						from = B(84.5, 15.5, 72.5),
						lookAt = B(80, 13, 79.5),
						fov = 55,
					},
					cues = Kit.cues(
						{
							cue({ actor = "BallerinaPast", visible = false }),
							cue({
								actor = "Little",
								moveTo = B(80, 13.6, 79.5, 270),
								moveTime = 0.05,
							}),
							cue({ actor = "Little", face = "happy" }),
						},
						guests(function()
							return cue({ visible = true })
						end),
						guests(function()
							return cue({ anim = "A-SIT_GROUND" })
						end)
					),
				}),
				shot({
					-- CLOSE on an old screen: WILL YOU COME BACK TOMORROW? [YES] [NO] — the cursor
					-- presses NO, the screen dies; a little Giallino alone in the dark
					n = "7",
					t0 = 42,
					t1 = 50,
					camera = {
						shot = "CLOSE",
						from = B(132.5, -23.8, 22.4),
						lookAt = B(134, -24.2, 20),
						fov = 44,
					},
					cues = Kit.cues(
						{
							cue({ clockTo = 0, clockTime = 0.05 }),
							cue({ world = "oldScreen", worldParams = { duration = 6.5 } }),
							cue({
								actor = "Little",
								moveTo = B(134, -24.5, 20, 140),
								moveTime = 0.05,
							}),
							cue({ actor = "Little", face = "sad" }),
							cue({ actor = "Little", light = { glow = 0.5 } }),
							cue({ actor = "LiriliPast", visible = false }),
							cue({ at = 0.5, line = "CS16_LIRILI_GAME" }),
						},
						guests(function()
							return cue({ visible = false })
						end)
					),
				}),
				shot({
					-- WIDE, the village at night (flashback): from her window Lirili sees Ballerina's
					-- pixels sucked into the light; she covers her mouth with her trunk (A-GASP)
					n = "8",
					t0 = 50,
					t1 = 58,
					camera = {
						shot = "OTS",
						from = {
							actor = "LiriliPast",
							part = "Head",
							offset = Vector3.new(1.2, 0.4, 3.2),
						},
						lookAt = B(80, 13.2, 72),
						fov = 50,
					},
					cues = {
						cue({ actor = "LiriliPast", visible = true }),
						cue({ actor = "LiriliPast", stopAnim = "*" }),
						cue({
							actor = "LiriliPast",
							moveTo = B(88, 12, 68.8, 250),
							moveTime = 0.05,
						}),
						cue({ actor = "LiriliPast", face = "scared" }),
						cue({ actor = "BallerinaPast", visible = true }),
						cue({ actor = "BallerinaPast", moveTo = B(80, 12, 72, 0), moveTime = 0.05 }),
						cue({ actor = "BallerinaPast", stopAnim = "*" }),
						cue({ actor = "BallerinaPast", face = "scared" }),
						cue({ actor = "Little", moveTo = B(80, 16, 74, 0), moveTime = 0.05 }),
						cue({ actor = "Little", face = "happy" }),
						cue({ actor = "Little", light = { glow = 2.5 } }),
						cue({ at = 1.5, line = "CS16_LIRILI_EVERYWORD" }),
						cue({
							at = 1.0,
							actor = "BallerinaPast",
							effect = "PixelDissolve",
							effectParams = { duration = 4, targetActor = "Little" },
						}),
						cue({ at = 3.0, actor = "LiriliPast", anim = "A-GASP" }),
					},
				}),
				shot({
					-- MED, the lab (flashback): Lirili at the switch, Giallino huge in the doorway with a
					-- broken face; she throws the switch - it does not work; he floats toward her
					n = "9",
					t0 = 58,
					t1 = 68,
					camera = {
						shot = "MED",
						from = B(137, -9.6, 44),
						lookAt = B(143, -10, 39),
						fov = 56,
					},
					cues = {
						cue({
							actor = "LiriliPast",
							moveTo = B(143.6, LAB_FLOOR, 37.5, 270),
							moveTime = 0.05,
						}),
						cue({ actor = "LiriliPast", stopAnim = "*" }),
						cue({ actor = "LiriliPast", face = "scared" }),
						cue({ actor = "Little", visible = false }),
						cue({ actor = "BigGiallino", visible = true }),
						cue({ actor = "BigGiallino", anim = "A-SCALE_4" }),
						cue({ actor = "BigGiallino", light = { glow = 3 } }),
						cue({ at = 1.0, actor = "LiriliPast", anim = "A-LEVER_PULL" }),
						cue({ at = 1.4, actor = "Lever", anim = "A-LEVER_THROW" }),
						cue({ at = 1.8, sfx = "lever_click", sfxVolume = 0.9 }),
						cue({ at = 2.6, sfx = "lever_click", sfxVolume = 0.5, sfxSpeed = 0.8 }),
						cue({ at = 3.0, line = "CS16_GIALLINO_MAMMA" }),
						cue({
							at = 3.4,
							actor = "BigGiallino",
							moveTo = B(143.5, LAB_FLOOR + 2.6, 41, 225),
							moveTime = 5,
							moveEasing = "SineInOut",
						}),
					},
				}),
				shot({
					-- CLOSE on Lirili: she raises her hand with the clock, crying
					n = "10",
					t0 = 68,
					t1 = 75,
					camera = {
						shot = "CLOSE",
						from = B(141.6, -9.8, 37.4),
						lookAt = { actor = "LiriliPast", part = "Head" },
						fov = 42,
					},
					cues = {
						cue({ actor = "LiriliPast", stopAnim = "A-LEVER_PULL" }),
						cue({ actor = "LiriliPast", anim = "A-HOLD_UP" }),
						cue({ actor = "LiriliPast", face = "crying" }),
						cue({ at = 1.0, line = "CS16_LIRILI_STOPPING" }),
					},
				}),
				shot({
					-- WIDE: a wave of white light from the clock - everything around her freezes;
					-- Giallino is thrown back, screaming without a sound
					n = "11",
					t0 = 75,
					t1 = 80,
					camera = {
						shot = "WIDE",
						from = B(136, -8.5, 44.5),
						lookAt = B(142, -10.5, 39),
						fov = 64,
					},
					transitionOut = { kind = "FADE_WHITE", seconds = 1 },
					cues = {
						cue({ sfx = "clock_time_stop", sfxVolume = 1 }),
						cue({ music = "SILENCE", musicFade = 0.3 }),
						cue({
							effect = "TimeFreeze",
							effectParams = {
								centerPoint = B(143.5, -10, 37.5),
								radius = 20,
								motes = 50,
							},
						}),
						cue({ actor = "BigGiallino", face = "screen_static" }),
						cue({
							at = 0.2,
							actor = "BigGiallino",
							moveTo = B(150, LAB_FLOOR + 3, 46, 225),
							moveTime = 1.2,
							moveEasing = "QuadOut",
						}),
					},
				}),
				-------------------------------------------------- Part C: now
				shot({
					-- CLOSE: Lirili, frozen again; her eyes on the players
					n = "12",
					t0 = 80,
					t1 = 88,
					grade = "CAVE",
					gradeTime = 0.3,
					transitionIn = { kind = "FADE_WHITE", seconds = 1 },
					camera = {
						shot = "CLOSE",
						from = B(141.4, -9.7, 42.6),
						lookAt = { actor = "Lirili", part = "Head" },
						fov = 42,
					},
					cues = {
						cue({ actor = "LiriliPast", visible = false }),
						cue({ actor = "BigGiallino", visible = false }),
						cue({ actor = "Lirili", visible = true }),
						cue({ music = "music_tragic", musicVolume = 0.3, musicFade = 2 }),
						cue({ at = 1.0, line = "CS16_LIRILI_GEARS" }),
					},
				}),
				shot({
					-- ECU on her frozen tear -> RACK to the three empty gear sockets in the clock
					n = "13",
					t0 = 88,
					t1 = 95,
					camera = {
						shot = "ECU",
						from = B(140.8, -9.6, 40.6),
						lookAt = { actor = "Lirili", part = "Head" },
						fov = 34,
						rack = {
							from = { actor = "Lirili", part = "Head" },
							to = B(140, -9.5, 36.6),
							at = 1.5,
							time = 2,
						},
						moves = { move({ kind = "PAN_L", angle = 12, from = 0.2, to = 0.6 }) },
					},
					transitionOut = { kind = "FADE_BLACK", seconds = 1 },
					cues = { cue({ at = 0.5, line = "CS16_LIRILI_AFRAID" }) },
				}),
			},
		},
	},
}

return data
