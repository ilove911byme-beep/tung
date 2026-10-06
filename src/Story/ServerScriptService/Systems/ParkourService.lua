--!strict
-- ParkourKit (brief, gameplay system 15): data-driven segments built from blocks
-- (1 block = 4 studs, positions relative to the segment origin):
--   block / start / checkpoint / finish, moving (back and forth), collapse (falls 2 s after it
--   is stepped on, comes back after 5 s), fake (no collision, subtle edge flicker on the client),
--   lava (instant Downed), ladder / vine (climbable trusses), and a fall line under the segment.
-- Every segment reports per player: Fell, Finished(clean = finished without falls).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local HealthService = require(script.Parent.HealthService)

export type BlockKind =
	"block"
	| "start"
	| "checkpoint"
	| "finish"
	| "moving"
	| "collapse"
	| "fake"
	| "lava"
	| "ladder"
	| "vine"

export type BlockDef = {
	kind: BlockKind,
	at: { number }, -- block coordinates relative to the origin (center of the block)
	size: { number }?, -- in blocks, default {1, 1, 1}
	move: { number }?, -- moving: offset in blocks
	period: number?,
	color: Color3?,
	material: Enum.Material?,
	blockName: string?, -- map.md palette name for footsteps
}

export type FallMode = "return" | "damage" | "downed"

export type SegmentDef = {
	id: string,
	blocks: { BlockDef },
	killY: number, -- blocks relative to the origin; falling below = fell
	fall: FallMode,
	fallDamage: number?,
	returnToStart: boolean?, -- true: back to the start of the segment, else last checkpoint
}

type PlayerState = { falls: number, checkpoint: CFrame, finished: boolean }

local ParkourService = {}
ParkourService.__index = ParkourService

export type Segment = typeof(setmetatable(
	{} :: {
		def: SegmentDef,
		model: Model,
		origin: CFrame,
		startCf: CFrame,
		states: { [Player]: PlayerState },
		connections: { RBXScriptConnection },
		fell: BindableEvent,
		finished: BindableEvent,
		Fell: RBXScriptSignal,
		Finished: RBXScriptSignal,
		tracking: boolean,
	},
	ParkourService
))

local S = Config.World.StudsPerBlock

local COLORS: { [string]: Color3 } = {
	block = Color3.fromRGB(118, 118, 118),
	start = Color3.fromRGB(90, 160, 90),
	checkpoint = Color3.fromRGB(90, 140, 220),
	finish = Color3.fromRGB(230, 200, 60),
	moving = Color3.fromRGB(156, 118, 70),
	collapse = Color3.fromRGB(150, 120, 90),
	fake = Color3.fromRGB(118, 118, 118),
	lava = Color3.fromRGB(224, 112, 24),
	ladder = Color3.fromRGB(156, 118, 70),
	vine = Color3.fromRGB(60, 120, 50),
}

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function characterOf(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model)
end

