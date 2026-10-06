--!strict
-- A-LEVER_THROW (1.0): (Lever rig) the handle is thrown forward.
return {
	id = "A-LEVER_THROW",
	length = 1,
	loop = false,
	tracks = {
		LeverJoint = {
			{ t = 0, rot = { -35, 0, 0 } },
			{ t = 0.4, rot = { 40, 0, 0 }, ease = "QuadIn" },
			{ t = 0.5, rot = { 35, 0, 0 } },
			{ t = 1, rot = { 35, 0, 0 } },
		},
	},
}
