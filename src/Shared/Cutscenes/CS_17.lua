--!strict
-- CS-17 "Crudelino" (~16 s), cutscenes.md: silence in the cave, red cracks run over the wall,
-- the wall explodes into blocks (A-WALL_BREAK) and a red cracked cube flies out of the dust,
-- its toothy grin, then the first dash right past the camera. World blocks: the cave spans
-- x 125-143, z 10-30, floor -25; Crudelino bursts out of the north wall.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local S = 4
local function slot(x: number, z: number): Vector3
	return Vector3.new(x * S, -25 * S, z * S)
end

local data: Types.Cutscene = {
	id = "CS_17",
	title = "Crudelino",
	noSkip = false,
	grade = "CAVE",
	actors = {
		{ id = "Wall", model = "WallChunk", at = B(134, -25, 10.3, 180), footsteps = false },
		{
			id = "Crudelino",
			model = "Crudelino",
			at = B(134, -21, 8.2, 180),
			face = "angry",
			visible = false,
		},
	},
	players = {
		mode = "slots",
		anchor = "Anchor_Origin",
		slots = {
			slot(132.5, 25),
			slot(135.5, 25),
			slot(131, 26.5),
			slot(137, 26.5),
			slot(134, 27.5),
			slot(129.5, 25.5),
		},
		yaw = 0, -- facing north, toward the wall
	},
	entry = "main",
	segments = {
		main = {
			length = 16,
			shots = {
				shot({
					-- WIDE, the cave in silence; red lines crack across the wall
					n = "1",
					t0 = 0,
					t1 = 3,
					camera = {
						shot = "WIDE",
						from = B(134, -22.5, 24),
						lookAt = B(134, -22, 11),
						fov = 60,
					},
					cues = {
						cue({ music = "SILENCE", musicFade = 0.5 }),
						cue({
							at = 0.6,
							actor = "Wall",
							effect = "ShowPart",
							effectParams = { part = "Crack1" },
						}),
						cue({
							at = 1.2,
							actor = "Wall",
							effect = "ShowPart",
							effectParams = { part = "Crack2" },
						}),
						cue({
							at = 1.8,
							actor = "Wall",
							effect = "ShowPart",
							effectParams = { part = "Crack3" },
						}),
						cue({
							at = 0.6,
							sfx = "block_break_stone",
							sfxVolume = 0.6,
							sfxSpeed = 0.7,
						}),
						cue({
							at = 1.8,
							sfx = "block_break_stone",
							sfxVolume = 0.8,
							sfxSpeed = 0.6,
						}),
					},
				}),
				shot({
					-- HANDHELD: the wall blows out in blocks; a red cracked cube flies out of the dust
					n = "2",
					t0 = 3,
					t1 = 7,
					camera = {
						shot = "MED",
						from = B(132, -22.4, 19),
						lookAt = B(134, -21.5, 11),
						fov = 56,
						moves = { move({ kind = "HANDHELD", amount = 0.4 }) },
					},
					cues = {
						cue({
							actor = "Wall",
							effect = "WallBreak",
							effectParams = { originPoint = B(134, -22, 8), force = 60 },
						}),
						cue({ sfx = "explosion_boom", sfxVolume = 1 }),
						cue({ at = 0.5, actor = "Crudelino", visible = true, light = { glow = 2 } }),
						cue({
							at = 0.5,
							actor = "Crudelino",
							moveTo = B(134, -20.5, 15.5, 180),
							moveTime = 1.2,
							moveEasing = "BackOut",
						}),
						cue({ at = 0.7, sfx = "crudelino_signature", sfxVolume = 1 }),
					},
				}),
				shot({
					-- CLOSE, LOW: the toothy grin, the cracks pulse
					n = "3",
					t0 = 7,
					t1 = 11,
					camera = {
						shot = "CLOSE",
						low = true,
						from = B(134, -22.6, 19.8),
						lookAt = { actor = "Crudelino" },
						fov = 48,
						shake = 0.15,
					},
					cues = {
						cue({ actor = "Crudelino", light = { glow = 3, time = 0.3 } }),
						cue({ at = 0.6, actor = "Crudelino", light = { glow = 1.2, time = 0.3 } }),
						cue({ at = 1.2, actor = "Crudelino", light = { glow = 3, time = 0.3 } }),
						cue({ at = 0.4, line = "CS17_CRUDELINO_NOMORE" }),
					},
				}),
				shot({
					-- WHIP onto the players; Crudelino's first dash right past the camera
					n = "4",
					t0 = 11,
					t1 = 16,
					camera = {
						shot = "MED",
						from = B(134, -23.3, 22.6),
						lookAt = { players = true },
						fov = 60,
						moves = { move({ kind = "WHIP" }) },
					},
					cues = {
						cue({ line = "CS17_CRUDELINO_BREAK" }),
						cue({ at = 2.2, actor = "Crudelino", anim = "A-CRUDELINO_DASH" }),
						cue({
							at = 3.2,
							actor = "Crudelino",
							moveTo = B(134.6, -23, 31, 180),
							moveTime = 0.45,
							moveEasing = "QuadIn",
						}),
						cue({
							at = 3.2,
							sfx = "crudelino_signature",
							sfxVolume = 0.9,
							sfxSpeed = 1.3,
						}),
						cue({ at = 3.2, music = "music_boss", musicVolume = 0.5, musicFade = 1 }),
					},
				}),
			},
		},
	},
}

return data
