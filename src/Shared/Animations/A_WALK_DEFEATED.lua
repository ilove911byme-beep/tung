--!strict
-- A-WALK_DEFEATED (1.6 loop): slow step (0.6x), head down, arms do not swing.
return {
	id = "A-WALK_DEFEATED",
	length = 1.6,
	loop = true,
	tracks = {
		LeftHip = {
			{ t = 0, rot = { -16, 0, 0 } },
			{ t = 0.8, rot = { 16, 0, 0 } },
			{ t = 1.6, rot = { -16, 0, 0 } },
		},
		LeftKnee = {
			{ t = 0, rot = { -18, 0, 0 } },
			{ t = 0.4, rot = { -30, 0, 0 } },
			{ t = 0.8, rot = { -4, 0, 0 } },
			{ t = 1.6, rot = { -18, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 2, 0, -2 } },
		},
		Neck = {
			{ t = 0, rot = { -30, 0, 0 } },
		},
		RightHip = {
			{ t = 0, rot = { 16, 0, 0 } },
			{ t = 0.8, rot = { -16, 0, 0 } },
			{ t = 1.6, rot = { 16, 0, 0 } },
		},
		RightKnee = {
			{ t = 0, rot = { -4, 0, 0 } },
			{ t = 0.8, rot = { -18, 0, 0 } },
			{ t = 1.2, rot = { -30, 0, 0 } },
			{ t = 1.6, rot = { -4, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 2, 0, 2 } },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 0.4, rot = { 0, 0, 0 }, pos = { 0, 0.03, 0 } },
			{ t = 0.8, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 1.2, rot = { 0, 0, 0 }, pos = { 0, 0.03, 0 } },
			{ t = 1.6, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
		},
		RootJoint = {
			{ t = 0, rot = { -8, 0, 0 } },
		},
	},
}
