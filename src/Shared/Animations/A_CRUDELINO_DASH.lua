--!strict
-- A-CRUDELINO_DASH (1.0): (Crudelino) screams and shakes for the 1 s telegraph before a dash.
return {
	id = "A-CRUDELINO_DASH",
	length = 1,
	loop = false,
	tracks = {
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 0.1, rot = { 0, 0, 6 }, pos = { 0.15, 0, 0 } },
			{ t = 0.2, rot = { 0, 0, -6 }, pos = { -0.15, 0, 0 } },
			{ t = 0.3, rot = { 0, 0, 6 }, pos = { 0.15, 0, 0 } },
			{ t = 0.4, rot = { 0, 0, -6 }, pos = { -0.15, 0, 0 } },
			{ t = 0.5, rot = { 0, 0, 6 }, pos = { 0.15, 0, 0 } },
			{ t = 0.6, rot = { 0, 0, -6 }, pos = { -0.15, 0, 0 } },
			{ t = 0.7, rot = { -15, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 1, rot = { -25, 0, 0 }, pos = { 0, 0, 0 } },
		},
	},
}
