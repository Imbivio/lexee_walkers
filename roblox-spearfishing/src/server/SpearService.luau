--[[
	SpearService
	Server-authoritative spearing. The client sends an aim ray + charge;
	the server checks the cooldown for the equipped spear, verifies the
	shot origin is at the player, raycasts against fish (terrain blocks
	shots, water is ignored) and rolls the catch:

		chance = clamp(power * (0.4 + 0.6 * charge) / toughness, 0.08, 0.95)
		toughness = 0.7 + kg / 6

	so a bamboo pole CAN land a 40 kg ulua — at ~8% odds. Missed or failed
	fish spook and bolt. Catches go into the bag (capacity from gear),
	trophies / goldens / legendaries get server-wide announcements.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FishData = require(ReplicatedStorage.Shared.FishData)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GearData = require(ReplicatedStorage.Shared.GearData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Util = require(ReplicatedStorage.Shared.Util)
local DataService = require(script.Parent.DataService)
local FishService = require(script.Parent.FishService)
local Signals = require(script.Parent.Signals)

local SpearService = {}

local rng = Random.new()
local lastThrow: { [Player]: number } = {}

local function announce(text: string, kind: string)
	Remotes.Event("Announce"):FireAllClients({ text = text, kind = kind })
end

local function registerCatch(player: Player, profile, fish: BasePart, species)
	local cm = fish:GetAttribute("SizeCm")
	local kg = fish:GetAttribute("WeightKg")
	local golden = fish:GetAttribute("Golden") == true
	local zoneId = fish:GetAttribute("Zone")
	local value = FishData.Value(species, cm, golden)

	local entry = {
		uid = profile.nextUid,
		species = species.id,
		cm = cm,
		kg = kg,
		golden = golden,
		value = value,
		zone = zoneId,
	}
	profile.nextUid += 1
	table.insert(profile.inventory, entry)
	profile.fishCaught += 1

	-- fishdex
	local dex = profile.fishdex[species.id]
	if not dex then
		dex = { count = 0, bestCm = 0, bestKg = 0, golden = false }
		profile.fishdex[species.id] = dex
	end
	dex.count += 1
	dex.bestCm = math.max(dex.bestCm, cm)
	dex.bestKg = math.max(dex.bestKg, kg)
	dex.golden = dex.golden or golden

	-- personal best
	if kg > (profile.bestKg or 0) then
		profile.bestKg = kg
		profile.bestSpecies = species.id
	end

	-- big moments -> server-wide announcements
	local norm = FishData.Norm(species, cm)
	if golden then
		announce(("%s speared a GOLDEN %s (%s)!"):format(player.Name, species.name, Util.FormatKg(kg)), "golden")
	elseif norm >= GameConfig.TrophyNorm then
		announce(("%s landed a trophy %s — %s!"):format(player.Name, species.name, Util.FormatKg(kg)), "trophy")
	elseif species.rarity == "Legendary" or species.rarity == "Mythic" then
		announce(("%s caught a %s %s!"):format(player.Name, species.rarity:lower(), species.name), "rare")
	end

	Remotes.Event("CatchMade"):FireClient(player, entry)
	Signals.FishCaught:Fire(player, entry, zoneId)
	DataService.PushSnapshot(player)
end

local function onThrowSpear(player: Player, origin: Vector3, direction: Vector3, charge: number)
	-- basic payload sanity
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" or type(charge) ~= "number" then
		return
	end
	if direction.Magnitude < 0.01 then
		return
	end
	charge = math.clamp(charge, 0.15, 1)

	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end
	local spear = GearData.ById[profile.gear.spear]
	if not spear then
		return
	end

	-- cooldown
	local now = os.clock()
	if now - (lastThrow[player] or 0) < spear.reload * 0.9 then
		return
	end
	lastThrow[player] = now

	-- origin must be at the player's character (anti-teleport-shot)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head or (head.Position - origin).Magnitude > 10 then
		return
	end

	local range = spear.range * (0.55 + 0.45 * charge)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { FishService.GetFolder(), Workspace.Terrain }
	params.IgnoreWater = true

	local result = Workspace:Raycast(origin, direction.Unit * range, params)
	local hitPos = result and result.Position or (origin + direction.Unit * range)

	-- show the shot to everyone nearby
	Remotes.Event("SpearVisual"):FireAllClients(player, origin, hitPos)

	local fish = result and result.Instance
	if not fish or not fish:GetAttribute("Species") then
		-- missed — spook anything close to the spear's end
		for _, other in ipairs(FishService.GetFolder():GetChildren()) do
			if other:IsA("BasePart") and (other.Position - hitPos).Magnitude < 14 then
				FishService.Spook(other, hitPos)
			end
		end
		return
	end

	local species = FishData.ById[fish:GetAttribute("Species")]
	if not species then
		return
	end

	-- bag space
	local bag = GearData.ById[profile.gear.bag]
	local capacity = bag and bag.capacity or 8
	if #profile.inventory >= capacity then
		Remotes.Event("Notify"):FireClient(player, {
			text = "Catch bag full! Sell your fish at the market.",
			kind = "bad",
		})
		FishService.Spook(fish, origin)
		return
	end

	-- the catch roll
	local kg = fish:GetAttribute("WeightKg") or 1
	local toughness = 0.7 + kg / 6
	local chance = math.clamp(spear.power * (0.4 + 0.6 * charge) / toughness, 0.08, 0.95)

	if rng:NextNumber() <= chance then
		registerCatch(player, profile, fish, species)
		FishService.RemoveFish(fish)
	else
		Remotes.Event("Notify"):FireClient(player, {
			text = ("The %s shook the spear and bolted!"):format(species.name),
			kind = "info",
		})
		FishService.Spook(fish, origin)
	end
end

function SpearService.Start()
	Remotes.Event("ThrowSpear").OnServerEvent:Connect(onThrowSpear)
	Players.PlayerRemoving:Connect(function(player)
		lastThrow[player] = nil
	end)
end

return SpearService
