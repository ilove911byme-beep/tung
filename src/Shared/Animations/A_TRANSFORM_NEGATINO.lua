--!strict
-- A-TRANSFORM_NEGATINO (3.0): yellow -> dark blue, stretches 1.5x vertically, the light dims to 0.2 (Transform effect).
return {
	id = "A-TRANSFORM_NEGATINO",
	length = 3,
	loop = false,
	tracks = {
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 1, rot = { 0, 15, 0 }, pos = { 0, 0.3, 0 } },
			{ t = 2, rot = { 0, -10, 0 }, pos = { 0, 0.6, 0 } },
			{ t = 3, rot = { 0, 0, 0 }, pos = { 0, 0.4, 0 } },
		},
	},
	effect = {
		kind = "Transform",
		at = 0,
		params = { color = Color3.fromHex("#1E2A6A"), stretch = 1.5, glow = 0.2, duration = 3 },
	},
}
