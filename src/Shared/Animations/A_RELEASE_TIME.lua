--!strict
-- A-RELEASE_TIME (3.0): the frozen pose thaws: first the eyes, then the arms, then she drops to her knees.
return {
	id = "A-RELEASE_TIME",
	length = 3,
	loop = false,
	tracks = {
		LeftHip = {
			{ t = 0, rot = { -20, 0, 0 } },
			{ t = 1.6, rot = { -20, 0, 0 } },
			{ t = 2.6, rot = { 0, 0, -2 } },
		},
		LeftKnee = {
			{ t = 0, rot = { -35, 0, 0 } },
			{ t = 1.6, rot = { -35, 0, 0 } },
			{ t = 2.6, rot = { -95, 0, 0 }, ease = "QuadIn" },
		},
		LeftShoulder = {
			{ t = 0, rot = { -15, 0, -8 } },
			{ t = 0.8, rot = { -15, 0, -8 } },
			{ t = 1.6, rot = { 5, 0, -5 } },
		},
		Neck = {
			{ t = 0, rot = { 5, 10, 0 } },
			{ t = 0.3, rot = { 5, 10, 0 } },
			{ t = 0.8, rot = { 0, 0, 0 } },
			{ t = 3, rot = { -25, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 15, 0, 0 } },
			{ t = 1.6, rot = { 5, 0, 0 } },
		},
		RightHip = {
			{ t = 0, rot = { 25, 0, 0 } },
			{ t = 1.6, rot = { 25, 0, 0 } },
			{ t = 2.6, rot = { 0, 0, 2 } },
		},
		RightKnee = {
			{ t = 0, rot = { -10, 0, 0 } },
			{ t = 1.6, rot = { -10, 0, 0 } },
			{ t = 2.6, rot = { -95, 0, 0 }, ease = "QuadIn" },
		},
		RightShoulder = {
			{ t = 0, rot = { 80, 0, -10 } },
			{ t = 0.8, rot = { 80, 0, -10 } },
			{ t = 1.6, rot = { 5, 0, 5 }, ease = "QuadOut" },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 1.6, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 2.6, rot = { 0, 0, 0 }, pos = { 0, -1.15, 0 }, ease = "QuadIn" },
			{ t = 3, rot = { 0, 0, 0 }, pos = { 0, -1.15, 0 } },
		},
		RootJoint = {
			{ t = 0, rot = { -8, 8, 0 } },
			{ t = 1.6, rot = { -4, 0, 0 } },
			{ t = 3, rot = { -18, 0, 0 } },
		},
	},
}