--- Builds a segment under `parent` at `origin`.
function ParkourService.build(def: SegmentDef, parent: Instance, origin: CFrame): Segment
	local model = Instance.new("Model")
	model.Name = "Parkour_" .. def.id
	local fell = Instance.new("BindableEvent")
	local finished = Instance.new("BindableEvent")
	local self = setmetatable({
		def = def,
		model = model,
		origin = origin,
		startCf = origin,
		states = {},
		connections = {},
		fell = fell,
		finished = finished,
		Fell = fell.Event,
		Finished = finished.Event,
		tracking = false,
	}, ParkourService)

	for i, b in def.blocks do
		local size = v3(b.size or { 1, 1, 1 }) * S
		local cf = origin * CFrame.new(v3(b.at) * S)
		local part: BasePart
		if b.kind == "ladder" or b.kind == "vine" then
			local truss = Instance.new("TrussPart")
			truss.Size = Vector3.new(2, math.max(size.Y, 2), 2)
			part = truss
		else
			local p = Instance.new("Part")
			p.Size = size
			part = p
		end
		part.Name = b.kind .. i
		part.CFrame = cf
		part.Anchored = true
		part.Color = b.color or COLORS[b.kind] or COLORS.block
		part.Material = b.material
			or (
				if b.kind == "lava"
					then Enum.Material.Neon
					elseif b.kind == "vine" then Enum.Material.Grass
					else Enum.Material.Slate
			)
		part.TopSurface = Enum.SurfaceType.Smooth
		if b.blockName then
			part:SetAttribute("Block", b.blockName)
		end
		part.Parent = model
		if b.kind == "start" then
			self.startCf = cf + Vector3.new(0, size.Y / 2 + 3, 0)
		elseif b.kind == "fake" then
			part.CanCollide = false
			CollectionService:AddTag(part, "FakeBlock")
		elseif b.kind == "moving" and b.move then
			local tween = TweenService:Create(
				part,
				TweenInfo.new(
					b.period or 3,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut,
					-1,
					true
				),
				{ CFrame = cf * CFrame.new(v3(b.move) * S) }
			)
			tween:Play()
		elseif b.kind == "collapse" then
			local busy = false
			table.insert(
				self.connections,
				part.Touched:Connect(function(hit)
					if busy or not characterOf(hit) then
						return
					end
					busy = true
					task.delay(2, function()
						part.CanCollide = false
						TweenService:Create(
							part,
							TweenInfo.new(0.6),
							{ CFrame = cf - Vector3.new(0, 8, 0), Transparency = 1 }
						):Play()
						task.wait(5)
						part.CFrame = cf
						part.Transparency = 0
						part.CanCollide = true
						busy = false
					end)
				end)
			)
		end
		if b.kind == "lava" then
			table.insert(
				self.connections,
				part.Touched:Connect(function(hit)
					local player = characterOf(hit)
					if player and self.tracking and self.states[player] then
						self:_fall(player, true)
					end
				end)
			)
		elseif b.kind == "checkpoint" or b.kind == "finish" then
			table.insert(
				self.connections,
				part.Touched:Connect(function(hit)
					local player = characterOf(hit)
					local state = player and self.states[player]
					if not player or not state then
						return
					end
					state.checkpoint = cf + Vector3.new(0, size.Y / 2 + 3, 0)
					if b.kind == "finish" and not state.finished then
						state.finished = true
						finished:Fire(player, state.falls == 0)
					end
				end)
			)
		end
	end
	model.Parent = parent
	return self
end

function ParkourService._fall(self: Segment, player: Player, lava: boolean?)
	local state = self.states[player]
	if not state or state.finished then
		return
	end
	state.falls += 1
	self.fell:Fire(player)
	local character = player.Character
	if lava or self.def.fall == "downed" then
		HealthService.down(player)
		-- downed players are carried back so teammates can reach them
	elseif self.def.fall == "damage" then
		HealthService.damage(player, self.def.fallDamage or 25, "fall")
	end
	if character then
		local target = if self.def.returnToStart then self.startCf else state.checkpoint
		character:PivotTo(target)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end
end

--- Starts watching these players (falls / finish). Players start at the segment start.
--- Can be called again for more players (one watcher per segment).
function ParkourService.track(self: Segment, players: { Player }, teleport: boolean?)
	for i, p in players do
		if not self.states[p] then
			self.states[p] = { falls = 0, checkpoint = self.startCf, finished = false }
		end
		if teleport and p.Character then
			p.Character:PivotTo(self.startCf * CFrame.new((i - 1) * 2, 0, 0))
		end
	end
	if self.tracking then
		return
	end
	self.tracking = true
	local killY = (self.origin * CFrame.new(0, self.def.killY * S, 0)).Position.Y
	table.insert(
		self.connections,
		RunService.Heartbeat:Connect(function()
			for p, state in self.states do
				local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if
					root
					and root:IsA("BasePart")
					and not state.finished
					and root.Position.Y < killY
				then
					self:_fall(p)
				end
			end
		end)
	)
end

--- Stops watching a player (they left the course on purpose).
function ParkourService.untrack(self: Segment, player: Player)
	self.states[player] = nil
end

--- True while the player is on the course and has not finished it.
function ParkourService.isRunning(self: Segment, player: Player): boolean
	local s = self.states[player]
	return s ~= nil and not s.finished
end

function ParkourService.falls(self: Segment, player: Player): number
	local s = self.states[player]
	return if s then s.falls else 0
end

function ParkourService.allFinished(self: Segment): boolean
	for p, s in self.states do
		if p.Parent and not s.finished and p:GetAttribute("LifeState") ~= "Dead" then
			return false
		end
	end
	return true
end

function ParkourService.anyFinished(self: Segment): boolean
	for _, s in self.states do
		if s.finished then
			return true
		end
	end
	return false
end

function ParkourService.destroy(self: Segment)
	self.tracking = false
	for _, c in self.connections do
		c:Disconnect()
	end
	self.model:Destroy()
end

return ParkourService
