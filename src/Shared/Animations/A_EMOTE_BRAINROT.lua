--!strict
-- A-EMOTE_BRAINROT (1.2 loop): (lobby emote) brainrot dance: hips sway, arms wave overhead in turn, knees bounce.
return {
	id = "A-EMOTE_BRAINROT",
	length = 1.2,
	loop = true,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 80, 0, 0 }, ease = "SineInOut" },
			{ t = 0.6, rot = { 20, 0, 0 }, ease = "SineInOut" },
			{ t = 1.2, rot = { 80, 0, 0 }, ease = "SineInOut" },
		},
		LeftKnee = {
			{ t = 0, rot = { -25, 0, 0 }, ease = "SineInOut" },
			{ t = 0.3, rot = { 0, 0, 0 }, ease = "SineInOut" },
			{ t = 0.6, rot = { -25, 0, 0 }, ease = "SineInOut" },
			{ t = 0.9, rot = { 0, 0, 0 }, ease = "SineInOut" },
			{ t = 1.2, rot = { -25, 0, 0 }, ease = "SineInOut" },
		},
		LeftShoulder = {
			{ t = 0, rot = { 40, 0, -30 }, ease = "SineInOut" },
			{ t = 0.6, rot = { 150, 0, -15 }, ease = "SineInOut" },
			{ t = 1.2, rot = { 40, 0, -30 }, ease = "SineInOut" },
		},
		Neck = {
			{ t = 0, rot = { 0, -10, -8 }, ease = "SineInOut" },
			{ t = 0.6, rot = { 0, 10, 8 }, ease = "SineInOut" },
			{ t = 1.2, rot = { 0, -10, -8 }, ease = "SineInOut" },
		},
		RightElbow = {
			{ t = 0, rot = { 20, 0, 0 }, ease = "SineInOut" },
			{ t = 0.6, rot = { 80, 0, 0 }, ease = "SineInOut" },
			{ t = 1.2, rot = { 20, 0, 0 }, ease = "SineInOut" },
		},
		RightKnee = {
			{ t = 0, rot = { 0, 0, 0 }, ease = "SineInOut" },
			{ t = 0.3, rot = { -25, 0, 0 }, ease = "SineInOut" },
			{ t = 0.6, rot = { 0, 0, 0 }, ease = "SineInOut" },
			{ t = 0.9, rot = { -25, 0, 0 }, ease = "SineInOut" },
			{ t = 1.2, rot = { 0, 0, 0 }, ease = "SineInOut" },
		},
		RightShoulder = {
			{ t = 0, rot = { 150, 0, 15 }, ease = "SineInOut" },
			{ t = 0.6, rot = { 40, 0, 30 }, ease = "SineInOut" },
			{ t = 1.2, rot = { 150, 0, 15 }, ease = "SineInOut" },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 10, 10 }, ease = "SineInOut" },
			{ t = 0.6, rot = { 0, -10, -10 }, ease = "SineInOut" },
			{ t = 1.2, rot = { 0, 10, 10 }, ease = "SineInOut" },
		},
	},
}
