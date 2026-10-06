--!strict
-- CS-DOWN "Down" (~2 s, every player has their own), cutscenes.md service cutscenes.
-- CLOSE from a low point on the local player falling to their knees (A-PLAYER_DOWN is played
-- by DownedClient on every client, so the cutscene only frames it and does not animate the
-- character itself), the screen edges turn red,
-- heartbeat. Control comes back for crawling.
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

local data: Types.Cutscene = {
	id = "CS_DOWN",
	title = "Down",
	noSkip = false,
	grade = "KEEP",
	actors = {
		{ id = "Player", model = "@LocalPlayer", at = { localPlayer = true }, footsteps = false },
	},
	players = { mode = "keep" },
	entry = "main",
	segments = {
		main = {
			length = 2,
			shots = {
				shot({
					n = "1",
					t0 = 0,
					t1 = 2,
					camera = {
						shot = "CLOSE",
						low = true,
						-- in front of the player, low and slightly to the right, looking up
						from = {
							actor = "Player",
							part = "HumanoidRootPart",
							offset = Vector3.new(1.6, -2.2, -5.5),
						},
						lookAt = {
							actor = "Player",
							part = "HumanoidRootPart",
							offset = Vector3.new(0, -0.6, 0),
						},
						fov = 55,
						roll = -6,
						moves = { move({ kind = "CRANE_DOWN", amount = 0.8, easing = "QuadOut" }) },
						shake = 0.05,
					},
					cues = {
						cue({ vignette = Color3.fromRGB(150, 10, 10) }),
						-- the heartbeat loop is started by DownedClient and lasts while you crawl
					},
					transitionOut = { kind = "BLEND", seconds = 0.4 },
				}),
			},
		},
	},
}

return data
