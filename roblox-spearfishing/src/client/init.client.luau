--[[
	Kai Hohonu — client bootstrap.
	Fetches the profile snapshot, keeps it live, and starts every
	controller with a tiny shared state object:
		state.snapshot  — latest server profile snapshot
		state.changed   — signal fired on every snapshot update
		state.uiOpen()  — true while a blocking window is open
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Util = require(ReplicatedStorage.Shared.Util)

local HUD = require(script.HUD)
local SpearController = require(script.SpearController)
local ShopUI = require(script.ShopUI)
local BagUI = require(script.BagUI)
local QuestTracker = require(script.QuestTracker)
local FishBillboards = require(script.FishBillboards)

local state = {
	snapshot = nil,
	changed = Util.CreateSignal(),
	uiOpen = function()
		return (ShopUI.IsOpen and ShopUI.IsOpen()) or (BagUI.IsOpen and BagUI.IsOpen()) or false
	end,
}

Remotes.Event("ProfileChanged").OnClientEvent:Connect(function(snapshot)
	state.snapshot = snapshot
	state.changed:Fire(snapshot)
end)

HUD.Start(state)
SpearController.Start(state, HUD.Gui)
ShopUI.Start(state, HUD.Toast)
BagUI.Start(state)
QuestTracker.Start(state)
FishBillboards.Start()

-- initial snapshot (server may still be loading the profile)
task.spawn(function()
	local snapshot = Remotes.Function("GetSnapshot"):InvokeServer()
	if snapshot and not state.snapshot then
		state.snapshot = snapshot
		state.changed:Fire(snapshot)
	end
end)

print("[KaiHohonu] Client ready — hold click to charge your spear!")
