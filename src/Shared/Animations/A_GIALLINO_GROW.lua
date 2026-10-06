--!strict
-- A-GIALLINO_GROW (2.0): scale 1 -> 12 (the cutscene adds the Bloom flash).
return {
	id = "A-GIALLINO_GROW",
	length = 2,
	loop = false,
	tracks = {
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 2, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
		},
	},
	scale = {
		{ t = 0, v = 1 },
		{ t = 2, v = 12, ease = "QuadOut" },
	},
}
