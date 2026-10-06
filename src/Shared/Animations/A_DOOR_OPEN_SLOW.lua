--!strict
-- A-DOOR_OPEN_SLOW (3.0): (Door rig) the door swings open slowly on its hinge.
return {
	id = "A-DOOR_OPEN_SLOW",
	length = 3,
	loop = false,
	tracks = {
		DoorHinge = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { 0, -8, 0 } },
			{ t = 3, rot = { 0, -100, 0 }, ease = "SineOut" },
		},
	},
}
