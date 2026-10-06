--!strict
-- Every player-facing UI string lives here so the game can be translated in one place.
-- Story dialogue is NOT here: it lives in the cutscene / dialogue / voice line data modules.
-- Templates use string.format placeholders (%d, %s). "[Name]" is filled per client by the
-- dialogue/subtitle code, never on the server.

local Strings = {}

Strings.GameTitle = "NIGHT IN BRAINROT VALLEY"
Strings.Tagline = "No doesn't mean goodbye."

Strings.Menu = {
	Play = "PLAY",
	Chapters = "CHAPTERS",
	Endings = "ENDINGS",
	Achievements = "ACHIEVEMENTS",
	Settings = "SETTINGS",
	Credits = "CREDITS",
	Back = "BACK",
	Locked = "LOCKED",
	Unknown = "???",
}

Strings.Chapters = {
	[1] = "Arrival",
	[2] = "First Night",
	[3] = "Investigation",
	[4] = "Second Night",
	[5] = "The Abandoned Mine",
	[6] = "The Clock Tower",
}

Strings.ChapterLabel = "Chapter %d"

Strings.Endings = {
	Dawn = "Dawn",
	EndlessNight = "Endless Night",
	Sahur = "Sahur",
}

Strings.Settings = {
	MusicVolume = "Music",
	AmbienceVolume = "Ambience",
	SfxVolume = "SFX",
	VoiceVolume = "Voice",
	Subtitles = "Subtitles",
	Voices = "Voices",
	CameraShake = "Camera shake",
	Graphics = "Graphics",
	GraphicsLow = "Low",
	GraphicsHigh = "High",
	On = "ON",
	Off = "OFF",
}

Strings.Credits = {
	Title = "CREDITS",
	-- Placeholder lines until the real credits are written.
	Lines = {
		"Game design and story: TODO",
		"Music and sound: TODO",
		"Textures: TODO",
		"Thanks for playing!",
	},
}

Strings.Rarity = {
	Common = "Common",
	Rare = "Rare",
	Epic = "Epic",
	Legendary = "Legendary",
	Secret = "Secret",
}

Strings.Achievements = {
	ToastTitle = "Achievement unlocked",
	PageTitle = "ACHIEVEMENTS",
	Hidden = "???",
	HiddenDescription = "A secret achievement.",
}

Strings.Loading = {
	Connecting = "Connecting to Brainrot Valley…",
	Hello = "Hi, [Name]. :)",
	TipsTitle = "TIP",
	Tips = {
		"Lanterns keep the dark away.",
		"Not everything that smiles is your friend.",
		"Say their names. Nobody fades while someone says their name.",
		"Hiding takes steady breath. Do not let go too early.",
	},
}

Strings.Queue = {
	Cart = "Minecart %d",
	Status = "%d/%d · Starting in %d",
	Waiting = "%d/%d · Waiting for riders",
	Public = "Public",
	FriendsOnly = "Friends only",
	StartNow = "Start now",
	Leave = "Leave",
	Locked = "Rolling out…",
}

Strings.Lobby = {
	SpeakerAnnouncement = "Last stop: Brainrot Valley. Please keep your hands inside the minecart. And your lantern lit.",
	AuraBoard = "AURA",
	SixSevenSign = "6 7",
}

Strings.Dialogue = {
	VoteTimer = "Vote: %d",
	VoteTitle = "Choose",
	VoteCount = "%d",
	Skip = "Skip",
	SkipVotes = "Skip %d/%d",
}

-- Speaker names shown in subtitles and dialogue boxes.
Strings.Speakers = {
	Narrator = "Narrator",
	Giallino = "Giallino",
	Falsino = "Falsino",
	Negatino = "Negatino",
	Crudelino = "Crudelino",
	GiallinoTotale = "Giallino Totale",
	TungTung = "Tung Tung Tung Sahur",
	Lirili = "Lirili Larila",
	Ballerina = "Ballerina Cappuccina",
	Tralalero = "Tralalero Tralala",
	Chimpanzini = "Chimpanzini Bananini",
	Patapim = "Brr Brr Patapim",
	Bombardiro = "Bombardiro Crocodilo",
	Cappuccino = "Cappuccino Assassino",
} :: { [string]: string }

Strings.Journal = {
	Title = "JOURNAL",
	TabClues = "Clues",
	TabSuspects = "Suspects",
	TabMemories = "Memories",
	TabNames = "Names",
	Unverified = "?",
	ReadAloud = "Read aloud",
}

Strings.Items = {
	Wood = "Wood",
	Lantern = "Lantern",
	Bandage = "Bandage",
	CaveMap = "Cave map",
	TruthGear = "Truth Gear",
	InventoryFull = "Inventory full",
}

Strings.Health = {
	Downed = "You are down!",
	HoldToRevive = "Hold E to revive",
	Reviving = "Reviving…",
	BleedoutTimer = "%d",
	Dead = "You were supposed to say yes.",
	Revive = "REVIVE — %d R$",
	Spectate = "Spectate",
	RetryFromCheckpoint = "Retry from checkpoint",
	PurchaseFailed = "Purchase could not be completed.",
}

Strings.Aura = {
	Gain = "+%d AURA",
	Loss = "−%d AURA",
}

Strings.Prompts = {
	Interact = "Press E",
	Pickup = "Pick up",
	Talk = "Talk",
	Open = "Open",
	Read = "Read",
	Hide = "Hide",
	HoldBreath = "Hold your breath!",
	Chop = "Chop",
	Buy = "Buy",
	Search = "Search",
	Inspect = "Inspect",
	Light = "Light",
	Pull = "Pull",
	Insert = "Insert",
	Ride = "Get in",
	Take = "Take",
	Push = "Push",
	Fan = "Fan the fire!",
	AddWood = "Add wood",
	Enter = "Enter",
	Throw = "Throw",
	Code = "Enter code",
}

Strings.QTE = {
	Tap = "Mash %s!",
	Hold = "Hold %s - keep the marker in the green!",
	Left = "LEFT",
	Right = "RIGHT",
	Duck = "DUCK",
	Party = "Everyone mash %s!",
	Success = "Nice!",
	Fail = "Missed!",
}

Strings.Hud = {
	Checkpoint = "Checkpoint",
	Journal = "Journal",
	Memory = "Memory Page",
	NewClue = "New clue: %s",
	PageFound = "Memory Page found (%d/12)",
}

return Strings
