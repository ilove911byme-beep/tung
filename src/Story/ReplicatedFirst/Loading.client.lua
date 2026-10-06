--!strict
-- The join loading screen of the Story place: the same design as the lobby's TeleportGui (black,
-- Giallino "booting up" in a ring of blocks, a random tip), so the jump from the minecart into
-- the valley feels like one screen. Closes when the story starts (or after a timeout).
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

ReplicatedFirst:RemoveDefaultLoadingScreen()
local arriving = TeleportService:GetArrivingTeleportGui()
if arriving then
	arriving.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LoadingScreen = require(Shared:WaitForChild("UI"):WaitForChild("LoadingScreen"))

local handle = LoadingScreen.show()
if arriving then
	arriving:Destroy()
end
local started = os.clock()
local loadedAt: number? = nil
-- in Studio the test stage never starts a chapter on its own: do not block it for long
local maxAfterLoad = if RunService:IsStudio() then 6 else 35
while true do
	if game:IsLoaded() and not loadedAt then
		loadedAt = os.clock()
	end
	local storyStarted = workspace:GetAttribute("StoryStarted") == true
	local p = 0.15 + (if loadedAt then 0.45 else math.min((os.clock() - started) / 20, 0.4))
	if loadedAt then
		p += math.min((os.clock() - loadedAt) / 30, 0.35)
	end
	handle.setProgress(if storyStarted then 1 else p)
	if storyStarted or (loadedAt and os.clock() - loadedAt > maxAfterLoad) then
		break
	end
	task.wait(0.1)
end
handle.finish(true)
