--!strict
-- A-KNEEL_HOLD_ITEM (2.0): down on both knees, the item held to the chest with both hands.
return {
	id = "A-KNEEL_HOLD_ITEM",
	length = 2,
	loop = false,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1.2, rot = { 95, 0, 0 } },
		},
		LeftHip = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { 30, 0, 0 } },
			{ t = 1.2, rot = { 5, 0, -2 } },
		},
		LeftKnee = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { -50, 0, 0 } },
			{ t = 1.2, rot = { -95, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 0, 0, -3 } },
			{ t = 1.2, rot = { 60, 0, 20 } },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 2, rot = { -25, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1.2, rot = { 95, 0, 0 } },
		},
		RightHip = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { 30, 0, 0 } },
			{ t = 1.2, rot = { 5, 0, 2 } },
		},
		RightKnee = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { -50, 0, 0 } },
			{ t = 1.2, rot = { -95, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 0, 0, 3 } },
			{ t = 1.2, rot = { 60, 0, -20 } },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 1.2, rot = { 0, 0, 0 }, pos = { 0, -1.15, 0 }, ease = "QuadOut" },
			{ t = 2, rot = { 0, 0, 0 }, pos = { 0, -1.15, 0 } },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1.2, rot = { -12, 0, 0 } },
			{ t = 2, rot = { -15, 0, 0 } },
		},
	},
}
