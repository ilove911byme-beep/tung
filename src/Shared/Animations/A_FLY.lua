--!strict
-- A-FLY (1.6 loop): (helper) flying: body horizontal, wings out, a slow bank left and right.
return {
	id = "A-FLY",
	length = 1.6,
	loop = true,
	tracks = {
		LeftHip = {
			{ t = 0, rot = { -10, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 0, 0, -85 } },
		},
		Neck = {
			{ t = 0, rot = { 35, 0, 0 } },
		},
		RightHip = {
			{ t = 0, rot = { -10, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 0, 0, 85 } },
		},
		Root = {
			{ t = 0, rot = { -75, 0, -8 } },
			{ t = 0.8, rot = { -75, 0, 8 } },
			{ t = 1.6, rot = { -75, 0, -8 } },
		},
	},
}
