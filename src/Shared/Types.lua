--!strict
-- Shared type definitions. This module has no runtime content; other modules do
--   local Types = require(ReplicatedStorage.Shared.Types)
-- and use Types.Achievement etc. Shapes follow roblox_horror_prompt.md and cutscenes.md.

export type Rarity = "Common" | "Rare" | "Epic" | "Legendary" | "Secret"

export type Achievement = {
	id: string,
	name: string,
	rarity: Rarity,
	description: string,
	badgeId: number, -- 0 until the badge is created
	hidden: boolean, -- true for Secret: shown as "???" until owned
}

export type ChapterId = number -- 0 = prologue, 1..6 = chapters

export type MoodTier = "Happy" | "Off" | "Broken" | "Hostile"

export type FormId = "Giallino" | "Falsino" | "Negatino" | "Crudelino" | "Totale"

export type SpeakerId =
	"Narrator"
	| "Giallino"
	| "Falsino"
	| "Negatino"
	| "Crudelino"
	| "GiallinoTotale"
	| "TungTung"
	| "Lirili"
	| "Ballerina"
	| "Tralalero"
	| "Chimpanzini"
	| "Patapim"
	| "Bombardiro"
	| "Cappuccino"

-- Roblox AudioTextToSpeech settings per speaker (voice_lines.md)
export type VoiceSettings = {
	voiceId: string,
	pitch: number,
	speed: number,
}

export type VoiceLine = {
	id: string,
	speaker: SpeakerId,
	text: string, -- may contain [Name] / [Hiding spot], filled in per client
	chapter: ChapterId,
	scene: string, -- e.g. "CS-05" or "1-3"
	soundId: string?, -- uploaded override; nil = use TTS
}

-- Cutscene vocabulary (cutscenes.md section 0)
export type ShotType = "WIDE" | "MED" | "CLOSE" | "ECU" | "OTS" | "POV" | "LOW" | "HIGH"

export type CameraMove =
	"STATIC"
	| "DOLLY_IN"
	| "DOLLY_OUT"
	| "PAN_L"
	| "PAN_R"
	| "ORBIT"
	| "CRANE_UP"
	| "CRANE_DOWN"
	| "HANDHELD"
	| "WHIP"
	| "RACK"

export type TransitionKind = "CUT" | "BLEND" | "FADE_BLACK" | "FADE_WHITE" | "GLITCH_CUT"

export type Transition = {
	kind: TransitionKind,
	seconds: number?,
}

export type GradePreset = "DUSK" | "NIGHT" | "NIGHT_DEEP" | "FLASHBACK" | "GLITCH" | "DAWN" | "CAVE"

export type FaceId =
	"neutral"
	| "happy"
	| "sad"
	| "crying"
	| "scared"
	| "angry"
	| "shocked"
	| "eyes_closed"
	| "tired"
	| "smile_crooked"
	| "screen_static"

-- A camera position relative to a named anchor Part in the map (e.g. "Anchor_Tavern_Window").
export type AnchorRef = {
	anchor: string,
	offset: CFrame,
}

export type CameraSpec = {
	shotType: ShotType,
	move: CameraMove,
	from: AnchorRef,
	to: AnchorRef?,
	target: AnchorRef | string?, -- anchor or actor id to look at
	fov: number?,
	shake: number?, -- 0 = none
}

export type ActorCue = {
	id: string,
	anim: string?, -- animation id, e.g. "A-BALLERINA_DANCE"
	face: FaceId?,
	moveTo: AnchorRef?,
}

export type LineCue = {
	speaker: SpeakerId,
	voiceLineId: string,
}

export type Shot = {
	t0: number,
	t1: number,
	camera: CameraSpec,
	actors: { ActorCue }?,
	line: LineCue?,
	sfx: { string }?,
	music: string?, -- music state or "SILENCE"
	grade: GradePreset?,
	transitionIn: Transition?,
}

export type Cutscene = {
	id: string, -- equals the file name, e.g. "CS_05"
	length: number,
	noSkip: boolean, -- the lock-icon cutscenes
	grade: GradePreset?,
	shots: { Shot },
}

-- Data passed through TeleportService from Lobby to Story
export type TeleportData = {
	partyId: string,
	members: { number }, -- UserIds
	chosenChapter: ChapterId,
}

-- Minimal story flag set named in the brief and screenplay. Phase 1b finalizes the full list.
export type StoryFlags = {
	giallinoMood: number,
	cluesFound: { [string]: boolean },
	riddleCorrect: boolean,
	spottedFalsino: boolean,
	sawTungRunning: boolean,
	tungTungJailed: boolean,
}

export type PlayerLifeState = "Alive" | "Downed" | "Dead"

return {}
