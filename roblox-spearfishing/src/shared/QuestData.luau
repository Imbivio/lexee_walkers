--[[
	QuestData
	Three quest lines, one per NPC. Within a line, quests unlock in order;
	the first uncompleted quest of each line is always active. Quests
	auto-complete when their goal is met (no turn-in friction).

	Goal types:
		catch    { count, species?, rarity?, zone?, minKg?, invasive? }
		sell     { amount }              -- lifetime coins earned from selling
		earn     { amount }              -- lifetime coins earned (any source)
		discover { count }               -- distinct species in fishdex
		breath   { level }               -- lung level reached
		depth    { studs }               -- deepest dive
		own      { gearId }
]]

export type Quest = {
	id: string,
	npc: string,
	title: string,
	desc: string,
	goal: { [string]: any },
	reward: { coins: number, unlocks: string? },
}

local QuestData = {}

QuestData.Lines = {
	kimo = {
		{ id = "kimo_first", title = "First Blood",
			desc = "Spear your first fish on the shallow reef.",
			goal = { type = "catch", count = 1 }, reward = { coins = 25 } },
		{ id = "kimo_manini", title = "Manini Money",
			desc = "Bring Uncle Kimo 3 manini for the poke counter.",
			goal = { type = "catch", count = 3, species = "manini" }, reward = { coins = 50 } },
		{ id = "kimo_sell", title = "Open for Business",
			desc = "Sell 10 fish at the market.",
			goal = { type = "sellCount", count = 10 }, reward = { coins = 75 } },
		{ id = "kimo_variety", title = "Mixed Plate",
			desc = "Discover 5 different species.",
			goal = { type = "discover", count = 5 }, reward = { coins = 150 } },
		{ id = "kimo_weke", title = "Weke Fry Friday",
			desc = "Catch 5 weke — Kimo's fry special sells out every week.",
			goal = { type = "catch", count = 5, species = "weke" }, reward = { coins = 200 } },
		{ id = "kimo_big", title = "Da Big One",
			desc = "Catch any fish over 2 kg.",
			goal = { type = "catch", count = 1, minKg = 2 }, reward = { coins = 300 } },
		{ id = "kimo_uncommon", title = "Quality Catch",
			desc = "Catch 8 uncommon fish.",
			goal = { type = "catch", count = 8, rarity = "Uncommon" }, reward = { coins = 400 } },
		{ id = "kimo_feast", title = "Lū'au Order",
			desc = "Earn 3,000 coins selling fish.",
			goal = { type = "sell", amount = 3000 }, reward = { coins = 800 } },
		{ id = "kimo_kumu", title = "The Red Prize",
			desc = "Catch 2 kūmū. The old-timers pay anything for kūmū.",
			goal = { type = "catch", count = 2, species = "kumu" }, reward = { coins = 1200 } },
		{ id = "kimo_master", title = "Market Legend",
			desc = "Discover 15 species.",
			goal = { type = "discover", count = 15 }, reward = { coins = 2500 } },
	},

	leilani = {
		{ id = "lei_dip", title = "First Duck Dive",
			desc = "Dive 10 m down.",
			goal = { type = "depth", studs = 10 }, reward = { coins = 30 } },
		{ id = "lei_lungs1", title = "Breathe Up",
			desc = "Train your lungs to level 2. Time underwater is training.",
			goal = { type = "breath", level = 2 }, reward = { coins = 60 } },
		{ id = "lei_deep", title = "Past the Ledge",
			desc = "Dive 25 m down.",
			goal = { type = "depth", studs = 25 }, reward = { coins = 150 } },
		{ id = "lei_invasive1", title = "Reef Cleanup",
			desc = "Cull 5 invasive snapper (ta'ape or to'au). They eat the keiki fish.",
			goal = { type = "catch", count = 5, invasive = true }, reward = { coins = 250 } },
		{ id = "lei_lungs2", title = "Diaphragm Stretch",
			desc = "Reach lung level 5.",
			goal = { type = "breath", level = 5 }, reward = { coins = 350 } },
		{ id = "lei_roi", title = "Roi Roundup",
			desc = "Cull 8 roi on the outer reef. Every one helps the natives.",
			goal = { type = "catch", count = 8, species = "roi" }, reward = { coins = 700 } },
		{ id = "lei_deep2", title = "The Blue Door",
			desc = "Dive 60 m down the drop-off.",
			goal = { type = "depth", studs = 60 }, reward = { coins = 900 } },
		{ id = "lei_lungs3", title = "Still Water Mind",
			desc = "Reach lung level 12.",
			goal = { type = "breath", level = 12 }, reward = { coins = 1500 } },
		{ id = "lei_invasive2", title = "Guardian of the Reef",
			desc = "Cull 25 invasive fish in total.",
			goal = { type = "catch", count = 25, invasive = true },
			reward = { coins = 2000, unlocks = "Kaimana Fins" } },
		{ id = "lei_abyss", title = "Where Light Ends",
			desc = "Dive to 100 m. Bring a light.",
			goal = { type = "depth", studs = 100 }, reward = { coins = 3000 } },
	},

	kainoa = {
		{ id = "kai_savings", title = "Boat Fund",
			desc = "Earn 2,000 coins in total.",
			goal = { type = "earn", amount = 2000 }, reward = { coins = 200 } },
		{ id = "kai_kayak", title = "Paddle Out",
			desc = "Buy the fishing kayak.",
			goal = { type = "own", gearId = "boat_kayak" }, reward = { coins = 300 } },
		{ id = "kai_papio", title = "Pāpio Run",
			desc = "Catch 5 pāpio.",
			goal = { type = "catch", count = 5, species = "papio" }, reward = { coins = 350 } },
		{ id = "kai_omilu", title = "Blue Lightning",
			desc = "Catch an 'ōmilu — the fastest thing on the reef.",
			goal = { type = "catch", count = 1, species = "omilu" }, reward = { coins = 500 } },
		{ id = "kai_dropoff", title = "Over the Edge",
			desc = "Catch 5 fish at the drop-off.",
			goal = { type = "catch", count = 5, zone = "dropoff" }, reward = { coins = 900 } },
		{ id = "kai_skiff", title = "Real Horsepower",
			desc = "Buy the aluminum skiff.",
			goal = { type = "own", gearId = "boat_skiff" }, reward = { coins = 1000 } },
		{ id = "kai_uku", title = "Deep Water Green",
			desc = "Catch 2 uku off the ledge.",
			goal = { type = "catch", count = 2, species = "uku" }, reward = { coins = 1500 } },
		{ id = "kai_mahi", title = "FAD Raider",
			desc = "Catch a mahimahi at the offshore FAD buoy.",
			goal = { type = "catch", count = 1, species = "mahimahi" }, reward = { coins = 2500 } },
		{ id = "kai_ono", title = "Ono Means Delicious",
			desc = "Catch an ono.",
			goal = { type = "catch", count = 1, species = "ono" }, reward = { coins = 4000 } },
		{ id = "kai_ulua", title = "The White Ulua",
			desc = "Land a 20 kg+ ulua. Kainoa will open his private locker.",
			goal = { type = "catch", count = 1, species = "ulua", minKg = 20 },
			reward = { coins = 10000, unlocks = "Railgun + Sportfisher" } },
	},
}

QuestData.ById = {} :: { [string]: Quest }
for npc, line in pairs(QuestData.Lines) do
	for index, quest in ipairs(line) do
		quest.npc = npc
		quest.index = index
		QuestData.ById[quest.id] = quest
	end
end

-- Human-readable progress target for UI, e.g. "3/5"
function QuestData.GoalTarget(quest: Quest): number
	local goal = quest.goal
	if goal.type == "catch" or goal.type == "discover" or goal.type == "sellCount" then
		return goal.count
	elseif goal.type == "sell" or goal.type == "earn" then
		return goal.amount
	elseif goal.type == "breath" then
		return goal.level
	elseif goal.type == "depth" then
		return goal.studs
	elseif goal.type == "own" then
		return 1
	end
	return 1
end

return QuestData
