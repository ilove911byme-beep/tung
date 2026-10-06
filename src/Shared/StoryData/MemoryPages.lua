--!strict
-- The 12 Memory Pages (lore.md section 6): exact in-game texts, the Narrator reads each one.
-- location = where the MapBuilder places the glowing page (see map.md section 7).
export type Page = { id: string, chapter: number, location: string, text: string }

local MemoryPages: { Page } = {
	{
		id = "M1",
		chapter = 0,
		location = "Last Stop station, under the bench (lobby)",
		text = "Every meme that falls here was once loved. Remember their names.",
	},
	{
		id = "M2",
		chapter = 1,
		location = "Roots at the village entrance",
		text = "Patapim was the first. The forest grew from his loneliness.",
	},
	{
		id = "M3",
		chapter = 1,
		location = "The long sahur table",
		text = "Sahur: we eat before dawn and call every name out loud. Nobody fades while someone says their name.",
	},
	{
		id = "M4",
		chapter = 2,
		location = "Tavern, behind the fireplace",
		text = "Day 1: Lirili found a little yellow light in the mine. It says hello to everyone.",
	},
	{
		id = "M5",
		chapter = 3,
		location = "Ballerina's house, the mirror",
		text = '"It asked me to dance forever. I said not forever. It looked at me like I had broken it." — Ballerina',
	},
	{
		id = "M6",
		chapter = 3,
		location = "Tung Tung's hut on the hill",
		text = "A list of names, carved in wood. The newest one is still fresh: Ballerina Cappuccina.",
	},
	{
		id = "M7",
		chapter = 3,
		location = "Clock tower roof",
		text = '"I taught it every word. I keep forgetting to teach it the hardest one." — Lirili',
	},
	{
		id = "M8",
		chapter = 4,
		location = "Patapim's hollow",
		text = "The yellow light is not from our world. It fell from a game where everyone left.",
	},
	{
		id = "M9",
		chapter = 5,
		location = "Mine entrance",
		text = 'Old screen text, glitched: "WILL YOU COME BACK TOMORROW? [YES] [NO]" — the NO button is scratched out.',
	},
	{
		id = "M10",
		chapter = 5,
		location = "Lirili's lab",
		text = '"If I stop time around myself, it cannot take me. But I cannot hold it forever." — Lirili',
	},
	{
		id = "M11",
		chapter = 5,
		location = "Crudelino's cave, after the fight",
		text = '"It does not want to hurt us. It wants nobody to ever leave. That is worse." — Bombardiro',
	},
	{
		id = "M12",
		chapter = 6,
		location = "Top of the clock tower",
		text = '"Dear little light. No is not goodbye. — L."',
	},
}

return MemoryPages
