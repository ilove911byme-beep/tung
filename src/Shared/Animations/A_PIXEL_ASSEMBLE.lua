--!strict
-- A-PIXEL_ASSEMBLE (2.0): reverse of A-PIXEL_DISSOLVE with a golden flash (CS-REVIVE).
return {
	id = "A-PIXEL_ASSEMBLE",
	length = 2.0,
	loop = false,
	tracks = {},
	effect = {
		kind = "PixelAssemble",
		at = 0,
		params = { duration = 2.0, spiral = false, flash = true },
	},
}
