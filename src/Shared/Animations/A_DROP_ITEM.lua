--!strict
-- A-DROP_ITEM (0.8): the hand drops, the held item falls (DropItem effect), shoulders flinch.
-- effectParams.part names the held part (default "Apple").
return {
	id = "A-DROP_ITEM",
	length = 0.8,
	loop = false,
	tracks = {
		LeftShoulder = {
			{ t = 0, rot = { 0, 0, -3 } },
			{ t = 0.3, rot = { 15, 0, -12 } },
			{ t = 0.8, rot = { 0, 0, -3 } },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.3, rot = { 8, 0, 0 } },
			{ t = 0.8, rot = { 0, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 60, 0, 0 } },
			{ t = 0.25, rot = { 10, 0, 0 }, ease = "QuadIn" },
			{ t = 0.8, rot = { 5, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 40, 0, 5 } },
			{ t = 0.25, rot = { 10, 0, 5 }, ease = "QuadIn" },
			{ t = 0.8, rot = { 0, 0, 3 } },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.3, rot = { 4, 0, 0 } },
			{ t = 0.8, rot = { 0, 0, 0 } },
		},
	},
	effect = { kind = "DropItem", at = 0.25 },
}
