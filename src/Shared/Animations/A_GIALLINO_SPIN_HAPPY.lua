--!strict
-- A-GIALLINO_SPIN_HAPPY (1.0): one full turn and a little hop.
return {
	id = "A-GIALLINO_SPIN_HAPPY",
	length = 1.0,
	loop = false,
	tracks = {
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 0.4, rot = { 0, 150, 0 }, pos = { 0, 1.0, 0 }, ease = "QuadOut" },
			{ t = 0.8, rot = { 0, 330, 0 }, pos = { 0, 0, 0 }, ease = "QuadIn" },
			{ t = 1.0, rot = { 0, 360, 0 }, pos = { 0, 0, 0 } },
		},
	},
}
