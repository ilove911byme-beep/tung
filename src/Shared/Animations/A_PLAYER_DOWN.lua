--!strict
-- A-PLAYER_DOWN (1.0): falls to the knees, then onto the belly.
-- Player characters are R15: the Root track drives the real Root motor (HumanoidRootPart -> LowerTorso).
return {
	id = "A-PLAYER_DOWN",
	length = 1,
	loop = false,
	tracks = {
		LeftKnee = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { -90, 0, 0 }, ease = "QuadIn" },
			{ t = 1, rot = { -10, 0, 0 }, ease = "QuadOut" },
		},
		LeftShoulder = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { 25, 0, -10 }, ease = "QuadIn" },
			{ t = 1, rot = { 155, 0, -12 }, ease = "QuadOut" },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { -10, 0, 0 }, ease = "QuadIn" },
			{ t = 1, rot = { 40, 0, 0 }, ease = "QuadOut" },
		},
		RightKnee = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { -90, 0, 0 }, ease = "QuadIn" },
			{ t = 1, rot = { -10, 0, 0 }, ease = "QuadOut" },
		},
		RightShoulder = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { 25, 0, 10 }, ease = "QuadIn" },
			{ t = 1, rot = { 155, 0, 12 }, ease = "QuadOut" },
		},
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 0.4, rot = { -10, 0, 0 }, pos = { 0, -1.1, 0 }, ease = "QuadIn" },
			{ t = 1, rot = { -85, 0, 0 }, pos = { 0, -2.3, 0.4 }, ease = "QuadOut" },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.4, rot = { -12, 0, 0 }, ease = "QuadIn" },
			{ t = 1, rot = { 0, 0, 0 }, ease = "QuadOut" },
		},
	},
}
