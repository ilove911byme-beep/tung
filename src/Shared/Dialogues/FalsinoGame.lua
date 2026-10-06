--!strict
-- Chapter 3: before the truth-or-lie game. Whoever noticed the green eye can call it out
-- (flag spottedFalsino, achievement LIAR_SPOTTED).
return {
	id = "FalsinoGame",
	start = "start",
	nodes = {
		done = {},
		start = {
			choices = {
				{ id = "play", text = "Okay, let's play.", next = "done" },
				{
					id = "spotted",
					text = "You're not Giallino.",
					next = "spotted",
					effects = { flag = "spottedFalsino", value = true, badge = "LIAR_SPOTTED" },
				},
			},
		},
		spotted = { lines = { "C3_FALSINO_SPOTTED" } },
	},
}
