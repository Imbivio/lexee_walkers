--[[
	QuestService
	Drives the three NPC quest lines. The first uncompleted quest in each
	line is active; count-based goals (catch quests) accumulate progress
	from the moment the quest becomes active, state-based goals (breath
	level, depth, earnings, gear owned, species discovered) are evaluated
	against the profile. Quests auto-complete with a toast + coin reward.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishData = require(ReplicatedStorage.Shared.FishData)
local QuestData = require(ReplicatedStorage.Shared.QuestData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Util = require(ReplicatedStorage.Shared.Util)
local DataService = require(script.Parent.DataService)
local Signals = require(script.Parent.Signals)

local QuestService = {}

local function activeQuests(profile): { any }
	local list = {}
	for _, line in pairs(QuestData.Lines) do
		for _, quest in ipairs(line) do
			if not profile.quests.completed[quest.id] then
				table.insert(list, quest)
				break
			end
		end
	end
	return list
end

local function countDiscovered(profile): number
	local n = 0
	for _ in pairs(profile.fishdex) do
		n += 1
	end
	return n
end

local completeQuest -- forward-declared (completion rechecks state goals)

-- Recompute state-based goals; returns true if anything completed
local function evaluateStateGoals(player: Player, profile): boolean
	local completedAny = false
	for _, quest in ipairs(activeQuests(profile)) do
		local goal = quest.goal
		local progress = nil
		if goal.type == "discover" then
			progress = countDiscovered(profile)
		elseif goal.type == "breath" then
			progress = player:GetAttribute("LungLevel") or 0
		elseif goal.type == "depth" then
			progress = math.floor(profile.maxDepth or 0)
		elseif goal.type == "earn" then
			progress = profile.totalEarned
		elseif goal.type == "sell" then
			progress = profile.totalSold
		elseif goal.type == "own" then
			progress = profile.owned[goal.gearId] and 1 or 0
		end
		if progress ~= nil then
			profile.quests.progress[quest.id] = progress
			if progress >= QuestData.GoalTarget(quest) then
				completeQuest(player, profile, quest)
				completedAny = true
			end
		end
	end
	return completedAny
end

completeQuest = function(player: Player, profile, quest)
	profile.quests.completed[quest.id] = true
	profile.quests.progress[quest.id] = nil
	DataService.AwardCoins(player, quest.reward.coins)

	local text = ("Quest complete: %s (+%s coins)"):format(quest.title, Util.Comma(quest.reward.coins))
	if quest.reward.unlocks then
		text ..= " — unlocked: " .. quest.reward.unlocks .. "!"
	end
	Remotes.Event("Notify"):FireClient(player, { text = text, kind = "quest" })
	Remotes.Event("QuestCompleted"):FireClient(player, quest.id)

	-- reward coins / unlocks can immediately satisfy the next quest
	evaluateStateGoals(player, profile)
end

local function bumpCountGoal(player: Player, profile, quest, amount: number)
	local progress = (profile.quests.progress[quest.id] or 0) + amount
	profile.quests.progress[quest.id] = progress
	if progress >= QuestData.GoalTarget(quest) then
		completeQuest(player, profile, quest)
	end
end

local function onFishCaught(player: Player, entry, zoneId: string)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	local species = FishData.ById[entry.species]
	for _, quest in ipairs(activeQuests(profile)) do
		local goal = quest.goal
		if goal.type == "catch" then
			local matches = (goal.species == nil or goal.species == entry.species)
				and (goal.rarity == nil or (species and species.rarity == goal.rarity))
				and (goal.zone == nil or goal.zone == zoneId)
				and (goal.minKg == nil or entry.kg >= goal.minKg)
				and (goal.invasive == nil or (species and species.invasive == true))
			if matches then
				bumpCountGoal(player, profile, quest, 1)
			end
		end
	end
	evaluateStateGoals(player, profile) -- discover-count quests
	DataService.PushSnapshot(player)
end

local function onFishSold(player: Player, _total: number, count: number)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	for _, quest in ipairs(activeQuests(profile)) do
		if quest.goal.type == "sellCount" then
			bumpCountGoal(player, profile, quest, count)
		end
	end
	evaluateStateGoals(player, profile) -- sell/earn amounts
	DataService.PushSnapshot(player)
end

local function recheck(player: Player)
	local profile = DataService.GetProfile(player)
	if profile and evaluateStateGoals(player, profile) then
		DataService.PushSnapshot(player)
	elseif profile then
		DataService.PushSnapshot(player)
	end
end

function QuestService.Start()
	Signals.FishCaught:Connect(onFishCaught)
	Signals.FishSold:Connect(onFishSold)
	Signals.GearPurchased:Connect(function(player)
		recheck(player)
	end)
	Signals.BreathLevelUp:Connect(function(player)
		recheck(player)
	end)
	Signals.DepthRecord:Connect(function(player)
		recheck(player)
	end)
	Signals.ProfileLoaded:Connect(function(player)
		-- catch up on anything already satisfied (e.g. after an update)
		-- and populate progress numbers for the first snapshot
		task.defer(function()
			if player.Parent then
				recheck(player)
			end
		end)
	end)
end

return QuestService
