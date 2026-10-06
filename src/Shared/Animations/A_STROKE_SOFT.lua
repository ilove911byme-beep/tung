--!strict
-- A-STROKE_SOFT (helper, 2.4 loop, not in the cutscenes.md library): the right hand rests on
-- something low in front of a kneeling rig and strokes it slowly. Used in CS-05 shot 5
-- ("gently strokes Giallino like a child") on top of A-KNEEL_SOFT.
return {
	id = "A-STROKE_SOFT",
	length = 2.4,
	loop = true,
	tracks = {
		RightElbow = {
			{ t = 0, rot = { 9, -2, -15 } },
			{ t = 1.2, rot = { 16, -2, -15 } },
			{ t = 2.4, rot = { 9, -2, -15 } },
		},
		RightShoulder = {
			{ t = 0, rot = { 107, -43, -40 } },
			{ t = 1.2, rot = { 98, -43, -40 } },
			{ t = 2.4, rot = { 107, -43, -40 } },
		},
		RightWrist = {
			{ t = 0, rot = { 25, 0, 0 } },
			{ t = 1.2, rot = { 15, 0, 0 } },
			{ t = 2.4, rot = { 25, 0, 0 } },
		},
	},
}
