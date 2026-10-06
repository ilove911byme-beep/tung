--!strict
-- A-KNOCK_SOFT (2.0): three soft knocks with 0.6 s pauses.
return {
	id = "A-KNOCK_SOFT",
	length = 2,
	loop = false,
	tracks = {
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.3, rot = { -6, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 10, 0, 0 } },
			{ t = 0.3, rot = { 70, 0, 0 } },
			{ t = 0.4, rot = { 70, 0, 0 } },
			{ t = 0.5, rot = { 45, 0, 0 } },
			{ t = 0.6, rot = { 70, 0, 0 } },
			{ t = 1, rot = { 70, 0, 0 } },
			{ t = 1.1, rot = { 45, 0, 0 } },
			{ t = 1.2, rot = { 70, 0, 0 } },
			{ t = 1.6, rot = { 70, 0, 0 } },
			{ t = 1.7, rot = { 45, 0, 0 } },
			{ t = 1.8, rot = { 70, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 10, 0, 3 } },
			{ t = 0.3, rot = { 95, 0, -5 } },
			{ t = 2, rot = { 95, 0, -5 } },
		},
	},
}
