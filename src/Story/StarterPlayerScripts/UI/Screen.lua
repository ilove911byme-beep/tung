--!strict
-- Helpers for responsive ScreenGuis: panels are authored in pixels for UITheme.ReferenceResolution
-- and get a UIScale that follows the viewport, clamped so touch targets stay >= 44 px.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local UITheme = require(Shared:WaitForChild("UITheme"))

local Screen = {}

local MIN_SCALE = 0.75 -- 60 px buttons never get smaller than 45 px
local MAX_SCALE = 1.5

function Screen.scale(): number
	local camera = workspace.CurrentCamera
	local size = if camera then camera.ViewportSize else UITheme.ReferenceResolution
	local ref = UITheme.ReferenceResolution
	return math.clamp(math.min(size.X / ref.X, size.Y / ref.Y), MIN_SCALE, MAX_SCALE)
end

--- A full-screen ScreenGui in PlayerGui.
function Screen.gui(name: string, displayOrder: number): ScreenGui
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild(name)
	if existing and existing:IsA("ScreenGui") then
		return existing
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.DisplayOrder = displayOrder
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	return gui
end

--- Adds a UIScale to a pixel-sized panel that tracks the viewport size.
function Screen.autoScale(panel: GuiObject): UIScale
	local scale = Instance.new("UIScale")
	scale.Scale = Screen.scale()
	scale.Parent = panel
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			scale.Scale = Screen.scale()
		end)
	end
	return scale
end

--- Dark glass panel in the game style.
function Screen.panel(parent: Instance, name: string): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = UITheme.Colors.Panel
	frame.BackgroundTransparency = UITheme.Transparency.Panel
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UITheme.CornerRadius
	corner.Parent = frame
	frame.Parent = parent
	return frame
end

--- Text button with the hover/press feel from the brief (scale 1.05 / 0.95, orange stroke).
function Screen.button(parent: Instance, name: string, text: string, size: Vector2): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(math.max(size.X, UITheme.MinTouchTarget), math.max(size.Y, 60))
	button.BackgroundColor3 = UITheme.Colors.Panel
	button.BackgroundTransparency = UITheme.Transparency.Panel
	button.AutoButtonColor = false
	button.Font = UITheme.Fonts.Body
	button.TextColor3 = UITheme.Colors.Text
	button.TextSize = 24
	button.Text = text
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UITheme.CornerRadius
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = UITheme.StrokeThickness
	stroke.Color = UITheme.Colors.Orange
	stroke.Transparency = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	local scale = Instance.new("UIScale")
	scale.Parent = button
	button.MouseEnter:Connect(function()
		stroke.Transparency = 0
		scale.Scale = UITheme.Tween.HoverScale
	end)
	button.MouseLeave:Connect(function()
		stroke.Transparency = 1
		scale.Scale = 1
	end)
	button.MouseButton1Down:Connect(function()
		scale.Scale = UITheme.Tween.PressScale
	end)
	button.MouseButton1Up:Connect(function()
		scale.Scale = 1
	end)
	button.Parent = parent
	return button
end

return Screen
