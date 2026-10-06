--!strict
-- CS-05 "Ballerina's last dance" (lock, ~48 s), cutscenes.md. TRAGIC: timings are exact.
-- Seen through the tavern window. Coordinates are local to Anchor_Square_Center, which faces
-- west toward the tavern: -Z = toward the tavern window. Ballerina dances 14 studs from the
-- center, facing the window. Music: Giallino's music box (music_lullaby_box at volume 0.4),
-- music_lullaby_stop at shot 6 (brief, MusicDirector).
local Types = require(script.Parent.Parent.Types)

-- typed wrappers so the type checker validates every entry on its own
local function cue(c: Types.Cue): Types.Cue
	return c
end

local function shot(s: Types.Shot): Types.Shot
	return s
end

local function move(m: Types.CameraMoveSpec): Types.CameraMoveSpec
	return m
end

local SQUARE = "Anchor_Square_Center"
local WINDOW = "Anchor_Tavern_Window"

local function sq(x: number, y: number, z: number, yaw: number?): Types.Point
	return { anchor = SQUARE, offset = Vector3.new(x, y, z), yaw = yaw }
end

local DANCE_SPOT = sq(0, 0, -14)
local GIALLINO: Types.Point = { actor = "Giallino" }
local LIGHT_CIRCLE: Types.PropSpec =
	{ id = "LightCircle", kind = "LightCircle", at = DANCE_SPOT, radius = 5.5 }
local BALLERINA_HEAD: Types.Point = { actor = "Ballerina", part = "Head" }

