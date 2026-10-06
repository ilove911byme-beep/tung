--!strict
-- Chapter 3 interrogation: Chimpanzini Bananini. The rude option costs a random item ("Fanum
-- tax"); the chapter script takes it when the choice "rude" was picked.
return {
	id = "Chimpanzini",
	start = "ask",
	nodes = {
		done = {},
		ask = {
			choices = {
				{ id = "saw", text = "What did you see last night?", next = "saw" },
				{ id = "glow", text = "Do you sell anything that glows yellow?", next = "glow" },
				{
					id = "rude",
					text = "Spit it out, monkey!",
					next = "rude",
					effects = { giallinoMood = 2 },
				},
				{ id = "bye", text = "Thanks, Chimpanzini.", next = "done" },
			},
		},
		saw = { lines = { "C3_CHIMP_SAW" }, next = "ask" },
		glow = { lines = { "C3_CHIMP_GLOW" }, next = "ask" },
		rude = { lines = { "C3_CHIMP_FANUM" } },
	},
}
