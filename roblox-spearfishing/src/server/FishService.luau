--[[
	FishService
	Spawns and simulates every fish in the ocean. Fish are anchored parts
	tagged "Fish" carrying attributes (Species, SizeCm, WeightKg, Rarity,
	Golden, Zone); the client renders nameplates from the tag.

	Spawning: each zone keeps `count` slots filled. A slot rolls a species
	from the zone's table weighted by rarity, rolls a size skewed small,
	and has a 1/200 chance of being a Golden variant (6x value, sparkles).

	AI: fish cruise between random waypoints inside their zone; when a
	player gets inside spookRadius (or a spear misses them) they flee fast
	for a few seconds. Rarer fish are faster and spook from further away.
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local FishData = require(ReplicatedStorage.Shared.FishData)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Util = require(ReplicatedStorage.Shared.Util)

local FishService = {}

local rng = Random.new()
local fishFolder: Folder
local activeFish: { [BasePart]: any } = {} -- part -> state
local zoneSpawnTables: { [string]: { any } } = {}

-- Build per-zone weighted species tables once
local function buildSpawnTables()
	for _, zone in ipairs(GameConfig.Zones) do
		local entries = {}
		for _, species in ipairs(FishData.Species) do
			if table.find(species.zones, zone.id) then
				table.insert(entries, {
					species = species,
					weight = GameConfig.RaritySpawnWeights[species.rarity] or 1,
				})
			end
		end
		zoneSpawnTables[zone.id] = entries
	end
end

-- Position helpers -------------------------------------------------------

local function randomZonePosition(zone): Vector3
	local x, z
	if zone.center then
		local angle = rng:NextNumber() * math.pi * 2
		local radius = math.sqrt(rng:NextNumber()) * zone.radius
		x = zone.center.X + math.cos(angle) * radius
		z = zone.center.Y + math.sin(angle) * radius
	else
		local angle = rng:NextNumber() * math.pi * 2
		local radius = rng:NextNumber(zone.inner, zone.outer)
		x = math.cos(angle) * radius
		z = math.sin(angle) * radius
	end
	local distFromIsland = math.sqrt(x * x + z * z)
	local floorY = GameConfig.FloorAt(distFromIsland)
	local y = -rng:NextNumber(zone.depthMin, zone.depthMax)
	y = math.clamp(y, floorY + 2, GameConfig.SeaLevel - 2)
	return Vector3.new(x, y, z)
end

-- Spawning ---------------------------------------------------------------

local function spawnFish(zone)
	local entries = zoneSpawnTables[zone.id]
	local isNight = GameConfig.IsNight(Lighting.ClockTime)

	-- filter night-only species during the day
	local pool = {}
	for _, entry in ipairs(entries) do
		if not entry.species.nightOnly or isNight then
			table.insert(pool, entry)
		end
	end
	local pick = Util.WeightedPick(pool, rng)
	if not pick then
		return
	end
	local species = pick.species

	-- size roll skewed toward small fish; big ones are the trophies
	local norm = rng:NextNumber() ^ 2.2
	local cm = species.minCm + (species.maxCm - species.minCm) * norm
	local kg = FishData.WeightKg(species, cm)
	local golden = rng:NextNumber() < GameConfig.GoldenChance

	local length = math.max(1.2, cm / 18) -- studs
	local fish = Instance.new("Part")
	fish.Name = species.id
	fish.Size = Vector3.new(length * 0.35, length * 0.32, length)
	fish.Color = golden and Color3.fromRGB(255, 200, 40) or species.color
	fish.Material = golden and Enum.Material.Neon or Enum.Material.SmoothPlastic
	fish.Anchored = true
	fish.CanCollide = false
	fish.CanTouch = false
	fish.CastShadow = false

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = fish

	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.15, length * 0.28, length * 0.3)
	tail.Color = fish.Color
	tail.Material = fish.Material
	tail.Anchored = true
	tail.CanCollide = false
	tail.CanQuery = false
	tail.CanTouch = false
	tail.CastShadow = false
	tail.Parent = fish

	if golden then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Rate = 6
		sparkle.Lifetime = NumberRange.new(0.6, 1.2)
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.Size = NumberSequence.new(0.4)
		sparkle.Parent = fish
	end

	fish:SetAttribute("Species", species.id)
	fish:SetAttribute("SizeCm", math.floor(cm * 10 + 0.5) / 10)
	fish:SetAttribute("WeightKg", Util.RoundKg(kg))
	fish:SetAttribute("Rarity", species.rarity)
	fish:SetAttribute("Golden", golden)
	fish:SetAttribute("Zone", zone.id)
	CollectionService:AddTag(fish, "Fish")

	local position = randomZonePosition(zone)
	fish.CFrame = CFrame.new(position)
	tail.CFrame = fish.CFrame * CFrame.new(0, 0, fish.Size.Z / 2 + tail.Size.Z / 2)

	activeFish[fish] = {
		species = species,
		zone = zone,
		position = position,
		waypoint = randomZonePosition(zone),
		fleeUntil = 0,
		fleeDir = Vector3.zAxis,
		bornAt = os.clock(),
		phase = rng:NextNumber() * math.pi * 2,
	}
	fish.Parent = fishFolder
end

local function countZoneFish(zoneId: string): number
	local count = 0
	for _, state in pairs(activeFish) do
		if state.zone.id == zoneId then
			count += 1
		end
	end
	return count
end

-- AI loop ----------------------------------------------------------------

local function stepFish(dt: number)
	local now = os.clock()
	local playerRoots = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			table.insert(playerRoots, root.Position)
		end
	end

	for fish, state in pairs(activeFish) do
		if not fish.Parent then
			activeFish[fish] = nil
			continue
		end

		-- lifetime reshuffle
		if now - state.bornAt > GameConfig.Fish.MaxLifetime then
			FishService.RemoveFish(fish, true)
			continue
		end

		local species = state.species
		local fleeing = now < state.fleeUntil

		-- proximity spook
		if not fleeing then
			for _, rootPos in ipairs(playerRoots) do
				local offset = state.position - rootPos
				if offset.Magnitude < species.spookRadius then
					state.fleeUntil = now + GameConfig.Fish.FleeSeconds
					state.fleeDir = offset.Magnitude > 0.1 and offset.Unit or Vector3.zAxis
					fleeing = true
					break
				end
			end
		end

		local target, speed
		if fleeing then
			target = state.position + state.fleeDir * 50
			speed = species.speed * GameConfig.Fish.FleeSpeedMult
		else
			target = state.waypoint
			speed = species.speed
			if (target - state.position).Magnitude < 4 then
				state.waypoint = randomZonePosition(state.zone)
				target = state.waypoint
			end
		end

		local toTarget = target - state.position
		if toTarget.Magnitude > 0.1 then
			local step = toTarget.Unit * math.min(speed * dt, toTarget.Magnitude)
			local newPos = state.position + step
			-- keep fish in the water column
			local dist = math.sqrt(newPos.X ^ 2 + newPos.Z ^ 2)
			local floorY = GameConfig.FloorAt(dist)
			local clampedY = math.clamp(newPos.Y, floorY + 1.5, GameConfig.SeaLevel - 1.5)
			state.position = Vector3.new(newPos.X, clampedY, newPos.Z)
		end

		-- gentle bobbing + face travel direction
		state.phase += dt * 3
		local bob = math.sin(state.phase) * 0.3
		local look = toTarget.Magnitude > 0.1 and toTarget.Unit or fish.CFrame.LookVector
		local flatLook = Vector3.new(look.X, look.Y * 0.6, look.Z)
		if flatLook.Magnitude < 0.05 then
			flatLook = Vector3.zAxis
		end
		fish.CFrame = CFrame.lookAt(
			state.position + Vector3.new(0, bob, 0),
			state.position + Vector3.new(0, bob, 0) + flatLook
		)
		local tail = fish:FindFirstChild("Tail")
		if tail then
			local wag = math.sin(state.phase * 4) * 0.5
			tail.CFrame = fish.CFrame * CFrame.new(0, 0, fish.Size.Z / 2 + tail.Size.Z / 2)
				* CFrame.Angles(0, wag, 0)
		end
	end
end

-- Public API -------------------------------------------------------------

function FishService.GetState(fish: BasePart)
	return activeFish[fish]
end

function FishService.Spook(fish: BasePart, fromPosition: Vector3)
	local state = activeFish[fish]
	if state then
		local away = state.position - fromPosition
		state.fleeUntil = os.clock() + GameConfig.Fish.FleeSeconds
		state.fleeDir = away.Magnitude > 0.1 and away.Unit or Vector3.zAxis
	end
end

function FishService.RemoveFish(fish: BasePart, silent: boolean?)
	activeFish[fish] = nil
	fish:Destroy()
end

function FishService.GetFolder(): Folder
	return fishFolder
end

function FishService.Start()
	fishFolder = Instance.new("Folder")
	fishFolder.Name = "Fish"
	fishFolder.Parent = Workspace

	buildSpawnTables()

	-- initial stock
	for _, zone in ipairs(GameConfig.Zones) do
		for _ = 1, zone.count do
			spawnFish(zone)
		end
	end

	-- restock loop
	task.spawn(function()
		while true do
			task.wait(GameConfig.Fish.RespawnSeconds / 4)
			for _, zone in ipairs(GameConfig.Zones) do
				if countZoneFish(zone.id) < zone.count then
					spawnFish(zone)
				end
			end
		end
	end)

	-- AI at a throttled tick to keep replication cheap
	local accumulator = 0
	local tickTime = 1 / GameConfig.Fish.UpdateRate
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator >= tickTime then
			stepFish(accumulator)
			accumulator = 0
		end
	end)
end

return FishService
