--!strict
-- CS-02 "Hi, I'm Giallino" (~30 s + vote), cutscenes.md. Includes choice 1-2.
-- Coordinates are local to Anchor_Station (faces east, toward the village): -Z = forward,
-- +X = the station's right. Players stand in a row on the platform, the lantern is 10 studs
-- in front of them.
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

local STATION = "Anchor_Station"

local function at(x: number, y: number, z: number, yaw: number?): Types.Point
	return { anchor = STATION, offset = Vector3.new(x, y, z), yaw = yaw }
end

local GIALLINO: Types.Point = { actor = "Giallino" }

local data: Types.Cutscene = {
	id = "CS_02",
	title = "Hi, I'm Giallino",
	noSkip = false,
	grade = "DUSK",
	clockTime = 17.9,
	actors = {
		{
			id = "Giallino",
			model = "Giallino",
			at = at(0, 6.2, -8, 180),
			face = "off",
			visible = false,
		},
	},
	players = {
		mode = "slots",
		anchor = STATION,
		slots = {
			Vector3.new(-1, 0, 0),
			Vector3.new(1, 0, 0),
			Vector3.new(-3, 0, 0),
			Vector3.new(3, 0, 0),
			Vector3.new(-5, 0, 0),
			Vector3.new(5, 0, 0),
		},
		yaw = 0,
	},
	hideNpcs = { "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 23,
			next = "choice",
			shots = {
				shot({
					-- MED on the players: yellow light flows out of the lantern and assembles
					n = "1",
					t0 = 0,
					t1 = 4,
					camera = {
						shot = "MED",
						from = at(9, 5.2, -5),
						lookAt = at(0, 4.6, -5),
						moves = { move({ kind = "DOLLY_IN", amount = 0.12 }) },
					},
					cues = {
						cue({ music = "SILENCE", musicFade = 4 }), -- the dusk piano fades out
						cue({ sfx = "giallino_boot", sfxVolume = 0.8 }),
						cue({
							actor = "Giallino",
							visible = true,
							anim = "A-GIALLINO_ASSEMBLE",
							effectParams = { fromPoint = at(0, 6.5, -10) },
						}),
						cue({ at = 2.6, actor = "Giallino", anim = "A-GIALLINO_IDLE" }),
					},
				}),
				shot({
					-- CLOSE, LOW on Giallino: the screen face turns on (happy), a little bow
					n = "2",
					t0 = 4,
					t1 = 9,
					camera = { shot = "CLOSE", low = true, lookAt = GIALLINO, distance = 7.5 },
					cues = {
						cue({ actor = "Giallino", face = "happy" }),
						cue({ at = 0.2, line = "CS02_GIALLINO_HELLO" }),
						cue({ at = 0.5, actor = "Giallino", anim = "A-GIALLINO_BOW" }),
						cue({ at = 1.7, actor = "Giallino", anim = "A-GIALLINO_IDLE" }),
					},
				}),
				shot({
					-- ORBIT around the players; Giallino flies to every face and inspects it
					n = "3",
					t0 = 9,
					t1 = 13,
					camera = {
						shot = "WIDE",
						from = at(0, 6.5, -13),
						lookAt = { players = true },
						moves = { move({ kind = "ORBIT", angle = 75 }) },
					},
					cues = {
						cue({
							actor = "Giallino",
							tour = {
								targets = "players",
								distance = 3.4,
								height = 0.2,
								anim = "A-GIALLINO_INSPECT",
							},
						}),
						cue({ at = 0.4, line = "CS02_GIALLINO_TRUTH" }),
					},
				}),
				shot({
					-- OTS from behind Giallino onto the players; it stops dead in front of the camera
					n = "4",
					t0 = 13,
					t1 = 18,
					camera = {
						shot = "OTS",
						from = at(2.4, 6.6, -12),
						lookAt = at(0, 4.6, 0),
						fov = 50,
					},
					cues = {
						cue({ actor = "Giallino", moveTo = at(0, 5.4, -5.5, 180), moveTime = 1.0 }),
						cue({ at = 0.6, line = "CS02_GIALLINO_RULE" }),
						cue({ at = 1.0, actor = "Giallino", stopAnim = "*" }),
					},
				}),
				shot({
					-- CLOSE on the face: a pause, the smile "hangs" for one frame of static
					n = "5",
					t0 = 18,
					t1 = 23,
					camera = {
						shot = "CLOSE",
						lookAt = GIALLINO,
						distance = 6.5,
						moves = { move({ kind = "DOLLY_IN", amount = 0.08 }) },
					},
					cues = {
						cue({
							at = 1.0,
							actor = "Giallino",
							face = "screen_static",
							faceFor = 1 / 30,
						}),
						cue({ at = 1.4, line = "CS02_GIALLINO_PROMISE" }),
					},
				}),
			},
		},
		choice = {
			-- shot 6: CHOICE 1-2, the cutscene waits for the vote while the camera slowly dollies in
			length = 15,
			vote = {
				seconds = 15,
				options = {
					{ id = "yes", text = "Yes!", next = "yes" },
					{
						id = "maybe",
						text = "Maybe…",
						next = "no",
						effects = { giallinoMood = -5 },
					},
					{
						id = "no",
						text = "No.",
						next = "no",
						effects = { giallinoMood = -5, badge = "FIRST_NO" },
					},
				},
			},
			shots = {
				shot({
					n = "6",
					t0 = 0,
					t1 = 15,
					camera = {
						shot = "CLOSE",
						lookAt = GIALLINO,
						distance = 6.0,
						moves = { move({ kind = "DOLLY_IN", amount = 0.3, easing = "Linear" }) },
					},
					cues = { cue({ sfx = "vote_tick" }) },
				}),
			},
		},
		yes = {
			length = 4.5,
			shots = {
				shot({
					-- 7a: happy, spins
					n = "7a",
					t0 = 0,
					t1 = 4.5,
					camera = { shot = "CLOSE", lookAt = GIALLINO, distance = 6.5 },
					cues = {
						cue({ actor = "Giallino", face = "happy" }),
						cue({ at = 0.2, actor = "Giallino", anim = "A-GIALLINO_SPIN_HAPPY" }),
						cue({ at = 0.3, line = "CS02_GIALLINO_YES" }),
						cue({ at = 1.3, actor = "Giallino", anim = "A-GIALLINO_IDLE" }),
					},
				}),
			},
		},
		no = {
			length = 5.5,
			shots = {
				shot({
					-- 7b: the screen goes dark for 1 s, comes back happy but the eyes are 1 pixel lower
					n = "7b",
					t0 = 0,
					t1 = 5.5,
					camera = { shot = "ECU", lookAt = GIALLINO, distance = 3.6, fov = 40 },
					cues = {
						cue({ actor = "Giallino", face = "off" }),
						cue({
							at = 1.0,
							actor = "Giallino",
							face = "happy",
							eyeOffset = Vector2.new(0, 1),
						}),
						cue({ at = 1.3, line = "CS02_GIALLINO_NO" }),
						cue({ at = 1.3, sfx = "giallino_mood_drop", sfxVolume = 0.25 }),
					},
				}),
			},
		},
	},
}

return data
