--!strict
-- A-GASP (0.8): head back, a hand (or trunk) to the face.
return {
	id = "A-GASP",
	length = 0.8,
	loop = false,
	tracks = {
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.25, rot = { 18, 0, 0 } },
			{ t = 0.8, rot = { 12, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.3, rot = { 110, 0, 0 } },
			{ t = 0.8, rot = { 105, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 0, 0, 3 } },
			{ t = 0.3, rot = { 120, 0, -25 } },
			{ t = 0.8, rot = { 115, 0, -25 } },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.25, rot = { 8, 0, 0 } },
			{ t = 0.8, rot = { 4, 0, 0 } },
		},
	},
}
