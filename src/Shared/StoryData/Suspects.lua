--!strict
-- Journal "Suspects" tab (Chapter 3 accusation). Notes are filled in by clues as they appear.
export type Suspect = { id: string, name: string, note: string, clues: { string } }

local Suspects: { Suspect } = {
	{
		id = "TungTung",
		name = "Tung Tung Tung Sahur",
		note = "Knocks on doors every night. Everybody blames him. Giallino says it saw him.",
		clues = { "C4", "F1", "F2" },
	},
	{
		id = "Cappuccino",
		name = "Cappuccino Assassino",
		note = "Quiet, hides in the shadows. Carries a pointe shoe. Talked to us in secret.",
		clues = { "C1" },
	},
	{
		id = "Bombardiro",
		name = "Bombardiro Crocodilo",
		note = "Loud. Built the tunnel with Lirili. Saw a floating light from the sky.",
		clues = { "C6" },
	},
	{
		id = "Giallino",
		name = "Giallino?",
		note = '"Giallino never lies." Round footprints. Melted glass. A yellow shard.',
		clues = { "C1", "C3", "C7" },
	},
}

return Suspects
