--!strict
-- Design tokens for every UI in both places. UI code never hard-codes colors, fonts or timings.
local Types = require(script.Parent.Types)

local UITheme = {}

UITheme.Colors = {
	Orange = Color3.fromHex("#FF9A3C"), -- title, hover stroke, accents
	Panel = Color3.fromHex("#0E1220"), -- dark glass panels
	PanelLight = Color3.fromHex("#1A2036"),
	Text = Color3.fromHex("#F4EFE6"),
	TextDim = Color3.fromHex("#9AA0B4"),
	Giallino = Color3.fromHex("#FFD83A"),
	Danger = Color3.fromHex("#E04848"),
	Success = Color3.fromHex("#5BD36E"),
	Black = Color3.fromHex("#000000"),
	White = Color3.fromHex("#FFFFFF"),
}

UITheme.Transparency = {
	Panel = 0.15,
	Dim = 0.5,
}

UITheme.Fonts = {
	Title = Enum.Font.Creepster,
	Body = Enum.Font.FredokaOne,
}

UITheme.CornerRadius = UDim.new(0, 10)
UITheme.StrokeThickness = 2
UITheme.Padding = UDim.new(0, 12)

-- Touch targets must be at least this many pixels on every side.
UITheme.MinTouchTarget = 44

-- Reference resolution for UIScale. Layouts are authored for this size and scaled to fit
-- 360x640 phones up to 1920x1080 desktops (see README, "UI quality bar").
UITheme.ReferenceResolution = Vector2.new(1280, 720)

UITheme.Tween = {
	Fast = 0.12,
	Normal = 0.25,
	Slow = 0.6,
	ButtonStagger = 0.06,
	HoverScale = 1.05,
	PressScale = 0.95,
}

UITheme.Rarity = {
	Common = Color3.fromHex("#9AA0A6"), -- grey
	Rare = Color3.fromHex("#3FA0FF"), -- blue
	Epic = Color3.fromHex("#A64DFF"), -- purple
	Legendary = Color3.fromHex("#FFC83A"), -- gold
	Secret = Color3.fromHex("#FF3B3B"), -- glitchy red (the toast adds the glitch animation)
} :: { [Types.Rarity]: Color3 }

-- Subtitle / dialogue name colors per speaker.
UITheme.Speaker = {
	Narrator = Color3.fromHex("#D9D2C0"),
	Giallino = Color3.fromHex("#FFD83A"),
	Falsino = Color3.fromHex("#C8E04A"),
	Negatino = Color3.fromHex("#4A6CFF"),
	Crudelino = Color3.fromHex("#FF4040"),
	GiallinoTotale = Color3.fromHex("#FFA030"),
	TungTung = Color3.fromHex("#B07A48"),
	Lirili = Color3.fromHex("#7DBF6A"),
	Ballerina = Color3.fromHex("#FF8FC2"),
	Tralalero = Color3.fromHex("#4FC3F7"),
	Chimpanzini = Color3.fromHex("#F2D24B"),
	Patapim = Color3.fromHex("#8A9A5B"),
	Bombardiro = Color3.fromHex("#8FA860"),
	Cappuccino = Color3.fromHex("#C9A27A"),
} :: { [Types.SpeakerId]: Color3 }

return UITheme
