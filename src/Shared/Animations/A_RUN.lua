--!strict
-- A-RUN (0.66 loop): bigger strides, bent elbows, leaning forward.
return {
	id = "A-RUN",
	length = 0.66,
	loop = true,
	tracks = {
		Root = {
			{ t = 0, pos = { 0, -0.05, 0 } },
			{ t = 0.165, pos = { 0, 0.18, 0 } },
			{ t = 0.33, pos = { 0, -0.05, 0 } },
			{ t = 0.495, pos = { 0, 0.18, 0 } },
			{ t = 0.66, pos = { 0, -0.05, 0 } },
		},
		RootJoint = { { t = 0, rot = { -12, 0, 0 } } },
		RightHip = {
			{ t = 0, rot = { 45, 0, 0 } },
			{ t = 0.33, rot = { -40, 0, 0 } },
			{ t = 0.66, rot = { 45, 0, 0 } },
		},
		RightKnee = {
			{ t = 0, rot = { -15, 0, 0 } },
			{ t = 0.33, rot = { -40, 0, 0 } },
			{ t = 0.5, rot = { -90, 0, 0 } },
			{ t = 0.66, rot = { -15, 0, 0 } },
		},
		LeftHip = {
			{ t = 0, rot = { -40, 0, 0 } },
			{ t = 0.33, rot = { 45, 0, 0 } },
			{ t = 0.66, rot = { -40, 0, 0 } },
		},
		LeftKnee = {
			{ t = 0, rot = { -40, 0, 0 } },
			{ t = 0.17, rot = { -90, 0, 0 } },
			{ t = 0.33, rot = { -15, 0, 0 } },
			{ t = 0.66, rot = { -40, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { -45, 0, 5 } },
			{ t = 0.33, rot = { 50, 0, 5 } },
			{ t = 0.66, rot = { -45, 0, 5 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 50, 0, -5 } },
			{ t = 0.33, rot = { -45, 0, -5 } },
			{ t = 0.66, rot = { 50, 0, -5 } },
		},
		RightElbow = { { t = 0, rot = { 70, 0, 0 } } },
		LeftElbow = { { t = 0, rot = { 70, 0, 0 } } },
	},
}
