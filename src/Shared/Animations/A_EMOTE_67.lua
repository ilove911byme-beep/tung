--!strict
-- A-EMOTE_67 (0.6 loop): (lobby emote) "6 7": both forearms up, palms up, the hands bounce up and down in turn.
return {
	id = "A-EMOTE_67",
	length = 0.6,
	loop = true,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 60, 0, 0 }, ease = "SineInOut" },
			{ t = 0.3, rot = { 75, 0, 0 }, ease = "SineInOut" },
			{ t = 0.6, rot = { 60, 0, 0 }, ease = "SineInOut" },
		},
		LeftShoulder = {
			{ t = 0, rot = { 55, 0, -4 }, ease = "SineInOut" },
			{ t = 0.3, rot = { 35, 0, -4 }, ease = "SineInOut" },
			{ t = 0.6, rot = { 55, 0, -4 }, ease = "SineInOut" },
		},
		Neck = {
			{ t = 0, rot = { -4, 6, 0 }, ease = "SineInOut" },
			{ t = 0.3, rot = { -4, -6, 0 }, ease = "SineInOut" },
			{ t = 0.6, rot = { -4, 6, 0 }, ease = "SineInOut" },
		},
		RightElbow = {
			{ t = 0, rot = { 75, 0, 0 }, ease = "SineInOut" },
			{ t = 0.3, rot = { 60, 0, 0 }, ease = "SineInOut" },
			{ t = 0.6, rot = { 75, 0, 0 }, ease = "SineInOut" },
		},
		RightShoulder = {
			{ t = 0, rot = { 35, 0, 4 }, ease = "SineInOut" },
			{ t = 0.3, rot = { 55, 0, 4 }, ease = "SineInOut" },
			{ t = 0.6, rot = { 35, 0, 4 }, ease = "SineInOut" },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 2 }, ease = "SineInOut" },
			{ t = 0.3, rot = { 0, 0, -2 }, ease = "SineInOut" },
			{ t = 0.6, rot = { 0, 0, 2 }, ease = "SineInOut" },
		},
	},
}
