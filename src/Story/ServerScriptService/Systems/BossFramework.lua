--!strict
-- One reusable state machine for every boss (brief, gameplay system 16): phases with HP- or
-- objective-based progress, attacks with telegraphs (sound + red highlight 1 s before),
-- Glitchling waves, arena bounds and the intro card. A checkpoint before the fight is set by the
-- chapter; the finale passes checkpointEachPhase so each phase gets its own checkpoint.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))

local Hud = require(script.Parent.Hud)
local ThreatService = require(script.Parent.ThreatService)

export type Phase = {
	name: string,
	objective: string?,
	run: (boss: Boss) -> (),
}

export type BossDef = {
	name: string,
	cardTitle: string,
	cardSubtitle: string,
	signature: string,
	phases: { Phase },
	arenaCenter: Vector3?,
	arenaRadius: number?,
	onPhase: ((boss: Boss, index: number) -> ())?, -- checkpoint hook
}

local BossFramework = {}
BossFramework.__index = BossFramework

export type Boss = typeof(setmetatable(
	{} :: {
		def: BossDef,
		phaseIndex: number,
		hits: number,
		model: Model?,
		running: boolean,
		cleanups: { () -> () },
		data: { [string]: any },
	},
	BossFramework
))

function BossFramework.new(def: BossDef): Boss
	return setmetatable({
		def = def,
		phaseIndex = 0,
		hits = 0,
		model = nil,
		running = false,
		cleanups = {},
		data = {},
	}, BossFramework)
end

function BossFramework.card(self: Boss)
	Hud.bossCard(self.def.cardTitle, self.def.cardSubtitle, self.def.signature)
	task.wait(3.2)
end

--- Red highlight + warning sound on `target`, then waits `seconds` (default 1 s).
function BossFramework.telegraph(self: Boss, target: Instance, seconds: number?, sound: string?)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 30, 30)
	highlight.OutlineColor = Color3.fromRGB(255, 80, 80)
	highlight.FillTransparency = 0.45
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = target
	highlight.Parent = target
	local part = if target:IsA("BasePart")
		then target
		elseif target:IsA("Model") then target.PrimaryPart
		else nil
	Audio.play(sound or self.def.signature, part, { volume = 0.8, rollOffMax = 160 })
	task.wait(seconds or 1)
	highlight:Destroy()
end

function BossFramework.wave(_self: Boss, count: number, center: CFrame, radius: number)
	ThreatService.wave(count, center, radius)
end

--- Keeps players inside the arena (pushes them back toward the center).
function BossFramework.arena(self: Boss, center: Vector3, radius: number)
	local active = true
	table.insert(self.cleanups, function()
		active = false
	end)
	task.spawn(function()
		while active do
			for _, p in Players:GetPlayers() do
				local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					local flat =
						Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z)
					if flat.Magnitude > radius then
						local back = center + flat.Unit * (radius - 4)
						p.Character:PivotTo(CFrame.new(back.X, root.Position.Y, back.Z))
					end
				end
			end
			task.wait(0.3)
		end
	end)
end

function BossFramework.onCleanup(self: Boss, fn: () -> ())
	table.insert(self.cleanups, fn)
end

--- Runs every phase in order (yields). Returns when the last phase is complete.
function BossFramework.run(self: Boss)
	self.running = true
	for i, phase in self.def.phases do
		self.phaseIndex = i
		self.hits = 0
		if self.def.onPhase then
			self.def.onPhase(self, i)
		end
		if phase.objective then
			Hud.objective(phase.objective)
		end
		phase.run(self)
	end
	self:cleanup()
end

function BossFramework.cleanup(self: Boss)
	self.running = false
	for _, fn in self.cleanups do
		pcall(fn)
	end
	table.clear(self.cleanups)
	ThreatService.clear()
end

return BossFramework
