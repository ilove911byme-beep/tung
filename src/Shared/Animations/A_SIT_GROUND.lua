--!strict
-- A-SIT_GROUND (1.0 loop): (helper) sits at the table / on the ground.
return {
	id = "A-SIT_GROUND",
	length = 1,
	loop = true,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 40, 0, 0 } },
		},
		LeftHip = {
			{ t = 0, rot = { 88, 0, -4 } },
		},
		LeftKnee = {
			{ t = 0, rot = { -88, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 30, 0, -4 } },
		},
		RightElbow = {
			{ t = 0, rot = { 40, 0, 0 } },
		},
		RightHip = {
			{ t = 0, rot = { 88, 0, 4 } },
		},
		RightKnee = {
			{ t = 0, rot = { -88, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 30, 0, 4 } },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, -1.1, 0 } },
		},
	},
}
