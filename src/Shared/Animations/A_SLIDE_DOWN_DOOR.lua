--!strict
-- A-SLIDE_DOWN_DOOR (4.0): the back slides down the door into a sitting pose, the head drops onto the shoulder.
return {
	id = "A-SLIDE_DOWN_DOOR",
	length = 4,
	loop = false,
	tracks = {
		LeftHip = {
			{ t = 0, rot = { 30, 0, -6 } },
			{ t = 4, rot = { 85, 0, -8 } },
		},
		LeftKnee = {
			{ t = 0, rot = { -35, 0, 0 } },
			{ t = 4, rot = { -25, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { -20, 0, -70 } },
			{ t = 2.5, rot = { 0, 0, -25 } },
			{ t = 4, rot = { 5, 0, -12 } },
		},
		Neck = {
			{ t = 0, rot = { -5, 0, 0 } },
			{ t = 3, rot = { -10, 0, 0 } },
			{ t = 4, rot = { -14, 0, 22 }, ease = "QuadOut" },
		},
		RightHip = {
			{ t = 0, rot = { 30, 0, 6 } },
			{ t = 4, rot = { 85, 0, 8 } },
		},
		RightKnee = {
			{ t = 0, rot = { -35, 0, 0 } },
			{ t = 4, rot = { -25, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { -20, 0, 70 } },
			{ t = 2.5, rot = { 0, 0, 25 } },
			{ t = 4, rot = { 5, 0, 12 } },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, -0.3, 0 } },
			{ t = 4, rot = { 0, 0, 0 }, pos = { 0, -2.1, 0.3 }, ease = "QuadInOut" },
		},
		RootJoint = {
			{ t = 0, rot = { 10, 0, 0 } },
			{ t = 4, rot = { 6, 0, 0 } },
		},
	},
}
