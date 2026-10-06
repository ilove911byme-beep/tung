--!strict
-- Chapter 3: Bombardiro Crocodilo has a piece of the cave map (clue 6) — only for polite guests.
return {
	id = "Bombardiro",
	start = "intro",
	nodes = {
		intro = {
			lines = { "C3_BOMBARDIRO_SKY" },
			choices = {
				{ id = "polite", text = "Could we please see your cave map?", next = "polite" },
				{ id = "rude", text = "Hand over the map, crocodile.", next = "rude" },
			},
		},
		polite = { lines = { "C3_BOMBARDIRO_POLITE" } },
		rude = { lines = { "C3_BOMBARDIRO_RUDE" } },
	},
}
