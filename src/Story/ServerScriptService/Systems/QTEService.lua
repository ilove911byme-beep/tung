--!strict
-- Quick-time events (brief, gameplay system 17). Works on PC (keys), mobile (big buttons) and
-- gamepad; the client shows the prompt and reports the result.
--   tap    : press the button `presses` times within `duration`
--   hold   : hold-breath: keep the marker inside the green zone (hold to raise, release to fall)
--   choice : press the right direction ("left" | "right" | "duck") within `window`
--   party  : shared bar for the whole party, everyone taps, it drains over time
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))
local Remotes = require(Shared:WaitForChild("Remotes"))

export type Spec = {
	type: "tap" | "hold" | "choice" | "party",
	duration: number?,
	presses: number?,
	answer: string?,
	window: number?,
	label: string?,
	perTap: number?,
	drain: number?,
}

type Active = {
	id: string,
	spec: Spec,
	players: { [Player]: boolean },
	results: { [Player]: boolean },
	progress: number,
	done: BindableEvent,
	closed: boolean,
}

local QTEService = {}

local active: { [string]: Active } = {}
local counter = 0
local resultLimiter = RateLimiter.new(0.05)
local tapLimiter = RateLimiter.new(1 / 15)

local function remaining(q: Active): boolean
	for p in q.players do
		if p.Parent and q.results[p] == nil then
			return true
		end
	end
	return false
end

local function finish(q: Active)
	if q.closed then
		return
	end
	q.closed = true
	q.done:Fire()
end

--- Runs a QTE for these players and yields. Returns success per player.
function QTEService.run(players: { Player }, spec: Spec): { [Player]: boolean }
	counter += 1
	local q: Active = {
		id = "qte" .. counter,
		spec = spec,
		players = {},
		results = {},
		progress = 0,
		done = Instance.new("BindableEvent"),
		closed = false,
	}
	local list = {}
	for _, p in players do
		if p.Parent and p:GetAttribute("LifeState") ~= "Dead" then
			q.players[p] = true
			table.insert(list, p)
		end
	end
	if #list == 0 then
		return {}
	end
	active[q.id] = q
	local duration = spec.duration or spec.window or 4
	local remote = Remotes.get(Remotes.Names.QTEStart)
	for _, p in list do
		remote:FireClient(p, q.id, spec, workspace:GetServerTimeNow() + duration)
	end
	local timer = task.delay(duration + 1.0, function()
		finish(q)
	end)
	q.done.Event:Wait()
	task.cancel(timer)
	active[q.id] = nil
	local results: { [Player]: boolean } = {}
	for _, p in list do
		results[p] = q.results[p] == true
	end
	local endRemote = Remotes.get(Remotes.Names.QTEEnd)
	for _, p in list do
		endRemote:FireClient(p, q.id, results[p])
	end
	q.done:Destroy()
	return results
end

--- Shared party bar: returns true if the bar reached 100 % before `duration` ran out.
function QTEService.party(players: { Player }, spec: Spec): boolean
	counter += 1
	local q: Active = {
		id = "qte" .. counter,
		spec = spec,
		players = {},
		results = {},
		progress = 0,
		done = Instance.new("BindableEvent"),
		closed = false,
	}
	local list = {}
	for _, p in players do
		if p.Parent and p:GetAttribute("LifeState") ~= "Dead" then
			q.players[p] = true
			table.insert(list, p)
		end
	end
	if #list == 0 then
		return false
	end
	active[q.id] = q
	local duration = spec.duration or 30
	local endsAt = workspace:GetServerTimeNow() + duration
	local start = Remotes.get(Remotes.Names.QTEStart)
	for _, p in list do
		start:FireClient(p, q.id, spec, endsAt)
	end
	local progressRemote = Remotes.get(Remotes.Names.QTEProgress)
	local drain = spec.drain or 0.06
	local success = false
	while not q.closed and workspace:GetServerTimeNow() < endsAt do
		local dt = task.wait(0.1)
		q.progress = math.max(0, q.progress - drain * dt)
		for _, p in list do
			progressRemote:FireClient(p, q.id, q.progress)
		end
		if q.progress >= 1 then
			success = true
			break
		end
	end
	q.closed = true
	active[q.id] = nil
	local endRemote = Remotes.get(Remotes.Names.QTEEnd)
	for _, p in list do
		endRemote:FireClient(p, q.id, success)
	end
	q.done:Destroy()
	return success
end

--- Closes every running QTE (party wipe / restart).
function QTEService.cancelAll()
	for _, q in active do
		finish(q)
	end
end

function QTEService.init()
	Remotes.get(Remotes.Names.QTEResult).OnServerEvent
		:Connect(function(player: Player, id: unknown, success: unknown)
			if
				typeof(id) ~= "string"
				or typeof(success) ~= "boolean"
				or not resultLimiter:allow(player)
			then
				return
			end
			local q = active[id]
			if
				not q
				or q.closed
				or not q.players[player]
				or q.results[player] ~= nil
				or q.spec.type == "party"
			then
				return
			end
			q.results[player] = success
			if not remaining(q) then
				finish(q)
			end
		end)
	Remotes.get(Remotes.Names.QTETap).OnServerEvent:Connect(function(player: Player, id: unknown)
		if typeof(id) ~= "string" or not tapLimiter:allow(player) then
			return
		end
		local q = active[id]
		if not q or q.closed or q.spec.type ~= "party" or not q.players[player] then
			return
		end
		local n = 0
		for _ in q.players do
			n += 1
		end
		q.progress = math.min(1, q.progress + (q.spec.perTap or 0.012) * 3 / math.max(n, 1) ^ 0.5)
	end)
	Players.PlayerRemoving:Connect(function(p)
		for _, q in active do
			q.players[p] = nil
			if not q.closed and q.spec.type ~= "party" and not remaining(q) then
				finish(q)
			end
		end
	end)
end

return QTEService
