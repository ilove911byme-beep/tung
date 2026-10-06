--!strict
-- All spoken lines, merged from the child modules (one per chapter / group). Lines are added
-- phase by phase together with their cutscenes. Use VoiceLines.get(id).
local Types = require(script.Parent.Types)

local VoiceLines = {}

local byId: { [string]: Types.VoiceLine } = {}
local chantBySpeaker: { [string]: Types.VoiceLine } = {}

for _, child in script:GetChildren() do
	if child:IsA("ModuleScript") then
		local list = (require :: any)(child) :: { Types.VoiceLine }
		for _, line in list do
			if byId[line.id] then
				warn(string.format("[VoiceLines] duplicate id %s in %s", line.id, child.Name))
			end
			if #line.text > 300 then
				warn(
					string.format(
						"[VoiceLines] %s is longer than 300 characters (TTS limit)",
						line.id
					)
				)
			end
			byId[line.id] = line
			if line.scene == "CHANT" then
				chantBySpeaker[line.speaker] = line
			end
		end
	end
end

function VoiceLines.get(id: string): Types.VoiceLine?
	return byId[id]
end

function VoiceLines.chant(speaker: Types.SpeakerId): Types.VoiceLine?
	return chantBySpeaker[speaker]
end

return VoiceLines
