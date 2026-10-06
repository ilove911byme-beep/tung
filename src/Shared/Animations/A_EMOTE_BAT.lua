--!strict
-- A-EMOTE_BAT (1.6 loop): (lobby emote) Tung Tung bat swing: wind up over the shoulder, a big swing, follow-through, pause.
return {
	id = "A-EMOTE_BAT",
	length = 1.6,
	loop = true,
	tracks = {
		LeftElbow = {
			{ t = 0, rot = { 30, 0, 0 }, ease = "SineInOut" },
			{ t = 0.45, rot = { 90, 0, 0 }, ease = "SineInOut" },
			{ t = 0.65, rot = { 10, 0, 0 }, ease = "SineInOut" },
			{ t = 1.6, rot = { 30, 0, 0 }, ease = "SineInOut" },
		},
		LeftShoulder = {
			{ t = 0, rot = { 20, 0, -10 }, ease = "SineInOut" },
			{ t = 0.45, rot = { 140, 0, 10 }, ease = "QuadOut" },
			{ t = 0.65, rot = { 80, 0, 20 }, ease = "BackOut" },
			{ t = 1, rot = { 70, 0, 25 }, ease = "SineInOut" },
			{ t = 1.6, rot = { 20, 0, -10 }, ease = "SineInOut" },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 }, ease = "SineInOut" },
			{ t = 0.45, rot = { 0, -25, 0 }, ease = "SineInOut" },
			{ t = 0.65, rot = { -5, 30, 0 }, ease = "SineInOut" },
			{ t = 1.6, rot = { 0, 0, 0 }, ease = "SineInOut" },
		},
		RightElbow = {
			{ t = 0, rot = { 30, 0, 0 }, ease = "SineInOut" },
			{ t = 0.45, rot = { 90, 0, 0 }, ease = "SineInOut" },
			{ t = 0.65, rot = { 10, 0, 0 }, ease = "SineInOut" },
			{ t = 1.6, rot = { 30, 0, 0 }, ease = "SineInOut" },
		},
		RightShoulder = {
			{ t = 0, rot = { 20, 0, 10 }, ease = "SineInOut" },
			{ t = 0.45, rot = { 150, 0, 40 }, ease = "QuadOut" },
			{ t = 0.65, rot = { 80, 0, -30 }, ease = "BackOut" },
			{ t = 1, rot = { 70, 0, -35 }, ease = "SineInOut" },
			{ t = 1.6, rot = { 20, 0, 10 }, ease = "SineInOut" },
		},
		RootJoint = {
			{ t = 0, rot = { 0, 0, 0 }, ease = "SineInOut" },
			{ t = 0.45, rot = { 0, 35, 0 }, ease = "QuadOut" },
			{ t = 0.65, rot = { -8, -40, 0 }, ease = "BackOut" },
			{ t = 1, rot = { -5, -35, 0 }, ease = "SineInOut" },
			{ t = 1.6, rot = { 0, 0, 0 }, ease = "SineInOut" },
		},
	},
}
