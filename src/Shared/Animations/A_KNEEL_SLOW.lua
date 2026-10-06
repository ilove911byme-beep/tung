--!strict
-- A-KNEEL_SLOW (3.0): very slowly down onto both knees, the head drops last.
return {
	id = "A-KNEEL_SLOW",
	length = 3,
	loop = false,
	tracks = {
		LeftHip = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1.1, rot = { 30, 0, 0 } },
			{ t = 2.2, rot = { 5, 0, -2 } },
		},
		LeftKnee = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1.1, rot = { -50, 0, 0 } },
			{ t = 2.2, rot = { -95, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 0, 0, -3 } },
			{ t = 2.2, rot = { 5, 0, -5 } },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 2.3, rot = { -5, 0, 0 } },
			{ t = 3, rot = { -40, 0, 0 }, ease = "QuadIn" },
		},
		RightHip = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1.1, rot = { 30, 0, 0 } },
			{ t = 2.2, rot = { 5, 0, 2 } },
		},
		RightKnee = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1.1, rot = { -50, 0, 0 } },
			{ t = 2.2, rot = { -95, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 0, 0, 3 } },
			{ t = 2.2, rot = { 5, 0, 5 } },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 2.2, rot = { 0, 0, 0 }, pos = { 0, -1.15, 0 }, ease = "QuadInOut" },
			{ t = 3, rot = { 0, 0, 0 }, pos = { 0, -1.15, 0 } },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 2.2, rot = { -8, 0, 0 } },
			{ t = 3, rot = { -12, 0, 0 } },
		},
	},
}
