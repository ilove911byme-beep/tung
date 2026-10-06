--!strict
-- A-HOLD_UP (1.0): (helper) raises the left arm high, holding something up (Lirili's clock, a sign).
return {
	id = "A-HOLD_UP",
	length = 1,
	loop = false,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 5, 0, 0 } },
			{ t = 0.6, rot = { 10, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 10, 0, -3 } },
			{ t = 0.6, rot = { 160, 0, 8 } },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { 15, 0, 0 } },
		},
	},
}
