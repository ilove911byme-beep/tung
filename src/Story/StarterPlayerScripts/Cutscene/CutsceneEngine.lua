--!strict
-- Client cutscene player. The server sends (runId, cutscene id, segment, shared start time);
-- this plays the shots from Shared/Cutscenes data on the server clock so every client is in
-- sync: camera (CameraRig), transitions (CUT, BLEND, FADE BLACK/WHITE, GLITCH CUT, WHIP),
-- color grades, letterbox, subtitles + voices, actors with PoseAnimator animations, faces,
-- effects, sounds and music. When the last segment is over it reports "finished" and holds the
-- last frame until the server ends the cutscene, then blends the camera back behind the player.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))
local CutsceneLibrary = require(Shared:WaitForChild("CutsceneLibrary"))
local Effects = require(Shared:WaitForChild("Visual"):WaitForChild("Effects"))
local FaceController = require(Shared:WaitForChild("Visual"):WaitForChild("FaceController"))
local PoseAnimator = require(Shared:WaitForChild("Visual"):WaitForChild("PoseAnimator"))
local PoseMath = require(Shared:WaitForChild("Visual"):WaitForChild("PoseMath"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Types = require(Shared:WaitForChild("Types"))
local VoiceLines = require(Shared:WaitForChild("VoiceLines"))

local Client = script.Parent.Parent
local MusicDirector = require(Client:WaitForChild("Audio"):WaitForChild("MusicDirector"))
local VoiceService = require(Client:WaitForChild("Audio"):WaitForChild("VoiceService"))
local Actors = require(script.Parent:WaitForChild("Actors"))
local CameraRig = require(script.Parent:WaitForChild("CameraRig"))
local Grade = require(script.Parent:WaitForChild("Grade"))
local Overlay = require(script.Parent:WaitForChild("Overlay"))
local Points = require(script.Parent:WaitForChild("Points"))
local WorldFx = require(Client:WaitForChild("Gameplay"):WaitForChild("WorldFx"))

local CutsceneEngine = {}

local RENDER_NAME = "CutscenePlayback"
local LATE_SKIP = 1.0 -- sounds/lines more than this late are dropped (client joined late)
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

type Run = {
	runId: string,
	data: Types.Cutscene,
	segKey: string,
	seg: Types.Segment,
	segStart: number,
	shotIndex: number,
	prevCf: CFrame,
	prevFov: number,
	fired: { [Types.Cue]: boolean },
	registry: Actors.Registry,
	props: { Instance },
	tokens: { [string]: string },
	finishedSent: boolean,
	hidden: { [Instance]: number },
	hiddenGuis: { [Instance]: boolean },
	hidePlayers: boolean,
	lastCf: CFrame,
	localMode: boolean,
}

local run: Run? = nil
local NO_CUES: { Types.Cue } = {}
local NO_PROPS: { Types.PropSpec } = {}
local NO_NAMES: { string } = {}
local camera = workspace.CurrentCamera
local savedCameraType: Enum.CameraType = Enum.CameraType.Custom
local savedFov = 70
local controls: any = nil

local function clock(): number
	return workspace:GetServerTimeNow()
end

local function getControls(): any
	if controls then
		return controls
	end
	local playerScripts = Players.LocalPlayer:FindFirstChild("PlayerScripts")
	local module = playerScripts and playerScripts:FindFirstChild("PlayerModule")
	if module and module:IsA("ModuleScript") then
		local ok, playerModule = pcall(require, module)
		if ok and playerModule and (playerModule :: any).GetControls then
			controls = (playerModule :: any):GetControls()
		end
	end
	return controls
end

local function setControls(enabled: boolean)
	local c = getControls()
	if c then
		pcall(function()
			if enabled then
				c:Enable()
			else
				c:Disable()
			end
		end)
	end
end

------------------------------------------------------------------ hiding NPCs / players
local function hideModel(r: Run, model: Instance)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			if r.hidden[d] == nil then
				r.hidden[d] = (d :: any).LocalTransparencyModifier
			end
			(d :: any).LocalTransparencyModifier = 1
		elseif d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			if r.hiddenGuis[d] == nil then
				r.hiddenGuis[d] = (d :: any).Enabled
			end
			(d :: any).Enabled = false
		end
	end
end

local function hideNpcs(r: Run)
	local names: { [string]: boolean } = {}
	for _, n in r.data.hideNpcs or NO_NAMES do
		names[n] = true
	end
	if next(names) == nil then
		return
	end
	for _, d in workspace:GetDescendants() do
		if d:IsA("Model") and d.Parent ~= r.registry.folder then
			local id = d:GetAttribute("CharacterId")
			if typeof(id) == "string" and names[id] and not d:IsDescendantOf(r.registry.folder) then
				hideModel(r, d)
			end
		end
	end
end

local function hidePlayers(r: Run)
	for _, p in Players:GetPlayers() do
		if p.Character then
			hideModel(r, p.Character)
		end
	end
end

local function unhideAll(r: Run)
	for inst, value in r.hidden do
		if inst.Parent then
			(inst :: any).LocalTransparencyModifier = value
		end
	end
	for gui, enabled in r.hiddenGuis do
		if gui.Parent then
			(gui :: any).Enabled = enabled
		end
	end
end

------------------------------------------------------------------ props
local function spawnProps(r: Run)
	for _, prop in r.data.props or NO_PROPS do
		local at = Points.resolve(prop.at, Actors.lookup(r.registry))
		if at and prop.kind == "LightCircle" then
			local radius = prop.radius or 5
			local disc = Instance.new("Part")
			disc.Name = prop.id
			disc.Shape = Enum.PartType.Cylinder
			disc.Size = Vector3.new(0.08, radius * 2, radius * 2)
			disc.CFrame = CFrame.new(at.Position + Vector3.new(0, 0.07, 0))
				* CFrame.Angles(0, 0, math.pi / 2)
			disc.Color = prop.color or Color3.fromRGB(255, 216, 90)
			disc.Material = Enum.Material.Neon
			disc.Transparency = 0.78
			disc.Anchored = true
			disc.CanCollide = false
			disc.CanQuery = false
			disc.CastShadow = false
			disc.Parent = r.registry.folder
			table.insert(r.props, disc)
		end
	end
end

------------------------------------------------------------------ cues
local function resolveParams(r: Run, params: { [string]: any }?): { [string]: any }
	local out: { [string]: any } = {}
	if not params then
		return out
	end
	for k, v in params do
		out[k] = v
	end
	if typeof(out.targetActor) == "string" then
		local actor = Actors.get(r.registry, out.targetActor)
		out.target = actor and actor.model.PrimaryPart
		out.targetActor = nil
	end
	if typeof(out.fromPoint) == "table" then
		out.from = Points.position(out.fromPoint :: any, Actors.lookup(r.registry))
		out.fromPoint = nil
	end
	return out
end

local function speakerModel(r: Run, speaker: string): Model?
	local actor = Actors.get(r.registry, speaker)
	if actor then
		return actor.model
	end
	for _, a in r.registry.byId do
		if a.model:GetAttribute("CharacterId") == speaker then
			return a.model
		end
	end
	return nil
end

local function fireCue(r: Run, cue: Types.Cue, shot: Types.Shot, cueClock: number)
	local late = clock() - cueClock
	local actor = if cue.actor then Actors.get(r.registry, cue.actor) else nil
	local model = actor and actor.model
	if actor and cue.visible ~= nil then
		Actors.setVisible(actor, cue.visible)
	end
	if actor and cue.anim then
		actor.driven = true
		actor.animator:play(cue.anim, {
			startClock = cueClock,
			speed = cue.animSpeed,
			restart = cue.animSpeed == nil,
			effectParams = resolveParams(r, cue.effectParams),
		})
	end
	if actor and cue.stopAnim then
		actor.animator:stop(cue.stopAnim)
	end
	if model and cue.face then
		if cue.faceFor then
			FaceController.flash(model, cue.face, cue.faceFor)
		else
			FaceController.set(model, cue.face)
		end
	end
	if model and cue.eyeOffset then
		FaceController.setEyeOffset(model, cue.eyeOffset)
	end
	if model and cue.faceDim then
		FaceController.setDim(model, cue.faceDim, cue.faceDimTime)
	end
	if actor and cue.moveTo then
		Actors.moveTo(r.registry, actor, cue.moveTo, cue.moveTime or 1, cue.moveEasing, cueClock)
	end
	if actor and cue.orbit then
		Actors.orbit(r.registry, actor, cue.orbit, cueClock)
	end
	if actor and cue.tour then
		Actors.tour(actor, cue.tour, cueClock, shot.t1 - shot.t0 - (cue.at or 0))
	end
	if actor and cue.light then
		Actors.light(actor, cue.light)
	end
	if cue.effect then
		local params = resolveParams(r, cue.effectParams)
		if cue.effectAt then
			params.at = Points.position(cue.effectAt, Actors.lookup(r.registry))
		end
		task.spawn(Effects.run, cue.effect, model, params)
	end
	if cue.music then
		MusicDirector.override(cue.music, cue.musicFade, cue.musicVolume)
	end
	if cue.vignette then
		Overlay.setVignette(true, cue.vignette)
	end
	if cue.clockTo then
		Grade.setClock(cue.clockTo, cue.clockTime or 1)
	end
	if cue.world then
		WorldFx.play(cue.world, cue.worldParams or {})
	end
	if late <= LATE_SKIP then
		if cue.sfx then
			Audio.play(cue.sfx, nil, { volume = cue.sfxVolume, speed = cue.sfxSpeed })
		end
		if cue.line then
			local line = VoiceLines.get(cue.line)
			VoiceService.say(cue.line, {
				speakerModel = if line then speakerModel(r, line.speaker) else nil,
				tokens = r.tokens,
			})
		end
	end
end

------------------------------------------------------------------ segments / shots
local function preloadSegment(r: Run)
	local ids = {}
	for _, shot in r.seg.shots do
		for _, cue in shot.cues or NO_CUES do
			if cue.line then
				table.insert(ids, cue.line)
			end
		end
	end
	VoiceService.preload(ids, r.tokens)
end

local function setSegment(r: Run, key: string, startTime: number)
	local seg = r.data.segments[key]
	if not seg then
		warn("[CutsceneEngine] unknown segment " .. key)
		return
	end
	r.segKey = key
	r.seg = seg
	r.segStart = startTime
	r.shotIndex = 0
	r.fired = {}
	r.finishedSent = false
	preloadSegment(r)
end

local function shotAt(seg: Types.Segment, t: number): number
	local shots = seg.shots
	for i, shot in shots do
		if t < shot.t1 then
			return i
		end
	end
	return #shots
end

local function enterShot(r: Run, index: number)
	local shot = r.seg.shots[index]
	r.shotIndex = index
	r.prevCf = camera.CFrame
	r.prevFov = camera.FieldOfView
	if shot.grade then
		Grade.apply(shot.grade, shot.gradeTime or 1)
	end
	local tin = shot.transitionIn
	if tin and (tin.kind == "FADE_BLACK" or tin.kind == "FADE_WHITE") then
		Overlay.setFade(if tin.kind == "FADE_WHITE" then WHITE else BLACK, 1)
	elseif Overlay.fadeOpacity() > 0 and not shot.transitionOut then
		Overlay.setFade(BLACK, 0)
	end
	if tin and tin.kind == "GLITCH_CUT" then
		Overlay.glitchBurst(tin.seconds or 0.2)
		Audio.play("glitch_burst", nil, { volume = 0.6 })
	end
	if CameraRig.hasMove(shot.camera, "WHIP") then
		Grade.blurPulse(14, 0.35)
	end
end

local function update()
	local r = run
	if not r then
		return
	end
	local now = clock()
	local t = now - r.segStart
	local preroll = t < 0
	if preroll then
		t = 0
	end
	local seg = r.seg
	local index = shotAt(seg, t)
	if index ~= r.shotIndex and not preroll then
		enterShot(r, index)
	end
	local shot = seg.shots[math.max(index, 1)]

	if not preroll then
		-- every cue whose time has come, in order (also the ones of shots we jumped over)
		for _, s in seg.shots do
			if s.t0 > t then
				break
			end
			for _, cue in s.cues or NO_CUES do
				local at = s.t0 + (cue.at or 0)
				if t >= at and not r.fired[cue] then
					r.fired[cue] = true
					fireCue(r, cue, s, r.segStart + at)
				end
			end
		end
	end

	Actors.update(r.registry)
	if r.hidePlayers then
		hidePlayers(r)
	end

	local duration = shot.t1 - shot.t0
	local localT = math.clamp(t - shot.t0, 0, duration)
	local frame = CameraRig.evaluate(shot.camera, localT, duration, Actors.lookup(r.registry))
	if frame then
		local cf, fov = frame.cframe, frame.fov
		local tin = shot.transitionIn
		if tin and tin.kind == "BLEND" and not preroll then
			local a = PoseMath.ease("SineInOut", localT / math.max(tin.seconds or 0.5, 1e-3))
			if a < 1 then
				cf = r.prevCf:Lerp(cf, a)
				fov = r.prevFov + (fov - r.prevFov) * a
			end
		elseif CameraRig.hasMove(shot.camera, "WHIP") and not preroll then
			local a = PoseMath.ease("QuadOut", localT / 0.3)
			if a < 1 then
				cf = r.prevCf:Lerp(cf, a)
			end
		end
		camera.CFrame = cf
		camera.FieldOfView = fov
		r.lastCf = cf
		Grade.setFocus(frame.focus)
	end

	-- fades inside the shot
	if not preroll then
		local tin = shot.transitionIn
		if tin and (tin.kind == "FADE_BLACK" or tin.kind == "FADE_WHITE") then
			local secs = tin.seconds or 1
			if localT <= secs + 0.5 then -- keep writing a little past the end so it lands on 0
				Overlay.setFade(
					if tin.kind == "FADE_WHITE" then WHITE else BLACK,
					math.clamp(1 - localT / secs, 0, 1)
				)
			end
		end
		local tout = shot.transitionOut
		if tout and (tout.kind == "FADE_BLACK" or tout.kind == "FADE_WHITE") then
			local secs = tout.seconds or 1
			local startFade = duration - secs
			if localT >= startFade then
				Overlay.setFade(
					if tout.kind == "FADE_WHITE" then WHITE else BLACK,
					(localT - startFade) / secs
				)
			end
		end
	end

	-- the last segment is over: tell the server, hold the last frame until it ends the cutscene
	if not seg.next and not seg.vote and t >= seg.length and not r.finishedSent then
		r.finishedSent = true
		if r.localMode then
			local id = r.runId
			task.defer(function()
				CutsceneEngine.finishLocal(id)
			end)
		else
			Remotes.get(Remotes.Names.CutsceneFinished):FireServer(r.runId, r.segKey)
		end
	end
end

------------------------------------------------------------------ start / end
local function cleanup(r: Run)
	RunService:UnbindFromRenderStep(RENDER_NAME)
	Actors.cleanup(r.registry)
	for _, p in r.props do
		p:Destroy()
	end
	unhideAll(r)
	Effects.run("TimeResume", nil, nil)
end

local function returnCamera(fromCf: CFrame)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") then
		local focus = root.Position + Vector3.new(0, 1.5, 0)
		local behind = root.CFrame * CFrame.new(0, 2.5, 11)
		local goal = CFrame.lookAt(behind.Position, focus)
		local start = os.clock()
		local blend = Config.Cutscene.ReturnBlendSeconds
		while os.clock() - start < blend do
			local a = PoseMath.ease("SineInOut", (os.clock() - start) / blend)
			camera.CFrame = fromCf:Lerp(goal, a)
			camera.FieldOfView = camera.FieldOfView + (savedFov - camera.FieldOfView) * a
			RunService.RenderStepped:Wait()
		end
		camera.CFrame = goal
	end
	camera.FieldOfView = savedFov
	camera.CameraType = savedCameraType
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

local function start(
	runId: string,
	cutsceneId: string,
	segKey: string,
	startTime: number,
	info: { [string]: any },
	localMode: boolean?
)
	local data = CutsceneLibrary.get(cutsceneId)
	if not data then
		warn("[CutsceneEngine] unknown cutscene " .. cutsceneId)
		return
	end
	local old = run
	if old then
		cleanup(old)
	end
	local runtime: Instance? = nil
	if localMode then
		runtime = ReplicatedStorage:WaitForChild("RigTemplates", 5)
	else
		local runtimeRoot = ReplicatedStorage:WaitForChild("CutsceneRuntime", 5)
		runtime = runtimeRoot and runtimeRoot:WaitForChild(runId, 5)
	end
	if not runtime then
		warn("[CutsceneEngine] actors for " .. runId .. " did not arrive")
		return
	end
	camera = workspace.CurrentCamera
	if not old then
		savedCameraType = camera.CameraType
		savedFov = camera.FieldOfView
	end
	camera.CameraType = Enum.CameraType.Scriptable
	setControls(false)
	Grade.begin()
	Grade.apply(data.grade, 0.8)
	if data.clockTime then
		Grade.setClock(data.clockTime, 0.8)
	end
	Overlay.letterbox(true)
	Overlay.setSkip(info.skippable == true)

	local registry = Actors.spawn(runtime :: Instance, data, clock, { models = info.models })
	local tokens = if typeof(info.tokens) == "table" then info.tokens else {}
	local r: Run = {
		runId = runId,
		data = data,
		segKey = segKey,
		seg = data.segments[segKey],
		segStart = startTime,
		shotIndex = 0,
		prevCf = camera.CFrame,
		prevFov = camera.FieldOfView,
		fired = {},
		registry = registry,
		props = {},
		tokens = tokens,
		finishedSent = false,
		hidden = {},
		hiddenGuis = {},
		hidePlayers = data.players ~= nil and data.players.mode == "hide",
		lastCf = camera.CFrame,
		localMode = localMode == true,
	}
	run = r
	spawnProps(r)
	hideNpcs(r)
	setSegment(r, segKey, startTime)
	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, update)
end

local function finish(runId: string, skipped: boolean)
	local r = run
	if not r or r.runId ~= runId then
		return
	end
	run = nil
	if skipped then
		VoiceService.stopAll()
		Overlay.fadeTo(BLACK, 1, 0.25)
		task.wait(0.3)
	end
	cleanup(r)
	MusicDirector.clearOverride(1.5)
	Overlay.setSkip(false)
	Grade.finish(1)
	Overlay.letterbox(false)
	local faded = Overlay.fadeOpacity() > 0
	if faded then
		Overlay.fadeTo(BLACK, 0, 0.8)
	end
	returnCamera(r.lastCf)
	setControls(true)
end

function CutsceneEngine.isPlaying(): boolean
	return run ~= nil
end

local localCounter = 0

export type LocalOptions = { models: { [string]: string }? }

--- Plays a cutscene only on this client (service cutscenes CS-DOWN / CS-DEAD / CS-REVIVE).
--- Ignored while a party cutscene is running.
function CutsceneEngine.playLocal(id: string, opts: LocalOptions?)
	if run and not run.localMode then
		return
	end
	localCounter += 1
	local o: LocalOptions = opts or {}
	task.spawn(
		start,
		"local_" .. localCounter,
		id,
		"main",
		clock() + 0.05,
		{ models = o.models, skippable = false },
		true
	)
end

function CutsceneEngine.finishLocal(runId: string)
	finish(runId, false)
end

function CutsceneEngine.init()
	Overlay.init()
	PoseAnimator.setEffectRunner(function(model: Model, kind: string, params: { [string]: any })
		local r = run
		local resolved = if r then resolveParams(r, params) else params
		Effects.run(kind, model, resolved)
	end)
	Overlay.onSkip(function()
		local r = run
		if r then
			Remotes.get(Remotes.Names.CutsceneSkip):FireServer(r.runId)
		end
	end)
	Remotes.get(Remotes.Names.CutsceneStart).OnClientEvent:Connect(start)
	Remotes.get(Remotes.Names.CutsceneSegment).OnClientEvent
		:Connect(function(runId: string, segKey: string, startTime: number, jumped: boolean?)
			local r = run
			if r and r.runId == runId then
				if jumped then
					VoiceService.stopAll() -- skipped ahead to the next choice
				end
				setSegment(r, segKey, startTime)
			end
		end)
	Remotes.get(Remotes.Names.CutsceneEnd).OnClientEvent:Connect(finish)
	Remotes.get(Remotes.Names.CutsceneSkipState).OnClientEvent
		:Connect(function(runId: string, votes: number, needed: number, allowed: boolean)
			local r = run
			if r and r.runId == runId then
				Overlay.setSkip(allowed, votes, needed)
			end
		end)
end

return CutsceneEngine
