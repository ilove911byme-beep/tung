--!strict
-- A-EMOTE_AURA (3.0 loop): (lobby emote) aura farming: chin up, one hand at the chin, the other on the hip, a slow proud sway.
return {
	id = "A-EMOTE_AURA",
	length = 3,
	loop = true,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 70, 0, 0 }, ease = "SineInOut" },
			{ t = 3, rot = { 70, 0, 0 }, ease = "SineInOut" },
		},
		LeftShoulder = {
			{ t = 0, rot = { -10, 0, -35 }, ease = "SineInOut" },
			{ t = 3, rot = { -10, 0, -35 }, ease = "SineInOut" },
		},
		Neck = {
			{ t = 0, rot = { 12, 10, 0 }, ease = "SineInOut" },
			{ t = 1.5, rot = { 14, -6, 0 }, ease = "SineInOut" },
			{ t = 3, rot = { 12, 10, 0 }, ease = "SineInOut" },
		},
		RightElbow = {
			{ t = 0, rot = { 120, 0, 0 }, ease = "SineInOut" },
			{ t = 3, rot = { 120, 0, 0 }, ease = "SineInOut" },
		},
		RightShoulder = {
			{ t = 0, rot = { 70, 0, 25 }, ease = "SineInOut" },
			{ t = 3, rot = { 70, 0, 25 }, ease = "SineInOut" },
		},
		RootJoint = {
			{ t = 0, rot = { -3, 6, 0 }, ease = "SineInOut" },
			{ t = 1.5, rot = { -3, -6, 0 }, ease = "SineInOut" },
			{ t = 3, rot = { -3, 6, 0 }, ease = "SineInOut" },
		},
	},
}
