--!strict
-- A-GIALLINO_BOW (1.0): tilts forward 30 degrees and back.
return {
	id = "A-GIALLINO_BOW",
	length = 1.0,
	loop = false,
	tracks = {
		Root = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { -30, 0, 0 } },
			{ t = 0.55, rot = { -30, 0, 0 } },
			{ t = 1.0, rot = { 0, 0, 0 } },
		},
	},
}
