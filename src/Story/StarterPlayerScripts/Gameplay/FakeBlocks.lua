--!strict
-- Fake parkour blocks have no collision; their edges flicker very slightly so a careful player can
-- spot them (screenplay: "у фальшивых блоков чуть мерцает край").
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local FakeBlocks = {}

local boxes: { [BasePart]: SelectionBox } = {}

local function add(inst: Instance)
	if not inst:IsA("BasePart") or boxes[inst] then
		return
	end
	local box = Instance.new("SelectionBox")
	box.Adornee = inst
	box.LineThickness = 0.03
	box.Color3 = Color3.fromRGB(255, 240, 200)
	box.SurfaceTransparency = 1
	box.Transparency = 0.9
	box.Parent = inst
	boxes[inst] = box
end

function FakeBlocks.init()
	for _, inst in CollectionService:GetTagged("FakeBlock") do
		add(inst)
	end
	CollectionService:GetInstanceAddedSignal("FakeBlock"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("FakeBlock"):Connect(function(inst)
		if inst:IsA("BasePart") then
			boxes[inst] = nil
		end
	end)
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		acc += dt
		if acc < 0.09 then
			return
		end
		acc = 0
		for part, box in boxes do
			if not part.Parent then
				boxes[part] = nil
			else
				box.Transparency = if math.random() < 0.3 then 0.55 else 0.92
			end
		end
	end)
end

return FakeBlocks
