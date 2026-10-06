--!strict
-- CS-23 "The choice" (waits for the vote), cutscenes.md: on top of the tower the giant cube
-- shrinks to the size of a house and hangs before the players, sad; the narrator asks; the
-- camera orbits slowly while the party votes. Entries: "main" (Shut it down / Let Giallino
-- stay) and "secret" (+ "Teach it the word no." when the secret ending's conditions are met).
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local S = 4
local function slot(x: number, z: number): Vector3
	return Vector3.new(x * S, 42 * S, z * S)
end

local function intro(): { Types.Shot }
	return {
		shot({
			-- WIDE on top of the tower: the giant cube shrinks to the size of a house, sad
			n = "1",
			t0 = 0,
			t1 = 8,
			camera = { shot = "WIDE", from = B(76.5, 44, 63.4), lookAt = B(80, 45.5, 72), fov = 60 },
			cues = {
				cue({ music = "SILENCE", musicFade = 2 }),
				cue({ sfx = "amb_wind_loop", sfxVolume = 0.8 }),
				cue({ actor = "Totale", anim = "A-SCALE_6" }),
				cue({
					actor = "Totale",
					moveTo = B(80, 45.5, 72, 0),
					moveTime = 4,
					moveEasing = "SineInOut",
				}),
				cue({ actor = "Totale", light = { glow = 2 } }),
				cue({ at = 4.5, line = "CS23_NARR_CHOICE" }),
			},
		}),
	}
end

local function voting(): { Types.Shot }
	return {
		shot({
			-- the camera orbits slowly while the party votes
			n = "2",
			t0 = 0,
			t1 = 20,
			camera = {
				shot = "WIDE",
				from = B(80, 44.5, 62.5),
				lookAt = B(80, 44, 68.5),
				fov = 58,
				moves = { move({ kind = "ORBIT", angle = 60, easing = "Linear" }) },
			},
			cues = { cue({ sfx = "vote_tick", sfxVolume = 0.5 }) },
		}),
	}
end

local data: Types.Cutscene = {
	id = "CS_23",
	title = "The Choice",
	noSkip = false,
	grade = "NIGHT",
	clockTime = 5.4,
	actors = {
		{ id = "Totale", model = "GiallinoTotale", at = B(80, 54, 76, 0), face = "sad" },
	},
	players = {
		mode = "slots",
		anchor = "Anchor_Origin",
		slots = {
			slot(79, 67),
			slot(81, 67),
			slot(78.2, 65.6),
			slot(81.8, 65.6),
			slot(80, 64.6),
			slot(80, 66.2),
		},
		yaw = 180, -- facing south, toward the cube
	},
	hideNpcs = { "GiallinoTotale" },
	entry = "main",
	segments = {
		main = { length = 8, shots = intro(), next = "vote" },
		vote = {
			length = 20,
			shots = voting(),
			vote = {
				seconds = 20,
				options = {
					{ id = "shut", text = "Shut it down" },
					{ id = "stay", text = "Let Giallino stay" },
				},
			},
		},
		secret = { length = 8, shots = intro(), next = "secretVote" },
		secretVote = {
			length = 20,
			shots = voting(),
			vote = {
				seconds = 20,
				options = {
					{ id = "shut", text = "Shut it down" },
					{ id = "stay", text = "Let Giallino stay" },
					{ id = "teach", text = "Teach it the word no." },
				},
			},
		},
	},
}

return data
