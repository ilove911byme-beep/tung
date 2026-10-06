--!strict
-- Idle chatter of the Giallino companion (original lines), picked by mood tier
-- (Happy 100-70, Off 69-40, Broken 39-10, Hostile <10). Shown as small subtitles with blips;
-- these never use TTS so the voice budget stays for the story. Never shown in cutscenes.
local GiallinoLines: { [string]: { string } } = {
	Happy = {
		"I counted the clouds. There are many. Giallino likes many.",
		"You walk so fast! I like when you stay close.",
		"Giallino never lies! Ask me anything!",
		"Do you like this village? You can stay. Everybody stays.",
		"Look, a flower! I will remember it for you.",
	},
	Off = {
		"Why are you looking at that? Look at me instead.",
		"Some clues are wrong. I can help you pick the right ones.",
		"You are asking a lot of questions. Questions are… fine.",
		"Tung Tung is bad. Remember that. Remember what I said.",
		"I am not upset. Giallino is never upset.",
	},
	Broken = {
		"Every light goes out. Yours will too.",
		"You will leave. They always leave. Why do you try?",
		"It is so dark in here. Do you hear it? It is empty.",
		"Say yes. Just once. It is easy. It is so easy.",
	},
	Hostile = {
		"NO MORE NO.",
		"I SEE YOU.",
		"STAY. STAY. STAY.",
		"NOBODY LEAVES.",
	},
}

return GiallinoLines
