--!strict
-- A-WALK_TIRED (2.4 loop): half-speed walk, leaning forward, stopping after every 4 steps.
return {
	id = "A-WALK_TIRED",
	length = 2.4,
	loop = true,
	tracks = {
		LeftHip = {
			{ t = 0, rot = { -14, 0, 0 } },
			{ t = 0.4, rot = { 14, 0, 0 } },
			{ t = 0.8, rot = { -14, 0, 0 } },
			{ t = 1.2, rot = { 14, 0, 0 } },
			{ t = 1.6, rot = { 0, 0, 0 } },
			{ t = 2.4, rot = { -14, 0, 0 } },
		},
		LeftKnee = {
			{ t = 0, rot = { -25, 0, 0 } },
			{ t = 0.2, rot = { -5, 0, 0 } },
			{ t = 0.4, rot = { -25, 0, 0 } },
			{ t = 0.6, rot = { -5, 0, 0 } },
			{ t = 0.8, rot = { -25, 0, 0 } },
			{ t = 1, rot = { -5, 0, 0 } },
			{ t = 1.2, rot = { -25, 0, 0 } },
			{ t = 1.6, rot = { 0, 0, 0 } },
			{ t = 2.4, rot = { -25, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 5, 0, -3 } },
		},
		Neck = {
			{ t = 0, rot = { -15, 0, 0 } },
		},
		RightHip = {
			{ t = 0, rot = { 14, 0, 0 } },
			{ t = 0.4, rot = { -14, 0, 0 } },
			{ t = 0.8, rot = { 14, 0, 0 } },
			{ t = 1.2, rot = { -14, 0, 0 } },
			{ t = 1.6, rot = { 0, 0, 0 } },
			{ t = 2.4, rot = { 14, 0, 0 } },
		},
		RightKnee = {
			{ t = 0, rot = { -5, 0, 0 } },
			{ t = 0.2, rot = { -25, 0, 0 } },
			{ t = 0.4, rot = { -5, 0, 0 } },
			{ t = 0.6, rot = { -25, 0, 0 } },
			{ t = 0.8, rot = { -5, 0, 0 } },
			{ t = 1, rot = { -25, 0, 0 } },
			{ t = 1.2, rot = { -5, 0, 0 } },
			{ t = 1.6, rot = { 0, 0, 0 } },
			{ t = 2.4, rot = { -5, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 5, 0, 3 } },
		},
		RootJoint = {
			{ t = 0, rot = { -12, 0, 0 } },
			{ t = 1.6, rot = { -16, 0, 0 } },
			{ t = 2, rot = { -10, 0, 0 } },
			{ t = 2.4, rot = { -12, 0, 0 } },
		},
	},
}
