--!strict
-- A-HUG (2.5): arms come forward and close around, slow rocking (two actors move together by cues).
return {
	id = "A-HUG",
	length = 2.5,
	loop = false,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 5, 0, 0 } },
			{ t = 0.8, rot = { 55, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 5, 0, -3 } },
			{ t = 0.8, rot = { 85, 0, 35 } },
			{ t = 2.5, rot = { 85, 0, 35 } },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.8, rot = { -10, 15, 0 } },
			{ t = 2.5, rot = { -10, 15, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 5, 0, 0 } },
			{ t = 0.8, rot = { 55, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 5, 0, 3 } },
			{ t = 0.8, rot = { 85, 0, -35 } },
			{ t = 2.5, rot = { 85, 0, -35 } },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.8, rot = { -6, 0, 0 } },
			{ t = 1.4, rot = { -6, 0, 5 } },
			{ t = 2, rot = { -6, 0, -5 } },
			{ t = 2.5, rot = { -6, 0, 0 } },
		},
	},
}
