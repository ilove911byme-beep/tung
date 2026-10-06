--!strict
-- A-DOOR_CLOSE (1.2): (helper, Door / Gate rigs) the door swings shut from open.
return {
	id = "A-DOOR_CLOSE",
	length = 1.2,
	loop = false,
	tracks = {
		DoorHinge = {
			{ t = 0, rot = { 0, -100, 0 } },
			{ t = 1, rot = { 0, 0, 0 }, ease = "QuadIn" },
			{ t = 1.1, rot = { 0, 3, 0 } },
			{ t = 1.2, rot = { 0, 0, 0 } },
		},
	},
}
