--!strict
-- CS-E1 "DAWN" (the good ending, lock, ~70 s), cutscenes.md. The players pull the shutdown lever,
-- Giallino dims and shrinks to a pixel that goes out; thousands of pixels fly over the valley
-- like fireflies and assemble back into the vanished villagers; time starts again in the lab,
-- Lirili's tear finally falls; Tung Tung wakes at the tower door ("free") or steps out of the
-- barn ("jailed"); Ballerina runs into Cappuccino's arms; the long sahur table at sunrise with one
-- empty plate and a little yellow lamp.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

-- seats at the long table: left side faces east, right side faces west
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
	seat("TungTung", 78.4, 85.2),
}

local actors: { Types.ActorSpec } = {
	Kit.actor({ id = "Giallino", model = "Giallino", at = B(80, 43.6, 68.6, 0), face = "sad" }),
	Kit.actor({ id = "Lever", model = "Lever", at = B(81.4, 42, 65.4, 180), footsteps = false }),
	Kit.actor({ id = "P1", model = "@Player1", at = B(81.4, 42, 64.4, 180), footsteps = false }),
	Kit.actor({
		id = "Plate",
		model = "LampPlate",
		at = B(80.6, 12.85, 85.2),
		visible = false,
		footsteps = false,
	}),
	Kit.actor({
		id = "JailGateN",
		model = "Gate",
		at = {
			anchor = "Anchor_Origin",
			offset = Vector3.new(99.5 * 4, 12 * 4, 66.5 * 4),
			yaw = -90,
		},
		footsteps = false,
	}),
	Kit.actor({
		id = "JailGateS",
		model = "Gate",
		at = {
			anchor = "Anchor_Origin",
			offset = Vector3.new(99.5 * 4, 12 * 4, 69.5 * 4),
			yaw = 90,
		},
		footsteps = false,
	}),
}
local START: { [string]: Types.Point } = {
	Ballerina = B(79, 12, 84, 90),
	FrigoCamelo = B(81.5, 12, 83, 180),
	UdinDinDinDun = B(77.5, 12, 82.4, 0),
	Lirili = B(140, -12, 39.4, 0),
	TungTung = B(80, 12, 68.3, 0),
	Cappuccino = B(84.2, 12, 86, 270),
}
for _, s in SEATS do
	local id = s.id
	table.insert(actors, {
		id = id,
		model = id,
		at = START[id] or B(s.x, 12, s.z, if s.x < 80 then 90 else 270),
		face = "happy",
		visible = START[id] ~= nil
			and id ~= "Ballerina"
			and id ~= "FrigoCamelo"
			and id ~= "UdinDinDinDun",
	})
end

local function seatCues(t: number): { Types.Cue }
	local out: { Types.Cue } = {}
	for _, s in SEATS do
		local id = s.id
		local x, z = s.x, s.z
		table.insert(out, cue({ at = t, actor = id, visible = true }))
		table.insert(out, cue({ at = t, actor = id, stopAnim = "*" }))
		table.insert(
			out,
			cue({
				at = t,
				actor = id,
				moveTo = B(x, 12, z, if x < 80 then 90 else 270),
				moveTime = 0.05,
			})
		)
		table.insert(out, cue({ at = t + 0.1, actor = id, anim = "A-SIT_GROUND" }))
		table.insert(out, cue({ at = t, actor = id, face = "happy" }))
	end
	table.insert(
		out,
		cue({
			at = t,
			actor = "Bombardiro",
			effect = "ShowPart",
			effectParams = { part = "Bandage" },
		})
	)
	table.insert(out, cue({ at = t, actor = "Plate", visible = true }))
	return out
end

