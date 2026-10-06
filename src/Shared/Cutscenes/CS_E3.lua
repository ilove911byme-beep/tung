--!strict
-- CS-E3 "SAHUR" (the secret ending, lock, ~95 s + 12 s after the credits), cutscenes.md — the
-- most important tragic-and-warm scene. The giant shrinks into a little scared cube on the tower
-- floor; Lirili climbs up slowly, kneels, holds it: "No doesn't mean goodbye."; its first pixel
-- tears; the music box plays on from the note where it stopped in CS-05; "Repeat after me. No."
-- - "...No."; the pixels breathe out of it toward the square, its color turns pale gold; Ballerina
-- comes back and hugs Cappuccino, Patapim blooms again; the dawn table where everybody says each
-- other's names; "...That's my name." Entry "post": Tung Tung knocks softly on the inn door and
-- a little pale-gold Giallino opens it.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local PALE_GOLD = Color3.fromRGB(232, 217, 160)
local SQUARE = Vector3.new(80 * 4, 13 * 4, 84 * 4)

type Seat = { id: string, x: number, z: number }
local function seat(id: string, x: number, z: number): Seat
	return { id = id, x = x, z = z }
end
local SEATS: { Seat } = {
	seat("Tralalero", 78.4, 74.7),
	seat("Chimpanzini", 81.6, 74.7),
	seat("TrippiTroppi", 78.4, 76.2),
	seat("BonecaAmbalabu", 81.6, 76.2),
	seat("Ballerina", 78.4, 77.7),
	seat("Cappuccino", 81.6, 77.7),
	seat("FrigoCamelo", 78.4, 79.2),
	seat("UdinDinDinDun", 81.6, 79.2),
	seat("LaVacaSaturno", 78.4, 80.7),
	seat("GlorboFruttodrillo", 81.6, 80.7),
	seat("Strawberry", 78.4, 82.2),
	seat("Banana", 81.6, 82.2),
	seat("Lirili", 78.4, 83.7),
	seat("Bombardiro", 81.6, 83.7),
	seat("Patapim", 81.6, 85.2),
}

local actors: { Types.ActorSpec } = {
	Kit.actor({ id = "Giallino", model = "Giallino", at = B(80, 49, 69.5, 0), face = "scared" }),
	Kit.actor({
		id = "TungTung",
		model = "TungTung",
		at = B(80, 12, 73.3, 180),
		face = "happy",
		visible = false,
	}),
	Kit.actor({
		id = "Door",
		model = "Door",
		at = { anchor = "Anchor_Origin", offset = Vector3.new(70 * 4, 12 * 4, 84.5 * 4), yaw = 90 },
		footsteps = false,
	}),
	Kit.actor({
		id = "LittleAtDoor",
		model = "Giallino",
		at = B(69.6, 12.7, 84, 90),
		face = "happy",
		visible = false,
	}),
}
local START: { [string]: Types.Point } = {
	Lirili = B(82.5, 42, 64.6, 200),
	Ballerina = B(79, 12, 86.5, 90),
	Cappuccino = B(83.6, 12, 86.5, 270),
	Patapim = B(74.5, 12, 92, 45),
}
for _, s in SEATS do
	local id = s.id
	table.insert(actors, {
		id = id,
		model = id,
		at = START[id] or B(s.x, 12, s.z, if s.x < 80 then 90 else 270),
		face = if id == "Lirili" then "tired" else "happy",
		visible = false,
	})
end

local function seatCues(): { Types.Cue }
	local out: { Types.Cue } = {}
	for _, s in SEATS do
		local id = s.id
		local x, z = s.x, s.z
		table.insert(out, cue({ actor = id, visible = true }))
		table.insert(out, cue({ actor = id, stopAnim = "*" }))
		table.insert(
			out,
			cue({ actor = id, moveTo = B(x, 12, z, if x < 80 then 90 else 270), moveTime = 0.05 })
		)
		table.insert(out, cue({ at = 0.1, actor = id, anim = "A-SIT_GROUND" }))
		table.insert(out, cue({ actor = id, face = "happy" }))
	end
	table.insert(
		out,
		cue({ actor = "Bombardiro", effect = "ShowPart", effectParams = { part = "Bandage" } })
	)
	table.insert(out, cue({ actor = "TungTung", visible = true }))
	table.insert(out, cue({ actor = "TungTung", anim = "A-IDLE_BREATH" }))
	-- the pale-gold little light sits on Lirili's shoulder
	table.insert(
		out,
		cue({ actor = "Giallino", effect = "Shrink", effectParams = { to = 0.3, duration = 0.05 } })
	)
	table.insert(
		out,
		cue({ at = 0.2, actor = "Giallino", moveTo = B(78.1, 14.15, 83.7, 90), moveTime = 0.05 })
	)
	return out
