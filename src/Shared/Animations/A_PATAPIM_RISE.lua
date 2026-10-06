--!strict
-- A-PATAPIM_RISE (3.0): rises out of the ground, clods of earth fall off (DirtBurst effect).
return {
	id = "A-PATAPIM_RISE",
	length = 3,
	loop = false,
	tracks = {
		LeftShoulder = {
			{ t = 0, rot = { 150, 0, -30 } },
			{ t = 1.5, rot = { 120, 0, -30 } },
			{ t = 3, rot = { 10, 0, -8 } },
		},
		Neck = {
			{ t = 0, rot = { -20, 0, 0 } },
			{ t = 2, rot = { -10, 0, 0 } },
			{ t = 3, rot = { 0, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 150, 0, 30 } },
			{ t = 1.5, rot = { 120, 0, 30 } },
			{ t = 3, rot = { 10, 0, 8 } },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, -6, 0 } },
			{ t = 0.4, rot = { 0, 0, 3 }, pos = { 0, -5, 0 } },
			{ t = 1.2, rot = { 0, 0, -3 }, pos = { 0, -2.5, 0 } },
			{ t = 2.2, rot = { 0, 0, 2 }, pos = { 0, -0.6, 0 } },
			{ t = 3, rot = { 0, 0, 0 }, pos = { 0, 0, 0 }, ease = "QuadOut" },
		},
	},
	effect = { kind = "DirtBurst", at = 0.1 },
}
