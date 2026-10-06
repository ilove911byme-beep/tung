--!strict
-- Chapter 3 interrogation: Cappuccino Assassino (3 questions).
return {
	id = "Cappuccino",
	start = "ask",
	nodes = {
		done = {},
		ask = {
			choices = {
				{ id = "who", text = "Who are you, really?", next = "who" },
				{ id = "light", text = "What do you know about the light?", next = "light" },
				{ id = "shoe", text = "Why do you have Ballerina's shoe?", next = "shoe" },
				{ id = "bye", text = "We'll leave you alone.", next = "done" },
			},
		},
		who = { lines = { "C3_CAPPUCCINO_WHO" }, next = "ask" },
		light = { lines = { "C3_CAPPUCCINO_LIGHT" }, next = "ask" },
		shoe = { lines = { "C3_CAPPUCCINO_SHOE" }, next = "ask" },
	},
}
