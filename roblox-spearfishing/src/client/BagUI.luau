--[[
	BagUI — [B] toggles the catch bag & fishdex window.
	Bag tab: what you're carrying and what it's worth.
	Fishdex tab: all species; undiscovered show as "???". Tracks count,
	best size and golden finds — the collection is a long-term goal.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local FishData = require(ReplicatedStorage.Shared.FishData)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GearData = require(ReplicatedStorage.Shared.GearData)
local Util = require(ReplicatedStorage.Shared.Util)
local UIKit = require(script.Parent.UIKit)

local BagUI = {}

local player = Players.LocalPlayer

function BagUI.Start(state)
	local gui = UIKit.new("ScreenGui", {
		Name = "SpearfishBag",
		ResetOnSpawn = false,
		DisplayOrder = 10,
	})
	gui.Parent = player:WaitForChild("PlayerGui")

	local window, content = UIKit.window(gui, "Catch Bag & Fishdex", UDim2.new(0, 480, 0, 440))

	local currentTab = "Bag"

	local tabBar = UIKit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		[UIKit.Children] = {
			UIKit.new("UIListLayout", {
				Padding = UDim.new(0, 6),
				FillDirection = Enum.FillDirection.Horizontal,
			}),
		},
	})
	tabBar.Parent = content

	local list = UIKit.new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -40),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		[UIKit.Children] = {
			UIKit.new("UIListLayout", {
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	list.Parent = content

	local rebuild

	local function row(height: number): Frame
		local frame = UIKit.new("Frame", {
			Size = UDim2.new(1, -8, 0, height),
			BackgroundColor3 = UIKit.Colors.PanelLight,
			[UIKit.Children] = { UIKit.corner(8), UIKit.padding(8) },
		})
		frame.Parent = list
		return frame
	end

	local function buildBag()
		local snapshot = state.snapshot
		local inventory = snapshot.inventory or {}
		local bag = GearData.ById[snapshot.gear.bag]
		local capacity = bag and bag.capacity or 8

		local total = 0
		for _, entry in ipairs(inventory) do
			total += entry.value
		end

		local header = row(40)
		UIKit.label({
			Size = UDim2.new(1, 0, 1, 0),
			Text = ("%d / %d fish · worth 🪙 %s · sell at the Fish Market"):format(
				#inventory, capacity, Util.Comma(total)
			),
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = UIKit.Colors.Coin,
		}).Parent = header

		for _, entry in ipairs(inventory) do
			local species = FishData.ById[entry.species]
			local frame = row(44)
			local name = species and species.name or entry.species
			if entry.golden then
				name = "✨ " .. name
			end
			UIKit.label({
				Size = UDim2.new(0.5, 0, 1, 0),
				Text = name,
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				TextColor3 = species and GameConfig.RarityColors[species.rarity] or UIKit.Colors.Text,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}).Parent = frame
			UIKit.label({
				Size = UDim2.new(0.3, 0, 1, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				Text = Util.FormatCm(entry.cm) .. " · " .. Util.FormatKg(entry.kg),
				TextSize = 13,
				TextColor3 = UIKit.Colors.TextDim,
			}).Parent = frame
			UIKit.label({
				Size = UDim2.new(0.2, 0, 1, 0),
				Position = UDim2.new(0.8, 0, 0, 0),
				Text = "🪙 " .. Util.Comma(entry.value),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = UIKit.Colors.Coin,
			}).Parent = frame
		end
	end

	local function buildDex()
		local snapshot = state.snapshot
		local dex = snapshot.fishdex or {}

		local discovered = 0
		for _ in pairs(dex) do
			discovered += 1
		end
		local header = row(36)
		UIKit.label({
			Size = UDim2.new(1, 0, 1, 0),
			Text = ("Discovered %d / %d species"):format(discovered, #FishData.Species),
			Font = Enum.Font.GothamBold,
			TextSize = 14,
		}).Parent = header

		for _, species in ipairs(FishData.Species) do
			local record = dex[species.id]
			local frame = row(46)
			local rarityColor = GameConfig.RarityColors[species.rarity] or UIKit.Colors.Text
			if record then
				local goldenMark = record.golden and "  ✨" or ""
				UIKit.label({
					Size = UDim2.new(0.55, 0, 0, 20),
					Text = species.name .. goldenMark,
					Font = Enum.Font.GothamBold,
					TextSize = 14,
					TextColor3 = rarityColor,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}).Parent = frame
				UIKit.label({
					Size = UDim2.new(0.55, 0, 0, 16),
					Position = UDim2.new(0, 0, 0, 20),
					Text = species.english .. " · " .. species.rarity
						.. (species.invasive and " · INVASIVE" or ""),
					TextSize = 11,
					TextColor3 = UIKit.Colors.TextDim,
				}).Parent = frame
				UIKit.label({
					Size = UDim2.new(0.45, 0, 1, 0),
					Position = UDim2.new(0.55, 0, 0, 0),
					Text = ("x%d · best %s / %s"):format(
						record.count,
						Util.FormatCm(record.bestCm),
						Util.FormatKg(record.bestKg)
					),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextColor3 = UIKit.Colors.Text,
				}).Parent = frame
			else
				UIKit.label({
					Size = UDim2.new(0.55, 0, 1, 0),
					Text = "???",
					Font = Enum.Font.GothamBold,
					TextSize = 14,
					TextColor3 = UIKit.Colors.TextDim,
				}).Parent = frame
				UIKit.label({
					Size = UDim2.new(0.45, 0, 1, 0),
					Position = UDim2.new(0.55, 0, 0, 0),
					Text = species.rarity,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
					TextColor3 = rarityColor,
				}).Parent = frame
			end
		end
	end

	rebuild = function()
		if not state.snapshot then
			return
		end
		UIKit.clear(list)
		UIKit.clear(tabBar)
		for _, tabName in ipairs({ "Bag", "Fishdex" }) do
			local isActive = tabName == currentTab
			UIKit.button({
				Size = UDim2.new(0, 100, 0, 28),
				Text = tabName,
				BackgroundColor3 = isActive and UIKit.Colors.Accent or UIKit.Colors.PanelLight,
				TextColor3 = isActive and Color3.fromRGB(10, 25, 32) or UIKit.Colors.Text,
			}, function()
				currentTab = tabName
				rebuild()
			end).Parent = tabBar
		end
		if currentTab == "Bag" then
			buildBag()
		else
			buildDex()
		end
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.B then
			if window.Visible then
				window.Visible = false
			else
				rebuild()
				window.Visible = true
			end
		end
	end)

	state.changed:Connect(function()
		if window.Visible then
			rebuild()
		end
	end)

	BagUI.IsOpen = function()
		return window.Visible
	end
end

return BagUI
