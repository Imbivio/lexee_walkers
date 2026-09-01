--[[
	MapBuilder
	Procedurally builds the whole map at server start: ocean, island rings,
	coral reef decorations, dock, NPC stands, FAD buoy, spawn point,
	tropical lighting and a slow day/night cycle. No place file needed —
	the game runs from a bare Rojo build.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local MapBuilder = {}

local rng = Random.new(7)

local function part(props: { [string]: any }): BasePart
	local p = Instance.new(props.Shape == "Cylinder" and "Part" or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		if key == "Shape" then
			p.Shape = Enum.PartType[value]
		else
			(p :: any)[key] = value
		end
	end
	return p
end

-- Terrain ----------------------------------------------------------------

local function buildTerrain()
	local terrain = Workspace.Terrain
	local half = GameConfig.WaterHalfSize
	local floorY = GameConfig.OceanFloorY

	-- 1. ocean water block
	terrain:FillBlock(
		CFrame.new(0, (GameConfig.SeaLevel + floorY) / 2, 0),
		Vector3.new(half * 2, GameConfig.SeaLevel - floorY, half * 2),
		Enum.Material.Water
	)
	-- 2. ocean floor slab under the water
	terrain:FillBlock(
		CFrame.new(0, floorY - 8, 0),
		Vector3.new(half * 2, 16, half * 2),
		Enum.Material.Slate
	)
	-- 3. island rings, largest first so smaller rings overwrite
	local bottom = floorY - 4
	for i = #GameConfig.Rings, 1, -1 do
		local ring = GameConfig.Rings[i]
		local height = ring.top - bottom
		terrain:FillCylinder(
			CFrame.new(0, bottom + height / 2, 0),
			height,
			ring.r,
			Enum.Material[ring.material]
		)
	end

	terrain.WaterTransparency = 0.35
	terrain.WaterReflectance = 0.4
	terrain.WaterColor = Color3.fromRGB(25, 118, 138)
	terrain.WaterWaveSize = 0.12
	terrain.WaterWaveSpeed = 12
end

-- Reef decorations -------------------------------------------------------

local CORAL_COLORS = {
	Color3.fromRGB(238, 130, 145),
	Color3.fromRGB(245, 170, 90),
	Color3.fromRGB(150, 110, 200),
	Color3.fromRGB(90, 190, 170),
	Color3.fromRGB(230, 210, 130),
	Color3.fromRGB(200, 90, 90),
}

local function buildReefDecor(folder: Folder)
	-- coral heads & boulders scattered across the reef shelves
	local clusters = {
		{ inner = 170, outer = 295, count = 90 },
		{ inner = 305, outer = 535, count = 70 },
		{ inner = 555, outer = 900, count = 35 },
	}
	for _, cluster in ipairs(clusters) do
		for _ = 1, cluster.count do
			local angle = rng:NextNumber() * math.pi * 2
			local radius = math.sqrt(rng:NextNumber()) * (cluster.outer - cluster.inner) + cluster.inner
			local x = math.cos(angle) * radius
			local z = math.sin(angle) * radius
			local floorTop = GameConfig.FloorAt(radius)
			local isRock = rng:NextNumber() < 0.3
			local size = rng:NextNumber(1.5, isRock and 7 or 4.5)
			local p = part({
				Shape = "Ball",
				Size = Vector3.new(size, size * rng:NextNumber(0.5, 1), size * rng:NextNumber(0.7, 1)),
				Position = Vector3.new(x, floorTop + size * 0.2, z),
				Color = isRock and Color3.fromRGB(105, 100, 95)
					or CORAL_COLORS[rng:NextInteger(1, #CORAL_COLORS)],
				Material = isRock and Enum.Material.Rock or Enum.Material.Coral,
				CanCollide = false,
				CanQuery = false,
			})
			p.Name = "Coral"
			p.Parent = folder
		end
	end

	-- a few palm "trees" on the island
	for _ = 1, 14 do
		local angle = rng:NextNumber() * math.pi * 2
		local radius = rng:NextNumber(20, 95)
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		local baseY = radius <= 70 and 11 or 9
		local trunkHeight = rng:NextNumber(9, 14)
		local trunk = part({
			Size = Vector3.new(1.2, trunkHeight, 1.2),
			Position = Vector3.new(x, baseY + trunkHeight / 2, z),
			Color = Color3.fromRGB(124, 92, 60),
			Material = Enum.Material.Wood,
			CanQuery = false,
		})
		trunk.Name = "Palm"
		trunk.Parent = folder
		local fronds = part({
			Shape = "Ball",
			Size = Vector3.new(8, 3, 8),
			Position = Vector3.new(x, baseY + trunkHeight + 1, z),
			Color = Color3.fromRGB(60, 140, 60),
			Material = Enum.Material.Grass,
			CanCollide = false,
			CanQuery = false,
		})
		fronds.Parent = folder
	end
end

-- Dock, buoy, spawn ------------------------------------------------------

local function buildDock(folder: Folder)
	local deck = part({
		Size = Vector3.new(75, 1, 8),
		Position = Vector3.new(160, 3, 0),
		Color = Color3.fromRGB(140, 108, 78),
		Material = Enum.Material.WoodPlanks,
	})
	deck.Name = "Dock"
	deck.Parent = folder
	-- ramp from beach up to the dock
	local ramp = part({
		Size = Vector3.new(14, 1, 8),
		CFrame = CFrame.new(117, 4.6, 0) * CFrame.Angles(0, 0, math.rad(25)),
		Color = Color3.fromRGB(140, 108, 78),
		Material = Enum.Material.WoodPlanks,
	})
	ramp.Parent = folder
	for x = 130, 195, 13 do
		for _, z in ipairs({ -3.5, 3.5 }) do
			local post = part({
				Size = Vector3.new(1, 10, 1),
				Position = Vector3.new(x, -1.5, z),
				Color = Color3.fromRGB(110, 84, 60),
				Material = Enum.Material.Wood,
				CanQuery = false,
			})
			post.Parent = folder
		end
	end
end

local function buildFAD(folder: Folder)
	local pos = GameConfig.FADPosition
	local buoy = part({
		Shape = "Ball",
		Size = Vector3.new(6, 6, 6),
		Position = Vector3.new(pos.X, 1, pos.Z),
		Color = Color3.fromRGB(235, 190, 40),
		Material = Enum.Material.SmoothPlastic,
	})
	buoy.Name = "FADBuoy"
	buoy.Parent = folder
	local pole = part({
		Size = Vector3.new(0.4, 8, 0.4),
		Position = Vector3.new(pos.X, 7, pos.Z),
		Color = Color3.fromRGB(200, 200, 200),
		Material = Enum.Material.Metal,
		CanQuery = false,
	})
	pole.Parent = folder
	local flag = part({
		Size = Vector3.new(0.2, 2, 3),
		Position = Vector3.new(pos.X, 10, pos.Z + 1.5),
		Color = Color3.fromRGB(220, 60, 50),
		Material = Enum.Material.Fabric,
		CanCollide = false,
		CanQuery = false,
	})
	flag.Parent = folder

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 210, 120)
	light.Range = 40
	light.Brightness = 2
	light.Parent = buoy
end

local function buildSpawn(folder: Folder)
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.Position = GameConfig.PlayerSpawn
	spawnLocation.Anchored = true
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	spawnLocation.Color = Color3.fromRGB(210, 195, 150)
	spawnLocation.Material = Enum.Material.Sand
	spawnLocation.TopSurface = Enum.SurfaceType.Smooth
	spawnLocation.Parent = folder
end

-- NPCs -------------------------------------------------------------------

local SHOP_FOR_NPC = {
	kimo = "market",
	leilani = "gear",
	kainoa = "boats",
}

local function buildNPC(folder: Folder, npc)
	local model = Instance.new("Model")
	model.Name = "NPC_" .. npc.id

	local stand = part({
		Size = Vector3.new(6, 1, 6),
		Position = npc.position - Vector3.new(0, 1.5, 0),
		Color = Color3.fromRGB(150, 120, 90),
		Material = Enum.Material.WoodPlanks,
	})
	stand.Parent = model

	local body = part({
		Size = Vector3.new(2, 4.4, 1.4),
		Position = npc.position + Vector3.new(0, 1.2, 0),
		Color = npc.color,
		Material = Enum.Material.SmoothPlastic,
	})
	body.Name = "Body"
	body.Parent = model

	local head = part({
		Shape = "Ball",
		Size = Vector3.new(1.8, 1.8, 1.8),
		Position = npc.position + Vector3.new(0, 4.2, 0),
		Color = Color3.fromRGB(198, 146, 108),
		Material = Enum.Material.SmoothPlastic,
	})
	head.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 220, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 90
	billboard.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = npc.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = billboard

	local roleLabel = Instance.new("TextLabel")
	roleLabel.Size = UDim2.new(1, 0, 0.45, 0)
	roleLabel.Position = UDim2.new(0, 0, 0.55, 0)
	roleLabel.BackgroundTransparency = 1
	roleLabel.Text = npc.role
	roleLabel.TextColor3 = Color3.fromRGB(255, 225, 140)
	roleLabel.TextStrokeTransparency = 0.4
	roleLabel.Font = Enum.Font.Gotham
	roleLabel.TextScaled = true
	roleLabel.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = npc.role
	prompt.ObjectText = npc.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	prompt.Triggered:Connect(function(player)
		Remotes.Event("OpenShop"):FireClient(player, SHOP_FOR_NPC[npc.id])
	end)

	model.Parent = folder
end

-- Lighting & day cycle ---------------------------------------------------

local function setupLighting()
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.3
	atmosphere.Color = Color3.fromRGB(199, 219, 224)
	atmosphere.Decay = Color3.fromRGB(92, 120, 150)
	atmosphere.Glare = 0.3
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting

	-- slow day/night cycle; menpachi only spawn at night
	task.spawn(function()
		local hoursPerSecond = 24 / (GameConfig.DayLengthMinutes * 60)
		while true do
			local dt = task.wait(1)
			Lighting.ClockTime = (Lighting.ClockTime + hoursPerSecond * dt) % 24
		end
	end)
end

-- ------------------------------------------------------------------------

function MapBuilder.Build()
	if Workspace:FindFirstChild("SpearfishIsland") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "SpearfishIsland"
	folder.Parent = Workspace

	buildTerrain()
	buildReefDecor(folder)
	buildDock(folder)
	buildFAD(folder)
	buildSpawn(folder)
	for _, npc in ipairs(GameConfig.NPCs) do
		buildNPC(folder, npc)
	end
	setupLighting()
end

return MapBuilder
