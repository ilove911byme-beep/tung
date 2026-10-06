--!strict
-- CS-01 "The Valley" (lock, ~32 s), cutscenes.md. The minecarts burst out of the tunnel into the
-- sunset, the camera flies over the valley, the carts brake at the village station and the
-- lantern at the end of the rails lights up yellow by itself. Players ride as stand-ins
-- (@Player1..6) seated in three carts. Coordinates are world blocks (map.md).
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local RAIL_Z = 80.5
local START_X = { 16, 14.4, 12.8 } -- inside the tunnel
local OUT_X = { 30, 28.4, 26.8 }
local NEAR_X = { 44, 42.4, 40.8 }
local STOP_X = { 51, 49.4, 47.8 }

local function cartId(i: number): string
	return "Cart" .. i
end

local carts: { Types.ActorSpec } = {}
for i = 1, 3 do
	local cart: Types.ActorSpec = {
		id = cartId(i),
		model = "Minecart",
		at = B(START_X[i], 12, RAIL_Z, 90),
		footsteps = false,
	}
	table.insert(carts, cart)
end

-- two riders per cart, front and back seat
local function seat(i: number): Types.RideSpec
	local cart = math.floor((i - 1) / 2) + 1
	local back = (i % 2 == 0)
	return { actor = cartId(cart), offset = Vector3.new(0, 1.6, if back then 1.2 else -1.2) }
end

local riders = Kit.standIns(Kit.MAX_PLAYERS, function(i)
	local cart = math.floor((i - 1) / 2) + 1
	return B(START_X[cart], 12, RAIL_Z, 90)
end, seat)

local actors: { Types.ActorSpec } = {
	Kit.actor({ id = "Tralalero", model = "Tralalero", at = B(74, 12, 96, 90), face = "happy" }),
	Kit.actor({
		id = "Chimpanzini",
		model = "Chimpanzini",
		at = B(69.5, 12, 87.4, 0),
		face = "neutral",
	}),
}
for _, c in carts do
	table.insert(actors, c)
end
for _, r in riders do
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
	id = "CS_01",
	title = "The Valley",
	noSkip = true,
	grade = "DUSK",
	clockTime = 17.6,
	actors = actors,
	players = { mode = "hide" },
	hideNpcs = { "Tralalero", "Chimpanzini" },
	entry = "main",
	segments = {
		main = {
			length = 32,
			shots = {
				shot({
					-- WIDE, static, beside the rails at the tunnel mouth: the carts burst into the light
					n = "1",
					t0 = 0,
					t1 = 4,
					camera = {
						shot = "WIDE",
						from = B(30, 15, 88),
						lookAt = B(24, 13, RAIL_Z),
						fov = 62,
					},
					transitionIn = { kind = "FADE_WHITE", seconds = 0.9 },
					cues = Kit.cues(
						{ cue({ music = "dusk_piano_theme", musicFade = 0.5, musicVolume = 0.55 }) },
						Kit.forPlayers(Kit.MAX_PLAYERS, function()
							return cue({ anim = "A-SIT_CART" })
						end),
						cartMoves(OUT_X, 4, "QuadOut")
					),
				}),
				shot({
					-- CRANE UP + ORBIT over the valley: river, Patapim's forest, village, clock tower
					n = "2",
					t0 = 4,
					t1 = 14,
					camera = {
						shot = "WIDE",
						from = B(80, 30, 132),
						lookAt = B(80, 16, 84),
						fov = 60,
						moves = {
							move({ kind = "ORBIT", angle = 110, easing = "SineInOut" }),
							move({ kind = "CRANE_UP", amount = 50, easing = "SineInOut" }),
						},
					},
					transitionIn = { kind = "BLEND", seconds = 0.8 },
					cues = Kit.cues(
						{ cue({ at = 1.0, line = "CS01_NARR_1" }) },
						cartMoves(NEAR_X, 19, "Linear")
					),
				}),
				shot({
					-- WIDE, PAN R over the village: Tralalero runs about, Chimpanzini opens his shop,
					-- the long sahur table on the square has far too many empty chairs
					n = "3",
					t0 = 14,
					t1 = 19,
					camera = {
						shot = "WIDE",
						from = B(96, 22, 98),
						lookAt = B(78, 13, 84),
						fov = 58,
						moves = { move({ kind = "PAN_R", angle = 35 }) },
					},
					cues = {
						cue({ actor = "Tralalero", anim = "A-RUN" }),
						cue({
							actor = "Tralalero",
							moveTo = B(90, 12, 96, 90),
							moveTime = 5,
							moveEasing = "Linear",
						}),
						cue({ at = 0.5, actor = "Chimpanzini", anim = "A-STAND_STRETCH" }),
						cue({ at = 0.8, line = "CS01_NARR_2" }),
					},
				}),
				shot({
					-- CLOSE on an empty chair: the name sign "Ballerina Cappuccina", still bright
					n = "4",
					t0 = 19,
					t1 = 23,
					camera = {
						shot = "CLOSE",
						from = B(75.6, 13.4, 79.4),
						lookAt = B(78.0, 13.05, 79.2),
						fov = 38,
						moves = { move({ kind = "DOLLY_IN", amount = 0.18 }) },
					},
					cues = { cue({ at = 0.6, line = "CS01_NARR_3" }) },
				}),
				shot({
					-- MED: the carts brake at the village station, the players stand up and stretch
					n = "5",
					t0 = 23,
					t1 = 27,
					camera = {
						shot = "MED",
						from = B(57, 14.2, 86),
						lookAt = B(49.5, 13, RAIL_Z),
						fov = 55,
					},
					cues = Kit.cues(
						cartMoves(STOP_X, 2.4, "QuadOut"),
						{ cue({ sfx = "door_open", sfxVolume = 0.5, sfxSpeed = 1.8 }) }, -- brakes squeal
						Kit.forPlayers(Kit.MAX_PLAYERS, function(i)
							local cart = math.floor((i - 1) / 2) + 1
							local back = i % 2 == 0
							return cue({
								at = 2.5,
								dismount = true,
								stopAnim = "A-SIT_CART",
								moveTo = B(
									STOP_X[cart] + (if back then -0.3 else 0.3),
									12.3,
									RAIL_Z,
									90
								),
								moveTime = 0.5,
							})
						end),
						Kit.forPlayers(Kit.MAX_PLAYERS, function()
							return cue({ at = 2.7, anim = "A-STAND_STRETCH" })
						end)
					),
				}),
				shot({
					-- ECU on the empty lantern at the end of the rails -> RACK onto the yellow glow:
					-- it lights up by itself. It is not fire.
					n = "6",
					t0 = 27,
					t1 = 32,
					camera = {
						shot = "ECU",
						from = B(53.2, 13.5, 79.3),
						lookAt = B(54.5, 13.35, 80.5),
						fov = 34,
						rack = {
							from = B(54.5, 13.35, 80.5),
							to = B(57, 14, 82.5),
							at = 1.8,
							time = 1.4,
						},
					},
					cues = {
						cue({
							at = 1.2,
							world = "lightsOn",
							worldParams = { tag = "StationLantern" },
						}),
						cue({ at = 1.4, sfx = "giallino_boot", sfxVolume = 0.25 }),
						cue({ at = 3.5, music = "SILENCE", musicFade = 3 }),
					},
				}),
			},
		},
	},
}

return data
