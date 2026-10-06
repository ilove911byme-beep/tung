--!strict
-- A-GIALLINO_INSPECT (1.5): close to the target's face (the cutscene moves it there),
-- leans in and tilts to the sides +-15 degrees.
return {
	id = "A-GIALLINO_INSPECT",
	length = 1.5,
	loop = false,
	tracks = {
		Root = {
			{ t = 0, rot = { 0, 0, 0 } },
			{ t = 0.35, rot = { -8, 0, 15 } },
			{ t = 0.85, rot = { -8, 0, -15 } },
			{ t = 1.2, rot = { -5, 0, 6 } },
			{ t = 1.5, rot = { 0, 0, 0 } },
		},
	},
}
