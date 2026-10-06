--!strict
-- Resolves Types.Point (anchor / actor / players / local player + offsets) to a CFrame.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Anchors = require(Shared:WaitForChild("World"):WaitForChild("Anchors"))
local Types = require(Shared:WaitForChild("Types"))

local Points = {}

export type ActorLookup = (id: string) -> Model?

local function headOf(character: Model?): BasePart?
	if not character then
		return nil
	end
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

--- Heads of all players, sorted by UserId so every client sees the same order.
function Points.playerHeads(): { BasePart }
	local list = Players:GetPlayers()
	table.sort(list, function(a, b)
		return a.UserId < b.UserId
	end)
	local heads = {}
	for _, p in list do
		local head = headOf(p.Character)
		if head then
			table.insert(heads, head)
		end
	end
	return heads
end

local function partOf(model: Model, name: string?): BasePart?
	if name then
		local found = model:FindFirstChild(name, true)
		if found and found:IsA("BasePart") then
			return found
		end
	end
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

--- World CFrame of a point. Returns nil if its base does not exist (yet).
function Points.resolve(point: Types.Point, actors: ActorLookup): CFrame?
	local base: CFrame? = nil
	if point.actor then
		local model = actors(point.actor)
		local part = model and partOf(model, point.part)
		if part then
			base = part.CFrame
		end
	elseif point.anchor then
		base = Anchors.get(point.anchor)
	elseif point.players then
		local heads = Points.playerHeads()
		if #heads > 0 then
			local sum = Vector3.zero
			for _, h in heads do
				sum += h.Position
			end
			local center = sum / #heads
			base = CFrame.new(center) * heads[1].CFrame.Rotation
		end
	elseif point.localPlayer then
		local head = headOf(Players.LocalPlayer.Character)
		if head then
			base = head.CFrame
		end
	end
	if not base then
		return nil
	end
	local cf = base
	if point.offset then
		cf = cf * CFrame.new(point.offset)
	end
	if point.yaw then
		cf = cf * CFrame.Angles(0, math.rad(point.yaw), 0)
	end
	if point.worldOffset then
		cf = cf + point.worldOffset
	end
	return cf
end

function Points.position(point: Types.Point, actors: ActorLookup): Vector3?
	local cf = Points.resolve(point, actors)
	return if cf then cf.Position else nil
end

return Points
