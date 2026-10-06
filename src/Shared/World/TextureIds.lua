--!strict
-- Roblox asset ids of our own block textures (assets/textures/*.png, map.md section 2).
-- Upload each PNG (Creator Hub -> Decals) and paste "rbxassetid://<id>" here. While an id is
-- empty the MapBuilder uses the fallback material + color from Shared/World/Blocks, so the map
-- always looks complete. Every face gets a Texture with StudsPerTileU/V = 4 (one block).
return {
	bricks = "", -- assets/textures/bricks.png
	coal_ore = "", -- assets/textures/coal_ore.png
	cobblestone = "", -- assets/textures/cobblestone.png
	dirt = "", -- assets/textures/dirt.png
	dirt_path = "", -- assets/textures/dirt_path.png
	glass = "", -- assets/textures/glass.png
	glowstone_ore = "", -- assets/textures/glowstone_ore.png
	gold_ore = "", -- assets/textures/gold_ore.png
	grass_side = "", -- assets/textures/grass_side.png
	grass_top = "", -- assets/textures/grass_top.png
	gravel = "", -- assets/textures/gravel.png
	hay_side = "", -- assets/textures/hay_side.png
	iron_ore = "", -- assets/textures/iron_ore.png
	lava = "", -- assets/textures/lava.png
	leaves = "", -- assets/textures/leaves.png
	mossy_cobblestone = "", -- assets/textures/mossy_cobblestone.png
	oak_log_side = "", -- assets/textures/oak_log_side.png
	oak_log_top = "", -- assets/textures/oak_log_top.png
	oak_planks = "", -- assets/textures/oak_planks.png
	pale_log_side = "", -- assets/textures/pale_log_side.png
	sand = "", -- assets/textures/sand.png
	stone = "", -- assets/textures/stone.png
	water = "", -- assets/textures/water.png
	wool_red = "", -- assets/textures/wool_red.png
} :: { [string]: string }
