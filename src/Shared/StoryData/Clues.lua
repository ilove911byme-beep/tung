--!strict
-- Chapter 3 clues (screenplay.md 3-1): 7 real + 2 fake planted by Falsino. Fake clues show "?"
-- in the Journal until the clue named in `debunkedBy` is found.
export type Clue = {
	id: string,
	number: string, -- shown in the Journal
	title: string,
	text: string,
	fake: boolean,
	debunkedBy: string?,
}

local Clues: { Clue } = {
	{
		id = "C1",
		number = "1",
		title = "Round footprints",
		text = "Footprints by Ballerina's house. Too round for feet. Something that hovers, not walks.",
		fake = false,
	},
	{
		id = "C2",
		number = "2",
		title = "Coordinate log",
		text = "Numbers scratched on a sign by the well: the same spot, every night, at the same hour.",
		fake = false,
	},
	{
		id = "C3",
		number = "3",
		title = "Melted lantern glass",
		text = "Glass on the bakery roof, melted from the inside. A lantern does not burn that hot. A yellow light does.",
		fake = false,
	},
	{
		id = "C4",
		number = "4",
		title = "Ballerina's diary page",
		text = '"It asked me again to dance forever. I said not forever. It went quiet. Tung Tung knocks to wake us, not to hurt us."',
		fake = false,
	},
	{
		id = "C5",
		number = "5",
		title = "Lirili's stopped clock",
		text = "Lirili's pocket clock in the music box. Stopped three days ago, at the hour the bell started ringing by itself.",
		fake = false,
	},
	{
		id = "C6",
		number = "6",
		title = "Piece of the cave map",
		text = "Bombardiro's map piece: a lab marked deep in the mine, with a clock drawn next to it.",
		fake = false,
	},
	{
		id = "C7",
		number = "7",
		title = "Yellow shard",
		text = "A shard of yellow light from Patapim's hollow. It is warm and it hums like a happy little voice.",
		fake = false,
	},
	{
		id = "F1",
		number = "?",
		title = "Tung Tung's bat (with something on it)",
		text = "A bat by the mill, smeared with something dark. It smells like paint. Fresh paint.",
		fake = true,
		debunkedBy = "C4",
	},
	{
		id = "F2",
		number = "?",
		title = "Note: Tung will hurt everyone",
		text = 'A note on the board: "Tung will hurt everyone." The letters glow faintly yellow.',
		fake = true,
		debunkedBy = "C3",
	},
}

return Clues
