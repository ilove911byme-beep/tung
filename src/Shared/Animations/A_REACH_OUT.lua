--!strict
-- A-REACH_OUT (2.0): the right arm slowly reaches forward (toward the camera / the tavern
-- window), the hand opens at the end (wrist from curled to flat) and the pose holds.
-- The head lifts to look where the hand goes.
return {
	id = "A-REACH_OUT",
	length = 2,
	loop = false,
	tracks = {
		Neck = {
			{ t = 0, rot = { -14, 0, 4 } },
			{ t = 0.9, rot = { 6, 0, 0 } },
			{ t = 1.8, rot = { 12, 0, -4 }, ease = "SineOut" },
			{ t = 2, rot = { 12, 0, -4 } },
		},
		RightElbow = {
			{ t = 0, rot = { 20, -5, -10 } },
			{ t = 0.9, rot = { 16, 0, -4 } },
			{ t = 1.8, rot = { 6, 0, 0 }, ease = "SineOut" },
			{ t = 2, rot = { 6, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 60, -30, -30 } },
			{ t = 0.9, rot = { 80, -20, -14 } },
			{ t = 1.8, rot = { 96, -12, -6 }, ease = "SineOut" },
			{ t = 2, rot = { 96, -12, -6 } },
		},
		RightWrist = {
			{ t = 0, rot = { 40, 0, 0 } },
			{ t = 0.9, rot = { 45, 0, 0 } },
			{ t = 1.8, rot = { -12, 0, 0 }, ease = "SineOut" },
			{ t = 2, rot = { -12, 0, 0 } },
		},
		RootJoint = {
			{ t = 0, rot = { -20, 0, 0 } },
			{ t = 0.9, rot = { -14, 0, 0 } },
			{ t = 1.8, rot = { -8, 0, 0 }, ease = "SineOut" },
			{ t = 2, rot = { -8, 0, 0 } },
		},
	},
}
