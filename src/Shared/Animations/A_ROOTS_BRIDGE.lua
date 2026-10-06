--!strict
-- A-ROOTS_BRIDGE (5.0): arms reach down toward the gorge while the roots grow across it (RootsBridge effect).
-- The cue passes effectParams.fromPoint / toPoint (the two edges of the gorge).
return {
	id = "A-ROOTS_BRIDGE",
	length = 5,
	loop = false,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 5, 0, 0 } },
			{ t = 0.6, rot = { 10, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 10, 0, -8 } },
			{ t = 0.6, rot = { 70, 0, -20 } },
			{ t = 5, rot = { 75, 0, -22 } },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { -15, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 5, 0, 0 } },
			{ t = 0.6, rot = { 10, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 10, 0, 8 } },
			{ t = 0.6, rot = { 70, 0, 20 } },
			{ t = 5, rot = { 75, 0, 22 } },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { -20, 0, 0 } },
			{ t = 5, rot = { -24, 0, 0 } },
		},
	},
	effect = { kind = "RootsBridge", at = 0.5 },
}
