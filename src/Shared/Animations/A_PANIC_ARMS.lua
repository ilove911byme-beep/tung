--!strict
-- A-PANIC_ARMS (1.2 loop): arms flap up and down fast, the head looks around.
return {
	id = "A-PANIC_ARMS",
	length = 1.2,
	loop = true,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 40, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 40, 0, -30 } },
			{ t = 0.3, rot = { 150, 0, -20 } },
			{ t = 0.6, rot = { 40, 0, -30 } },
			{ t = 0.9, rot = { 150, 0, -20 } },
			{ t = 1.2, rot = { 40, 0, -30 } },
		},
		Neck = {
			{ t = 0, rot = { 5, 25, 0 } },
			{ t = 0.6, rot = { 5, -25, 0 } },
			{ t = 1.2, rot = { 5, 25, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 40, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 150, 0, 20 } },
			{ t = 0.3, rot = { 40, 0, 30 } },
			{ t = 0.6, rot = { 150, 0, 20 } },
			{ t = 0.9, rot = { 40, 0, 30 } },
			{ t = 1.2, rot = { 150, 0, 20 } },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 0.3, rot = { 0, 0, 0 }, pos = { 0, 0.06, 0 } },
			{ t = 0.6, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 0.9, rot = { 0, 0, 0 }, pos = { 0, 0.06, 0 } },
			{ t = 1.2, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
		},
	},
}
