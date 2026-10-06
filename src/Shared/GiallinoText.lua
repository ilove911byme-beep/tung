--!strict
-- Text corruption for Giallino as its mood breaks (brief, gameplay system 7):
-- Happy = clean, Off = a few wrong letters, Broken = stutters and glitch marks, Hostile = CAPS.
local GiallinoText = {}

local GLITCH = { "#", "%", "&", "?", "!", "/", "_", "0", "1" }

function GiallinoText.corrupt(text: string, tier: string, seed: number?): string
	if tier == "Happy" then
		return text
	end
	local rng = Random.new(seed or os.clock() * 1000)
	local out = {}
	local rate = if tier == "Off" then 0.04 elseif tier == "Broken" then 0.12 else 0.18
	for _, code in utf8.codes(text) do
		local ch = utf8.char(code)
		if ch ~= " " and rng:NextNumber() < rate then
			if tier == "Broken" and rng:NextNumber() < 0.5 then
				table.insert(out, ch .. "-" .. ch) -- s-stutter
			else
				table.insert(out, GLITCH[rng:NextInteger(1, #GLITCH)])
			end
		else
			table.insert(out, ch)
		end
	end
	local result = table.concat(out)
	if tier == "Hostile" then
		result = string.upper(result)
	end
	return result
end

return GiallinoText
