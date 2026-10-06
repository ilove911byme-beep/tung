--!strict
-- A-BALLERINA_SLOW_STOP (3.0): two last turns, each one twice as slow as the one before
-- (1.0 s, then 2.0 s with Quad Out). On the last turn the arms come down and the head bows.
-- continueYaw: the turn continues from the facing she has when it starts.
return {
	id = "A-BALLERINA_SLOW_STOP",
	length = 3,
	loop = false,
	continueYaw = true,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 0, -10.3, 30.3 } },
			{ t = 1, rot = { 0, -10.3, 30.3 }, ease = "Linear" },
			{ t = 3, rot = { 10, 0, 0 }, ease = "QuadOut" },
		},
		LeftHip = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1, rot = { 0, 0, 0 }, ease = "Linear" },
			{ t = 3, rot = { 0, 0, 0 }, ease = "QuadOut" },
		},
		LeftKnee = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1, rot = { 0, 0, 0 }, ease = "Linear" },
			{ t = 3, rot = { 0, 0, 0 }, ease = "QuadOut" },
		},
		LeftShoulder = {
			{ t = 0, rot = { 146.8, 31.9, 14.6 } },
			{ t = 1, rot = { 146.8, 31.9, 14.6 }, ease = "Linear" },
			{ t = 3, rot = { 4, 0, -3 }, ease = "QuadOut" },
		},
		LeftWrist = {
			{ t = 0, rot = { 0, 0, 10 } },
			{ t = 1, rot = { 0, 0, 10 }, ease = "Linear" },
			{ t = 3, rot = { 6, 0, 0 }, ease = "QuadOut" },
		},
		Neck = {
			{ t = 0, rot = { -5, 0, 0 } },
			{ t = 1, rot = { -5, 0, 0 }, ease = "Linear" },
			{ t = 3, rot = { -24, 0, 6 }, ease = "QuadOut" },
		},
		RightElbow = {
			{ t = 0, rot = { 0, 10.3, -30.3 } },
			{ t = 1, rot = { 0, 10.3, -30.3 }, ease = "Linear" },
			{ t = 3, rot = { 10, 0, 0 }, ease = "QuadOut" },
		},
		RightHip = {
			{ t = 0, rot = { 55, 0, 22 } },
			{ t = 1, rot = { 55, 0, 22 }, ease = "Linear" },
			{ t = 3, rot = { 0, 0, 0 }, ease = "QuadOut" },
		},
		RightKnee = {
			{ t = 0, rot = { -100, 0, 0 } },
			{ t = 1, rot = { -100, 0, 0 }, ease = "Linear" },
			{ t = 3, rot = { 0, 0, 0 }, ease = "QuadOut" },
		},
		RightShoulder = {
			{ t = 0, rot = { 146.8, -31.9, -14.6 } },
			{ t = 1, rot = { 146.8, -31.9, -14.6 }, ease = "Linear" },
			{ t = 3, rot = { 4, 0, 3 }, ease = "QuadOut" },
		},
		RightWrist = {
			{ t = 0, rot = { 0, 0, -10 } },
			{ t = 1, rot = { 0, 0, -10 }, ease = "Linear" },
			{ t = 3, rot = { 6, 0, 0 }, ease = "QuadOut" },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0.25, 0 } },
			{ t = 1, rot = { 0, 360, 0 }, pos = { 0, 0.22, 0 }, ease = "Linear" },
			{ t = 3, rot = { 0, 720, 0 }, pos = { 0, 0, 0 }, ease = "QuadOut" },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1, rot = { 0, 0, 0 }, ease = "Linear" },
			{ t = 3, rot = { -6, 0, 0 }, ease = "QuadOut" },
		},
	},
}
