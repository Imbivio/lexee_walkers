--[[
	Kai Hohonu — Hawaiian spearfishing game, server bootstrap.
	Order matters: remotes + data first, then the world, then gameplay.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- creates the Remotes folder before any client can ask for it
require(ReplicatedStorage.Shared.Remotes).Event("Notify")

local DataService = require(script.DataService)
local MapBuilder = require(script.MapBuilder)
local FishService = require(script.FishService)
local BreathService = require(script.BreathService)
local BoatService = require(script.BoatService)
local SpearService = require(script.SpearService)
local EconomyService = require(script.EconomyService)
local QuestService = require(script.QuestService)

DataService.Start()
MapBuilder.Build()
FishService.Start()
BreathService.Start()
BoatService.Start()
SpearService.Start()
EconomyService.Start()
QuestService.Start()

print("[KaiHohonu] Server started — e komo mai, dive safe!")
