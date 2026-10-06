--!strict
-- Chapter 3: Brr Brr Patapim's riddle (clue 7, flag riddleCorrect).
return {
	id = "PatapimRiddle",
	start = "riddle",
	nodes = {
		riddle = {
			lines = { "C3_PATAPIM_RIDDLE" },
			choices = {
				{ id = "giallino", text = "Giallino. The thing that glows.", next = "right" },
				{ id = "tung", text = "Tung Tung Tung Sahur.", next = "wrong" },
				{ id = "moon", text = "The moon.", next = "wrong" },
			},
		},
		right = {
			lines = { "C3_PATAPIM_RIGHT" },
			effects = { flag = "riddleCorrect", value = true },
		},
		wrong = { lines = { "C3_PATAPIM_WRONG" } },
	},
}
