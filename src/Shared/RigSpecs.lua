--!strict
-- Placeholder rig definitions (plain data, no Roblox types, so tools/anim_preview can read it).
-- Humanoid rigs share one blocky skeleton with elbows, wrists and knees (needed for kneeling,
-- reaching and sliding down a door). Units are studs; the rig stands on y = 0 and faces -Z.
-- Joint c0 / c1 are positions in Part0 / Part1 space, exactly like Motor6D.C0 / C1.
-- The legs hang from the HumanoidRootPart (the pelvis), so RootJoint bends only the upper body.
-- Animation angles: rot = {pitch, yaw, roll} in degrees (CFrame.Angles order).
--   Limbs hang down, so +pitch swings an arm/leg FORWARD; knees bend with -pitch, elbows +pitch.
--   Parts that point up (torso at RootJoint, head at Neck, the whole model at Root) tilt
--   FORWARD with -pitch (bow, look down) and back with +pitch.
--   +roll moves a part toward +X (the rig's right side): right arm out = +roll, left arm = -roll.
--   +yaw turns left (counter-clockwise seen from above).

export type PartDef = { size: { number } }
export type JointDef =
	{ name: string, part0: string, part1: string, c0: { number }, c1: { number } }
export type AccessoryDef = {
	name: string,
	part: string,
	size: { number },
	offset: { number },
	color: string,
	material: string?,
	transparency: number?,
}
export type CharacterDef = {
	kind: "humanoid" | "cube",
	displayName: string,
	faceStyle: "villager" | "screen",
	colors: { [string]: string }, -- part name -> hex color ("*" = default)
	accessories: { AccessoryDef }?,
	cubeSize: number?,
	material: string?,
}

local RigSpecs = {}

RigSpecs.skeleton = {
	rootHeight = 3.2, -- HumanoidRootPart center above the ground
	parts = {
		HumanoidRootPart = { size = { 2, 2, 1 } },
		Torso = { size = { 2, 2, 1 } },
		Head = { size = { 1.3, 1.3, 1.3 } },
		RightUpperArm = { size = { 0.9, 1.1, 0.9 } },
		RightLowerArm = { size = { 0.85, 1.0, 0.85 } },
		RightHand = { size = { 0.8, 0.4, 0.8 } },
		LeftUpperArm = { size = { 0.9, 1.1, 0.9 } },
		LeftLowerArm = { size = { 0.85, 1.0, 0.85 } },
		LeftHand = { size = { 0.8, 0.4, 0.8 } },
		RightThigh = { size = { 0.92, 1.1, 0.92 } },
		RightShin = { size = { 0.9, 1.1, 0.9 } },
		LeftThigh = { size = { 0.92, 1.1, 0.92 } },
		LeftShin = { size = { 0.9, 1.1, 0.9 } },
	} :: { [string]: PartDef },
	joints = {
		{
			name = "RootJoint",
			part0 = "HumanoidRootPart",
			part1 = "Torso",
			c0 = { 0, -1, 0 },
			c1 = { 0, -1, 0 },
		},
		{ name = "Neck", part0 = "Torso", part1 = "Head", c0 = { 0, 1, 0 }, c1 = { 0, -0.65, 0 } },
		{
			name = "RightShoulder",
			part0 = "Torso",
			part1 = "RightUpperArm",
			c0 = { 1.47, 0.75, 0 },
			c1 = { 0, 0.3, 0 },
		},
		{
			name = "RightElbow",
			part0 = "RightUpperArm",
			part1 = "RightLowerArm",
			c0 = { 0, -0.55, 0 },
			c1 = { 0, 0.5, 0 },
		},
		{
			name = "RightWrist",
			part0 = "RightLowerArm",
			part1 = "RightHand",
			c0 = { 0, -0.5, 0 },
			c1 = { 0, 0.2, 0 },
		},
		{
			name = "LeftShoulder",
			part0 = "Torso",
			part1 = "LeftUpperArm",
			c0 = { -1.47, 0.75, 0 },
			c1 = { 0, 0.3, 0 },
		},
		{
			name = "LeftElbow",
			part0 = "LeftUpperArm",
			part1 = "LeftLowerArm",
			c0 = { 0, -0.55, 0 },
			c1 = { 0, 0.5, 0 },
		},
		{
			name = "LeftWrist",
			part0 = "LeftLowerArm",
			part1 = "LeftHand",
			c0 = { 0, -0.5, 0 },
			c1 = { 0, 0.2, 0 },
		},
		{
			name = "RightHip",
			part0 = "HumanoidRootPart",
			part1 = "RightThigh",
			c0 = { 0.5, -1, 0 },
			c1 = { 0, 0.55, 0 },
		},
		{
			name = "RightKnee",
			part0 = "RightThigh",
			part1 = "RightShin",
			c0 = { 0, -0.55, 0 },
			c1 = { 0, 0.55, 0 },
		},
		{
			name = "LeftHip",
			part0 = "HumanoidRootPart",
			part1 = "LeftThigh",
			c0 = { -0.5, -1, 0 },
			c1 = { 0, 0.55, 0 },
		},
		{
			name = "LeftKnee",
			part0 = "LeftThigh",
			part1 = "LeftShin",
			c0 = { 0, -0.55, 0 },
			c1 = { 0, 0.55, 0 },
		},
	} :: { JointDef },
}

RigSpecs.characters = {
	Ballerina = {
		kind = "humanoid",
		displayName = "Ballerina Cappuccina",
		faceStyle = "villager",
		colors = {
			["*"] = "#F8D5E0", -- tights
			Torso = "#F2A7C3", -- leotard
			Head = "#FAF6EE", -- the cappuccino cup
			RightUpperArm = "#F3D2B5",
			RightLowerArm = "#F3D2B5",
			RightHand = "#F3D2B5",
			LeftUpperArm = "#F3D2B5",
			LeftLowerArm = "#F3D2B5",
			LeftHand = "#F3D2B5",
		},
		accessories = {
			{
				name = "CupFoam",
				part = "Head",
				size = { 1.4, 0.26, 1.4 },
				offset = { 0, 0.78, 0 },
				color = "#E9D3AF",
			},
			{
				name = "CupCoffee",
				part = "Head",
				size = { 1.1, 0.06, 1.1 },
				offset = { 0, 0.94, 0 },
				color = "#7A4A2A",
			},
			{
				name = "CupHandle",
				part = "Head",
				size = { 0.32, 0.75, 0.26 },
				offset = { 0.8, 0, 0 },
				color = "#FAF6EE",
			},
			{
				name = "Tutu",
				part = "HumanoidRootPart", -- stays at the hips when the torso bends
				size = { 2.9, 0.36, 2.0 },
				offset = { 0, -0.86, 0 },
				color = "#FFB6D5",
				material = "Fabric",
			},
			{
				name = "PointeShoe",
				part = "LeftShin",
				size = { 0.96, 0.36, 1.06 },
				offset = { 0, -0.4, -0.06 },
				color = "#F7C6D9",
				material = "Fabric",
			},
			{
				name = "PointeShoeR",
				part = "RightShin",
				size = { 0.96, 0.36, 1.06 },
				offset = { 0, -0.4, -0.06 },
				color = "#F7C6D9",
				material = "Fabric",
			},
		},
	},
	Giallino = {
		kind = "cube",
		displayName = "Giallino",
		faceStyle = "screen",
		colors = { ["*"] = "#FFD83A" },
		cubeSize = 4, -- one block
		material = "Neon",
	},
	Dummy = {
		kind = "humanoid",
		displayName = "Test Dummy",
		faceStyle = "villager",
		colors = { ["*"] = "#A0A4B0", Torso = "#6C7A96", Head = "#D9C7A8" },
	},
} :: { [string]: CharacterDef }

return RigSpecs
