--!strict
-- A-TUNG_LOOK_BACK (1.6): stops, turns the head back for 1.0 s, turns away again.
return {
	id = "A-TUNG_LOOK_BACK",
	length = 1.6,
	loop = false,
	tracks = {
		LeftHip = {
			{ t = 0, rot = { 0, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 0, 0, -3 } },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.3, rot = { 0, 100, 0 } },
			{ t = 1.3, rot = { 0, 100, 0 } },
			{ t = 1.6, rot = { 0, 0, 0 } },
		},
		RightHip = {
			{ t = 0, rot = { 0, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 0, 0, 3 } },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.3, rot = { 0, 45, 0 } },
			{ t = 1.3, rot = { 0, 45, 0 } },
			{ t = 1.6, rot = { 0, 0, 0 } },
		},
	},
}
