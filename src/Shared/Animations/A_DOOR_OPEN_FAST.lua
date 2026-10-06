--!strict
-- A-DOOR_OPEN_FAST (0.6): (helper, Door rig) the door is pulled open fast.
return {
	id = "A-DOOR_OPEN_FAST",
	length = 0.6,
	loop = false,
	tracks = {
		DoorHinge = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.6, rot = { 0, -100, 0 }, ease = "QuadOut" },
		},
	},
}
