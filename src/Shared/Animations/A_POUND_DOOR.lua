--!strict
-- A-POUND_DOOR (1.5 loop): both fists pound the door in turn.
return {
	id = "A-POUND_DOOR",
	length = 1.5,
	loop = true,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 20, 0, 0 } },
			{ t = 0.75, rot = { 20, 0, 0 } },
			{ t = 1.125, rot = { 55, 0, 0 } },
			{ t = 1.5, rot = { 20, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 105, 0, 12 } },
			{ t = 0.75, rot = { 105, 0, 12 } },
			{ t = 1.125, rot = { 80, 0, 12 } },
			{ t = 1.5, rot = { 105, 0, 12 } },
		},
		Neck = {
			{ t = 0, rot = { -10, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 20, 0, 0 } },
			{ t = 0.375, rot = { 55, 0, 0 } },
			{ t = 0.75, rot = { 20, 0, 0 } },
			{ t = 1.5, rot = { 20, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 105, 0, -12 } },
			{ t = 0.375, rot = { 80, 0, -12 } },
			{ t = 0.75, rot = { 105, 0, -12 } },
			{ t = 1.125, rot = { 105, 0, -12 } },
			{ t = 1.5, rot = { 105, 0, -12 } },
		},
		RootJoint = {
			{ t = 0, rot = { -6, 0, 0 } },
			{ t = 0.375, rot = { -2, 0, 0 } },
			{ t = 0.75, rot = { -6, 0, 0 } },
			{ t = 1.125, rot = { -2, 0, 0 } },
			{ t = 1.5, rot = { -6, 0, 0 } },
		},
	},
}
