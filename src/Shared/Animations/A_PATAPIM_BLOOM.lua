--!strict
-- A-PATAPIM_BLOOM (4.0): new green leaves appear on the branches, scale 0 -> 1 (Bloom effect).
return {
	id = "A-PATAPIM_BLOOM",
	length = 4,
	loop = false,
	tracks = {
		LeftShoulder = {
			{ t = 0, rot = { 5, 0, -8 } },
			{ t = 2, rot = { 40, 0, -40 } },
			{ t = 4, rot = { 30, 0, -35 } },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 2, rot = { 15, 0, 0 } },
			{ t = 4, rot = { 10, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 5, 0, 8 } },
			{ t = 2, rot = { 40, 0, 40 } },
			{ t = 4, rot = { 30, 0, 35 } },
		},
	},
	effect = { kind = "Bloom", at = 0, params = { duration = 4 } },
}
