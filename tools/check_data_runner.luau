-- Runner for tools/check_data.py (appended to the bundle). Prints PASS / FAIL lines.
local failures = 0
local checks = 0

local function check(ok: boolean, message: string)
	checks += 1
	if not ok then
		failures += 1
		print("FAIL " .. message)
	end
end

local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-6)
end

------------------------------------------------------------------ lookups
local lineById = {}
for _, l in ipairs(__lines) do
	check(lineById[l.id] == nil, "duplicate voice line " .. l.id)
	lineById[l.id] = l
	check(#l.text <= 300, l.id .. " longer than 300 characters")
	check(__VoiceSettings[l.speaker] ~= nil, l.id .. ": no VoiceSettings for speaker " .. tostring(l.speaker))
end

local function soundExists(name: string): boolean
	if __SoundIds[name] then
		return true
	end
	return __SoundIds[name .. "_1"] ~= nil
end

local function animExists(id: string): boolean
	return __anims[(string.gsub(id, "-", "_"))] ~= nil
end

local function checkPoint(where: string, p)
	if p == nil then
		return
	end
	if p.anchor then
		check(__Anchors.Defs[p.anchor] ~= nil, where .. ": unknown anchor " .. p.anchor)
	end
end

------------------------------------------------------------------ cutscenes
for id, cs in pairs(__cutscenes) do
	check(cs.id == id, id .. ": id field must equal the file name")
	check(cs.segments[cs.entry] ~= nil, id .. ": entry segment missing")
	local actorIds = {}
	for _, a in ipairs(cs.actors) do
		actorIds[a.id] = true
		check(string.sub(a.model, 1, 1) == "@" or __RigSpecs.characters[a.model] ~= nil, id .. ": actor model not in RigSpecs: " .. a.model)
		checkPoint(id .. " actor " .. a.id, a.at)
	end
	for _, prop in ipairs(cs.props or {}) do
		checkPoint(id .. " prop", prop.at)
	end
	if cs.players and cs.players.anchor then
		check(__Anchors.Defs[cs.players.anchor] ~= nil, id .. ": players anchor")
	end
	for key, seg in pairs(cs.segments) do
		local lastEnd = 0
		for _, shot in ipairs(seg.shots) do
			local where = string.format("%s/%s shot %s", id, key, shot.n)
			check(shot.t1 > shot.t0, where .. ": t1 <= t0")
			check(shot.t0 >= lastEnd - 1e-6, where .. ": overlaps the previous shot")
			lastEnd = shot.t1
			checkPoint(where .. " camera.from", shot.camera.from)
			checkPoint(where .. " camera.lookAt", shot.camera.lookAt)
			if shot.camera.lookAt.actor then
				check(actorIds[shot.camera.lookAt.actor] ~= nil, where .. ": camera looks at unknown actor")
			end
			for _, cue in ipairs(shot.cues or {}) do
				if cue.actor then
					check(actorIds[cue.actor] ~= nil, where .. ": unknown actor " .. cue.actor)
				end
				if cue.anim then
					check(animExists(cue.anim), where .. ": unknown animation " .. cue.anim)
				end
				if cue.tour and cue.tour.anim then
					check(animExists(cue.tour.anim), where .. ": unknown tour animation")
				end
				if cue.line then
					check(lineById[cue.line] ~= nil, where .. ": unknown voice line " .. cue.line)
				end
				if cue.sfx then
					check(soundExists(cue.sfx), where .. ": unknown sound " .. cue.sfx)
				end
				if cue.music and cue.music ~= "SILENCE" then
					check(soundExists(cue.music), where .. ": unknown music " .. cue.music)
				end
				if cue.effect then
					check(__effects[cue.effect] == true, where .. ": unknown effect " .. cue.effect)
				end
				if cue.at then
					check(cue.at >= 0 and cue.at <= shot.t1 - shot.t0, where .. ": cue time outside the shot")
				end
				checkPoint(where .. " moveTo", cue.moveTo)
				checkPoint(where .. " effectAt", cue.effectAt)
				if cue.effectParams and cue.effectParams.targetActor then
					check(actorIds[cue.effectParams.targetActor] ~= nil, where .. ": unknown effect target actor")
				end
			end
		end
		check(lastEnd <= seg.length + 1e-6, id .. "/" .. key .. ": shots run past the segment length")
		if seg.next then
			check(cs.segments[seg.next] ~= nil, id .. "/" .. key .. ": next segment missing")
		end
		if seg.vote then
			for _, o in ipairs(seg.vote.options) do
				if o.next then
					check(cs.segments[o.next] ~= nil, id .. ": vote option " .. o.id .. " -> missing segment")
				end
			end
		end
	end
	-- storyboard timing from cutscenes.md
	local expected = __expected[id]
	if expected then
		for _, e in ipairs(expected) do
			local seg = cs.segments[e.seg]
			local found = nil
			for _, shot in ipairs(seg and seg.shots or {}) do
				if shot.n == e.n then
					found = shot
				end
			end
			check(found ~= nil, string.format("%s: shot %s missing", id, e.n))
			if found then
				check(
					near(found.t0, e.t0) and near(found.t1, e.t1),
					string.format("%s shot %s: %g-%g, storyboard says %g-%g", id, e.n, found.t0, found.t1, e.t0, e.t1)
				)
			end
		end
	end
	print(string.format("cutscene %s checked", id))
end

------------------------------------------------------------------ animations
for name, a in pairs(__anims) do
	check(a.id == (string.gsub(name, "_", "-", 1)), name .. ": id does not match the file name")
	check(type(a.length) == "number" and a.length > 0, name .. ": bad length")
	for joint, keys in pairs(a.tracks) do
		for _, k in ipairs(keys) do
			check(k.t >= 0 and k.t <= a.length + 1e-6, name .. "/" .. joint .. ": key outside the length")
		end
	end
	if a.effect then
		check(__effects[a.effect.kind] == true, name .. ": unknown effect " .. a.effect.kind)
	end
end

------------------------------------------------------------------ PoseMath / PoseMixer unit tests
local PM = __PoseMath
check(PM.ease(nil, 0) == 0 and PM.ease(nil, 1) == 1, "ease endpoints")
check(near(PM.ease("SineInOut", 0.5), 0.5), "SineInOut midpoint")
check(near(PM.ease("QuadOut", 0.5), 0.75), "QuadOut midpoint")
check(near(PM.lerpAngle(350, 10, 0.5), 360), "lerpAngle wraps the short way")
check(near(PM.lerpAngle(720, 0, 0.5) % 360, 0), "720 -> 0 does not spin")
local track = PM.normalizeTrack({ { t = 1, rot = { 90, 0, 0 } }, { t = 0, pos = { 0, 1, 0 } } })
check(track[1].t == 0 and track[2].pos[2] == 1, "normalizeTrack sorts and carries values")
local t, done = PM.localTime(6, true, 13)
check(near(t, 1) and not done, "looping localTime")
t, done = PM.localTime(3, false, 5)
check(t == 3 and done, "one-shot localTime clamps")

local function loader(id)
	local data = __anims[(string.gsub(id, "-", "_"))]
	local tracks = {}
	for j, keys in pairs(data.tracks) do
		tracks[j] = PM.normalizeTrack(keys)
	end
	return { data = data, tracks = tracks, scale = data.scale }
end
local now = 0
local names = {}
for _, j in ipairs(__RigSpecs.skeleton.joints) do
	table.insert(names, j.name)
end
local mixer = __PoseMixer.new(names, loader, function()
	return now
end)
-- CS-05 timeline: dance, tired from 5.3, slow stop at 12 -> she must end facing forward
mixer:play("A-BALLERINA_DANCE", { startClock = 0 })
for step = 0, 5.3 * 60 do
	now = step / 60
	mixer:step()
end
mixer:play("A-BALLERINA_DANCE", { startClock = 5.3, speed = 0.8 })
while now < 12 do
	now += 1 / 60
	mixer:step()
end
mixer:play("A-BALLERINA_SLOW_STOP", { startClock = 12 })
while now < 15.05 do
	now += 1 / 60
	mixer:step()
end
local poses = mixer:step()
check(near(poses.Root.rot[2] % 360, 0, 0.5), "slow stop ends facing forward (yaw " .. poses.Root.rot[2] .. ")")
-- speed change keeps the position
local m2 = __PoseMixer.new(names, loader, function()
	return now
end)
now = 0
m2:play("A-BALLERINA_DANCE", { startClock = 0 })
now = 2
local before = m2:step().Root.rot[2]
m2:play("A-BALLERINA_DANCE", { speed = 0.5 })
local after = m2:step().Root.rot[2]
check(near(before, after, 1e-3), "changing speed does not jump")

------------------------------------------------------------------ dialogues
for name, d in pairs(__dialogues) do
	check(d.id == name, name .. ": dialogue id must equal the file name")
	check(d.nodes[d.start] ~= nil, name .. ": start node missing")
	for key, node in pairs(d.nodes) do
		for _, lineId in ipairs(node.lines or {}) do
			check(lineById[lineId] ~= nil, name .. "/" .. key .. ": unknown line " .. lineId)
		end
		if node.next then
			check(d.nodes[node.next] ~= nil, name .. "/" .. key .. ": next node missing " .. node.next)
		end
		for _, c in ipairs(node.choices or {}) do
			if c.next then
				check(d.nodes[c.next] ~= nil, name .. "/" .. key .. ": choice " .. c.id .. " -> missing node " .. c.next)
			end
		end
	end
	print("dialogue " .. name .. " checked")
end

print(string.format("%d checks, %d failures", checks, failures))
if failures > 0 then
	print("FAIL")
else
	print("PASS")
end

