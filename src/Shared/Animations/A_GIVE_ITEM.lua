--!strict
-- A-GIVE_ITEM (1.2): the arm reaches forward, holds 0.4 s, lowers slowly.
return {
	id = "A-GIVE_ITEM",
	length = 1.2,
	loop = false,
	tracks = {
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { -10, 0, 0 } },
			{ t = 1.2, rot = { -5, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 10, 0, 0 } },
			{ t = 0.4, rot = { 15, 0, 0 } },
			{ t = 0.8, rot = { 15, 0, 0 } },
			{ t = 1.2, rot = { 10, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 5, 0, 3 } },
			{ t = 0.4, rot = { 80, 0, 0 } },
			{ t = 0.8, rot = { 80, 0, 0 } },
			{ t = 1.2, rot = { 10, 0, 3 }, ease = "QuadOut" },
		},
		RightWrist = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { -10, 0, 0 } },
			{ t = 1.2, rot = { 0, 0, 0 } },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { -6, 0, 0 } },
			{ t = 1.2, rot = { -2, 0, 0 } },
		},
	},
}
