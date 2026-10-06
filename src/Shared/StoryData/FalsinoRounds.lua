--!strict
-- Falsino's truth-or-lie rounds (screenplay.md 3-4): three statements, one lie. The lines are
-- VoiceLines F_R<round>_<n>; `lie` is the index of the false statement. Round 1 is the example
-- from the screenplay (the hint is in clue 4, Ballerina's diary).
export type Round = { lines: { string }, texts: { string }, lie: number }

local function round(r: number, lie: number, texts: { string }): Round
	return {
		lines = { "F_R" .. r .. "_1", "F_R" .. r .. "_2", "F_R" .. r .. "_3" },
		texts = texts,
		lie = lie,
	}
end

return {
	round(1, 1, {
		"Tung Tung knocks to hurt you.",
		"Lirili built the clock tower.",
		"Ballerina left by herself.",
	}),
	round(2, 3, {
		"Lirili found a little light in the mine.",
		"The bell rang by itself.",
		"Giallino was home all night.",
	}),
	round(3, 1, {
		"Ballerina's door broke from the outside.",
		"Cappuccino is Ballerina's brother.",
		"The footprints were too round for feet.",
	}),
	round(
		4,
		3,
		{ "Patapim speaks in riddles.", "Six and seven are just numbers.", "Giallino never lies." }
	),
	round(5, 3, {
		"Bombardiro saw a floating light.",
		"Tung Tung says names every night.",
		"Lirili left the valley on a train.",
	}),
	round(6, 3, {
		"Frigo and Udin vanished at night.",
		"Lanterns keep the dark away.",
		"Nobody ever said no to Giallino.",
	}),
} :: { Round }
