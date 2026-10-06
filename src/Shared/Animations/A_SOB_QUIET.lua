--!strict
-- A-SOB_QUIET (2.0 loop): shoulders shake three times (up 0.05 stud), head down. Layer it over a pose.
return {
	id = "A-SOB_QUIET",
	length = 2,
	loop = true,
	tracks = {
		LeftShoulder = {
			{ t = 0, rot = { 60, 0, 20 }, pos = { 0, 0, 0 } },
			{ t = 0.2, rot = { 60, 0, 20 }, pos = { 0, 0.05, 0 } },
			{ t = 0.4, rot = { 60, 0, 20 }, pos = { 0, 0, 0 } },
			{ t = 0.8, rot = { 60, 0, 20 }, pos = { 0, 0.05, 0 } },
			{ t = 1, rot = { 60, 0, 20 }, pos = { 0, 0, 0 } },
			{ t = 1.4, rot = { 60, 0, 20 }, pos = { 0, 0.05, 0 } },
			{ t = 1.6, rot = { 60, 0, 20 }, pos = { 0, 0, 0 } },
			{ t = 2, rot = { 60, 0, 20 }, pos = { 0, 0, 0 } },
		},
		Neck = {
			{ t = 0, rot = { -35, 0, 0 } },
			{ t = 0.2, rot = { -38, 0, 0 } },
			{ t = 0.4, rot = { -35, 0, 0 } },
			{ t = 0.8, rot = { -38, 0, 0 } },
			{ t = 1, rot = { -35, 0, 0 } },
			{ t = 1.4, rot = { -38, 0, 0 } },
			{ t = 1.6, rot = { -35, 0, 0 } },
			{ t = 2, rot = { -35, 0, 0 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 60, 0, -20 }, pos = { 0, 0, 0 } },
			{ t = 0.2, rot = { 60, 0, -20 }, pos = { 0, 0.05, 0 } },
			{ t = 0.4, rot = { 60, 0, -20 }, pos = { 0, 0, 0 } },
			{ t = 0.8, rot = { 60, 0, -20 }, pos = { 0, 0.05, 0 } },
			{ t = 1, rot = { 60, 0, -20 }, pos = { 0, 0, 0 } },
			{ t = 1.4, rot = { 60, 0, -20 }, pos = { 0, 0.05, 0 } },
			{ t = 1.6, rot = { 60, 0, -20 }, pos = { 0, 0, 0 } },
			{ t = 2, rot = { 60, 0, -20 }, pos = { 0, 0, 0 } },
		},
	},
}
