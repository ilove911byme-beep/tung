--!strict
-- A-PLAYER_CRAWL (1.6 loop): crawls on the belly, arms reaching forward in turn.
return {
	id = "A-PLAYER_CRAWL",
	length = 1.6,
	loop = true,
	tracks = {
		LeftHip = {
			{ t = 0, rot = { 8, 0, 0 } },
			{ t = 0.8, rot = { -8, 0, 0 } },
			{ t = 1.6, rot = { 8, 0, 0 } },
		},
		LeftKnee = {
			{ t = 0, rot = { -5, 0, 0 } },
			{ t = 0.8, rot = { -35, 0, 0 } },
			{ t = 1.6, rot = { -5, 0, 0 } },
		},
		LeftShoulder = {
			{ t = 0, rot = { 125, 0, -12 } },
			{ t = 0.8, rot = { 175, 0, -12 } },
			{ t = 1.6, rot = { 125, 0, -12 } },
		},
		Neck = {
			{ t = 0, rot = { 40, 0, 0 } },
			{ t = 0.8, rot = { 40, 0, 0 } },
			{ t = 1.6, rot = { 40, 0, 0 } },
		},
		RightHip = {
			{ t = 0, rot = { -8, 0, 0 } },
			{ t = 0.8, rot = { 8, 0, 0 } },
			{ t = 1.6, rot = { -8, 0, 0 } },
		},
		RightKnee = {
			{ t = 0, rot = { -35, 0, 0 } },
			{ t = 0.8, rot = { -5, 0, 0 } },
			{ t = 1.6, rot = { -35, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 175, 0, 12 } },
			{ t = 0.8, rot = { 125, 0, 12 } },
			{ t = 1.6, rot = { 175, 0, 12 } },
		},
		Root = {
			{ t = 0, rot = { -85, 0, 0 }, pos = { 0, -2.3, 0.4 } },
			{ t = 0.8, rot = { -85, 0, 0 }, pos = { 0, -2.3, 0.4 } },
			{ t = 1.6, rot = { -85, 0, 0 }, pos = { 0, -2.3, 0.4 } },
		},
	},
}
