--!strict
-- A-PIXEL_DISSOLVE (6.0, short version 2.0 via effectParams.duration): the body breaks into
-- 0.4-stud cubes from the bottom up; see Visual/Effects/PixelDissolve.
return {
	id = "A-PIXEL_DISSOLVE",
	length = 6.0,
	loop = false,
	tracks = {},
	effect = { kind = "PixelDissolve", at = 0, params = { duration = 6.0, cubeSize = 0.4 } },
}
