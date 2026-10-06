--!strict
-- Inventory items (max 4 slots, server-validated). stack = how many fit in one slot.
export type ItemDef = { id: string, name: string, stack: number, color: Color3, usable: boolean }

local rgb = Color3.fromRGB

local Items: { [string]: ItemDef } = {
	wood = { id = "wood", name = "Wood", stack = 16, color = rgb(156, 118, 70), usable = false },
	lantern = {
		id = "lantern",
		name = "Lantern",
		stack = 1,
		color = rgb(255, 200, 90),
		usable = false,
	},
	glowing_lantern = {
		id = "glowing_lantern",
		name = "Glowing Lantern",
		stack = 1,
		color = rgb(255, 240, 150),
		usable = false,
	},
	bandage = {
		id = "bandage",
		name = "Bandage",
		stack = 3,
		color = rgb(235, 235, 225),
		usable = true,
	},
	bread = { id = "bread", name = "Bread", stack = 4, color = rgb(205, 150, 80), usable = true },
	apple = { id = "apple", name = "Apple", stack = 4, color = rgb(200, 40, 40), usable = true },
	cave_map = {
		id = "cave_map",
		name = "Cave Map",
		stack = 1,
		color = rgb(220, 200, 150),
		usable = false,
	},
	truth_gear = {
		id = "truth_gear",
		name = "Truth Gear",
		stack = 3,
		color = rgb(230, 190, 60),
		usable = false,
	},
	oil_bottle = {
		id = "oil_bottle",
		name = "Oil Bottle",
		stack = 4,
		color = rgb(120, 90, 40),
		usable = true,
	},
	flare = { id = "flare", name = "Flare", stack = 3, color = rgb(255, 60, 60), usable = true },
	stone = { id = "stone", name = "Stone", stack = 5, color = rgb(120, 120, 120), usable = true },
	name_board = {
		id = "name_board",
		name = "Board of Names",
		stack = 1,
		color = rgb(120, 85, 50),
		usable = false,
	},
	pointe_shoe = {
		id = "pointe_shoe",
		name = "Pointe Shoe",
		stack = 1,
		color = rgb(247, 198, 217),
		usable = false,
	},
}

return Items
