--!strict
-- A-GIALLINO_ASSEMBLE (2.5): 30 yellow pixels fly in on a spiral and assemble into the cube.
-- The cube turns into place while it appears. Cutscenes pass effectParams.from (the lantern).
return {
	id = "A-GIALLINO_ASSEMBLE",
	length = 2.5,
	loop = false,
	tracks = {
		Root = {
			{ t = 0, rot = { 0, -120, 0 } },
			{ t = 2.5, rot = { 0, 0, 0 }, ease = "CubicOut" },
		},
	},
	effect = {
		kind = "PixelAssemble",
		at = 0,
		params = { duration = 2.5, count = 30, spiral = true },
	},
}
