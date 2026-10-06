--!strict
-- A-WALK (1.0 loop): blocky step, arms swing like pendulums opposite to the legs.
return {
	id = "A-WALK",
	length = 1.0,
	loop = true,
	tracks = {
		Root = {
			{ t = 0, pos = { 0, 0, 0 } },
			{ t = 0.25, pos = { 0, 0.08, 0 } },
			{ t = 0.5, pos = { 0, 0, 0 } },
			{ t = 0.75, pos = { 0, 0.08, 0 } },
			{ t = 1.0, pos = { 0, 0, 0 } },
		},
		RightHip = {
			{ t = 0, rot = { 28, 0, 0 } },
			{ t = 0.5, rot = { -28, 0, 0 } },
			{ t = 1.0, rot = { 28, 0, 0 } },
		},
		RightKnee = {
			{ t = 0, rot = { -5, 0, 0 } },
			{ t = 0.5, rot = { -25, 0, 0 } },
			{ t = 0.75, rot = { -45, 0, 0 } },
			{ t = 1.0, rot = { -5, 0, 0 } },
		},
		LeftHip = {
			{ t = 0, rot = { -28, 0, 0 } },
			{ t = 0.5, rot = { 28, 0, 0 } },
			{ t = 1.0, rot = { -28, 0, 0 } },
		},
		LeftKnee = {
			{ t = 0, rot = { -25, 0, 0 } },
			{ t = 0.25, rot = { -45, 0, 0 } },
			{ t = 0.5, rot = { -5, 0, 0 } },
			{ t = 1.0, rot = { -25, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { -24, 0, 3 } },
			{ t = 0.5, rot = { 24, 0, 3 } },
			{ t = 1.0, rot = { -24, 0, 3 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 24, 0, -3 } },
			{ t = 0.5, rot = { -24, 0, -3 } },
			{ t = 1.0, rot = { 24, 0, -3 } },
		},
		RightElbow = { { t = 0, rot = { 12, 0, 0 } } },
		LeftElbow = { { t = 0, rot = { 12, 0, 0 } } },
	},
}
