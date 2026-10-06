--!strict
-- A-SHOUT (1.0): head back, arms out to the sides, torso forward.
return {
	id = "A-SHOUT",
	length = 1,
	loop = false,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.3, rot = { 10, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 0, 0, -3 } },
			{ t = 0.3, rot = { 20, 0, -70 } },
			{ t = 0.8, rot = { 20, 0, -70 } },
			{ t = 1, rot = { 5, 0, -10 } },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.3, rot = { 25, 0, 0 } },
			{ t = 0.8, rot = { 25, 0, 0 } },
			{ t = 1, rot = { 5, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.3, rot = { 10, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 0, 0, 3 } },
			{ t = 0.3, rot = { 20, 0, 70 } },
			{ t = 0.8, rot = { 20, 0, 70 } },
			{ t = 1, rot = { 5, 0, 10 } },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.3, rot = { -12, 0, 0 } },
			{ t = 0.8, rot = { -12, 0, 0 } },
			{ t = 1, rot = { -3, 0, 0 } },
		},
	},
}
