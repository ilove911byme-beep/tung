--!strict
-- Applies the `effects` of party choices (cutscene votes and dialogue choices):
--   giallinoMood = n   change Giallino's mood (once per choice)
--   badge = "ID"       achievement for the players who voted for this option (FIRST_NO goes only
--                      to the "No" voters, see PROGRESS.md); for dialogue effects: everyone there
--   aura = n           Aura points for the same players
--   flag = "name", value = v   set a story flag (value defaults to true)
local SSS = script.Parent.Parent
local CutsceneService = require(SSS:WaitForChild("Services"):WaitForChild("CutsceneService"))
local Systems = SSS:WaitForChild("Systems")
local AchievementService = require(Systems:WaitForChild("AchievementService"))
local AuraService = require(Systems:WaitForChild("AuraService"))
local DialogueService = require(Systems:WaitForChild("DialogueService"))
local StoryFlags = require(Systems:WaitForChild("StoryFlags"))

local ChoiceEffects = {}

function ChoiceEffects.apply(effects: { [string]: any }, players: { Player })
	local mood = effects.giallinoMood
	if type(mood) == "number" then
		StoryFlags.addMood(mood)
	end
	if type(effects.flag) == "string" then
		StoryFlags.set(effects.flag, if effects.value == nil then true else effects.value)
	end
	for _, p in players do
		if type(effects.badge) == "string" then
			AchievementService.award(p, effects.badge)
		end
		if type(effects.aura) == "number" then
			AuraService.add(p, effects.aura)
		end
	end
end

function ChoiceEffects.init()
	CutsceneService.ChoiceMade:Connect(
		function(
			_cutsceneId: string,
			optionId: string,
			effects: { [string]: any },
			voters: { Player },
			byPlayer: { [Player]: string }?
		)
			local who: { Player } = {}
			for _, p in voters do
				if not byPlayer or byPlayer[p] == optionId then
					table.insert(who, p)
				end
			end
			ChoiceEffects.apply(effects, who)
		end
	)
	DialogueService.setEffectHandler(function(effects, voters)
		ChoiceEffects.apply(effects, voters)
	end)
end

return ChoiceEffects
