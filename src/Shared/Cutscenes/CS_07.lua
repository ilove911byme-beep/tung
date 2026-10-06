--!strict
-- CS-07 "The crooked smile" (~18 s), cutscenes.md: Falsino comes down to the square (Giallino's
-- boot with a false note), the crooked smile and the green left eye, one blink, and three signs
-- rise out of the ground for the truth-or-lie game. World blocks; the players stand on the west
-- side of the sahur table, Falsino hovers above its middle.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local S = 4
local function slot(x: number, z: number): Vector3
	return Vector3.new(x * S, 12 * S, z * S)
end

local SIGNS = { { 75.4, 76.6 }, { 74.6, 80 }, { 75.4, 83.4 } }

local actors: { Types.ActorSpec } = {
	Kit.actor({
		id = "Falsino",
		model = "Falsino",
		at = B(80, 24, 80, 270),
		face = "smile_crooked",
	}),
}
for i, s in SIGNS do
	table.insert(
		actors,
		{ id = "Sign" .. i, model = "Sign", at = B(s[1], 9, s[2], 270), footsteps = false }
	)
end

local signCues: { Types.Cue } = {}
for i, s in SIGNS do
	table.insert(
		signCues,
		cue({
			at = 0.6 + i * 0.5,
			actor = "Sign" .. i,
			moveTo = B(s[1], 12, s[2], 270),
			moveTime = 2,
			moveEasing = "BackOut",
		})
	)
	table.insert(
		signCues,
		cue({ at = 0.6 + i * 0.5, effect = "DirtBurst", effectAt = B(s[1], 12, s[2]) })
	)
end

local data: Types.Cutscene = {
	id = "CS_07",
	title = "The Crooked Smile",
	noSkip = false,
	grade = "DUSK",
	clockTime = 15.5,
	actors = actors,
	players = {
		mode = "slots",
		anchor = "Anchor_Origin",
		slots = {
			slot(72.4, 78.6),
			slot(72.4, 81.4),
			slot(71.2, 77.2),
			slot(71.2, 82.8),
			slot(70.4, 80),
			slot(73.4, 80),
		},
		yaw = -90, -- facing east, toward the table
	},
	hideNpcs = { "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 18,
			shots = {
				shot({
					-- WIDE, the square and the players: "Giallino" comes down into the middle
					n = "1",
					t0 = 0,
					t1 = 4,
					camera = {
						shot = "WIDE",
						from = B(68.5, 16.5, 88),
						lookAt = B(78, 14, 80),
						fov = 60,
					},
					cues = {
						cue({ music = "SILENCE", musicFade = 1 }),
						cue({
							actor = "Falsino",
							moveTo = B(80, 14.6, 80, 270),
							moveTime = 3.4,
							moveEasing = "QuadOut",
						}),
						cue({ actor = "Falsino", anim = "A-GIALLINO_IDLE" }),
						cue({ sfx = "giallino_boot", sfxVolume = 0.8 }),
						cue({ at = 1.2, sfx = "falsino_signature", sfxVolume = 0.7 }),
					},
				}),
				shot({
					-- CLOSE, slow DOLLY IN: the smile is crooked, the left eye is green
					n = "2",
					t0 = 4,
					t1 = 8,
					camera = {
						shot = "CLOSE",
						from = B(76.8, 14.8, 80),
						lookAt = { actor = "Falsino" },
						fov = 44,
						moves = { move({ kind = "DOLLY_IN", amount = 0.3 }) },
					},
				}),
				shot({
					-- ECU on the green eye: one frame, the eye blinks
					n = "3",
					t0 = 8,
					t1 = 12,
					camera = {
						shot = "ECU",
						from = { actor = "Falsino", offset = Vector3.new(0.7, 0.4, -4.2) },
						lookAt = { actor = "Falsino", offset = Vector3.new(0.7, 0.4, -2) },
						fov = 30,
					},
					cues = {
						cue({ at = 1.8, actor = "Falsino", face = "eyes_closed", faceFor = 0.07 }),
						cue({ at = 1.8, sfx = "glitch_burst", sfxVolume = 0.5, sfxSpeed = 1.5 }),
					},
				}),
				shot({
					-- ORBIT around Falsino while three signs rise out of the ground
					n = "4",
					t0 = 12,
					t1 = 18,
					camera = {
						shot = "MED",
						from = B(74.5, 15.5, 74.5),
						lookAt = { actor = "Falsino" },
						fov = 55,
						moves = { move({ kind = "ORBIT", angle = 70 }) },
					},
					cues = Kit.cues(signCues, {
						cue({ at = 0.3, line = "CS07_FALSINO" }),
						cue({ at = 0.4, music = "music_boss", musicVolume = 0.4, musicFade = 4 }),
					}),
				}),
			},
		},
	},
}

return data
