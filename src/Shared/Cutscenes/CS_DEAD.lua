--!strict
-- CS-DEAD "You were supposed to say yes" (~5 s, only for the player who died).
--   1  0-2  HIGH, camera above the lying player: the body breaks into pixels (A-PIXEL_DISSOLVE,
--           short 2 s version)
--   2  2-5  CLOSE, Giallino (or his current form; DownedClient remaps the model) leans into the
--           frame from above: "You were supposed to say yes." -> REVIVE 45 R$ / Spectate screen
--           (DeathUI waits for this cutscene to end).
-- Shot 2 is the dead player's view from the ground looking up, so Giallino peeks down at YOU.
local Types = require(script.Parent.Parent.Types)

local function cue(c: Types.Cue): Types.Cue
	return c
end

local function shot(s: Types.Shot): Types.Shot
	return s
end

local function move(m: Types.CameraMoveSpec): Types.CameraMoveSpec
	return m
end

local function root(x: number, y: number, z: number): Types.Point
	return { actor = "Player", part = "HumanoidRootPart", worldOffset = Vector3.new(x, y, z) }
end

local data: Types.Cutscene = {
	id = "CS_DEAD",
	title = "You Were Supposed to Say Yes",
	noSkip = false,
	grade = "KEEP",
	actors = {
		{ id = "Player", model = "@LocalPlayer", at = { localPlayer = true }, footsteps = false },
		-- starts high above, out of frame
		{ id = "Giallino", model = "Giallino", at = root(0, 16, 7), face = "neutral" },
	},
	players = { mode = "keep" },
	entry = "main",
	segments = {
		main = {
			length = 5,
			shots = {
				shot({
					n = "1",
					t0 = 0,
					t1 = 2,
					camera = {
						shot = "HIGH",
						high = true,
						from = root(0.5, 12, 3),
						lookAt = root(0, -1.4, 0),
						fov = 50,
						moves = { move({ kind = "CRANE_UP", amount = 2.5, easing = "SineOut" }) },
					},
					cues = {
						cue({ music = "SILENCE", musicFade = 0.6 }),
						cue({
							at = 0.15,
							actor = "Player",
							effect = "PixelDissolve",
							effectParams = { duration = 2.0, maxCubes = 140 },
						}),
						cue({ at = 0.2, sfx = "glitch_burst", sfxVolume = 0.35, sfxSpeed = 0.6 }),
					},
					transitionOut = { kind = "CUT" },
				}),
				shot({
					n = "2",
					t0 = 2,
					t1 = 5,
					camera = {
						shot = "CLOSE",
						low = true,
						from = root(0, -0.8, 0),
						lookAt = root(0, 7, -1.5),
						fov = 55,
						moves = {
							move({
								kind = "DOLLY_IN",
								amount = 0.12,
								from = 0.4,
								easing = "SineInOut",
							}),
						},
					},
					cues = {
						-- he leans into the frame from above and looks down at you
						cue({
							actor = "Giallino",
							moveTo = root(0, 6, -1.4),
							moveTime = 1.1,
							moveEasing = "QuadOut",
							faceToward = root(0, -0.8, 0),
						}),
						cue({ actor = "Giallino", light = { glow = 1.2, time = 0.6 } }),
						cue({ at = 0.9, actor = "Giallino", eyeOffset = Vector2.new(0, 1) }),
						cue({ at = 1.2, line = "SVC_DEAD" }),
						cue({ at = 2.4, actor = "Giallino", face = "smile_crooked" }),
					},
					transitionOut = { kind = "FADE_BLACK", seconds = 0.4 },
				}),
			},
		},
	},
}

return data
