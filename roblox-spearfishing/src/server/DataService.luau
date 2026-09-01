--[[
	DataService
	Loads/saves player profiles (DataStore), owns the in-memory profile,
	builds client snapshots and leaderstats.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local QuestData = require(ReplicatedStorage.Shared.QuestData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Util = require(ReplicatedStorage.Shared.Util)
local Signals = require(script.Parent.Signals)

local STORE_NAME = "SpearfishProfiles_v1"
local AUTOSAVE_INTERVAL = 120
local SAVE_RETRIES = 3

local DataService = {}

local profiles: { [Player]: any } = {}
local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local function newProfile()
	return {
		version = 1,
		coins = 0,
		totalEarned = 0,
		totalSold = 0,
		soldCount = 0,
		fishCaught = 0,
		breathXP = 0,
		maxDepth = 0,
		bestKg = 0,
		bestSpecies = "",
		gear = {
			spear = "spear_bamboo",
			fins = "fins_none",
			bag = "bag_small",
			light = "light_none",
			boat = "",
		},
		owned = {
			spear_bamboo = true,
			fins_none = true,
			bag_small = true,
			light_none = true,
		},
		inventory = {},
		nextUid = 1,
		fishdex = {},
		quests = { completed = {}, progress = {} },
	}
end

local function keyFor(player: Player): string
	return "p_" .. player.UserId
end

local function loadProfile(player: Player)
	local data = nil
	if store then
		for attempt = 1, SAVE_RETRIES do
			local ok, result = pcall(function()
				return store:GetAsync(keyFor(player))
			end)
			if ok then
				data = result
				break
			end
			warn(("[DataService] load attempt %d failed for %s: %s"):format(attempt, player.Name, tostring(result)))
			task.wait(2 ^ attempt)
		end
	end

	local profile = newProfile()
	if type(data) == "table" then
		-- shallow-merge saved fields over the template so new fields
		-- added in updates get defaults
		for key, value in pairs(data) do
			profile[key] = value
		end
	end
	return profile
end

local function saveProfile(player: Player)
	local profile = profiles[player]
	if not profile or not store then
		return
	end
	for attempt = 1, SAVE_RETRIES do
		local ok, err = pcall(function()
			store:SetAsync(keyFor(player), profile)
		end)
		if ok then
			return
		end
		warn(("[DataService] save attempt %d failed for %s: %s"):format(attempt, player.Name, tostring(err)))
		task.wait(2 ^ attempt)
	end
end

-- Leaderstats ------------------------------------------------------------

local function updateLeaderstats(player: Player)
	local profile = profiles[player]
	local stats = player:FindFirstChild("leaderstats")
	if not profile or not stats then
		return
	end
	stats.Coins.Value = profile.coins
	stats.Fish.Value = profile.fishCaught
	stats.Best.Value = profile.bestKg > 0 and Util.FormatKg(profile.bestKg) or "—"
end

local function makeLeaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = stats
	local fish = Instance.new("IntValue")
	fish.Name = "Fish"
	fish.Parent = stats
	local best = Instance.new("StringValue")
	best.Name = "Best"
	best.Value = "—"
	best.Parent = stats
	stats.Parent = player
end

-- Snapshot ---------------------------------------------------------------

-- Everything the client UI needs, pushed on every meaningful change.
function DataService.BuildSnapshot(player: Player)
	local profile = profiles[player]
	if not profile then
		return nil
	end
	local breathLevel = GameConfig.Breath.LevelFromXP(profile.breathXP)
	local nextLevelXP = breathLevel < GameConfig.Breath.MaxLevel
		and GameConfig.Breath.XPForLevel(breathLevel + 1)
		or GameConfig.Breath.XPForLevel(GameConfig.Breath.MaxLevel)

	-- active quest (first uncompleted) per NPC line, with progress
	local activeQuests = {}
	for npc, line in pairs(QuestData.Lines) do
		for _, quest in ipairs(line) do
			if not profile.quests.completed[quest.id] then
				table.insert(activeQuests, {
					id = quest.id,
					npc = npc,
					progress = profile.quests.progress[quest.id] or 0,
				})
				break
			end
		end
	end

	return {
		coins = profile.coins,
		totalEarned = profile.totalEarned,
		fishCaught = profile.fishCaught,
		gear = profile.gear,
		owned = profile.owned,
		inventory = profile.inventory,
		fishdex = profile.fishdex,
		bestKg = profile.bestKg,
		bestSpecies = profile.bestSpecies,
		maxDepth = profile.maxDepth,
		breath = {
			xp = profile.breathXP,
			level = breathLevel,
			max = GameConfig.Breath.MaxBreathForLevel(breathLevel),
			nextLevelXP = nextLevelXP,
		},
		quests = {
			active = activeQuests,
			completed = profile.quests.completed,
		},
	}
end

function DataService.PushSnapshot(player: Player)
	local snapshot = DataService.BuildSnapshot(player)
	if snapshot then
		Remotes.Event("ProfileChanged"):FireClient(player, snapshot)
		updateLeaderstats(player)
	end
end

-- Public API -------------------------------------------------------------

function DataService.GetProfile(player: Player)
	return profiles[player]
end

function DataService.AwardCoins(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.coins += amount
	if amount > 0 then
		profile.totalEarned += amount
	end
end

function DataService.Start()
	Remotes.Function("GetSnapshot").OnServerInvoke = function(player)
		-- wait briefly if profile still loading
		local deadline = os.clock() + 15
		while not profiles[player] and os.clock() < deadline do
			task.wait(0.2)
		end
		return DataService.BuildSnapshot(player)
	end

	local function onPlayer(player: Player)
		makeLeaderstats(player)
		local profile = loadProfile(player)
		if player.Parent then
			profiles[player] = profile
			updateLeaderstats(player)
			Signals.ProfileLoaded:Fire(player, profile)
			DataService.PushSnapshot(player)
		end
	end

	Players.PlayerAdded:Connect(onPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayer, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		saveProfile(player)
		profiles[player] = nil
	end)

	-- autosave
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in pairs(profiles) do
				saveProfile(player)
			end
		end
	end)

	if not RunService:IsStudio() then
		game:BindToClose(function()
			for player in pairs(profiles) do
				saveProfile(player)
			end
		end)
	end
end

return DataService
