--!strict
-- The jump from the lobby into the story (brief, lobby C): when the server launches our cart,
-- the riders of that cart become the stand-ins of CS-00 (the carts roll into the tunnel, the
-- lamps go out, the loading screen), the loading screen stays up and is also handed to Roblox
-- as the TeleportGui so the same screen continues while the Story place loads.
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CutsceneLibrary = require(Shared:WaitForChild("CutsceneLibrary"))
local LoadingScreen = require(Shared:WaitForChild("UI"):WaitForChild("LoadingScreen"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Client = script.Parent.Parent
local Actors = require(Client:WaitForChild("Cutscene"):WaitForChild("Actors"))
local WorldFx = require(Client:WaitForChild("Gameplay"):WaitForChild("WorldFx"))
local CutsceneEngine = require(Client:WaitForChild("Cutscene"):WaitForChild("CutsceneEngine"))

local Launch = {}

local hold: LoadingScreen.Handle? = nil
local hidden: { BasePart } = {}
local hiddenGuis: { BillboardGui } = {}
local generation = 0
local launched = Instance.new("BindableEvent")
Launch.Started = launched.Event
local cancelled = Instance.new("BindableEvent")
Launch.Cancelled = cancelled.Event

local function hideCarts(on: boolean)
	if on then
		local map = workspace:FindFirstChild("LobbyMap")
		if not map then
			return
		end
		for _, m in map:GetChildren() do
			if m:IsA("Model") and string.find(m.Name, "^QueueCart") then
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") then
						d.LocalTransparencyModifier = 1
						table.insert(hidden, d)
					elseif d:IsA("BillboardGui") and d.Enabled then
						d.Enabled = false
						table.insert(hiddenGuis, d)
					end
				end
			end
		end
	else
		for _, p in hidden do
			p.LocalTransparencyModifier = 0
		end
		table.clear(hidden)
		for _, g in hiddenGuis do
			g.Enabled = true
		end
		table.clear(hiddenGuis)
	end
end

--- Called when the server says the teleport failed: back to the platform.
function Launch.cancel()
	generation += 1
	local h = hold
	if h then
		h.destroy()
		hold = nil
	end
	hideCarts(false)
	Actors.setStandInPlayers(nil)
	-- CS-00 put the tunnel lamps out
	WorldFx.play("lightsOn", { tag = "TunnelLamp" })
	cancelled:Fire()
end

local function onLaunch(_cartIndex: number, startTime: number, ids: { number })
	generation += 1
	local mine = generation
	launched:Fire()
	local riders = {}
	for _, id in ids do
		local p = Players:GetPlayerByUserId(id)
		if p then
			table.insert(riders, p)
		end
	end
	Actors.setStandInPlayers(riders)
	-- the same loading screen keeps going through the teleport
	pcall(function()
		local gui = LoadingScreen.build()
		TeleportService:SetTeleportGui(gui)
	end)
	local untilStart = startTime - workspace:GetServerTimeNow()
	if untilStart > 0 then
		task.wait(untilStart)
	end
	hideCarts(true)
	CutsceneEngine.playLocal("CS_00")
	local data = CutsceneLibrary.get("CS_00")
	task.wait(if data then data.segments.main.length - 0.1 else 14)
	if mine ~= generation then
		return -- cancelled meanwhile (teleport failed)
	end
	-- black with the loaded Giallino until Roblox takes over with the TeleportGui
	local h = LoadingScreen.show()
	h.setProgress(1)
	hold = h
end

function Launch.init()
	Remotes.get(Remotes.Names.LobbyLaunch).OnClientEvent:Connect(onLaunch)
end

return Launch
