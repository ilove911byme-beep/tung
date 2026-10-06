--!strict
-- CS-E2 "ENDLESS NIGHT" (the bad ending, ~30 s), cutscenes.md: Giallino's huge happy face fills
-- the screen ("You stayed!"), white -> black and a minecart rattles; CS-00 again but the tunnel
-- lamps are yellow and square; the loading screen - but Giallino is already loaded to 100 % and
-- looks straight at you: "Welcome back, friends!" -> credits.
local Kit = require(script.Parent.Parent.CutsceneKit)
local Types = require(script.Parent.Parent.Types)

local cue, shot, move, B = Kit.cue, Kit.shot, Kit.move, Kit.B

local RAIL_Z = 80.5
local START_X = { 47, 48.6, 50.2 }
local MOUTH_X = { 26, 27.6, 29.2 }
local DEEP_X = { 8, 9.6, 11.2 }

local function cartId(i: number): string
	return "Cart" .. i
end

local actors: { Types.ActorSpec } = {
	Kit.actor({ id = "Giallino", model = "Giallino", at = B(80, 47, 71.5, 0), face = "happy" }),
}
for i = 1, 3 do
	local cart: Types.ActorSpec = {
		id = cartId(i),
		model = "Minecart",
		at = B(START_X[i], 12, RAIL_Z, 270),
		footsteps = false,
	}
	table.insert(actors, cart)
end
for _, r in
	Kit.standIns(Kit.MAX_PLAYERS, function(i)
		return B(START_X[math.floor((i - 1) / 2) + 1], 12, RAIL_Z, 270)
	end, function(i)
		return {
			actor = cartId(math.floor((i - 1) / 2) + 1),
			offset = Vector3.new(0, 1.6, if i % 2 == 0 then 1.2 else -1.2),
		}
	end)
do
	table.insert(actors, r)
end

local function cartMoves(xs: { number }, time: number): { Types.Cue }
	local out: { Types.Cue } = {}
	for i = 1, 3 do
		table.insert(
			out,
			cue({
				actor = cartId(i),
				moveTo = B(xs[i], 12, RAIL_Z, 270),
				moveTime = time,
				moveEasing = "Linear",
			})
		)
	end
	return out
end

local data: Types.Cutscene = {
	id = "CS_E2",
	title = "Endless Night",
	noSkip = false,
	grade = "NIGHT_DEEP",
	clockTime = 5,
	actors = actors,
	players = { mode = "hide" },
	hideNpcs = { "Giallino" },
	entry = "main",
	segments = {
		main = {
			length = 30,
			shots = {
				shot({
					-- CLOSE: Giallino, huge, his happy face fills the screen
					n = "1",
					t0 = 0,
					t1 = 6,
					camera = {
						shot = "CLOSE",
						from = { actor = "Giallino", offset = Vector3.new(0, 0, -34) },
						lookAt = { actor = "Giallino" },
						fov = 50,
					},
					cues = {
						cue({ actor = "Giallino", anim = "A-SCALE_6" }),
						cue({ actor = "Giallino", light = { glow = 5 } }),
						cue({ at = 0.5, line = "E2_GIALLINO_STAYED" }),
					},
					transitionOut = { kind = "FADE_WHITE", seconds = 1 },
				}),
				shot({
					-- white -> black; the rattle of a minecart
					n = "2",
					t0 = 6,
					t1 = 10,
					grade = "DUSK",
					gradeTime = 0.1,
					transitionIn = { kind = "FADE_BLACK", seconds = 60 },
					camera = {
						shot = "WIDE",
						from = B(52, 14, 86),
						lookAt = B(48, 13, RAIL_Z),
						fov = 60,
					},
					cues = Kit.cues(
						{
							cue({ sfx = "amb_minecart_loop", sfxVolume = 0.8 }),
							cue({ clockTo = 17.4, clockTime = 0.05 }),
						},
						Kit.forPlayers(Kit.MAX_PLAYERS, function()
							return cue({ anim = "A-SIT_CART" })
						end)
					),
				}),
				shot({
					-- CS-00 again: the carts roll off into the tunnel... but the tunnel lamps are yellow and square
					n = "3a",
					t0 = 10,
					t1 = 15,
					camera = {
						shot = "WIDE",
						from = B(40, 15, 88),
						lookAt = B(44, 13, RAIL_Z),
						fov = 60,
					},
					cues = Kit.cues({
						cue({ world = "tunnelLamps", worldParams = { duration = 22 } }),
						cue({ sfx = "lever_click", sfxVolume = 0.8 }),
					}, cartMoves(MOUTH_X, 5)),
				}),
				shot({
					-- inside the tunnel: yellow squares slide past
					n = "3b",
					t0 = 15,
					t1 = 20,
					grade = "NIGHT_DEEP",
					gradeTime = 2,
					camera = {
						shot = "POV",
						from = { actor = "Cart1", offset = Vector3.new(0, 4.4, -1.6) },
						lookAt = B(0, 14, RAIL_Z),
						fov = 55,
						moves = { move({ kind = "HANDHELD", amount = 0.05 }) },
					},
					transitionOut = { kind = "FADE_BLACK", seconds = 1 },
					cues = Kit.cues(
						{ cue({ at = 3.5, sfx = "glitch_burst", sfxVolume = 0.3 }) },
						cartMoves(DEEP_X, 5)
					),
				}),
				shot({
					-- the loading screen - but Giallino is already loaded to 100 % and looks right at you
					n = "4",
					t0 = 20,
					t1 = 30,
					transitionIn = { kind = "FADE_BLACK", seconds = 60 },
					camera = {
						shot = "WIDE",
						from = B(10, 14, RAIL_Z),
						lookAt = B(0, 14, RAIL_Z),
						fov = 50,
					},
					cues = {
						cue({
							world = "loadingScreen",
							worldParams = { duration = 10.5, stare = true },
						}),
						cue({ at = 1.5, line = "E2_GIALLINO_WELCOME" }),
					},
				}),
			},
		},
	},
}

return data
