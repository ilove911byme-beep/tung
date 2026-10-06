--!strict
-- All 30 badges from screenplay.md ("Ачивки"). badgeId = 0 until the badge is created in the
-- Creator Hub (Roblox allows 5 free badges per day per experience). Secret ones are hidden.
local Types = require(script.Parent.Types)

local function a(
	id: string,
	name: string,
	rarity: Types.Rarity,
	description: string
): Types.Achievement
	return {
		id = id,
		name = name,
		rarity = rarity,
		description = description,
		badgeId = 0,
		hidden = rarity == "Secret",
	}
end

local list: { Types.Achievement } = {
	a("CHAPTER_1", "Last Stop", "Common", "Finish Chapter 1."),
	a("CHAPTER_2", "Knock Knock", "Common", "Finish Chapter 2."),
	a("CHAPTER_3", "Detective", "Common", "Finish Chapter 3."),
	a("CHAPTER_4", "Light the Square", "Common", "Finish Chapter 4."),
	a("CHAPTER_5", "Into the Mine", "Common", "Finish Chapter 5."),
	a("FIRST_NO", "Rebel", "Common", 'Say "No" to Giallino in Chapter 1.'),
	a("OPEN_THE_DOOR", "Who's There?", "Common", "Open the door in Chapter 2."),
	a("SIX_SEVEN", "SIX… SEVEN!", "Common", "Find clues 6 and 7."),
	a("BEAT_FALSINO", "Lie Detector", "Rare", "Defeat Falsino."),
	a("BEAT_NEGATINO", "Firestarter", "Rare", "Defeat Negatino."),
	a("BEAT_CRUDELINO", "Bombs Away", "Rare", "Defeat Crudelino."),
	a("HERO_REVIVE", "Not Today", "Rare", "Revive 5 teammates in one game."),
	a("ROOFTOP_RUNNER", "Rooftop Runner", "Rare", "Finish the rooftop parkour without falling."),
	a("CLEAN_JUMPS", "Light Feet", "Rare", "Finish the parkour tutorial without falling."),
	a("PERFECT_RIDE", "Rail Master", "Epic", "Pass every minecart QTE without a mistake."),
	a("FLOOR_IS_LAVA", "The Floor Is Lava", "Epic", "Cross the lava parkour without falling."),
	a("NEVER_DARK", "Eternal Flame", "Epic", "Keep every brazier burning in the Negatino fight."),
	a("UNTOUCHABLE", "Untouchable", "Epic", "Nobody gets hit by Crudelino's dash."),
	a("LIAR_SPOTTED", "I See You", "Epic", "Recognise Falsino by its eyes."),
	a("ENDING_DAWN", "Dawn", "Legendary", "Reach the good ending."),
	a(
		"NO_DEATHS",
		"Immortal",
		"Legendary",
		"Finish the whole story without dying (Downed is fine)."
	),
	a("SPEEDRUN", "Before Sunrise", "Legendary", "Finish the story in under 35 minutes."),
	a("ENDING_ENDLESS_NIGHT", "Welcome Back", "Secret", "Reach the bad ending."),
	a("ENDING_SAHUR", "Good Morning", "Secret", "Reach the secret ending."),
	a("SECRET_LANTERN", "Hidden Light", "Secret", "Find the chest with the Glowing Lantern."),
	a(
		"NO_ONE_JAILED",
		"Innocent Until Proven",
		"Secret",
		"Reach the finale without locking anyone up."
	),
	a(
		"GIALLINO_STARE",
		"Staring Contest",
		"Secret",
		"Stare at Giallino in the menu for 60 seconds without moving the mouse."
	),
	a("TUNG_FRIEND", "Night Watch", "Secret", "Talk to Tung Tung three times."),
	a("ARCHIVIST", "Archivist", "Epic", "Collect all 12 Memory Pages."),
	a(
		"SAY_THEIR_NAMES",
		"Say Their Names",
		"Rare",
		"Read Tung Tung's list of names in the Journal."
	),
}

local Achievements = {}
Achievements.List = list
Achievements.ById = {} :: { [string]: Types.Achievement }
for _, item in list do
	Achievements.ById[item.id] = item
end

return Achievements