local data: Types.Cutscene = {
	id = "CS_05",
	title = "Ballerina's Last Dance",
	noSkip = true,
	grade = "NIGHT_DEEP",
	clockTime = 0.5,
	actors = {
		{ id = "Ballerina", model = "Ballerina", at = DANCE_SPOT, face = "happy" },
		{ id = "Giallino", model = "Giallino", at = sq(6, 7.5, -14), face = "happy" },
	},
	props = { LIGHT_CIRCLE },
	players = { mode = "hide" },
	hideNpcs = { "Ballerina", "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 48,
			shots = {
				shot({
					-- POV through the tavern window, slow dolly in through the glass
					n = "1",
					t0 = 0,
					t1 = 5,
					camera = {
						shot = "POV",
						from = { anchor = WINDOW, offset = Vector3.new(0, 0, 3) },
						lookAt = sq(0, 3.2, -14),
						fov = 60,
						moves = { move({ kind = "DOLLY_IN", amount = 0.28 }) },
					},
					cues = {
						cue({ music = "music_lullaby_box", musicVolume = 0.4, musicFade = 1.5 }),
						cue({ actor = "Ballerina", anim = "A-BALLERINA_DANCE" }),
						cue({
							actor = "Giallino",
							orbit = {
								center = DANCE_SPOT,
								radius = 6,
								height = 7.5,
								period = 7,
								faceCenter = true,
							},
							light = { spot = true, glow = 1.4 },
						}),
					},
				}),
				shot({
					-- WIDE, slow orbit: Giallino circles her like a searchlight; she smiles but is tired
					n = "2",
					t0 = 5,
					t1 = 12,
					camera = {
						shot = "WIDE",
						from = sq(15, 9, -4),
						lookAt = sq(0, 2.8, -14),
						fov = 60,
						moves = { move({ kind = "ORBIT", angle = 35 }) },
					},
					cues = {
						cue({
							at = 0.3,
							actor = "Ballerina",
							anim = "A-BALLERINA_DANCE",
							animSpeed = 0.8,
						}),
						cue({ at = 0.6, line = "CS05_GIALLINO_FOREVER" }),
					},
				}),
				shot({
					-- MED on Ballerina: she slows down, arms come down, face tired
					n = "3",
					t0 = 12,
					t1 = 17,
					camera = {
						shot = "MED",
						lookAt = {
							actor = "Ballerina",
							part = "Torso",
							offset = Vector3.new(0, 0.6, 0),
						},
						distance = 9,
						side = 35,
						fov = 50,
					},
					cues = {
						cue({ actor = "Ballerina", anim = "A-BALLERINA_SLOW_STOP" }),
						cue({
							actor = "Giallino",
							moveTo = sq(0, 2.3, -17.3, 180),
							moveTime = 2.6,
							light = { spot = false, glow = 1.2, time = 1 },
						}),
						cue({ at = 0.8, line = "CS05_BALLERINA_TIRED" }),
						cue({ at = 1.4, actor = "Ballerina", face = "tired" }),
					},
				}),
				shot({
					-- CLOSE on Giallino: the happy face twitches, one frame of static
					n = "4",
					t0 = 17,
					t1 = 21,
					camera = { shot = "CLOSE", lookAt = GIALLINO, distance = 7, side = 40 },
					cues = {
						cue({
							at = 0.6,
							actor = "Giallino",
							face = "screen_static",
							faceFor = 1 / 30,
						}),
						cue({ at = 1.0, line = "CS05_GIALLINO_TOMORROW" }),
					},
				}),
				shot({
					-- CLOSE, LOW on Ballerina: she kneels and strokes Giallino like a child
					n = "5",
					t0 = 21,
					t1 = 26,
					camera = {
						shot = "CLOSE",
						low = true,
						lookAt = BALLERINA_HEAD,
						distance = 6,
						side = -35,
					},
					cues = {
						cue({ actor = "Ballerina", anim = "A-KNEEL_SOFT" }),
						cue({ at = 0.9, line = "CS05_BALLERINA_NOT_FOREVER" }),
						cue({ at = 1.5, actor = "Ballerina", anim = "A-STROKE_SOFT" }),
					},
				}),
				shot({
					-- ECU Giallino's face: silence, the screen slowly darkens, the music box stops mid-note
					n = "6",
					t0 = 26,
					t1 = 29,
					camera = { shot = "ECU", lookAt = GIALLINO, distance = 4.2, side = 15 },
					cues = {
						cue({ music = "music_lullaby_stop", musicVolume = 0.4, musicFade = 0.15 }),
						cue({
							actor = "Giallino",
							faceDim = 0.85,
							faceDimTime = 2.8,
							light = { glow = 0.35, time = 2.8 },
						}),
						cue({ actor = "Ballerina", stopAnim = "A-STROKE_SOFT" }),
					},
				}),
				shot({
					-- ECU Ballerina's face: she understands. scared -> sad
					n = "7",
					t0 = 29,
					t1 = 31,
					camera = { shot = "ECU", lookAt = BALLERINA_HEAD, distance = 3.0, side = 20 },
					cues = {
						cue({ actor = "Ballerina", face = "scared" }),
						cue({ at = 1.0, actor = "Ballerina", face = "sad" }),
					},
				}),
				shot({
					-- MED STATIC: A-PIXEL_DISSOLVE from the feet up, pixels rise into Giallino;
					-- she reaches toward the tavern window, crying
					n = "8",
					t0 = 31,
					t1 = 40,
					camera = {
						shot = "MED",
						from = sq(4.5, 4.6, -23),
						lookAt = sq(0, 3.0, -15),
						fov = 55,
					},
					cues = {
						cue({ actor = "Ballerina", face = "crying" }),
						cue({
							actor = "Giallino",
							moveTo = sq(0, 6.6, -16.6, 180),
							moveTime = 2.2,
							light = { glow = 1.0, time = 2 },
						}),
						cue({ at = 0.2, actor = "Ballerina", anim = "A-REACH_OUT" }),
						cue({
							at = 0.5,
							actor = "Ballerina",
							anim = "A-PIXEL_DISSOLVE",
							effectParams = {
								targetActor = "Giallino",
								keep = { "PointeShoe" },
								dropKept = true,
							},
						}),
						cue({ at = 0.5, sfx = "glitch_burst", sfxVolume = 0.3, sfxSpeed = 0.35 }),
					},
				}),
				shot({
					-- ECU on the ground: one pointe shoe is left; the last pixel goes out on it
					n = "9",
					t0 = 40,
					t1 = 43,
					camera = {
						shot = "ECU",
						high = true,
						lookAt = { actor = "Ballerina", part = "PointeShoe" },
						distance = 3.2,
						fov = 45,
					},
					cues = {
						cue({
							at = 0.3,
							effect = "LastPixel",
							effectAt = { actor = "Ballerina", part = "PointeShoe" },
							effectParams = { duration = 2.4 },
						}),
					},
				}),
				shot({
					-- CLOSE Giallino, happy again, talking to itself -> FADE BLACK 2 s
					n = "10",
					t0 = 43,
					t1 = 48,
					camera = { shot = "CLOSE", lookAt = GIALLINO, distance = 7, side = -20 },
					transitionOut = { kind = "FADE_BLACK", seconds = 2 },
					cues = {
						cue({
							actor = "Giallino",
							face = "happy",
							faceDim = 0,
							faceDimTime = 0.8,
							light = { glow = 1.6, time = 0.8 },
						}),
						cue({ at = 0.8, line = "CS05_GIALLINO_WELCOME" }),
					},
				}),
			},
		},
	},
}

return data
