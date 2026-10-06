--!strict
-- CS-21 "Tung Tung holds the door" (lock, ~34 s, tragic) in phase 3 of the finale. Entries:
--   "free"          Tung Tung braces his back against the tower door, sends the players up, reads
--                   the names (Patapim's too), slides down the door that still holds and carves
--                   his own name on the last empty line
--   "freeNoPatapim" the same, Patapim is still alive so his name is not on the board
--   "jailed"        8 s: in the barn he pounds the boards: nobody holds the door (30 s, then
--                   Glitchlings climb in from below)
-- World blocks: the tower spans x 76.5-83.5, z 62.5-69.5; its door is in the south wall (z 69).
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, B = Kit.cue, Kit.shot, Kit.B

local N = Kit.MAX_PLAYERS
local STAIRS =
	{ { 82, 12.5, 68 }, { 82, 14.5, 64 }, { 78, 16.5, 64 }, { 78, 18.5, 68 }, { 82, 20.5, 68 } }

local function upTheStairs(): { Types.Cue }
	local out: { Types.Cue } = {}
	for i = 1, N do
		local delay = (i - 1) * 0.25
		table.insert(out, cue({ at = delay, actor = "P" .. i, anim = "A-RUN" }))
		for k, p in STAIRS do
			table.insert(
				out,
				cue({
					at = delay + (k - 1) * 0.75,
					actor = "P" .. i,
					moveTo = B(p[1], p[2], p[3]),
					moveTime = 0.75,
					moveEasing = "Linear",
				})
			)
		end
	end
	return out
end

local function holdShots(namesLine: string): { Types.Shot }
	return {
		shot({
			-- MED, the bottom of the tower: Tung Tung braces his back against the door
			n = "1",
			t0 = 0,
			t1 = 4,
			camera = {
				shot = "MED",
				from = B(80.4, 13.8, 65.6),
				lookAt = { actor = "TungTung", part = "Torso" },
				fov = 52,
			},
			cues = {
				cue({ music = "music_tragic", musicVolume = 0.35, musicFade = 2 }),
				cue({ actor = "TungTung", anim = "A-BRACE_DOOR" }),
				cue({ sfx = "knock_tung_x3", sfxVolume = 1, sfxSpeed = 0.6 }),
				cue({
					world = "doorShake",
					worldParams = { tag = "TowerDoor", knocks = 4, gap = 0.9 },
				}),
				cue({ at = 1.8, sfx = "door_close", sfxVolume = 1, sfxSpeed = 0.5 }),
			},
		}),
		shot({
			-- CLOSE on Tung Tung, angry
			n = "2",
			t0 = 4,
			t1 = 9,
			camera = {
				shot = "CLOSE",
				from = B(80, 13.9, 66.2),
				lookAt = { actor = "TungTung", part = "Head" },
				fov = 44,
				shake = 0.08,
			},
			cues = {
				cue({ actor = "TungTung", face = "angry" }),
				cue({ at = 0.4, line = "CS21_TUNG_GO" }),
			},
		}),
		shot({
			-- WIDE: the players run up the stairs, the camera stays at the bottom; the door cracks
			n = "3",
			t0 = 9,
			t1 = 14,
			camera = {
				shot = "WIDE",
				low = true,
				from = B(79.2, 12.7, 67.6),
				lookAt = B(80, 18, 65.6),
				fov = 70,
			},
			cues = Kit.cues(upTheStairs(), {
				cue({ at = 1.0, sfx = "block_break_wood", sfxVolume = 0.9, sfxSpeed = 0.7 }),
				cue({ at = 3.0, sfx = "block_break_wood", sfxVolume = 1, sfxSpeed = 0.6 }),
			}),
		}),
		shot({
			-- CLOSE: sad, he takes out the board of names and starts whispering them
			n = "4",
			t0 = 14,
			t1 = 22,
			camera = {
				shot = "CLOSE",
				from = B(80.3, 13.9, 66.4),
				lookAt = { actor = "TungTung", part = "Head" },
				fov = 42,
			},
			cues = {
				cue({ actor = "TungTung", face = "sad" }),
				cue({
					actor = "TungTung",
					effect = "ShowPart",
					effectParams = { part = "BoardInHand" },
				}),
				cue({
					actor = "TungTung",
					effect = "HidePart",
					effectParams = { part = "NameBoard" },
				}),
				cue({ at = 0.8, line = namesLine }),
			},
		}),
		shot({
			-- MED: he slowly slides down the door - but the door holds
			n = "5",
			t0 = 22,
			t1 = 28,
			camera = {
				shot = "MED",
				from = B(80.6, 13.4, 65.4),
				lookAt = { actor = "TungTung", part = "Torso" },
				fov = 50,
			},
			cues = {
				cue({ actor = "TungTung", stopAnim = "A-BRACE_DOOR" }),
				cue({ actor = "TungTung", anim = "A-SLIDE_DOWN_DOOR" }),
				cue({ at = 2.4, line = "CS21_TUNG_SAHUR" }),
			},
		}),
		shot({
			-- ECU on the board: the last name is an empty line; he carves "Tung" into it (A-CARVE);
			-- one lonely toll of the bell from above
			n = "6",
			t0 = 28,
			t1 = 34,
			camera = {
				shot = "ECU",
				from = B(80.2, 12.9, 67.1),
				lookAt = { actor = "TungTung", part = "LeftHand" },
				fov = 34,
			},
			cues = {
				cue({ actor = "TungTung", effect = "ShowPart", effectParams = { part = "Knife" } }),
				cue({ actor = "TungTung", anim = "A-CARVE" }),
				cue({ at = 0.6, sfx = "block_break_wood", sfxVolume = 0.3, sfxSpeed = 1.8 }),
				cue({ at = 1.1, sfx = "block_break_wood", sfxVolume = 0.3, sfxSpeed = 1.8 }),
				cue({ at = 1.6, sfx = "block_break_wood", sfxVolume = 0.3, sfxSpeed = 1.8 }),
				cue({ at = 4.0, sfx = "village_bell", sfxVolume = 0.8, sfxSpeed = 0.9 }),
			},
		}),
	}
end

local actors: { Types.ActorSpec } = {
	Kit.actor({ id = "TungTung", model = "TungTung", at = B(80, 12, 68.3, 0), face = "angry" }),
	Kit.actor({ id = "JailedTung", model = "TungTung", at = B(100.6, 12, 68, 270), face = "angry" }),
}
for _, s in
	Kit.standIns(N, function(i)
		return B(79.2 + (i % 3) * 0.8, 12, 67.4 - math.floor((i - 1) / 3) * 0.8, 0)
	end)
do
	table.insert(actors, s)
end

local data: Types.Cutscene = {
	id = "CS_21",
	title = "Tung Tung Holds the Door",
	noSkip = true,
	grade = "GLITCH",
	clockTime = 4.5,
	actors = actors,
	players = { mode = "hide" },
	hideNpcs = { "TungTung" },
	entry = "free",
	segments = {
		free = { length = 34, shots = holdShots("CS21_TUNG_NAMES") },
		freeNoPatapim = { length = 34, shots = holdShots("CS21_TUNG_NAMES_NOPATAPIM") },
		jailed = {
			length = 8,
			shots = {
				shot({
					-- the barn: Tung Tung pounds the boards from inside - nobody holds the tower door
					n = "1",
					t0 = 0,
					t1 = 8,
					camera = {
						shot = "MED",
						from = B(104, 13.9, 67.4),
						lookAt = { actor = "JailedTung", part = "Head" },
						fov = 50,
						shake = 0.12,
					},
					cues = {
						cue({ actor = "JailedTung", anim = "A-POUND_DOOR" }),
						cue({ sfx = "knock_tung_x3", sfxVolume = 0.9 }),
						cue({ at = 0.6, line = "C6_TUNG_JAILED" }),
					},
				}),
			},
		},
	},
}

return data
