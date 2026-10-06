--!strict
-- Runs the chapters in order from data modules (Story/Chapters/Chapter1..6). A chapter is a list
-- of steps; a step with `checkpoint` saves the story flags and inventories. A party wipe (or the
-- solo "Retry from checkpoint") cancels the running step, rolls the flags back, brings everybody
-- back at the checkpoint and runs the steps again from there.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Anchors = require(Shared:WaitForChild("World"):WaitForChild("Anchors"))
local Strings = require(Shared:WaitForChild("Strings"))

local SSS = script.Parent.Parent
local Services = SSS:WaitForChild("Services")
local Systems = SSS:WaitForChild("Systems")
local CutsceneService = require(Services:WaitForChild("CutsceneService"))
local VoteService = require(Services:WaitForChild("VoteService"))
local ClueService = require(Systems:WaitForChild("ClueService"))
local DialogueService = require(Systems:WaitForChild("DialogueService"))
local HealthService = require(Systems:WaitForChild("HealthService"))
local HidingService = require(Systems:WaitForChild("HidingService"))
local Hud = require(Systems:WaitForChild("Hud"))
local InventoryService = require(Systems:WaitForChild("InventoryService"))
local QTEService = require(Systems:WaitForChild("QTEService"))
local StoryFlags = require(Systems:WaitForChild("StoryFlags"))
local ThreatService = require(Systems:WaitForChild("ThreatService"))
local StoryContext = require(script.Parent:WaitForChild("StoryContext"))
local MapBuilder = require(SSS:WaitForChild("World"):WaitForChild("MapBuilder"))

export type Checkpoint = StoryContext.Checkpoint
export type Step = StoryContext.Step
export type Chapter = StoryContext.Chapter

local ChapterManager = {}

local chaptersFolder = script.Parent:WaitForChild("Chapters")
local running = false
local ctx: StoryContext.Context? = nil
local currentStepName = ""

local function chapterModule(index: number): Chapter?
	local module = chaptersFolder:FindFirstChild("Chapter" .. index)
	if module and module:IsA("ModuleScript") then
		return (require :: any)(module) :: Chapter
	end
	return nil
end

local function checkpointCf(cp: Checkpoint): CFrame
	local cf = if cp.point
		then MapBuilder.point(cp.point) - Vector3.new(0, 1, 0)
		else Anchors.get(cp.anchor or "Anchor_Station")
	if cp.offset then
		cf = cf * CFrame.new(cp.offset)
	end
	return cf + Vector3.new(0, 3, 0)
end

local function abortEverything(c: StoryContext.Context)
	CutsceneService.abort()
	VoteService.cancelAll()
	QTEService.cancelAll()
	DialogueService.close()
	ThreatService.clear()
	HidingService.unhideAll()
	c:cleanup()
	Hud.objective("")
	Hud.timer(0)
end

--- Runs one step in its own thread. Returns "done" or "wipe".
local function runStep(c: StoryContext.Context, step: Step): string
	local done = Instance.new("BindableEvent")
	local result = "done"
	local finished = false
	local thread = task.spawn(function()
		local ok, err = pcall(function()
			step.run(c)
		end)
		if not ok then
			warn(string.format("[ChapterManager] step %s failed: %s", step.name, tostring(err)))
		end
		if not finished then
			finished = true
			done:Fire()
		end
	end)
	local function wipe()
		if not finished then
			finished = true
			result = "wipe"
			done:Fire()
		end
	end
	local c1 = HealthService.PartyWiped:Connect(wipe)
	local c2 = HealthService.RetryRequested:Connect(wipe)
	if not finished then
		done.Event:Wait()
	end
	c1:Disconnect()
	c2:Disconnect()
	if result == "wipe" and coroutine.status(thread) ~= "dead" then
		task.cancel(thread)
	end
	done:Destroy()
	return result
end

function ChapterManager.context(): StoryContext.Context?
	return ctx
end

function ChapterManager.currentStep(): string
	return currentStepName
end

--- Runs the story from a chapter to the end (yields for the whole game).
function ChapterManager.run(startChapter: number, startStep: string?)
	if running then
		return
	end
	running = true
	local c = StoryContext.new()
	ctx = c
	if startChapter <= 1 then
		StoryFlags.reset()
	end
	StoryFlags.get().startedAt = os.clock()
	workspace:SetAttribute("StartChapter", startChapter) -- SPEEDRUN / NO_DEATHS need the whole story
	workspace:SetAttribute("StoryStarted", true) -- the join loading screen closes
	for index = startChapter, 6 do
		local chapter = chapterModule(index)
		if not chapter then
			warn("[ChapterManager] Chapter" .. index .. " missing")
			break
		end
		StoryFlags.set("chapter", index)
		workspace:SetAttribute("Chapter", index) -- clients pick Giallino's form / music from it
		ClueService.refreshPages(index)
		local steps = chapter.steps
		local i = 1
		if startStep and index == startChapter then
			for k, s in steps do
				if s.name == startStep then
					i = k
				end
			end
		end
		local checkpointIndex = i
		local snapshot = StoryFlags.snapshot()
		local inventories = InventoryService.snapshot()
		while i <= #steps do
			local step = steps[i]
			currentStepName = step.name
			if step.checkpoint then
				checkpointIndex = i
				snapshot = StoryFlags.snapshot()
				inventories = InventoryService.snapshot()
				c.checkpoint = checkpointCf(step.checkpoint)
				HealthService.respawnDead(c.checkpoint)
				Hud.toast(nil, "info", { text = Strings.Hud.Checkpoint })
			end
			local result = runStep(c, step)
			if result == "wipe" then
				abortEverything(c)
				task.wait(1.5)
				StoryFlags.restore(snapshot)
				InventoryService.restore(inventories)
				HealthService.resetAll(c.checkpoint)
				task.wait(2)
				i = checkpointIndex
			else
				i += 1
			end
		end
		c:cleanup()
	end
	running = false
end

function ChapterManager.isRunning(): boolean
	return running
end

function ChapterManager.chapterCount(): number
	local n = 0
	for i = 1, 6 do
		if chapterModule(i) then
			n = i
		end
	end
	return n
end

return ChapterManager