end

local names = {
	"Ballerina Cappuccina",
	"Lirili Larila",
	"Bombardiro Crocodilo",
	"Brr Brr Patapim",
	"Frigo Camelo",
	"Udin Din Din Dun",
	"Cappuccino Assassino",
	"Tung Tung Tung Sahur",
	"Giallino",
}

local data: Types.Cutscene = {
	id = "CS_E3",
	title = "Sahur",
	noSkip = true,
	grade = "NIGHT",
	clockTime = 5.2,
	actors = actors,
	players = { mode = "hide" },
	hideNpcs = {
		"Giallino",
		"TungTung",
		"Tralalero",
		"Chimpanzini",
		"TrippiTroppi",
		"BonecaAmbalabu",
		"Ballerina",
		"Cappuccino",
		"FrigoCamelo",
		"UdinDinDinDun",
		"LaVacaSaturno",
		"GlorboFruttodrillo",
		"Strawberry",
		"Banana",
		"Lirili",
		"Bombardiro",
		"Patapim",
	},
	entry = "main",
	segments = {
		main = {
			length = 95,
			shots = {
				shot({
					-- WIDE, the top of the tower: the giant shrinks to a little cube and falls to the floor, scared
					n = "1",
					t0 = 0,
					t1 = 6,
					camera = {
						shot = "WIDE",
						from = B(76.4, 44.5, 63.2),
						lookAt = B(80, 44, 68.5),
						fov = 64,
					},
					cues = {
						cue({ music = "SILENCE", musicFade = 1 }),
						cue({ actor = "Giallino", anim = "A-GIALLINO_FALL_SMALL" }),
						cue({
							actor = "Giallino",
							moveTo = B(80, 43.6, 67.8, 0),
							moveTime = 1.0,
							moveEasing = "QuadIn",
						}),
						cue({ at = 1.0, sfx = "block_place_wood", sfxVolume = 0.8 }),
						cue({ at = 1.5, sfx = "block_place_wood", sfxVolume = 0.5 }),
					},
				}),
				shot({
					-- MED: Lirili comes up the stairs - time thawed only partly, she moves slowly
					-- (A-WALK_TIRED) - and kneels beside it
					n = "2",
					t0 = 6,
					t1 = 14,
					camera = {
						shot = "MED",
						from = B(77, 43.8, 69.2),
						lookAt = B(81, 43, 66),
						fov = 52,
					},
					cues = {
						cue({ actor = "Lirili", visible = true }),
						cue({ actor = "Lirili", anim = "A-WALK_TIRED" }),
						cue({
							actor = "Lirili",
							moveTo = B(80.9, 42, 66.6, 225),
							moveTime = 4.6,
							moveEasing = "Linear",
						}),
						cue({ at = 4.6, actor = "Lirili", stopAnim = "A-WALK_TIRED" }),
						cue({ at = 4.7, actor = "Lirili", anim = "A-KNEEL_SOFT" }),
						cue({ at = 5.6, line = "E3_LIRILI_HELLO" }),
					},
				}),
				shot({
					-- CLOSE on Giallino: it backs away, scared
					n = "3",
					t0 = 14,
					t1 = 20,
					camera = {
						shot = "CLOSE",
						from = B(79.2, 43.5, 66.4),
						lookAt = { actor = "Giallino" },
						fov = 42,
					},
					cues = {
						cue({ actor = "Giallino", faceToward = B(80.9, 43, 66.6) }),
						cue({
							at = 0.4,
							actor = "Giallino",
							moveTo = B(79.6, 43.6, 68.4, 0),
							moveTime = 1.2,
							moveEasing = "QuadOut",
						}),
						cue({ at = 1.2, line = "E3_GIALLINO_LEAVING" }),
					},
				}),
				shot({
					-- CLOSE on Lirili: she lifts it with her trunk and holds it close, sad
					n = "4",
					t0 = 20,
					t1 = 30,
					camera = {
						shot = "CLOSE",
						from = B(79, 43.9, 65.6),
						lookAt = { actor = "Lirili", part = "Head" },
						fov = 44,
					},
					cues = {
						cue({ actor = "Lirili", face = "sad" }),
						cue({
							at = 0.6,
							actor = "Giallino",
							moveTo = {
								actor = "Lirili",
								part = "Head",
								offset = Vector3.new(0, -1.6, -1.6),
							},
							moveTime = 2,
							moveEasing = "SineInOut",
						}),
						cue({ at = 1.4, line = "E3_LIRILI_LISTEN" }),
					},
				}),
				shot({
					-- ECU on Giallino: for the first time, pixel tears on its screen; the music box plays
					-- again from the very note where it stopped in CS-05
					n = "5",
					t0 = 30,
					t1 = 36,
					camera = {
						shot = "ECU",
						from = { actor = "Giallino", offset = Vector3.new(0, 0, -6) },
						lookAt = { actor = "Giallino" },
						fov = 36,
					},
					cues = {
						cue({ actor = "Giallino", face = "crying" }),
						cue({
							at = 0.6,
							music = "music_lullaby_box",
							musicVolume = 0.4,
							musicFade = 1,
						}),
					},
				}),
				shot({
					-- MED
					n = "6",
					t0 = 36,
					t1 = 42,
					camera = {
						shot = "MED",
						from = B(77.6, 44, 64.4),
						lookAt = B(80.6, 43.2, 66.4),
						fov = 50,
					},
					cues = { cue({ at = 0.8, line = "E3_LIRILI_REPEAT" }) },
				}),
				shot({
					-- CLOSE on Giallino, a long pause
					n = "7",
					t0 = 42,
					t1 = 48,
					camera = {
						shot = "CLOSE",
						from = { actor = "Giallino", offset = Vector3.new(0, 0.2, -7) },
						lookAt = { actor = "Giallino" },
						fov = 40,
						moves = { move({ kind = "DOLLY_IN", amount = 0.12 }) },
					},
					cues = {
						cue({ actor = "Giallino", face = "sad" }),
						cue({ at = 3.0, line = "E3_GIALLINO_NO" }),
					},
				}),
				shot({
					-- WIDE: pixels gently leave the cube - not an explosion, a breath - and fly down to the
					-- square; its color turns from acid yellow to pale gold
					n = "8",
					t0 = 48,
					t1 = 58,
					grade = "DAWN",
					gradeTime = 6,
					camera = {
						shot = "WIDE",
						from = B(84, 45.5, 61.5),
						lookAt = B(80, 40, 72),
						fov = 60,
						moves = { move({ kind = "CRANE_UP", amount = 8 }) },
					},
					cues = {
						cue({ clockTo = 6.4, clockTime = 8 }),
						cue({
							actor = "Giallino",
							effect = "Transform",
							effectParams = { color = PALE_GOLD, glow = 0.8, duration = 6 },
						}),
						cue({
							world = "fireflies",
							worldParams = {
								at = Vector3.new(80.4 * 4, 43 * 4, 66.6 * 4),
								toward = SQUARE,
								count = 140,
								duration = 8,
							},
						}),
						cue({ at = 1.0, music = "ending_dawn", musicVolume = 0.6, musicFade = 2 }),
					},
				}),
				shot({
					-- MED, the square: Ballerina comes back together from the pixels, sees Cappuccino, they
					-- hug; behind them Patapim blooms with new leaves
					n = "9",
					t0 = 58,
					t1 = 68,
					camera = {
						shot = "MED",
						from = B(80.8, 14, 91.6),
						lookAt = B(80.6, 13, 86.6),
						fov = 54,
					},
					cues = {
						cue({ actor = "Ballerina", visible = true }),
						cue({
							actor = "Ballerina",
							effect = "PixelAssemble",
							effectParams = { duration = 2.5, spiral = true, flash = true },
						}),
						cue({ actor = "Cappuccino", visible = true }),
						cue({ actor = "Cappuccino", face = "crying" }),
						cue({ actor = "Patapim", visible = true }),
						cue({ at = 0.5, actor = "Patapim", anim = "A-PATAPIM_BLOOM" }),
						cue({
							at = 3.0,
							actor = "Ballerina",
							moveTo = B(82.8, 12, 86.5, 90),
							moveTime = 1.4,
						}),
						cue({ at = 3.0, actor = "Ballerina", anim = "A-RUN" }),
						cue({ at = 4.4, actor = "Ballerina", stopAnim = "A-RUN" }),
						cue({ at = 4.4, actor = "Ballerina", anim = "A-HUG" }),
						cue({ at = 4.4, actor = "Cappuccino", anim = "A-HUG" }),
						cue({ at = 5.4, line = "E3_BALLERINA_TOMORROW" }),
					},
				}),
				shot({
					-- CRANE UP, sunrise, the long sahur table: everybody, Tung Tung at the head, Bombardiro
					-- with a bandaged wing, the pale-gold Giallino on Lirili's shoulder; names roll by
					n = "10",
					t0 = 68,
					t1 = 80,
					camera = {
						shot = "WIDE",
						from = B(86, 14.2, 90),
						lookAt = B(80, 13, 79.5),
						fov = 58,
						moves = { move({ kind = "CRANE_UP", amount = 26, easing = "SineInOut" }) },
					},
					cues = Kit.cues(seatCues(), {
						cue({
							at = 1.0,
							world = "nameRoll",
							worldParams = { names = names, duration = 10 },
						}),
						cue({ at = 1.0, line = "E3_TUNG_NAMES" }),
					}),
				}),
				shot({
					-- CLOSE on Giallino: happy - truly, no static
					n = "11",
					t0 = 80,
					t1 = 88,
					camera = {
						shot = "CLOSE",
						from = B(79.6, 14.4, 82.6),
						lookAt = { actor = "Giallino" },
						fov = 36,
					},
					cues = {
						cue({ actor = "Giallino", face = "happy" }),
						cue({ at = 1.0, line = "E3_GIALLINO_NAME" }),
					},
				}),
				shot({
					-- FADE BLACK -> the credits (played by the chapter, then the "post" entry)
					n = "12",
					t0 = 88,
					t1 = 95,
					camera = {
						shot = "WIDE",
						from = B(92, 26, 96),
						lookAt = B(80, 14, 80),
						fov = 60,
					},
					transitionOut = { kind = "FADE_BLACK", seconds = 4 },
				}),
			},
		},
		post = {
			length = 12,
			shots = {
				shot({
					-- after the credits: a quiet dawn; Tung Tung knocks softly on the inn door, and the
					-- door is opened by a little Giallino
					n = "P",
					t0 = 0,
					t1 = 12,
					grade = "DAWN",
					gradeTime = 0.1,
					transitionIn = { kind = "FADE_BLACK", seconds = 2 },
					camera = {
						shot = "WIDE",
						from = B(76.2, 14, 88.4),
						lookAt = B(71, 13.4, 84.2),
						fov = 52,
					},
					cues = {
						cue({ clockTo = 6.6, clockTime = 0.05 }),
						cue({ actor = "TungTung", visible = true }),
						cue({ actor = "TungTung", moveTo = B(71.6, 12, 84, 270), moveTime = 0.05 }),
						cue({ actor = "TungTung", face = "happy" }),
						cue({ at = 1.5, actor = "TungTung", anim = "A-KNOCK_SOFT" }),
						cue({ at = 1.8, line = "E3_TUNG_MORNING" }),
						cue({ at = 6.4, actor = "Door", anim = "A-DOOR_OPEN_SLOW" }),
						cue({ at = 6.4, sfx = "door_open", sfxVolume = 0.6 }),
						cue({ at = 6.6, actor = "LittleAtDoor", visible = true }),
						cue({
							at = 6.6,
							actor = "LittleAtDoor",
							effect = "Transform",
							effectParams = { color = PALE_GOLD, glow = 0.8, duration = 0.05 },
						}),
						cue({
							at = 6.7,
							actor = "LittleAtDoor",
							effect = "Shrink",
							effectParams = { to = 0.5, duration = 0.05 },
						}),
						cue({ at = 7.0, actor = "LittleAtDoor", anim = "A-GIALLINO_BOW" }),
					},
					transitionOut = { kind = "FADE_BLACK", seconds = 2 },
				}),
			},
		},
	},
}

return data
