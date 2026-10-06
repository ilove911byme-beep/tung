--!strict
-- A-KNEEL_SOFT (1.5): goes down on one (right) knee, the torso leans forward and the right
-- hand reaches down (to stroke Giallino in CS-05).
return {
	id = "A-KNEEL_SOFT",
	length = 1.5,
	loop = false,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 10, 0, 0 } },
			{ t = 0.75, rot = { 25, 10, 15 } },
			{ t = 1.5, rot = { 45, 0, 0 }, ease = "QuadOut" },
		},
		LeftHip = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.75, rot = { 35, 0, -3 } },
			{ t = 1.5, rot = { 62, 0, -4 }, ease = "QuadOut" },
		},
		LeftKnee = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.75, rot = { -40, 0, 0 } },
			{ t = 1.5, rot = { -62, 0, 0 }, ease = "QuadOut" },
		},
		LeftShoulder = {
			{ t = 0, rot = { 4, 0, -3 } },
			{ t = 0.75, rot = { 20, 8, 10 } },
			{ t = 1.5, rot = { 38, 0, -6 }, ease = "QuadOut" },
		},
		LeftWrist = {
			{ t = 0, rot = { 6, 0, 0 } },
			{ t = 0.75, rot = { 6, 0, 0 } },
			{ t = 1.5, rot = { 0, 0, 0 }, ease = "QuadOut" },
		},
		Neck = {
			{ t = 0, rot = { -24, 0, 6 } },
			{ t = 0.75, rot = { -18, 0, 4 } },
			{ t = 1.5, rot = { -14, 0, 4 }, ease = "QuadOut" },
		},
		RightElbow = {
			{ t = 0, rot = { 10, 0, 0 } },
			{ t = 0.75, rot = { 25, -10, -15 } },
			{ t = 1.5, rot = { 39.8, -21.8, -38.4 }, ease = "QuadOut" },
		},
		RightHip = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.75, rot = { -14, 0, 0 } },
			{ t = 1.5, rot = { -4, 0, 0 }, ease = "QuadOut" },
		},
		RightKnee = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.75, rot = { -55, 0, 0 } },
			{ t = 1.5, rot = { -90, 0, 0 }, ease = "QuadOut" },
		},
		RightShoulder = {
			{ t = 0, rot = { 4, 0, 3 } },
			{ t = 0.75, rot = { 20, -8, -10 } },
			{ t = 1.5, rot = { 34.8, -15.3, -26.8 }, ease = "QuadOut" },
		},
		RightWrist = {
			{ t = 0, rot = { 6, 0, 0 } },
			{ t = 0.75, rot = { 6, 0, 0 } },
			{ t = 1.5, rot = { 10, 0, 0 }, ease = "QuadOut" },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 0.75, rot = { 0, 0, 0 }, pos = { 0, -0.35, 0 } },
			{ t = 1.5, rot = { 0, 0, 0 }, pos = { 0, -0.65, 0 }, ease = "QuadOut" },
		},
		RootJoint = {
			{ t = 0, rot = { -6, 0, 0 } },
			{ t = 0.75, rot = { -12, 0, 0 } },
			{ t = 1.5, rot = { -20, 0, 0 }, ease = "QuadOut" },
		},
	},
}
