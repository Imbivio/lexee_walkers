--[[
	QuestTracker — always-visible panel on the right listing the active
	quest from each NPC line with a progress bar. Rebuilt from snapshots.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestData = require(ReplicatedStorage.Shared.QuestData)
local Util = require(ReplicatedStorage.Shared.Util)
local UIKit = require(script.Parent.UIKit)

local QuestTracker = {}

local player = Players.LocalPlayer

local NPC_NAMES = {
	kimo = "Uncle Kimo",
	leilani = "Leilani",
	kainoa = "Kainoa",
}

function QuestTracker.Start(state)
	local gui = UIKit.new("ScreenGui", {
		Name = "SpearfishQuests",
		ResetOnSpawn = false,
		DisplayOrder = 4,
	})
	gui.Parent = player:WaitForChild("PlayerGui")

	local holder = UIKit.new("Frame", {
		Size = UDim2.new(0, 250, 0, 400),
		Position = UDim2.new(1, -262, 0, 90),
		BackgroundTransparency = 1,
		[UIKit.Children] = {
			UIKit.new("UIListLayout", {
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	holder.Parent = gui

	local function rebuild()
		local snapshot = state.snapshot
		if not snapshot then
			return
		end
		UIKit.clear(holder)

		UIKit.label({
			Size = UDim2.new(1, 0, 0, 18),
			Text = "QUESTS",
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = UIKit.Colors.TextDim,
			TextStrokeTransparency = 0.6,
		}).Parent = holder

		for _, active in ipairs(snapshot.quests.active) do
			local quest = QuestData.ById[active.id]
			if not quest then
				continue
			end
			local target = QuestData.GoalTarget(quest)
			local progress = math.min(active.progress or 0, target)

			local card = UIKit.new("Frame", {
				Size = UDim2.new(1, 0, 0, 84),
				BackgroundColor3 = UIKit.Colors.Panel,
				BackgroundTransparency = 0.25,
				[UIKit.Children] = { UIKit.corner(8), UIKit.padding(8) },
			})
			UIKit.label({
				Size = UDim2.new(1, 0, 0, 14),
				Text = NPC_NAMES[quest.npc] or quest.npc,
				TextSize = 11,
				TextColor3 = UIKit.Colors.Accent,
			}).Parent = card
			UIKit.label({
				Size = UDim2.new(1, 0, 0, 17),
				Position = UDim2.new(0, 0, 0, 13),
				Text = quest.title,
				Font = Enum.Font.GothamBold,
				TextSize = 14,
			}).Parent = card
			UIKit.label({
				Size = UDim2.new(1, 0, 0, 26),
				Position = UDim2.new(0, 0, 0, 30),
				Text = quest.desc,
				TextSize = 11,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextColor3 = UIKit.Colors.TextDim,
			}).Parent = card

			local bar = UIKit.new("Frame", {
				Size = UDim2.new(1, -60, 0, 8),
				Position = UDim2.new(0, 0, 1, -10),
				BackgroundColor3 = UIKit.Colors.PanelLight,
				[UIKit.Children] = { UIKit.corner(4) },
			})
			bar.Parent = card
			UIKit.new("Frame", {
				Size = UDim2.new(math.clamp(progress / target, 0, 1), 0, 1, 0),
				BackgroundColor3 = UIKit.Colors.Good,
				BorderSizePixel = 0,
				[UIKit.Children] = { UIKit.corner(4) },
			}).Parent = bar
			UIKit.label({
				Size = UDim2.new(0, 55, 0, 12),
				Position = UDim2.new(1, -55, 1, -13),
				Text = Util.Comma(progress) .. "/" .. Util.Comma(target),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = UIKit.Colors.Text,
			}).Parent = card

			card.Parent = holder
		end
	end

	state.changed:Connect(rebuild)
	rebuild()
end

return QuestTracker
