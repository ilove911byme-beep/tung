--!strict
-- A-POINT (1.2): (helper) points ahead and up with the right arm.
return {
	id = "A-POINT",
	length = 1.2,
	loop = false,
	tracks = {
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { 5, 10, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 5, 0, 0 } },
			{ t = 0.4, rot = { 0, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 5, 0, 3 } },
			{ t = 0.4, rot = { 105, 0, 5 } },
			{ t = 1.2, rot = { 105, 0, 5 } },
		},
	},
}
