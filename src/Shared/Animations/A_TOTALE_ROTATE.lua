--!strict
-- A-TOTALE_ROTATE (4.0 loop): the giant cube turns a new face to the camera every second.
return {
	id = "A-TOTALE_ROTATE",
	length = 4,
	loop = true,
	tracks = {
		Root = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.5, rot = { 0, 90, 0 } },
			{ t = 1, rot = { 0, 90, 0 } },
			{ t = 1.5, rot = { 0, 180, 0 } },
			{ t = 2, rot = { 0, 180, 0 } },
			{ t = 2.5, rot = { 0, 270, 0 } },
			{ t = 3, rot = { 0, 270, 0 } },
			{ t = 3.5, rot = { 0, 360, 0 } },
			{ t = 4, rot = { 0, 360, 0 } },
		},
	},
}
