--[[
	Signals — server-side event bus so services stay decoupled.
	QuestService listens here; gameplay services fire.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = require(ReplicatedStorage.Shared.Util)

return {
	FishCaught = Util.CreateSignal(), -- (player, catchEntry, zoneId)
	FishSold = Util.CreateSignal(), -- (player, coinsGained, count)
	GearPurchased = Util.CreateSignal(), -- (player, gearId)
	BreathLevelUp = Util.CreateSignal(), -- (player, newLevel)
	DepthRecord = Util.CreateSignal(), -- (player, depthStuds)
	ProfileLoaded = Util.CreateSignal(), -- (player, profile)
}
