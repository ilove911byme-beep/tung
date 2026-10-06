--!strict
-- Little lobby details, all local:
--   * Tung Tung stands far away on the foggy hill; walk close and he is gone (knock_tung_x3 once)
--   * the endings wall: a painting lights up for every ending this player owns
--   * fireflies over the station and the valley
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))
local Strings = require(Shared:WaitForChild("Strings"))

local Profile = require(script.Parent:WaitForChild("Profile"))

local Teasers = {}

local S = 4
local TUNG_SPOT = Vector3.new(12, 18, -36) * S
local TUNG_RANGE = 70

local function tung()
	local templates = ReplicatedStorage:WaitForChild("RigTemplates", 20)
	local template = templates and templates:FindFirstChild("TungTung")
	if not template or not template:IsA("Model") then
		return
	end
	local m = template:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("BillboardGui") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		end
	end
	local h = (m:GetAttribute("RootHeight") :: number?) or 0
	m:PivotTo(CFrame.lookAt(TUNG_SPOT, TUNG_SPOT + Vector3.new(0, 0, 1)) * CFrame.new(0, h, 0))
	m.Parent = workspace
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - TUNG_SPOT).Magnitude < TUNG_RANGE then
			conn:Disconnect()
			Audio.play("knock_tung_x3", nil, { volume = 0.7, group = "SFX" })
			m:Destroy()
		end
	end)
end

local SCENES: { [string]: { sky: string, ground: string, orb: string } } = {
	dawn = { sky = "#F4A86A", ground = "#5E9E4E", orb = "#FFE07A" },
	endless = { sky = "#0A0A18", ground = "#1A2A1A", orb = "#FFD83A" },
	sahur = { sky = "#F6D49A", ground = "#6DAE5C", orb = "#F0E0A0" },
}

local function paintings()
	local function refresh()
		for _, canvas in CollectionService:GetTagged("EndingPainting") do
			local ending = canvas:GetAttribute("Ending")
			if canvas:IsA("BasePart") and typeof(ending) == "string" then
				local old = canvas:FindFirstChild("Painting")
				if old then
					old:Destroy()
				end
				local owned = Profile.ownsEnding(ending)
				local gui = Instance.new("SurfaceGui")
				gui.Name = "Painting"
				gui.Face = Enum.NormalId.Right
				gui.CanvasSize = Vector2.new(210, 170)
				gui.LightInfluence = 0.6
				local scene = SCENES[ending]
				local bg = Instance.new("Frame")
				bg.Size = UDim2.fromScale(1, 1)
				bg.BorderSizePixel = 0
				bg.BackgroundColor3 = if owned and scene
					then Color3.fromHex(scene.sky)
					else Color3.fromRGB(20, 20, 26)
				bg.Parent = gui
				if owned and scene then
					local ground = Instance.new("Frame")
					ground.Position = UDim2.fromScale(0, 0.7)
					ground.Size = UDim2.fromScale(1, 0.3)
					ground.BorderSizePixel = 0
					ground.BackgroundColor3 = Color3.fromHex(scene.ground)
					ground.Parent = bg
					local orb = Instance.new("Frame")
					orb.Position = UDim2.fromScale(0.42, 0.2)
					orb.Size = UDim2.fromScale(0.16, 0.2)
					orb.BorderSizePixel = 0
					orb.BackgroundColor3 = Color3.fromHex(scene.orb)
					orb.Parent = bg
				end
				local title = Instance.new("TextLabel")
				title.BackgroundTransparency = 1
				title.Position = UDim2.fromScale(0, 0.78)
				title.Size = UDim2.fromScale(1, 0.2)
				title.Font = Enum.Font.Arcade
				title.TextScaled = true
				title.TextColor3 = Color3.fromRGB(240, 230, 210)
				local titles = Strings.Story.EndingTitles :: { [string]: string }
				title.Text = if owned then titles[ending] or ending else Strings.Menu.Unknown
				title.Parent = bg
				gui.Parent = canvas
			end
		end
		for _, lamp in CollectionService:GetTagged("PaintingLamp") do
			local ending = lamp:GetAttribute("Ending")
			local light = lamp:FindFirstChildOfClass("PointLight")
			if light and typeof(ending) == "string" then
				light.Enabled = Profile.ownsEnding(ending)
				light.Brightness = 1.4
			end
		end
	end
	Profile.Changed:Connect(refresh)
	CollectionService:GetInstanceAddedSignal("EndingPainting"):Connect(refresh)
	refresh()
end

local function fireflies()
	local folder = Instance.new("Folder")
	folder.Name = "Fireflies"
	folder.Parent = workspace
	local rng = Random.new()
	type Fly = { part: Part, home: Vector3, phase: number, speed: number }
	local flies: { Fly } = {}
	type Area = { lo: Vector3, hi: Vector3, n: number }
	local areas: { Area } = {
		{ lo = Vector3.new(0, 12.5, 30) * S, hi = Vector3.new(44, 16, 60) * S, n = 20 },
		{ lo = Vector3.new(104, 12, -20) * S, hi = Vector3.new(240, 20, 60) * S, n = 60 },
	}
	for _, a in areas do
		local lo, hi, n = a.lo, a.hi, a.n
		for _ = 1, n do
			local p = Instance.new("Part")
			p.Name = "Firefly"
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CastShadow = false
			p.Size = Vector3.new(0.3, 0.3, 0.3)
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromRGB(255, 230, 120)
			p.Parent = folder
			table.insert(flies, {
				part = p,
				home = Vector3.new(
					rng:NextNumber(lo.X, hi.X),
					rng:NextNumber(lo.Y, hi.Y),
					rng:NextNumber(lo.Z, hi.Z)
				),
				phase = rng:NextNumber(0, 6.28),
				speed = rng:NextNumber(0.3, 0.8),
			})
		end
	end
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for _, f in flies do
			local k = t * f.speed + f.phase
			f.part.Position = f.home
				+ Vector3.new(math.sin(k) * 3, math.sin(k * 1.7) * 1.2, math.cos(k * 0.8) * 3)
			f.part.Transparency = 0.2 + 0.6 * (0.5 + 0.5 * math.sin(k * 3))
		end
	end)
end

function Teasers.init()
	task.spawn(tung)
	paintings()
	fireflies()
end

return Teasers
