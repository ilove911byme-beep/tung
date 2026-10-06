--!strict
-- A-LOOK_UP (1.0): (helper) looks up at something above (Giallino over the crowd).
return {
	id = "A-LOOK_UP",
	length = 1,
	loop = false,
	tracks = {
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { 28, 0, 0 } },
			{ t = 1, rot = { 28, 0, 0 } },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { 5, 0, 0 } },
			{ t = 1, rot = { 5, 0, 0 } },
		},
	},
}
