--!strict
-- Text-to-speech voice per speaker (voice_lines.md table). pitch = semitones, speed = multiplier.
-- voiceId comes from the Roblox TTS voice list (create.roblox.com/docs/audio/objects):
--   1 British male, 2 British female, 3 US male #1, 4 US female #1, 5 US male #2,
--   6 US female #2, 7 Australian male, 8 Australian female, 9 Retro #1, 10 Retro #2, 11 Host.
-- Giallino and its forms use the retro voices: it was a helper bot in an old game.
local Types = require(script.Parent.Types)

local VoiceSettings: { [Types.SpeakerId]: Types.VoiceSettings } = {
	Narrator = { voiceId = "1", pitch = -4, speed = 0.85, volume = 1.2, villager = false },
	TungTung = { voiceId = "3", pitch = -6, speed = 0.9, volume = 1.1, villager = true },
	Lirili = { voiceId = "2", pitch = 2, speed = 0.8, volume = 1, villager = true },
	Ballerina = { voiceId = "4", pitch = 4, speed = 1.1, volume = 1, villager = true },
	Tralalero = { voiceId = "5", pitch = 1, speed = 1.25, volume = 1, villager = true },
	Chimpanzini = { voiceId = "7", pitch = 5, speed = 1.15, volume = 1, villager = true },
	Patapim = { voiceId = "1", pitch = -8, speed = 0.75, volume = 1.1, villager = true },
	Bombardiro = { voiceId = "5", pitch = -3, speed = 1.05, volume = 1.2, villager = true },
	Cappuccino = { voiceId = "3", pitch = -2, speed = 0.95, volume = 0.8, villager = true },
	Giallino = { voiceId = "9", pitch = 6, speed = 1.1, volume = 1, villager = false },
	Falsino = { voiceId = "9", pitch = 4.5, speed = 1.0, volume = 1, villager = false }, -- +6 -> +3 in the doc
	Negatino = { voiceId = "10", pitch = -10, speed = 0.7, volume = 1, villager = false },
	Crudelino = { voiceId = "10", pitch = -12, speed = 1.3, volume = 1.3, villager = false },
	GiallinoTotale = { voiceId = "10", pitch = -6, speed = 0.9, volume = 1.3, villager = false },
}

return VoiceSettings
