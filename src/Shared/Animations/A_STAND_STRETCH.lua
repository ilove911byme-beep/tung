--!strict
-- A-STAND_STRETCH (1.5): arms up, then down, the head looks to both sides.
return {
	id = "A-STAND_STRETCH",
	length = 1.5,
	loop = false,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { 10, 0, 0 } },
			{ t = 1.5, rot = { 5, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 0, 0, -3 } },
			{ t = 0.6, rot = { 170, 0, -10 } },
			{ t = 1.1, rot = { 170, 0, -10 } },
			{ t = 1.5, rot = { 0, 0, -3 }, ease = "QuadOut" },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { 12, 0, 0 } },
			{ t = 0.9, rot = { 10, 25, 0 } },
			{ t = 1.2, rot = { 10, -25, 0 } },
			{ t = 1.5, rot = { 0, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { 10, 0, 0 } },
			{ t = 1.5, rot = { 5, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 0, 0, 3 } },
			{ t = 0.6, rot = { 170, 0, 10 } },
			{ t = 1.1, rot = { 170, 0, 10 } },
			{ t = 1.5, rot = { 0, 0, 3 }, ease = "QuadOut" },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 0.6, rot = { 0, 0, 0 }, pos = { 0, 0.1, 0 } },
			{ t = 1.5, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { 6, 0, 0 } },
			{ t = 1.5, rot = { 0, 0, 0 } },
		},
	},
}
