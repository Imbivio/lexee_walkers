--[[
	EconomyService
	Selling fish and buying/equipping gear.

	Selling requires standing near Uncle Kimo's market stall — or aboard a
	cruiser/sportfisher, which sell at sea for a cut (80% / 90%).
	Quest-locked gear can't be bought until its quest is completed.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GearData = require(ReplicatedStorage.Shared.GearData)
local QuestData = require(ReplicatedStorage.Shared.QuestData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Util = require(ReplicatedStorage.Shared.Util)
local BoatService = require(script.Parent.BoatService)
local DataService = require(script.Parent.DataService)
local Signals = require(script.Parent.Signals)

local EconomyService = {}

local marketPosition: Vector3
for _, npc in ipairs(GameConfig.NPCs) do
	if npc.id == "kimo" then
		marketPosition = npc.position
	end
end

-- Returns the sell multiplier available at the player's location, or nil.
local function sellContext(player: Player): number?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	if (root.Position - marketPosition).Magnitude <= GameConfig.SellRange then
		return 1
	end
	local boat = BoatService.GetPlayerBoat(player)
	if boat and boat.item.sellAboard and (root.Position - boat.hull.Position).Magnitude <= 25 then
		return boat.item.sellAboard
	end
	return nil
end

local function sellFish(player: Player, uids: { number }?): (boolean, string, number)
	local profile = DataService.GetProfile(player)
	if not profile then
		return false, "Profile not loaded yet.", 0
	end
	local multiplier = sellContext(player)
	if not multiplier then
		return false, "You need to be at the fish market (or aboard a cruiser).", 0
	end
	if #profile.inventory == 0 then
		return false, "Your catch bag is empty.", 0
	end

	local uidSet = nil
	if uids then
		uidSet = {}
		for _, uid in ipairs(uids) do
			uidSet[uid] = true
		end
	end

	local total = 0
	local count = 0
	local kept = {}
	for _, entry in ipairs(profile.inventory) do
		if uidSet == nil or uidSet[entry.uid] then
			total += math.floor(entry.value * multiplier + 0.5)
			count += 1
		else
			table.insert(kept, entry)
		end
	end
	if count == 0 then
		return false, "Nothing selected to sell.", 0
	end

	profile.inventory = kept
	profile.totalSold += total
	profile.soldCount += count
	DataService.AwardCoins(player, total)

	Signals.FishSold:Fire(player, total, count)
	DataService.PushSnapshot(player)
	return true, ("Sold %d fish for %s coins."):format(count, Util.Comma(total)), total
end

local function buyGear(player: Player, gearId: string): (boolean, string)
	local profile = DataService.GetProfile(player)
	if not profile then
		return false, "Profile not loaded yet."
	end
	local item = GearData.ById[gearId]
	if not item then
		return false, "Unknown item."
	end
	if profile.owned[gearId] then
		return false, "You already own that."
	end
	if item.questLock and not profile.quests.completed[item.questLock] then
		local quest = QuestData.ById[item.questLock]
		local questName = quest and quest.title or item.questLock
		return false, "Locked — complete the quest \"" .. questName .. "\" first."
	end
	if profile.coins < item.price then
		return false, ("Not enough coins (%s needed)."):format(Util.Comma(item.price))
	end

	profile.coins -= item.price
	profile.owned[gearId] = true
	-- auto-equip upgrades
	local slot = GearData.CategorySlot[GearData.CategoryOf[gearId]]
	profile.gear[slot] = gearId

	Signals.GearPurchased:Fire(player, gearId)
	DataService.PushSnapshot(player)
	return true, item.name .. " purchased and equipped!"
end

local function equipGear(player: Player, gearId: string): (boolean, string)
	local profile = DataService.GetProfile(player)
	if not profile then
		return false, "Profile not loaded yet."
	end
	local item = GearData.ById[gearId]
	if not item or not profile.owned[gearId] then
		return false, "You don't own that."
	end
	local slot = GearData.CategorySlot[GearData.CategoryOf[gearId]]
	profile.gear[slot] = gearId
	DataService.PushSnapshot(player)
	return true, item.name .. " equipped."
end

function EconomyService.Start()
	Remotes.Function("SellFish").OnServerInvoke = sellFish
	Remotes.Function("BuyGear").OnServerInvoke = buyGear
	Remotes.Function("EquipGear").OnServerInvoke = equipGear
end

return EconomyService
