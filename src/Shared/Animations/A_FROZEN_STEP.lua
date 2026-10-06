--!strict
-- A-FROZEN_STEP (1.0 loop): (helper) frozen mid-step, one arm (the trunk side) reaching for the clock.
return {
	id = "A-FROZEN_STEP",
	length = 1,
	loop = true,
	tracks = {
		LeftHip = {
			{ t = 0, rot = { -20, 0, 0 } },
		},
		LeftKnee = {
			{ t = 0, rot = { -35, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { -15, 0, -8 } },
		},
		Neck = {
			{ t = 0, rot = { 5, 10, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 15, 0, 0 } },
		},
		RightHip = {
			{ t = 0, rot = { 25, 0, 0 } },
		},
		RightKnee = {
			{ t = 0, rot = { -10, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 80, 0, -10 } },
		},
		RootJoint = {
			{ t = 0, rot = { -8, 8, 0 } },
		},
	},
}
