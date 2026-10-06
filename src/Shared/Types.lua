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
	| "TrippiTroppi"
	| "BonecaAmbalabu"
	| "UdinDinDinDun"
	| "LaVacaSaturno"
	| "FrigoCamelo"
	| "GlorboFruttodrillo"
	| "Strawberry"
	| "Banana"

-- Roblox AudioTextToSpeech settings per speaker (voice_lines.md).
-- pitch is in semitones (-12..12), speed is a multiplier (0.5..2.0).
export type VoiceSettings = {
	voiceId: string,
	pitch: number,
	speed: number,
	volume: number,
	villager: boolean, -- villagers play an npc_hum before each TTS line
}

-- npc_hum played before a villager's TTS line. nil = picked from the text.
export type HumKind = "neutral" | "question" | "no" | "happy" | "none"

export type VoiceLine = {
	id: string,
	speaker: SpeakerId,
	text: string, -- may contain [Name] / [DisplayName] / [Hiding spot], filled in per client
	chapter: ChapterId,
	scene: string, -- e.g. "CS-05" or "1-3"
	soundId: string?, -- uploaded override; nil = use TTS
	hum: HumKind?,
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

-- "KEEP" leaves the current grading alone (service cutscenes CS-DOWN / CS-DEAD / CS-REVIVE).
export type GradePreset =
	"DUSK"
	| "NIGHT"
	| "NIGHT_DEEP"
	| "FLASHBACK"
	| "GLITCH"
	| "DAWN"
	| "CAVE"
	| "KEEP"

-- "off" is a utility state (screen powered off), not an expression from cutscenes.md.
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
	| "off"

export type EasingName =
	"Linear"
	| "Constant"
	| "SineIn"
	| "SineOut"
	| "SineInOut"
	| "QuadIn"
	| "QuadOut"
	| "QuadInOut"
	| "CubicIn"
	| "CubicOut"
	| "CubicInOut"
	| "BackOut"
	| "ExpoOut"

-- A position (and facing) in the world. Exactly one base is used, checked in this order:
-- actor (+ part), anchor, players (centroid of player heads), localPlayer (local head).
-- offset is in the base's local space, worldOffset is added in world space, yaw turns the
-- resulting facing (degrees, positive = turn left).
export type Point = {
	anchor: string?,
	actor: string?,
	part: string?,
	players: boolean?,
	localPlayer: boolean?,
	offset: Vector3?,
	worldOffset: Vector3?,
	yaw: number?,
}

export type CameraMoveSpec = {
	kind: CameraMove,
	amount: number?, -- DOLLY: fraction of the distance; CRANE: studs; HANDHELD: shake studs
	angle: number?, -- ORBIT / PAN degrees
	easing: EasingName?,
	from: number?, -- fraction of the shot where the move starts (default 0)
	to: number?, -- fraction of the shot where the move ends (default 1)
}

export type RackSpec = {
	from: Point,
	to: Point,
	at: number?, -- seconds after shot start
	time: number?, -- seconds the focus pull takes
}

export type CameraSpec = {
	shot: ShotType,
	lookAt: Point,
	from: Point?, -- nil = framed automatically in front of lookAt by shot type
	low: boolean?,
	high: boolean?,
	distance: number?,
	height: number?,
	side: number?, -- degrees around the subject for automatic framing (0 = in front)
	fov: number?,
	moves: { CameraMoveSpec }?,
	shake: number?,
	rack: RackSpec?,
	roll: number?, -- dutch angle, degrees
}

export type OrbitSpec = {
	center: Point,
	radius: number,
	height: number,
	period: number, -- seconds per full circle
	startAngle: number?, -- degrees
	clockwise: boolean?,
	faceCenter: boolean?,
}

export type TourSpec = {
	targets: "players",
	distance: number, -- studs in front of each face
	height: number?,
	anim: string?, -- played at every stop
}

export type LightCue = {
	glow: number?, -- PointLight brightness
	spot: boolean?, -- SpotLight on/off
	time: number?,
}

-- Something that happens `at` seconds after the shot starts.
export type Cue = {
	at: number?,
	actor: string?,
	anim: string?,
	animSpeed: number?,
	stopAnim: string?, -- id of one animation to stop, or "*" for all
	face: FaceId?,
	faceFor: number?, -- seconds, then the previous face comes back
	faceDim: number?, -- 0 = full brightness, 1 = black screen
	faceDimTime: number?,
	eyeOffset: Vector2?, -- face pixels (x right, y down)
	moveTo: Point?,
	moveTime: number?,
	moveEasing: EasingName?,
	faceToward: Point?,
	orbit: OrbitSpec?,
	tour: TourSpec?,
	effect: string?,
	effectAt: Point?,
	effectParams: { [string]: any }?,
	visible: boolean?,
	light: LightCue?,
	sfx: string?,
	sfxVolume: number?,
	sfxSpeed: number?,
	music: string?, -- track name or "SILENCE"
	musicFade: number?,
	musicVolume: number?,
	line: string?, -- VoiceLines id
	vignette: Color3?, -- tint the screen edges (CS-DOWN red), nil = unchanged
	clockTo: number?, -- time-lapse: tween Lighting.ClockTime to this
	clockTime: number?, -- seconds the time-lapse takes
	world: string?, -- WorldFx effect name (lights out, shutters, signs...)
	worldParams: { [string]: any }?,
	dismount: boolean?, -- the actor stops riding (stays where it is)
	ride: RideSpec?, -- the actor starts riding another actor
}

export type Shot = {
	n: string, -- shot number from cutscenes.md ("1", "7a")
	t0: number,
	t1: number,
	camera: CameraSpec,
	cues: { Cue }?,
	grade: GradePreset?,
	gradeTime: number?,
	transitionIn: Transition?,
	transitionOut: Transition?,
}

export type VoteOption = {
	id: string,
	text: string,
	next: string?, -- segment to play after this option wins
	effects: { [string]: any }?, -- handed to ChoiceMade listeners (StoryFlags / Achievements)
}

export type VoteSpec = {
	options: { VoteOption },
	seconds: number?,
}

export type Segment = {
	length: number,
	shots: { Shot },
	vote: VoteSpec?,
	next: string?,
}

-- An actor riding another one (players in the minecarts): its root follows the ridden actor's
-- pivot * offset (studs) until a `dismount` cue.
export type RideSpec = { actor: string, offset: Vector3, yaw: number? }

export type ActorSpec = {
	id: string,
	-- name of a rig in ServerStorage.Models, "@LocalPlayer" (the local character itself) or
	-- "@Player1".."@Player6" (a stand-in copy of the n-th party member's avatar, by UserId)
	model: string,
	at: Point,
	ride: RideSpec?,
	face: FaceId?,
	visible: boolean?,
	footsteps: boolean?,
}

export type PropSpec = {
	id: string,
	kind: "LightCircle",
	at: Point,
	radius: number?,
	color: Color3?,
}

export type PlayersMode = "keep" | "hide" | "slots"

export type PlayersSpec = {
	mode: PlayersMode,
	anchor: string?,
	slots: { Vector3 }?, -- local offsets from the anchor
	yaw: number?, -- facing of the slots relative to the anchor
}

export type Cutscene = {
	id: string,
	title: string,
	noSkip: boolean, -- the lock-icon cutscenes: no skip on the first play in this server
	grade: GradePreset,
	clockTime: number?,
	actors: { ActorSpec },
	props: { PropSpec }?,
	players: PlayersSpec?,
	hideNpcs: { string }?,
	entry: string,
	segments: { [string]: Segment },
}

-- PoseAnimator keyframe data (Shared/Animations/A_*.lua). Plain tables so the files have no
-- Roblox dependencies. rot = {pitch, yaw, roll} in degrees, pos = {x, y, z} studs.
export type AnimKey = {
	t: number,
	rot: { number }?,
	pos: { number }?,
	ease: EasingName?,
}

export type ScalarKey = {
	t: number,
	v: number,
	ease: EasingName?,
}

export type AnimationData = {
	id: string,
	length: number,
	loop: boolean,
	continueYaw: boolean?, -- Root yaw continues from the current facing instead of jumping
	tracks: { [string]: { AnimKey } },
	scale: { ScalarKey }?,
	effect: { kind: string, at: number, params: { [string]: any }? }?,
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
