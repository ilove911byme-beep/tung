--!strict
-- CS-REVIVE "Return" (~2 s): the pixels fly back into the player (A-PIXEL_ASSEMBLE), golden
-- flash, giallino_boot (high and short).
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
	id = "CS_REVIVE",
	title = "Return",
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
						shot = "MED",
						lookAt = {
							actor = "Player",
							part = "HumanoidRootPart",
							offset = Vector3.new(0, 0.4, 0),
						},
						distance = 9,
						side = 25,
						fov = 55,
						moves = { move({ kind = "ORBIT", angle = 30, easing = "SineInOut" }) },
					},
					cues = {
						cue({
							actor = "Player",
							effect = "PixelAssemble",
							effectParams = { duration = 2.0, flash = true, spiral = true },
						}),
						cue({ sfx = "giallino_boot", sfxVolume = 0.8, sfxSpeed = 1.5 }),
					},
					transitionOut = { kind = "BLEND", seconds = 0.4 },
				}),
			},
		},
	},
}

return data
