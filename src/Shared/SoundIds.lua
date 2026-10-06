--!strict
-- One entry per file in assets/audio/. Upload the file to Roblox (Creator Hub -> Audio) and
-- replace the matching "rbxassetid://0". Until then the Audio helper skips that sound
-- (and warns once in Studio). Sets named name_1..name_4 are picked at random by Audio.
local P = "rbxassetid://0" -- placeholder

local SoundIds: { [string]: string } = {
	---------------------------------------------------------------- audio/music (13)
	music_lobby = P, -- main menu + lobby station
	music_day_village = P, -- daytime village, Ch1 and Ch3
	music_night = P, -- night gameplay, Ch2 and Ch4
	music_investigation = P, -- clue hunting, Ch3
	music_chase = P, -- every chase (Ch1 fog run, Ch4 chase, Ch5 minecarts)
	music_boss = P, -- Falsino / Negatino / Crudelino fights
	music_cave = P, -- mineshaft, Ch5
	music_lullaby_box = P, -- Giallino's theme; CS-05 shots 1-5, CS-E3 from shot 5
	music_lullaby_stop = P, -- one-shot that slows and stops; CS-05 shot 6
	music_flashback = P, -- CS-16 part B
	music_tragic = P, -- CS-06, CS-09, CS-12, CS-14, CS-18, CS-21
	music_finale = P, -- Ch6 Giallino Totale
	music_ending_dawn = P, -- one-shot; endings Dawn and Sahur

	---------------------------------------------------------------- audio/sfx (26)
	knock_tung_x3 = P, -- Tung Tung's three knocks (CS-04, CS-12, lobby teaser)
	tung_chant_rhythm = P, -- Tung Tung intro chant bed
	giallino_boot = P, -- Giallino appears (CS-01, CS-02, CS-REVIVE, loading screen)
	giallino_blip_1 = P, -- Giallino typewriter blips (mood >= 40)
	giallino_blip_2 = P,
	giallino_blip_3 = P,
	giallino_blip_4 = P,
	giallino_blip_5 = P,
	giallino_blip_broken_1 = P, -- Giallino typewriter blips (mood < 40)
	giallino_blip_broken_2 = P,
	giallino_blip_broken_3 = P,
	giallino_mood_drop = P, -- hidden mood drop (CS-02 shot 7b, CS-09N)
	falsino_signature = P, -- Falsino appears (CS-07, boss card)
	negatino_signature = P, -- Negatino appears (CS-10, CS-11 reversed, boss card)
	crudelino_signature = P, -- Crudelino appears (CS-17, CS-18, boss card)
	glitch_burst = P, -- GLITCH CUT, CS-05 shot 8 (stretched), main menu title glitch
	jumpscare_stinger = P, -- CS-04A shot 3
	clue_found = P, -- clue picked up, CS-11 relief
	item_pickup = P, -- inventory pickup, menu click
	vote_tick = P, -- vote timer ticks, menu hover
	clock_time_stop = P, -- Lirili's time stop (CS-16, CS-22)
	ending_dawn = P, -- ending sting (CS-E1)
	dusk_piano_theme = P, -- dusk music state (CS-01, CS-03)
	ambience_night_loop = P, -- night outdoors bed
	ambience_cave_loop = P, -- mineshaft bed (CS-15 on)
	heartbeat_loop = P, -- threat proximity (CS-10, CS-13, CS-20)

	---------------------------------------------------------------- audio/world (58)
	step_grass_1 = P, -- footsteps on grass and dirt
	step_grass_2 = P,
	step_grass_3 = P,
	step_grass_4 = P,
	step_stone_1 = P, -- footsteps on stone, cobblestone, bricks
	step_stone_2 = P,
	step_stone_3 = P,
	step_stone_4 = P,
	step_wood_1 = P, -- footsteps on planks and logs
	step_wood_2 = P,
	step_wood_3 = P,
	step_wood_4 = P,
	step_gravel_1 = P, -- footsteps on gravel and dirt path
	step_gravel_2 = P,
	step_gravel_3 = P,
	step_gravel_4 = P,
	step_sand_1 = P, -- footsteps on sand
	step_sand_2 = P,
	step_sand_3 = P,
	step_sand_4 = P,
	block_break_dirt = P, -- block breaking (Crudelino, WallBreak)
	block_break_stone = P,
	block_break_wood = P, -- chopping wood (Ch1)
	block_break_glass = P,
	block_break_leaves = P,
	block_place_dirt = P, -- block placing (RootsBridge, building)
	block_place_stone = P,
	block_place_wood = P,
	block_place_glass = P,
	block_place_leaves = P,
	door_open = P,
	door_close = P,
	chest_open = P,
	lever_click = P, -- Ch5 lever room
	button_click = P,
	torch_ignite = P, -- braziers (Ch4)
	water_splash = P, -- falling into water
	village_bell = P, -- clock tower bell (CS-03)
	explosion_boom = P, -- Bombardiro bombs
	player_hurt = P, -- taking damage
	xp_orb_pickup = P, -- small pickups, Memory Pages
	npc_hum_neutral = P, -- before villager TTS lines
	npc_hum_question = P,
	npc_hum_no = P,
	npc_hum_happy = P,
	cave_eerie_1 = P, -- random mineshaft one-shots every 40-90 s
	cave_eerie_2 = P,
	cave_eerie_3 = P,
	cave_eerie_4 = P,
	owl_hoot = P, -- random night one-shot every 25-60 s
	amb_birds_loop = P, -- day outdoors
	amb_crickets_loop = P, -- night outdoors
	amb_wind_loop = P, -- day outdoors (quiet), hills (louder)
	amb_rain_loop = P, -- optional rain, second night (Ch4)
	amb_water_stream_loop = P, -- 3D on river parts
	amb_fireplace_loop = P, -- 3D at the tavern fireplace
	amb_lava_loop = P, -- lava cave (Ch5)
	amb_minecart_loop = P, -- minecart rides
}

return SoundIds
