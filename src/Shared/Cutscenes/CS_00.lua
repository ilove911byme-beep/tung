--!strict
-- CS-00 "The Tunnel" (lock, ~14 s), cutscenes.md: lobby -> loading. The minecarts with the
-- party (stand-ins) leave the "Last Stop" platform, roll into the black tunnel while the wall
-- lamps go out one by one, far ahead a tiny yellow dot blinks, fade to black -> the loading
-- screen where Giallino "loads" ("Hi, [Name]. :)" for one frame at 100 %). Plays in the Lobby
-- place: Anchor_Lobby_Platform (x 20, z 20) and the tunnel mouth at x 48 (world blocks).
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local RAIL_Z = 20
local START_X = { 20, 18.4, 16.8 }
local ROLL_X = { 27, 25.4, 23.8 }
local TUNNEL_X = { 52, 50.4, 48.8 }
local DEEP_X = { 62, 60.4, 58.8 }

local function cartId(i: number): string
	return "Cart" .. i
end

local actors: { Types.ActorSpec } = {
	Kit.actor({
		id = "Dot",
		model = "Giallino",
		at = B(78, 13.4, RAIL_Z, 270),
		face = "off",
		visible = false,
	}),
}
for i = 1, 3 do
	local cart: Types.ActorSpec = {
		id = cartId(i),
		model = "Minecart",
		at = B(START_X[i], 12, RAIL_Z, 90),
		footsteps = false,
	}
	table.insert(actors, cart)
end
for _, r in
	Kit.standIns(Kit.MAX_PLAYERS, function(i)
		return B(START_X[math.floor((i - 1) / 2) + 1], 12, RAIL_Z, 90)
	end, function(i)
		return {
			actor = cartId(math.floor((i - 1) / 2) + 1),
			offset = Vector3.new(0, 1.6, if i % 2 == 0 then 1.2 else -1.2),
		}
	end)
do
	table.insert(actors, r)
end

local function cartMoves(xs: { number }, time: number, easing: Types.EasingName): { Types.Cue }
	local out: { Types.Cue } = {}
	for i = 1, 3 do
		table.insert(
			out,
			cue({
				actor = cartId(i),
				moveTo = B(xs[i], 12, RAIL_Z, 90),
				moveTime = time,
				moveEasing = easing,
			})
		)
	end
	return out
end

local data: Types.Cutscene = {
	id = "CS_00",
	title = "The Tunnel",
	noSkip = true,
	grade = "DUSK",
	clockTime = 17.4,
	actors = actors,
	players = { mode = "hide" },
	entry = "main",
	segments = {
		main = {
			length = 14,
			shots = {
				shot({
					-- WIDE, static, beside the rails: the carts start, the safety bars click shut
					n = "1",
					t0 = 0,
					t1 = 3,
					camera = {
						shot = "WIDE",
						from = B(26, 15, 28),
						lookAt = B(20, 13, RAIL_Z),
						fov = 60,
					},
					cues = Kit.cues(
						{
							cue({ music = "SILENCE", musicFade = 1 }),
							cue({ at = 0.2, sfx = "lever_click", sfxVolume = 0.8 }),
							cue({ at = 0.5, sfx = "lever_click", sfxVolume = 0.8, sfxSpeed = 0.9 }),
							cue({ at = 0.9, sfx = "amb_minecart_loop", sfxVolume = 0.6 }),
						},
						Kit.forPlayers(Kit.MAX_PLAYERS, function()
							return cue({ anim = "A-SIT_CART" })
						end),
						cartMoves(ROLL_X, 3, "QuadIn")
					),
				}),
				shot({
					-- MED, DOLLY IN behind the carts: into the black tunnel, the wall lamps go out
					n = "2",
					t0 = 3,
					t1 = 7,
					grade = "NIGHT_DEEP",
					gradeTime = 3.5,
					camera = {
						shot = "MED",
						from = B(22, 14.3, RAIL_Z + 0.4),
						lookAt = B(40, 13.2, RAIL_Z),
						fov = 55,
						moves = { move({ kind = "DOLLY_IN", amount = 0.35 }) },
					},
					cues = Kit.cues({
						cue({
							at = 0.8,
							world = "lightsOut",
							worldParams = { tag = "TunnelLamp", stagger = 0.3 },
						}),
					}, cartMoves(TUNNEL_X, 4, "Linear")),
				}),
				shot({
					-- POV from the cart: darkness, far ahead a tiny yellow dot blinks
					n = "3",
					t0 = 7,
					t1 = 10,
					camera = {
						shot = "POV",
						from = { actor = "Cart1", offset = Vector3.new(0, 4.4, -1.6) },
						lookAt = B(78, 13.4, RAIL_Z),
						fov = 50,
						moves = { move({ kind = "HANDHELD", amount = 0.05 }) },
					},
					transitionOut = { kind = "FADE_BLACK", seconds = 1 },
					cues = Kit.cues({
						cue({ actor = "Dot", light = { glow = 3 } }),
						cue({ at = 0.4, actor = "Dot", visible = true }),
						cue({ at = 0.7, actor = "Dot", visible = false }),
						cue({ at = 1.1, actor = "Dot", visible = true }),
						cue({ at = 1.3, sfx = "glitch_burst", sfxVolume = 0.2 }),
						cue({ at = 1.5, actor = "Dot", visible = false }),
						cue({ at = 2.0, actor = "Dot", visible = true }),
					}, cartMoves(DEEP_X, 3, "Linear")),
				}),
				shot({
					-- black -> the loading screen: Giallino loads in the middle; at 100 %:
					-- "Hi, [Name]. :)" for one frame
					n = "4",
					t0 = 10,
					t1 = 14,
					camera = {
						shot = "WIDE",
						from = B(60, 14, RAIL_Z),
						lookAt = B(80, 14, RAIL_Z),
						fov = 50,
					},
					transitionIn = { kind = "FADE_BLACK", seconds = 60 },
					cues = {
						cue({
							world = "loadingScreen",
							worldParams = { duration = 3.6, greet = true },
						}),
					},
				}),
			},
		},
	},
}

return data
