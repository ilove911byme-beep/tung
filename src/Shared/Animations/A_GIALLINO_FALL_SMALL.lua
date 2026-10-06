--!strict
-- A-GIALLINO_FALL_SMALL (2.0): scale 12 -> 1, falls and bounces twice.
return {
	id = "A-GIALLINO_FALL_SMALL",
	length = 2,
	loop = false,
	tracks = {
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 1, rot = { 0, 0, 0 }, pos = { 0, -6, 0 }, ease = "QuadIn" },
			{ t = 1.3, rot = { 0, 0, 0 }, pos = { 0, -4.5, 0 }, ease = "QuadOut" },
			{ t = 1.55, rot = { 0, 0, 0 }, pos = { 0, -6, 0 }, ease = "QuadIn" },
			{ t = 1.75, rot = { 0, 0, 0 }, pos = { 0, -5.4, 0 }, ease = "QuadOut" },
			{ t = 2, rot = { 0, 0, 0 }, pos = { 0, -6, 0 }, ease = "QuadIn" },
		},
	},
	scale = {
		{ t = 0, v = 12 },
		{ t = 1, v = 1, ease = "QuadIn" },
		{ t = 2, v = 1 },
	},
}
