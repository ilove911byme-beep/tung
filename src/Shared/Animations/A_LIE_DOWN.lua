--!strict
-- A-LIE_DOWN (1.5): (helper) lies down on the back, arms loose.
return {
	id = "A-LIE_DOWN",
	length = 1.5,
	loop = false,
	tracks = {
		LeftShoulder = {
			{ t = 0, rot = { 0, 0, -3 } },
			{ t = 1.5, rot = { -20, 0, -25 } },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1.5, rot = { -5, 20, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 0, 0, 3 } },
			{ t = 1.5, rot = { -20, 0, 25 } },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 1.5, rot = { 80, 0, 0 }, pos = { 0, -2.5, 1 }, ease = "QuadIn" },
		},
	},
}
