--!strict
-- Chapter 3 interrogation: Tralalero Tralala (3 questions).
return {
	id = "Tralalero",
	start = "ask",
	nodes = {
		done = {},
		ask = {
			choices = {
				{ id = "where", text = "Where were you last night?", next = "where" },
				{ id = "saw", text = "Did you see anything?", next = "saw" },
				{ id = "who", text = "Who do you think did it?", next = "who" },
				{ id = "bye", text = "Thanks, Tralalero.", next = "done" },
			},
		},
		where = { lines = { "C3_TRALALERO_WHERE" }, next = "ask" },
		saw = { lines = { "C3_TRALALERO_SAW" }, next = "ask" },
		who = { lines = { "C3_TRALALERO_WHO" }, next = "ask" },
	},
}