local function dawnShots(tungShot: Types.Shot): { Types.Shot }
	return {
		shot({
			-- CLOSE on Giallino, the players pull the shutdown lever; the face dims, the cube shrinks to a pixel
			n = "1",
			t0 = 0,
			t1 = 6,
			camera = {
				shot = "CLOSE",
				from = B(80, 43.9, 64.2),
				lookAt = { actor = "Giallino" },
				fov = 42,
			},
			cues = {
				cue({ music = "dusk_piano_theme", musicVolume = 0.35, musicFade = 2 }),
				cue({ actor = "P1", anim = "A-LEVER_PULL" }),
				cue({ at = 0.4, actor = "Lever", anim = "A-LEVER_THROW" }),
				cue({ at = 0.5, line = "E1_GIALLINO_GOOD" }),
				cue({ at = 1.0, actor = "Giallino", faceDim = 1, faceDimTime = 4.5 }),
				cue({ at = 1.0, actor = "Giallino", light = { glow = 0.1, time = 4.5 } }),
				cue({
					at = 1.0,
					actor = "Giallino",
					effect = "Shrink",
					effectParams = { to = 0.06, duration = 4.6 },
				}),
			},
		}),
		shot({
			-- ECU: the tiny yellow dot goes out; silence
			n = "2",
			t0 = 6,
			t1 = 10,
			camera = {
				shot = "ECU",
				from = B(80, 43.65, 67.6),
				lookAt = B(80, 43.6, 68.6),
				fov = 30,
			},
			cues = {
				cue({ music = "SILENCE", musicFade = 1 }),
				cue({ actor = "Giallino", visible = false }),
				cue({
					effect = "LastPixel",
					effectAt = B(80, 43.6, 68.6),
					effectParams = { duration = 2.6 },
				}),
			},
		}),
		shot({
			-- WIDE: thousands of pixels fly out over the valley like fireflies
			n = "3",
			t0 = 10,
			t1 = 20,
			grade = "DAWN",
			gradeTime = 5,
			camera = {
				shot = "WIDE",
				from = B(98, 40, 96),
				lookAt = B(80, 36, 68),
				fov = 62,
				moves = { move({ kind = "CRANE_UP", amount = 12 }) },
			},
			cues = {
				cue({ clockTo = 6.3, clockTime = 8 }),
				cue({ music = "ending_dawn", musicVolume = 0.6, musicFade = 0.5 }),
				cue({
					world = "fireflies",
					worldParams = {
						at = Vector3.new(80 * 4, 44 * 4, 68 * 4),
						count = 240,
						radius = 220,
						duration = 9,
					},
				}),
			},
		}),
		shot({
			-- MED, the square: the pixels assemble into the villagers - Ballerina, Frigo, Udin - who look around, lost
			n = "4",
			t0 = 20,
			t1 = 30,
			camera = {
				shot = "MED",
				from = B(84.4, 14, 89.4),
				lookAt = B(79.5, 13, 83.4),
				fov = 54,
			},
			cues = {
				cue({ actor = "Ballerina", visible = true }),
				cue({
					actor = "Ballerina",
					effect = "PixelAssemble",
					effectParams = { duration = 2.5, spiral = true },
				}),
				cue({ at = 0.7, actor = "FrigoCamelo", visible = true }),
				cue({
					at = 0.7,
					actor = "FrigoCamelo",
					effect = "PixelAssemble",
					effectParams = { duration = 2.5, spiral = true },
				}),
				cue({ at = 1.4, actor = "UdinDinDinDun", visible = true }),
				cue({
					at = 1.4,
					actor = "UdinDinDinDun",
					effect = "PixelAssemble",
					effectParams = { duration = 2.5, spiral = true },
				}),
				cue({ at = 4.0, actor = "Ballerina", face = "shocked" }),
				cue({ at = 4.4, actor = "Ballerina", faceToward = B(86, 13, 80) }),
				cue({ at = 4.8, actor = "FrigoCamelo", faceToward = B(76, 13, 88) }),
				cue({ at = 5.2, actor = "UdinDinDinDun", anim = "A-LOOK_UP" }),
			},
		}),
		shot({
			-- WIDE, the mine -> the lab: time starts again; Lirili breathes out, falls to her knees,
			-- her tear finally falls (A-RELEASE_TIME)
			n = "5",
			t0 = 30,
			t1 = 38,
			grade = "CAVE",
			gradeTime = 0.5,
			camera = {
				shot = "MED",
				from = B(141.4, -9.8, 43),
				lookAt = { actor = "Lirili", part = "Head" },
				fov = 46,
			},
			cues = {
				cue({ actor = "Lirili", anim = "A-FROZEN_STEP" }),
				cue({ actor = "Lirili", face = "crying" }),
				cue({ actor = "Lirili", effect = "ShowPart", effectParams = { part = "Tear" } }),
				cue({ at = 0.6, effect = "TimeResume" }),
				cue({ at = 0.8, actor = "Lirili", anim = "A-RELEASE_TIME" }),
				cue({
					at = 2.2,
					actor = "Lirili",
					effect = "DropItem",
					effectParams = { part = "Tear", life = 3 },
				}),
				cue({ at = 3.4, line = "E1_LIRILI_SORRY" }),
			},
		}),
		tungShot,
		shot({
			-- WIDE: Ballerina runs in and hugs Cappuccino Assassino (A-HUG)
			n = "7",
			t0 = 46,
			t1 = 52,
			grade = "DAWN",
			gradeTime = 0.5,
			camera = {
				shot = "WIDE",
				from = B(81.6, 14.4, 91.6),
				lookAt = B(82.4, 13, 86),
				fov = 54,
			},
			cues = {
				cue({ actor = "Ballerina", moveTo = B(78.4, 12, 86, 90), moveTime = 0.05 }),
				cue({ actor = "Ballerina", face = "happy" }),
				cue({ actor = "Cappuccino", face = "crying" }),
				cue({ at = 0.2, actor = "Ballerina", anim = "A-RUN" }),
				cue({
					at = 0.2,
					actor = "Ballerina",
					moveTo = B(83.3, 12, 86, 90),
					moveTime = 2,
					moveEasing = "Linear",
				}),
				cue({ at = 2.2, actor = "Ballerina", stopAnim = "A-RUN" }),
				cue({ at = 2.2, actor = "Ballerina", anim = "A-HUG" }),
				cue({ at = 2.2, actor = "Cappuccino", anim = "A-HUG" }),
			},
		}),
		shot({
			-- CRANE UP over the long sahur table: everybody at the table; one place has an empty plate
			-- with a little yellow lamp
			n = "8",
			t0 = 52,
			t1 = 62,
			camera = {
				shot = "WIDE",
				from = B(86, 14, 90),
				lookAt = B(80, 13, 80),
				fov = 58,
				moves = { move({ kind = "CRANE_UP", amount = 28, easing = "SineInOut" }) },
			},
			cues = Kit.cues(seatCues(0), { cue({ at = 1.2, line = "E1_NARR_SUN" }) }),
		}),
		shot({
			-- ECU on the empty chair with the lamp -> FADE BLACK 3 s -> credits
			n = "9",
			t0 = 62,
			t1 = 70,
			camera = {
				shot = "ECU",
				from = B(80.2, 13.6, 87.2),
				lookAt = B(80.6, 13, 85.2),
				fov = 36,
			},
			transitionOut = { kind = "FADE_BLACK", seconds = 3 },
		}),
	}
