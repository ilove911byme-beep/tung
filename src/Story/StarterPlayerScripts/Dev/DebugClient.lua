--!strict
-- Studio only: /fx <Effect> runs a special effect on a local copy of the test dummy (so the
-- server copy stays intact) and removes it a few seconds later.
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Effects = require(Shared:WaitForChild("Visual"):WaitForChild("Effects"))
local PoseAnimator = require(Shared:WaitForChild("Visual"):WaitForChild("PoseAnimator"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DebugClient = {}

local function dummyTemplate(): Model?
	local stage = workspace:FindFirstChild("TestStage")
	local dummy = stage and stage:FindFirstChild("Dummy")
	if dummy and dummy:IsA("Model") then
		return dummy
	end
	return nil
end

local function run(kind: string)
	local template = dummyTemplate()
	if not template then
		warn("[DebugClient] no TestStage.Dummy")
		return
	end
	local copy = template:Clone()
	copy.Name = "FxDummy"
	copy.Parent = workspace
	for _, d in template:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 1
		end
	end
	local pivot = copy:GetPivot()
	if kind == "RootsBridge" then
		local from = pivot.Position + pivot.LookVector * 2 - Vector3.new(0, 3.2, 0)
		Effects.run(kind, nil, { from = from, to = from + pivot.LookVector * 16 })
	elseif kind == "TimeFreeze" then
		Effects.run(kind, nil, { center = pivot.Position, radius = 8, motes = 40 })
	elseif kind == "LastPixel" then
		Effects.run(kind, nil, { at = pivot.Position - Vector3.new(0, 3, 0) })
	elseif kind == "PixelDissolve" then
		local animator = PoseAnimator.new(copy)
		animator:play("A-REACH_OUT")
		local connection = RunService.RenderStepped:Connect(function()
			animator:step()
		end)
		Effects.run(kind, copy, { duration = 6 })
		connection:Disconnect()
	elseif kind == "Grow" then
		Effects.run(kind, copy, { to = 3, duration = 2, bloomFlash = true })
	else
		Effects.run(kind, copy, {})
	end
	task.delay(4, function()
		copy:Destroy()
		for _, d in template:GetDescendants() do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = 0
			end
		end
	end)
end

function DebugClient.init()
	Remotes.get(Remotes.Names.DebugFx).OnClientEvent:Connect(function(kind: string)
		task.spawn(run, kind)
	end)
end

return DebugClient
