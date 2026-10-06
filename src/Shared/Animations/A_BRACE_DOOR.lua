--!strict
-- A-BRACE_DOOR (1.0 loop): back against the door, feet braced, the torso shakes with every blow (0.1 stud impulse).
return {
	id = "A-BRACE_DOOR",
	length = 1,
	loop = true,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 10, 0, 0 } },
		},
		LeftHip = {
			{ t = 0, rot = { 30, 0, -6 } },
		},
		LeftKnee = {
			{ t = 0, rot = { -35, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { -20, 0, -70 } },
		},
		Neck = {
			{ t = 0, rot = { -5, 0, 0 } },
			{ t = 0.1, rot = { 5, 0, 0 } },
			{ t = 0.4, rot = { -5, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 10, 0, 0 } },
		},
		RightHip = {
			{ t = 0, rot = { 30, 0, 6 } },
		},
		RightKnee = {
			{ t = 0, rot = { -35, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { -20, 0, 70 } },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, -0.3, 0 } },
			{ t = 0.1, rot = { 0, 0, 0 }, pos = { 0, -0.3, 0.1 } },
			{ t = 0.3, rot = { 0, 0, 0 }, pos = { 0, -0.3, 0 } },
			{ t = 1, rot = { 0, 0, 0 }, pos = { 0, -0.3, 0 } },
		},
		RootJoint = {
			{ t = 0, rot = { 10, 0, 0 } },
			{ t = 0.1, rot = { 14, 0, 0 } },
			{ t = 0.3, rot = { 10, 0, 0 } },
			{ t = 1, rot = { 10, 0, 0 } },
		},
	},
}
