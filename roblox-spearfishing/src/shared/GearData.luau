--[[
	GearData
	All purchasable gear. Prices deliberately steep — the economy is tuned
	around ~1,000 coins/hour on the shallow reef with starter gear, rising
	to ~5,000+/hour at the drop-off, so the top items are 20+ hour goals.

	questLock: gear that can only be bought after completing that quest.
]]

export type GearItem = {
	id: string,
	name: string,
	desc: string,
	price: number,
	questLock: string?,
	-- spears
	range: number?, -- studs the spear reaches at full charge
	power: number?, -- vs fish toughness -> catch chance
	reload: number?, -- seconds between shots
	-- fins
	swimSpeed: number?,
	-- bags
	capacity: number?,
	-- lights
	lightFactor: number?, -- 0..1, how much depth darkness is removed
	-- boats
	speed: number?,
	turnRate: number?,
	sellAboard: number?, -- if set, can sell on the boat at this fraction
	hullSize: Vector3?,
	hullColor: Color3?,
}

local GearData = {}

GearData.Categories = { "Spears", "Fins", "Bags", "Lights", "Boats" }

GearData.Spears = {
	{ id = "spear_bamboo", name = "Bamboo Pole Spear", price = 0,
		desc = "The old family spear. It has caught a thousand manini.",
		range = 13, power = 1.0, reload = 1.2 },
	{ id = "spear_3prong", name = "Three-Prong", price = 250,
		desc = "Classic Hawaiian three-prong. Much easier to land small reef fish.",
		range = 15, power = 1.4, reload = 1.1 },
	{ id = "spear_alu", name = "Aluminum Pole Spear", price = 1200,
		desc = "Longer reach, stronger band.",
		range = 18, power = 1.8, reload = 1.2 },
	{ id = "spear_carbon", name = "Carbon Pole Spear", price = 4500,
		desc = "Fast, quiet, deadly at range.",
		range = 21, power = 2.3, reload = 1.1 },
	{ id = "gun_mini", name = "Mini Speargun (60cm)", price = 12000,
		desc = "Your first trigger. Reef fish beware.",
		range = 28, power = 3.0, reload = 2.2 },
	{ id = "gun_reef", name = "Reef Speargun (90cm)", price = 35000,
		desc = "The workhorse of the outer reef.",
		range = 34, power = 4.0, reload = 2.6 },
	{ id = "gun_blue", name = "Bluewater Speargun (120cm)", price = 90000,
		desc = "Built for uku, kahala and the deep ledges.",
		range = 42, power = 5.5, reload = 3.0 },
	{ id = "gun_rail", name = "Railgun (140cm)", price = 220000, questLock = "kai_ulua",
		desc = "Twin bands, enclosed track. The ulua gun.",
		range = 50, power = 7.5, reload = 3.4 },
}

GearData.Fins = {
	{ id = "fins_none", name = "Barefoot", price = 0,
		desc = "Tough feet, slow kick.", swimSpeed = 16 },
	{ id = "fins_rubber", name = "Rubber Fins", price = 800,
		desc = "Rental-shop rubber fins. +25% swim speed.", swimSpeed = 20 },
	{ id = "fins_freedive", name = "Freedive Fins", price = 4000,
		desc = "Long-blade plastic fins. +50% swim speed.", swimSpeed = 24 },
	{ id = "fins_carbon", name = "Carbon Fins", price = 15000,
		desc = "Featherweight carbon blades. +75% swim speed.", swimSpeed = 28 },
	{ id = "fins_kaimana", name = "Kaimana Fins", price = 60000, questLock = "lei_invasive2",
		desc = "Leilani's own design — 'power of the sea'. Double swim speed.", swimSpeed = 32 },
}

GearData.Bags = {
	{ id = "bag_small", name = "Mesh Pouch", price = 0,
		desc = "Holds a few small fish.", capacity = 8 },
	{ id = "bag_mesh", name = "Mesh Catch Bag", price = 900,
		desc = "A proper catch bag.", capacity = 14 },
	{ id = "bag_hunter", name = "Hunter's Bag", price = 5000,
		desc = "Reinforced for bigger fish.", capacity = 24 },
	{ id = "bag_pro", name = "Pro Game Bag", price = 20000,
		desc = "A full day's dive in one bag.", capacity = 40 },
}

GearData.Lights = {
	{ id = "light_none", name = "No Light", price = 0,
		desc = "Hope your eyes adjust.", lightFactor = 0 },
	{ id = "light_torch", name = "Dive Torch", price = 1500,
		desc = "Cuts through half the gloom below 30 studs.", lightFactor = 0.55 },
	{ id = "light_pro", name = "Canister Light", price = 12000,
		desc = "Turns midnight ledges into daylight. Menpachi hunting essential.", lightFactor = 0.9 },
}

GearData.Boats = {
	{ id = "boat_kayak", name = "Fishing Kayak", price = 3500,
		desc = "Paddle past the reef without burning your legs.",
		speed = 35, turnRate = 2.2, hullSize = Vector3.new(9, 1.4, 3), hullColor = Color3.fromRGB(226, 155, 64) },
	{ id = "boat_skiff", name = "Aluminum Skiff", price = 16000,
		desc = "Gets you to the drop-off in minutes.",
		speed = 55, turnRate = 1.8, hullSize = Vector3.new(13, 2, 5), hullColor = Color3.fromRGB(190, 195, 200) },
	{ id = "boat_cruiser", name = "Dive Cruiser", price = 65000,
		desc = "Ice chest aboard — sell your catch at sea for 80% price.",
		speed = 70, turnRate = 1.5, sellAboard = 0.8, hullSize = Vector3.new(17, 2.6, 6.5), hullColor = Color3.fromRGB(235, 238, 240) },
	{ id = "boat_sport", name = "Sportfisher", price = 300000, questLock = "kai_ulua",
		desc = "Tower, outriggers, and a live well. Sell at sea for 90% price.",
		speed = 90, turnRate = 1.3, sellAboard = 0.9, hullSize = Vector3.new(22, 3.2, 8), hullColor = Color3.fromRGB(52, 76, 96) },
}

-- Which profile slot each category equips into
GearData.CategorySlot = {
	Spears = "spear",
	Fins = "fins",
	Bags = "bag",
	Lights = "light",
	Boats = "boat",
}

GearData.ById = {} :: { [string]: GearItem }
GearData.CategoryOf = {} :: { [string]: string }
for _, category in ipairs(GearData.Categories) do
	for _, item in ipairs(GearData[category]) do
		GearData.ById[item.id] = item
		GearData.CategoryOf[item.id] = category
	end
end

return GearData
