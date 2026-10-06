--!strict
-- A-PLAYER_REVIVE_HELP (3.0 loop): the teammate kneels with both hands on the downed player back.
return {
	id = "A-PLAYER_REVIVE_HELP",
	length = 3,
	loop = true,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 25, 0, 0 } },
			{ t = 0.75, rot = { 25, 0, 0 } },
			{ t = 1.5, rot = { 25, 0, 0 } },
			{ t = 2.25, rot = { 25, 0, 0 } },
			{ t = 3, rot = { 25, 0, 0 } },
		},
		LeftKnee = {
			{ t = 0, rot = { -90, 0, 0 } },
			{ t = 0.75, rot = { -90, 0, 0 } },
			{ t = 1.5, rot = { -90, 0, 0 } },
			{ t = 2.25, rot = { -90, 0, 0 } },
			{ t = 3, rot = { -90, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 55, 0, -6 } },
			{ t = 0.75, rot = { 64, 0, -6 } },
			{ t = 1.5, rot = { 55, 0, -6 } },
			{ t = 2.25, rot = { 64, 0, -6 } },
			{ t = 3, rot = { 55, 0, -6 } },
		},
		Neck = {
			{ t = 0, rot = { -15, 0, 0 } },
			{ t = 0.75, rot = { -15, 0, 0 } },
			{ t = 1.5, rot = { -15, 0, 0 } },
			{ t = 2.25, rot = { -15, 0, 0 } },
			{ t = 3, rot = { -15, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 25, 0, 0 } },
			{ t = 0.75, rot = { 25, 0, 0 } },
			{ t = 1.5, rot = { 25, 0, 0 } },
			{ t = 2.25, rot = { 25, 0, 0 } },
			{ t = 3, rot = { 25, 0, 0 } },
		},
		RightKnee = {
			{ t = 0, rot = { -90, 0, 0 } },
			{ t = 0.75, rot = { -90, 0, 0 } },
			{ t = 1.5, rot = { -90, 0, 0 } },
			{ t = 2.25, rot = { -90, 0, 0 } },
			{ t = 3, rot = { -90, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 55, 0, 6 } },
			{ t = 0.75, rot = { 64, 0, 6 } },
			{ t = 1.5, rot = { 55, 0, 6 } },
			{ t = 2.25, rot = { 64, 0, 6 } },
			{ t = 3, rot = { 55, 0, 6 } },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, -1.2, 0 } },
			{ t = 0.75, rot = { 0, 0, 0 }, pos = { 0, -1.2, 0 } },
			{ t = 1.5, rot = { 0, 0, 0 }, pos = { 0, -1.2, 0 } },
			{ t = 2.25, rot = { 0, 0, 0 }, pos = { 0, -1.2, 0 } },
			{ t = 3, rot = { 0, 0, 0 }, pos = { 0, -1.2, 0 } },
		},
		RootJoint = {
			{ t = 0, rot = { -30, 0, 0 } },
			{ t = 0.75, rot = { -30, 0, 0 } },
			{ t = 1.5, rot = { -30, 0, 0 } },
			{ t = 2.25, rot = { -30, 0, 0 } },
			{ t = 3, rot = { -30, 0, 0 } },
		},
	},
}
