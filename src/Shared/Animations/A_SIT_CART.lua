--!strict
-- A-SIT_CART (1 loop): (helper) sits in a minecart: legs forward, hands on the rim.
return {
	id = "A-SIT_CART",
	length = 1,
	loop = true,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 35, 0, 0 } },
		},
		LeftHip = {
			{ t = 0, rot = { 85, 0, -4 } },
		},
		LeftKnee = {
			{ t = 0, rot = { -80, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 25, 0, -8 } },
		},
		Neck = {
			{ t = 0, rot = { -4, 0, 0 } },
		},
		RightElbow = {
			{ t = 0, rot = { 35, 0, 0 } },
		},
		RightHip = {
			{ t = 0, rot = { 85, 0, 4 } },
		},
		RightKnee = {
			{ t = 0, rot = { -80, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 25, 0, 8 } },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, -0.6, 0 } },
		},
	},
}
