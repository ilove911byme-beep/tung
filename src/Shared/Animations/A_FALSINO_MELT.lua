--!strict
-- A-FALSINO_MELT (4.0): cracks, the cube squashes to 10 % height, a yellow puddle grows (Melt effect).
return {
	id = "A-FALSINO_MELT",
	length = 4,
	loop = false,
	tracks = {
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 0.3, rot = { 0, 0, 4 }, pos = { 0, 0, 0 } },
			{ t = 0.6, rot = { 0, 0, -4 }, pos = { 0, 0, 0 } },
			{ t = 0.9, rot = { 0, 0, 2 }, pos = { 0, 0, 0 } },
			{ t = 1.2, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
		},
	},
	effect = { kind = "Melt", at = 0, params = { duration = 4 } },
}
