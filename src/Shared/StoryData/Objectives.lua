--!strict
-- Objective texts shown in the HUD. Story content, so it lives here and not in Strings.
-- %d / %s are filled by the chapter scripts (counts, names).
local Objectives: { [string]: string } = {
	-- Chapter 1
	C1_TUTORIAL = "Collect wood (%d/6), buy a lantern from Chimpanzini, find bread",
	C1_WOOD = "Collect wood (%d/6)",
	C1_LANTERN = "Buy a lantern from Chimpanzini Bananini",
	C1_BREAD = "Find a piece of bread",
	C1_APPLE = "Get the apple from the tall tree",
	C1_RUN_INN = "Get to the inn before dark (%d s)",
	C1_ENTER_INN = "Go inside the inn",
	-- Chapter 2
	C2_CHOICE = "The knocking...",
	C2_HIDE = "Hide! (%d s)",
	C2_BARRICADE = "Drag the crates to the door!",
	C2_FIRE = "Keep the fire burning until dawn (%d s)",
	-- Chapter 3
	C3_CLUES = "Find clues (%d/7 real). Talk to the villagers.",
	C3_ROOFTOPS = "Climb the rooftops to the bakery",
	C3_FALSINO = "Truth or lie: vote for the lie (round %d/3)",
	C3_ACCUSE = "Who knocks at night?",
	-- Chapter 4
	C4_OIL = "Find oil bottles and light the 4 braziers (%d/4)",
	C4_KEEP_LIT = "Keep all 4 braziers burning!",
	C4_RUN = "RUN to the forest!",
	C4_FOREST = "Get through the forest to the mine",
	-- Chapter 5
	C5_CODE = "Open the mine door",
	C5_RIDE = "Ride the minecarts: lean and duck!",
	C5_GEAR1 = "Gear 1: pull the levers in the right order",
	C5_GEAR2 = "Gear 2: cross the lava lake",
	C5_GEAR3 = "Gear 3: find the gear in the dark maze",
	C5_CRUDELINO = "Survive Crudelino",
	C5_FLARES = "Mark Crudelino with flares (%d/3 hits)",
	C5_STALACTITES = "Lure Crudelino under the stalactites and knock them down (%d/3)",
	C5_ESCAPE = "Climb out before the cave collapses!",
	-- Chapter 6
	C6_SKYPATH = "Cross the floating blocks to the clock tower",
	C6_DARK = "Carry the Truth Gears to the tower inside the lantern light",
	C6_CLIMB = "Climb the tower!",
	C6_MECHANISM = "Insert the gears and turn the hands together!",
	C6_CHOICE = "Shut it down… or let it stay?",
	-- general
	REVIVE_TEAMMATE = "A teammate is down! Hold E next to them",
}

return Objectives