end

local tungFree = shot({
	-- MED, the bottom of the tower: Tung Tung lies unconscious by the door; somebody shakes him
	-- gently and he opens his eyes
	n = "6",
	t0 = 38,
	t1 = 46,
	grade = "DAWN",
	gradeTime = 0.5,
	camera = {
		shot = "MED",
		from = B(80.6, 13.6, 65.6),
		lookAt = { actor = "TungTung", part = "Head" },
		fov = 48,
	},
	cues = {
		cue({ actor = "TungTung", anim = "A-SLIDE_DOWN_DOOR", animSpeed = 40 }),
		cue({ actor = "TungTung", face = "eyes_closed" }),
		cue({ actor = "P1", moveTo = B(80.6, 12, 67.2, 200), moveTime = 0.05 }),
		cue({ actor = "P1", stopAnim = "*" }),
		cue({ at = 0.3, actor = "P1", anim = "A-KNEEL_SOFT" }),
		cue({ at = 3.2, actor = "TungTung", face = "tired" }),
		cue({ at = 4.2, line = "E1_TUNG_SAHUR" }),
	},
})

local tungJailed = shot({
	-- MED, the barn at dawn: the gate swings open and Tung Tung steps out, blinking at the light
	n = "6",
	t0 = 38,
	t1 = 46,
	grade = "DAWN",
	gradeTime = 0.5,
	camera = { shot = "MED", from = B(95.5, 13.8, 70.5), lookAt = B(99.6, 13.4, 68), fov = 50 },
	cues = {
		cue({ actor = "TungTung", moveTo = B(101, 12, 68, 270), moveTime = 0.05 }),
		cue({ actor = "TungTung", face = "tired" }),
		cue({ at = 0.5, actor = "JailGateN", anim = "A-DOOR_OPEN_SLOW" }),
		cue({ at = 0.5, actor = "JailGateS", anim = "A-DOOR_OPEN_SLOW" }),
		cue({ at = 0.5, sfx = "door_open", sfxVolume = 0.8, sfxSpeed = 0.7 }),
		cue({ at = 2.5, actor = "TungTung", anim = "A-WALK" }),
		cue({ at = 2.5, actor = "TungTung", moveTo = B(97.4, 12, 68, 270), moveTime = 2 }),
		cue({ at = 4.5, actor = "TungTung", stopAnim = "A-WALK" }),
		cue({ at = 4.6, line = "E1_TUNG_SAHUR" }),
	},
})

local data: Types.Cutscene = {
	id = "CS_E1",
	title = "Dawn",
	noSkip = true,
	grade = "NIGHT",
	clockTime = 5.6,
	actors = actors,
	players = { mode = "hide" },
	hideNpcs = {
		"Giallino",
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
		"TungTung",
	},
	entry = "free",
	segments = {
		free = { length = 70, shots = dawnShots(tungFree) },
		jailed = { length = 70, shots = dawnShots(tungJailed) },
	},
}

return data
