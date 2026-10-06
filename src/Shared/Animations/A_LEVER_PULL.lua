--!strict
-- A-LEVER_PULL (1.2): (helper) both hands grab a lever and pull it down.
return {
	id = "A-LEVER_PULL",
	length = 1.2,
	loop = false,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 5, 0, 0 } },
			{ t = 0.4, rot = { 20, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 10, 0, -3 } },
			{ t = 0.4, rot = { 120, 0, 10 } },
			{ t = 1, rot = { 60, 0, 10 }, ease = "QuadIn" },
		},
		RightElbow = {
			{ t = 0, rot = { 5, 0, 0 } },
			{ t = 0.4, rot = { 20, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 10, 0, 3 } },
			{ t = 0.4, rot = { 120, 0, -10 } },
			{ t = 1, rot = { 60, 0, -10 }, ease = "QuadIn" },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1, rot = { -15, 0, 0 } },
		},
	},
}
