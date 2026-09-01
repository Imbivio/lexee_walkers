--[[
	FishData
	Every species in the game — real Hawaiian reef & pelagic fish, with
	Hawaiian names first (english shown as subtitle). Sizes are lengths in
	cm; weight is derived from length via the `condition` factor:
		kg = condition * cm^3 / 100000
	Value of a specimen:
		value = baseValue * (0.55 + 1.45 * norm^1.6)   (norm = size percentile)
	so a max-size fish is worth ~2x baseValue and a tiny one ~0.55x.

	`invasive` species (roi / ta'ape / to'au) were introduced to Hawai'i in
	the 1950s and are culled by real spearfishers — Leilani's quest line
	pays a bounty for them.
]]

export type Species = {
	id: string,
	name: string, -- Hawaiian name
	english: string,
	rarity: string, -- Common | Uncommon | Rare | Epic | Legendary | Mythic
	zones: { string },
	minCm: number,
	maxCm: number,
	condition: number, -- weight factor, see above
	baseValue: number, -- coins for an average specimen
	color: Color3,
	speed: number, -- studs/sec cruising
	spookRadius: number, -- studs; player closer than this spooks it
	invasive: boolean?,
	nightOnly: boolean?,
}

local FishData = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

FishData.Species = {
	-- Shallow reef -------------------------------------------------------
	{ id = "manini", name = "Manini", english = "Convict Tang", rarity = "Common",
		zones = { "shallow_reef" }, minCm = 8, maxCm = 23, condition = 1.3, baseValue = 5,
		color = rgb(215, 215, 195), speed = 7, spookRadius = 10 },
	{ id = "hinalea", name = "Hinālea", english = "Saddle Wrasse", rarity = "Common",
		zones = { "shallow_reef" }, minCm = 10, maxCm = 27, condition = 1.1, baseValue = 4,
		color = rgb(38, 145, 150), speed = 8, spookRadius = 9 },
	{ id = "kupipi", name = "Kūpīpī", english = "Blackspot Sergeant", rarity = "Common",
		zones = { "shallow_reef" }, minCm = 8, maxCm = 20, condition = 1.4, baseValue = 4,
		color = rgb(175, 175, 145), speed = 7, spookRadius = 9 },
	{ id = "weke", name = "Weke", english = "Yellowstripe Goatfish", rarity = "Common",
		zones = { "shallow_reef", "outer_reef" }, minCm = 15, maxCm = 34, condition = 1.2, baseValue = 7,
		color = rgb(232, 222, 152), speed = 8, spookRadius = 11 },
	{ id = "papio", name = "Pāpio", english = "Young Trevally", rarity = "Common",
		zones = { "shallow_reef", "outer_reef" }, minCm = 20, maxCm = 40, condition = 1.6, baseValue = 9,
		color = rgb(192, 200, 210), speed = 11, spookRadius = 12 },
	{ id = "kole", name = "Kole", english = "Goldring Surgeonfish", rarity = "Uncommon",
		zones = { "shallow_reef" }, minCm = 10, maxCm = 18, condition = 1.3, baseValue = 12,
		color = rgb(62, 52, 46), speed = 8, spookRadius = 11 },
	{ id = "humuhumu", name = "Humuhumunukunukuāpua'a", english = "Reef Triggerfish", rarity = "Uncommon",
		zones = { "shallow_reef" }, minCm = 15, maxCm = 30, condition = 1.5, baseValue = 15,
		color = rgb(96, 112, 140), speed = 9, spookRadius = 12 },
	{ id = "palani", name = "Palani", english = "Eyestripe Surgeonfish", rarity = "Uncommon",
		zones = { "shallow_reef", "outer_reef" }, minCm = 20, maxCm = 50, condition = 1.5, baseValue = 14,
		color = rgb(112, 120, 132), speed = 9, spookRadius = 12 },
	{ id = "taape", name = "Ta'ape", english = "Bluestripe Snapper", rarity = "Uncommon",
		zones = { "shallow_reef", "outer_reef" }, minCm = 15, maxCm = 30, condition = 1.3, baseValue = 10,
		color = rgb(250, 208, 60), speed = 9, spookRadius = 10, invasive = true },
	{ id = "toau", name = "To'au", english = "Blacktail Snapper", rarity = "Uncommon",
		zones = { "shallow_reef", "outer_reef" }, minCm = 15, maxCm = 33, condition = 1.3, baseValue = 11,
		color = rgb(202, 142, 62), speed = 9, spookRadius = 10, invasive = true },
	{ id = "oio", name = "'Ō'io", english = "Bonefish", rarity = "Rare",
		zones = { "shallow_reef", "outer_reef" }, minCm = 35, maxCm = 70, condition = 1.3, baseValue = 50,
		color = rgb(212, 216, 222), speed = 14, spookRadius = 16 },
	{ id = "kumu", name = "Kūmū", english = "Whitesaddle Goatfish", rarity = "Rare",
		zones = { "shallow_reef", "outer_reef" }, minCm = 20, maxCm = 45, condition = 1.4, baseValue = 45,
		color = rgb(198, 82, 70), speed = 10, spookRadius = 16 },

	-- Outer reef ---------------------------------------------------------
	{ id = "uhu", name = "Uhu", english = "Parrotfish", rarity = "Uncommon",
		zones = { "outer_reef" }, minCm = 25, maxCm = 60, condition = 1.5, baseValue = 18,
		color = rgb(44, 172, 160), speed = 9, spookRadius = 13 },
	{ id = "kala", name = "Kala", english = "Bluespine Unicornfish", rarity = "Uncommon",
		zones = { "outer_reef" }, minCm = 25, maxCm = 55, condition = 1.4, baseValue = 14,
		color = rgb(102, 112, 122), speed = 9, spookRadius = 12 },
	{ id = "nenue", name = "Nenue", english = "Rudderfish", rarity = "Uncommon",
		zones = { "outer_reef" }, minCm = 25, maxCm = 55, condition = 1.5, baseValue = 13,
		color = rgb(92, 96, 102), speed = 9, spookRadius = 12 },
	{ id = "roi", name = "Roi", english = "Peacock Grouper", rarity = "Uncommon",
		zones = { "outer_reef", "dropoff" }, minCm = 25, maxCm = 50, condition = 1.5, baseValue = 16,
		color = rgb(42, 62, 122), speed = 8, spookRadius = 12, invasive = true },
	{ id = "menpachi", name = "Menpachi", english = "Soldierfish", rarity = "Rare",
		zones = { "outer_reef", "dropoff" }, minCm = 15, maxCm = 30, condition = 1.4, baseValue = 35,
		color = rgb(222, 62, 52), speed = 8, spookRadius = 11, nightOnly = true },
	{ id = "mu", name = "Mū", english = "Bigeye Emperor", rarity = "Rare",
		zones = { "outer_reef" }, minCm = 30, maxCm = 60, condition = 1.6, baseValue = 40,
		color = rgb(152, 152, 162), speed = 10, spookRadius = 15 },
	{ id = "omilu", name = "'Ōmilu", english = "Bluefin Trevally", rarity = "Rare",
		zones = { "outer_reef", "dropoff" }, minCm = 30, maxCm = 70, condition = 1.7, baseValue = 55,
		color = rgb(62, 132, 220), speed = 13, spookRadius = 17 },

	-- The Drop-off -------------------------------------------------------
	{ id = "uku", name = "Uku", english = "Green Jobfish", rarity = "Epic",
		zones = { "dropoff" }, minCm = 40, maxCm = 90, condition = 1.6, baseValue = 140,
		color = rgb(112, 132, 112), speed = 12, spookRadius = 18 },
	{ id = "kahala", name = "Kāhala", english = "Amberjack", rarity = "Epic",
		zones = { "dropoff" }, minCm = 50, maxCm = 120, condition = 1.6, baseValue = 150,
		color = rgb(142, 132, 92), speed = 13, spookRadius = 18 },
	{ id = "opakapaka", name = "'Ōpakapaka", english = "Pink Snapper", rarity = "Epic",
		zones = { "dropoff" }, minCm = 40, maxCm = 80, condition = 1.5, baseValue = 170,
		color = rgb(232, 152, 152), speed = 11, spookRadius = 17 },
	{ id = "ulua", name = "Ulua", english = "Giant Trevally", rarity = "Legendary",
		zones = { "dropoff", "open_ocean" }, minCm = 60, maxCm = 160, condition = 1.8, baseValue = 450,
		color = rgb(118, 124, 130), speed = 15, spookRadius = 20 },

	-- Open ocean (FAD) ---------------------------------------------------
	{ id = "aku", name = "Aku", english = "Skipjack Tuna", rarity = "Rare",
		zones = { "open_ocean" }, minCm = 40, maxCm = 80, condition = 1.7, baseValue = 60,
		color = rgb(82, 92, 142), speed = 15, spookRadius = 15 },
	{ id = "mahimahi", name = "Mahimahi", english = "Dorado", rarity = "Epic",
		zones = { "open_ocean" }, minCm = 70, maxCm = 140, condition = 1.2, baseValue = 180,
		color = rgb(122, 200, 92), speed = 16, spookRadius = 18 },
	{ id = "ono", name = "Ono", english = "Wahoo", rarity = "Legendary",
		zones = { "open_ocean" }, minCm = 80, maxCm = 160, condition = 1.2, baseValue = 420,
		color = rgb(92, 102, 162), speed = 18, spookRadius = 20 },
	{ id = "ahi", name = "'Ahi", english = "Yellowfin Tuna", rarity = "Legendary",
		zones = { "open_ocean" }, minCm = 80, maxCm = 180, condition = 1.9, baseValue = 600,
		color = rgb(62, 72, 122), speed = 17, spookRadius = 20 },
	{ id = "kajiki", name = "Kajiki", english = "Blue Marlin", rarity = "Mythic",
		zones = { "open_ocean" }, minCm = 180, maxCm = 300, condition = 0.6, baseValue = 2600,
		color = rgb(52, 82, 162), speed = 20, spookRadius = 24 },
}

-- Lookup by id
FishData.ById = {} :: { [string]: Species }
for _, species in ipairs(FishData.Species) do
	FishData.ById[species.id] = species
end

function FishData.WeightKg(species: Species, cm: number): number
	return species.condition * cm ^ 3 / 100000
end

-- Size percentile 0..1 within the species range
function FishData.Norm(species: Species, cm: number): number
	return math.clamp((cm - species.minCm) / (species.maxCm - species.minCm), 0, 1)
end

function FishData.Value(species: Species, cm: number, golden: boolean?): number
	local norm = FishData.Norm(species, cm)
	local value = species.baseValue * (0.55 + 1.45 * norm ^ 1.6)
	if golden then
		value *= 6
	end
	return math.max(1, math.floor(value + 0.5))
end

return FishData
