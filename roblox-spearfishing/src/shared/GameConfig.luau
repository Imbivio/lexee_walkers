--[[
	GameConfig
	Central tuning for Kai Hohonu (Deep Sea) — Hawaiian spearfishing game.
	Progression is deliberately slow: breath training and gear prices are
	tuned so a full account takes tens of hours to max out.
]]

local GameConfig = {}

-- World -----------------------------------------------------------------

GameConfig.SeaLevel = 0
GameConfig.WaterHalfSize = 2200 -- ocean extends x/z in [-2200, 2200]
GameConfig.OceanFloorY = -108

-- Concentric island rings used by both MapBuilder (terrain) and
-- FishService (sea-floor height lookup). Ordered smallest radius first.
-- floorAt(r) = top of the first ring whose radius >= r.
GameConfig.Rings = {
	{ r = 70, top = 11, material = "LeafyGrass" },
	{ r = 110, top = 9, material = "Sand" },
	{ r = 160, top = 2, material = "Sand" },
	{ r = 230, top = -7, material = "Sand" },
	{ r = 300, top = -13, material = "Sandstone" },
	{ r = 540, top = -29, material = "Sandstone" },
	{ r = 990, top = -86, material = "Rock" },
}

function GameConfig.FloorAt(radius: number): number
	for _, ring in ipairs(GameConfig.Rings) do
		if radius <= ring.r then
			return ring.top
		end
	end
	return GameConfig.OceanFloorY
end

-- Fishing zones. Annulus zones use inner/outer radius around the island;
-- disc zones (open ocean) use center + radius. depthMin/Max are studs
-- below sea level that fish swim at (clamped above the sea floor).
GameConfig.Zones = {
	{
		id = "shallow_reef",
		name = "Shallow Reef",
		inner = 168,
		outer = 295,
		depthMin = 3,
		depthMax = 12,
		count = 42,
	},
	{
		id = "outer_reef",
		name = "Outer Reef",
		inner = 305,
		outer = 535,
		depthMin = 8,
		depthMax = 27,
		count = 34,
	},
	{
		id = "dropoff",
		name = "The Drop-off",
		inner = 550,
		outer = 980,
		depthMin = 18,
		depthMax = 80,
		count = 26,
	},
	{
		id = "open_ocean",
		name = "Open Ocean (FAD)",
		center = Vector2.new(1500, 0), -- x, z
		radius = 340,
		depthMin = 4,
		depthMax = 55,
		count = 20,
	},
}

GameConfig.FADPosition = Vector3.new(1500, 0, 0)
GameConfig.DockBoatSpawn = Vector3.new(215, 0, 0)
GameConfig.PlayerSpawn = Vector3.new(60, 12, 0)

GameConfig.NPCs = {
	{ id = "kimo", name = "Uncle Kimo", role = "Fish Market", position = Vector3.new(85, 10.5, 32), color = Color3.fromRGB(214, 121, 66) },
	{ id = "leilani", name = "Leilani", role = "Dive Shop", position = Vector3.new(85, 10.5, -32), color = Color3.fromRGB(88, 160, 189) },
	{ id = "kainoa", name = "Kainoa", role = "Boat Dock", position = Vector3.new(195, 4.5, 6), color = Color3.fromRGB(94, 142, 94) },
}

GameConfig.SellRange = 24 -- studs from Uncle Kimo to sell fish

-- Breath / freediving ----------------------------------------------------

GameConfig.Breath = {
	BaseSeconds = 25, -- starting breath hold
	SecondsPerLevel = 2, -- +2s max breath per lung level
	MaxLevel = 50, -- max breath 25 + 100 = 125s
	XPPerSecond = 1.0, -- lung XP per second underwater
	DepthXPBonus = 0.02, -- +2% XP per stud of depth (deep dives train faster)
	SurfaceRecoveryRate = 6, -- breath refills 6x faster than base drain
	DrainDepthFactor = 1 / 45, -- drain/s = 1 + depth * factor
	BlackoutDamagePerSecond = 20,
	BlackoutFishLoss = 0.25, -- fraction of unsold catch dropped on blackout
}

-- Total underwater seconds required to reach a lung level. Slow curve:
-- level 1 ≈ 1.5 min, level 10 ≈ 75 min, level 50 ≈ 19 hours of dive time.
function GameConfig.Breath.XPForLevel(level: number): number
	return math.floor(90 * level ^ 1.7)
end

function GameConfig.Breath.LevelFromXP(xp: number): number
	local level = 0
	while level < GameConfig.Breath.MaxLevel
		and xp >= GameConfig.Breath.XPForLevel(level + 1) do
		level += 1
	end
	return level
end

function GameConfig.Breath.MaxBreathForLevel(level: number): number
	return GameConfig.Breath.BaseSeconds + GameConfig.Breath.SecondsPerLevel * level
end

GameConfig.DefaultWalkSpeed = 16

-- Catch / economy --------------------------------------------------------

GameConfig.GoldenChance = 1 / 200 -- golden variant odds
GameConfig.GoldenValueMult = 6
GameConfig.TrophyNorm = 0.85 -- >= 85% of species max length counts as trophy

GameConfig.RaritySpawnWeights = {
	Common = 100,
	Uncommon = 45,
	Rare = 14,
	Epic = 5,
	Legendary = 1.5,
	Mythic = 0.3,
}

GameConfig.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(96, 200, 96),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(190, 100, 255),
	Legendary = Color3.fromRGB(255, 170, 40),
	Mythic = Color3.fromRGB(255, 70, 90),
}

-- Depth darkness (client overlay). Dive lights cut through it.
GameConfig.DarknessStartDepth = 30
GameConfig.DarknessFullDepth = 90
GameConfig.MaxDarkness = 0.8

-- Day/night cycle. Some fish (menpachi) only come out at night.
GameConfig.DayLengthMinutes = 20
GameConfig.NightStart = 18.5 -- ClockTime
GameConfig.NightEnd = 5.5

function GameConfig.IsNight(clockTime: number): boolean
	return clockTime >= GameConfig.NightStart or clockTime <= GameConfig.NightEnd
end

-- Fish AI ----------------------------------------------------------------

GameConfig.Fish = {
	UpdateRate = 10, -- AI ticks per second
	RespawnSeconds = 45, -- delay before a caught fish's slot refills
	MaxLifetime = 480, -- fish despawn & respawn to reshuffle the reef
	FleeSeconds = 3.5,
	FleeSpeedMult = 3,
}

return GameConfig
