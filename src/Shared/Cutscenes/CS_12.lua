--!strict
-- CS-12 "It's not me" (~28 s, tragic), cutscenes.md — Tung Tung's reveal. Two entries:
--   "free"   : Tung Tung pounds on the inn door, the players open it and he stands on the
--              threshold, cracked, his bat broken; he strokes the board of names
--   "jailed" : shot 3/4 from the barn: he shouts through the boards (A-POUND_DOOR); he gave the
--              board away in CS-09T, so he only presses his hands to the planks
-- Both end with the WHIP to the bell tower: a huge yellow beam shoots into the sky.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local DOOR: Types.Point =
	{ anchor = "Anchor_Origin", offset = Vector3.new(70 * 4, 12 * 4, 84.5 * 4), yaw = 90 }
local TOWER_TOP = Vector3.new(80 * 4, 42 * 4, 66 * 4)

local function knocking(): { Types.Shot }
	return {
		shot({
			-- MED, the inn door from inside: louder, desperate knocking
			n = "1",
			t0 = 0,
			t1 = 4,
			camera = {
				shot = "MED",
				from = B(66.6, 13.8, 82.6),
				lookAt = B(70.3, 13.2, 84),
				fov = 50,
				shake = 0.15,
			},
			cues = {
				cue({ music = "SILENCE", musicFade = 0.5 }),
				cue({ sfx = "knock_tung_x3", sfxVolume = 1 }),
				cue({
					world = "doorShake",
					worldParams = { tag = "TavernDoor", knocks = 6, gap = 0.3 },
				}),
				cue({ at = 1.9, sfx = "knock_tung_x3", sfxVolume = 1, sfxSpeed = 1.15 }),
			},
		}),
		shot({
			-- OTS from the players onto the door: a silhouette through the cracks
			n = "2",
			t0 = 4,
			t1 = 10,
			camera = {
				shot = "OTS",
				from = { actor = "P1", part = "Head", offset = Vector3.new(1.3, 0.5, 3) },
				lookAt = B(70.3, 13.4, 84),
				fov = 52,
				moves = { move({ kind = "HANDHELD", amount = 0.08 }) },
			},
			cues = {
				cue({ at = 0.3, line = "CS12_TUNG_WAKE" }),
				cue({
					at = 0.3,
					world = "doorShake",
					worldParams = { tag = "TavernDoor", knocks = 3, gap = 0.5 },
				}),
			},
		}),
	}
end

local function towerBeam(n: string, t0: number): Types.Shot
	return shot({
		-- WHIP to the bell tower: a huge yellow beam shoots into the sky
		n = n,
		t0 = t0,
		t1 = t0 + 6,
		camera = {
			shot = "WIDE",
			low = true,
			from = B(80.5, 13, 79),
			lookAt = B(80, 36, 66),
			fov = 60,
			moves = { move({ kind = "WHIP" }) },
		},
		cues = {
			cue({ at = 0.3, world = "beam", worldParams = { at = TOWER_TOP, duration = 8 } }),
			cue({ at = 0.3, sfx = "giallino_boot", sfxVolume = 1, sfxSpeed = 0.6 }),
			cue({ at = 1.0, line = "CS12_TUNG_RUN" }),
			cue({ at = 1.0, music = "music_chase", musicVolume = 0.5, musicFade = 2 }),
		},
	})
end

local free: { Types.Shot } = knocking()
table.insert(
	free,
	shot({
		-- the players open: WIDE, Tung Tung on the threshold, all cracks, his bat broken
		n = "3",
		t0 = 10,
		t1 = 16,
		camera = {
			shot = "WIDE",
			from = B(67.2, 14.2, 83.4),
			lookAt = B(71.4, 13.6, 84.2),
			fov = 56,
		},
		cues = {
			cue({ actor = "TungTung", visible = true }),
			cue({ actor = "Door", anim = "A-DOOR_OPEN_FAST" }),
			cue({ sfx = "door_open", sfxVolume = 0.9 }),
			cue({ actor = "TungTung", face = "scared" }),
			cue({ at = 0.8, line = "CS12_TUNG_KNOCKED" }),
		},
	})
)
table.insert(
	free,
	shot({
		-- CLOSE on Tung Tung: he takes out the board of names and strokes it
		n = "4",
		t0 = 16,
		t1 = 22,
		camera = {
			shot = "CLOSE",
			from = B(70, 13.9, 84.4),
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
			cue({ actor = "TungTung", effect = "HidePart", effectParams = { part = "NameBoard" } }),
			cue({ actor = "TungTung", anim = "A-STROKE_SOFT" }),
			cue({ at = 0.5, line = "CS12_TUNG_NAMES" }),
		},
	})
)
table.insert(free, towerBeam("5", 22))

local jailed: { Types.Shot } = knocking()
table.insert(
	jailed,
	shot({
		-- from the barn: Tung Tung shouts through the boards, pounding them (A-POUND_DOOR)
		n = "3",
		t0 = 10,
		t1 = 16,
		camera = {
			shot = "WIDE",
			from = B(104.5, 14, 67.2),
			lookAt = B(100.6, 13.4, 68),
			fov = 54,
			shake = 0.1,
		},
		cues = {
			cue({ actor = "JailedTung", face = "scared" }),
			cue({ actor = "JailedTung", anim = "A-POUND_DOOR" }),
			cue({ sfx = "knock_tung_x3", sfxVolume = 0.8, sfxSpeed = 0.8 }),
			cue({ at = 0.8, line = "CS12_TUNG_KNOCKED" }),
		},
	})
)
table.insert(
	jailed,
	shot({
		-- CLOSE: he gave his board away; he presses his hands to the planks instead
		n = "4",
		t0 = 16,
		t1 = 22,
		camera = {
			shot = "CLOSE",
			from = B(102.4, 13.9, 68.6),
			lookAt = { actor = "JailedTung", part = "Head" },
			fov = 42,
		},
		cues = {
			cue({ actor = "JailedTung", stopAnim = "A-POUND_DOOR" }),
			cue({ actor = "JailedTung", face = "sad" }),
			cue({ actor = "JailedTung", anim = "A-KNOCK_SOFT" }),
			cue({ at = 0.5, line = "CS12_TUNG_NAMES" }),
		},
	})
)
table.insert(jailed, towerBeam("5", 22))

local data: Types.Cutscene = {
	id = "CS_12",
	title = "It's Not Me",
	noSkip = false,
	grade = "NIGHT",
	clockTime = 1.5,
	actors = {
		{ id = "P1", model = "@Player1", at = B(67.4, 12, 83.2, 90), footsteps = false },
		{ id = "Door", model = "Door", at = DOOR, footsteps = false },
		{
			id = "TungTung",
			model = "TungTung",
			at = B(71.6, 12, 84, 270),
			face = "scared",
			visible = false,
		},
		{ id = "JailedTung", model = "TungTung", at = B(100.6, 12, 68, 270), face = "scared" },
	},
	players = { mode = "hide" },
	hideNpcs = { "TungTung" },
	entry = "free",
	segments = {
		free = { length = 28, shots = free },
		jailed = { length = 28, shots = jailed },
	},
}

return data
