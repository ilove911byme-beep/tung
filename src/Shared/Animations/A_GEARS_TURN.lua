--!strict
-- A-GEARS_TURN (2.0 loop): (Gears rig) the gears turn, each its own way.
return {
	id = "A-GEARS_TURN",
	length = 2,
	loop = true,
	tracks = {
		Gear1 = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1, rot = { 180, 0, 0 }, ease = "Linear" },
			{ t = 2, rot = { 360, 0, 0 }, ease = "Linear" },
		},
		Gear2 = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1, rot = { -180, 0, 0 }, ease = "Linear" },
			{ t = 2, rot = { -360, 0, 0 }, ease = "Linear" },
		},
		Gear3 = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1, rot = { 360, 0, 0 }, ease = "Linear" },
			{ t = 2, rot = { 720, 0, 0 }, ease = "Linear" },
		},
	},
}
