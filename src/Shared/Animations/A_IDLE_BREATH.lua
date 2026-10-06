--!strict
-- A-IDLE_BREATH (3.0 loop): torso moves up and down 0.1 stud, the head tilts a little.
return {
	id = "A-IDLE_BREATH",
	length = 3.0,
	loop = true,
	tracks = {
		RootJoint = {
			{ t = 0, pos = { 0, 0, 0 } },
			{ t = 1.5, pos = { 0, 0.1, 0 } },
			{ t = 3.0, pos = { 0, 0, 0 } },
		},
		Neck = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 1.5, rot = { 4, 0, 2 } },
			{ t = 3.0, rot = { 0, 0, 0 } },
		},
	},
}
