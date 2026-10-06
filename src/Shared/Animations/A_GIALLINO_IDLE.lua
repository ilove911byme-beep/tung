--!strict
-- A-GIALLINO_IDLE (2.0 loop): floats up and down 0.3 stud and slowly turns +-10 degrees.
return {
	id = "A-GIALLINO_IDLE",
	length = 2.0,
	loop = true,
	tracks = {
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 0.5, rot = { 0, 10, 0 }, pos = { 0, 0.15, 0 } },
			{ t = 1.0, rot = { 0, 0, 0 }, pos = { 0, 0.3, 0 } },
			{ t = 1.5, rot = { 0, -10, 0 }, pos = { 0, 0.15, 0 } },
			{ t = 2.0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
		},
	},
}
