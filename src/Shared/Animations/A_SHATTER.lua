--!strict
-- A-SHATTER (1.5): the cube bursts into 40 spinning shards (Shatter effect).
return {
	id = "A-SHATTER",
	length = 1.5,
	loop = false,
	tracks = {
		Root = {
			{ t = 0, rot = { 0, 0, 0 }, pos = { 0, 0, 0 } },
			{ t = 0.1, rot = { 5, 0, 5 }, pos = { 0, 0.2, 0 } },
		},
	},
	effect = { kind = "Shatter", at = 0, params = { pieces = 40 } },
}
