--!strict
-- A-CARVE (2.5): the hand with the knife makes 4 short strokes across the board held in the other hand.
return {
	id = "A-CARVE",
	length = 2.5,
	loop = false,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 5, 0, 0 } },
			{ t = 0.4, rot = { 70, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 10, 0, -3 } },
			{ t = 0.4, rot = { 60, 0, 15 } },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { -30, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 5, 0, 0 } },
			{ t = 0.4, rot = { 80, 0, 0 } },
			{ t = 0.6, rot = { 95, 0, 0 } },
			{ t = 0.8, rot = { 75, 0, 0 } },
			{ t = 1.1, rot = { 95, 0, 0 } },
			{ t = 1.3, rot = { 75, 0, 0 } },
			{ t = 1.6, rot = { 95, 0, 0 } },
			{ t = 1.8, rot = { 75, 0, 0 } },
			{ t = 2.1, rot = { 95, 0, 0 } },
			{ t = 2.3, rot = { 80, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 10, 0, 3 } },
			{ t = 0.4, rot = { 55, 0, -18 } },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { -6, 0, 0 } },
		},
	},
}
