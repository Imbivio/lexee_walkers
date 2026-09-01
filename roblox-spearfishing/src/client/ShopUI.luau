--[[
	ShopUI
	One window, three modes, opened by walking up to an NPC:
	  market — Uncle Kimo: sell your catch
	  gear   — Leilani: spears / fins / bags / lights
	  boats  — Kainoa: buy boats, take them out, stow them
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishData = require(ReplicatedStorage.Shared.FishData)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GearData = require(ReplicatedStorage.Shared.GearData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Util = require(ReplicatedStorage.Shared.Util)
local UIKit = require(script.Parent.UIKit)

local ShopUI = {}

local player = Players.LocalPlayer

local TITLES = {
	market = "Uncle Kimo's Fish Market",
	gear = "Leilani's Dive Shop",
	boats = "Kainoa's Boat Dock",
}

local GEAR_TABS = { "Spears", "Fins", "Bags", "Lights" }

function ShopUI.Start(state, toast)
	local gui = UIKit.new("ScreenGui", {
		Name = "SpearfishShop",
		ResetOnSpawn = false,
		DisplayOrder = 10,
	})
	gui.Parent = player:WaitForChild("PlayerGui")

	local window, content = UIKit.window(gui, "Shop", UDim2.new(0, 460, 0, 420))
	local titleLabel = window.TitleBar:FindFirstChildOfClass("TextLabel")

	local currentMode = nil
	local currentTab = "Spears"

	local list = UIKit.new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -44),
		Position = UDim2.new(0, 0, 0, 44),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		[UIKit.Children] = {
			UIKit.new("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	list.Parent = content

	local topBar = UIKit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		[UIKit.Children] = {
			UIKit.new("UIListLayout", {
				Padding = UDim.new(0, 6),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	topBar.Parent = content

	local rebuild -- fwd decl

	local function itemRow(labelText: string, descText: string, buttonText: string?, buttonColor: Color3?, onClick: (() -> ())?)
		local row = UIKit.new("Frame", {
			Size = UDim2.new(1, -8, 0, 58),
			BackgroundColor3 = UIKit.Colors.PanelLight,
			[UIKit.Children] = { UIKit.corner(8), UIKit.padding(8) },
		})
		UIKit.label({
			Size = UDim2.new(1, -110, 0, 20),
			Text = labelText,
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}).Parent = row
		UIKit.label({
			Size = UDim2.new(1, -110, 0, 28),
			Position = UDim2.new(0, 0, 0, 20),
			Text = descText,
			TextSize = 12,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = UIKit.Colors.TextDim,
		}).Parent = row
		if buttonText then
			local btn = UIKit.button({
				Size = UDim2.new(0, 96, 0, 30),
				Position = UDim2.new(1, -98, 0.5, -15),
				BackgroundColor3 = buttonColor or UIKit.Colors.Accent,
				Text = buttonText,
				TextSize = 13,
			}, onClick or function() end)
			btn.Parent = row
		end
		row.Parent = list
		return row
	end

	-- Market -------------------------------------------------------------

	local function buildMarket()
		local snapshot = state.snapshot
		if not snapshot then
			return
		end
		local inventory = snapshot.inventory or {}

		local total = 0
		for _, entry in ipairs(inventory) do
			total += entry.value
		end

		local sellAll = UIKit.button({
			Size = UDim2.new(0, 200, 0, 30),
			Text = ("Sell All (🪙 %s)"):format(Util.Comma(total)),
			BackgroundColor3 = UIKit.Colors.Coin,
		}, function()
			local ok, message = Remotes.Function("SellFish"):InvokeServer(nil)
			toast(message, ok and "good" or "bad")
		end)
		sellAll.Parent = topBar

		UIKit.label({
			Size = UDim2.new(0, 180, 0, 30),
			Text = ("%d fish in bag"):format(#inventory),
			TextColor3 = UIKit.Colors.TextDim,
		}).Parent = topBar

		if #inventory == 0 then
			itemRow("Empty bag", "Go spear something! The reef is right there.", nil, nil, nil)
			return
		end
		for _, entry in ipairs(inventory) do
			local species = FishData.ById[entry.species]
			local name = species and species.name or entry.species
			if entry.golden then
				name = "✨ GOLDEN " .. name
			end
			itemRow(
				name,
				("%s · %s · %s"):format(
					species and species.rarity or "?",
					Util.FormatCm(entry.cm),
					Util.FormatKg(entry.kg)
				),
				"🪙 " .. Util.Comma(entry.value),
				UIKit.Colors.Coin,
				function()
					local ok, message = Remotes.Function("SellFish"):InvokeServer({ entry.uid })
					toast(message, ok and "good" or "bad")
				end
			)
		end
	end

	-- Gear ---------------------------------------------------------------

	local function gearButtonFor(item)
		local snapshot = state.snapshot
		local slot = GearData.CategorySlot[GearData.CategoryOf[item.id]]
		if snapshot.gear[slot] == item.id then
			return "EQUIPPED", UIKit.Colors.Good, function() end
		elseif snapshot.owned[item.id] then
			return "EQUIP", UIKit.Colors.Accent, function()
				local ok, message = Remotes.Function("EquipGear"):InvokeServer(item.id)
				toast(message, ok and "good" or "bad")
			end
		else
			local locked = item.questLock and not snapshot.quests.completed[item.questLock]
			if locked then
				return "🔒 QUEST", UIKit.Colors.TextDim, function()
					local ok, message = Remotes.Function("BuyGear"):InvokeServer(item.id)
					toast(message, ok and "good" or "bad")
				end
			end
			return "🪙 " .. Util.Comma(item.price), UIKit.Colors.Coin, function()
				local ok, message = Remotes.Function("BuyGear"):InvokeServer(item.id)
				toast(message, ok and "good" or "bad")
			end
		end
	end

	local function statLine(item): string
		if item.range then
			return ("Range %d · Power %.1f · Reload %.1fs — %s"):format(item.range, item.power, item.reload, item.desc)
		elseif item.swimSpeed then
			return ("Swim speed %d — %s"):format(item.swimSpeed, item.desc)
		elseif item.capacity then
			return ("Holds %d fish — %s"):format(item.capacity, item.desc)
		elseif item.lightFactor then
			return ("Cuts %d%% of the dark — %s"):format(item.lightFactor * 100, item.desc)
		elseif item.speed then
			local extra = item.sellAboard and (" · sell at sea for %d%%"):format(item.sellAboard * 100) or ""
			return ("Top speed %d%s — %s"):format(item.speed, extra, item.desc)
		end
		return item.desc
	end

	local function buildGear()
		for _, tabName in ipairs(GEAR_TABS) do
			local isActive = tabName == currentTab
			local tabBtn = UIKit.button({
				Size = UDim2.new(0, 92, 0, 30),
				Text = tabName,
				BackgroundColor3 = isActive and UIKit.Colors.Accent or UIKit.Colors.PanelLight,
				TextColor3 = isActive and Color3.fromRGB(10, 25, 32) or UIKit.Colors.Text,
			}, function()
				currentTab = tabName
				rebuild()
			end)
			tabBtn.Parent = topBar
		end
		for _, item in ipairs(GearData[currentTab]) do
			local text, color, onClick = gearButtonFor(item)
			itemRow(item.name, statLine(item), text, color, onClick)
		end
	end

	-- Boats --------------------------------------------------------------

	local function buildBoats()
		local snapshot = state.snapshot
		local ownsAny = false
		for _, item in ipairs(GearData.Boats) do
			if snapshot.owned[item.id] then
				ownsAny = true
			end
		end
		if ownsAny then
			local takeOut = UIKit.button({
				Size = UDim2.new(0, 150, 0, 30),
				Text = "⚓ Take Out Boat",
			}, function()
				local ok, message = Remotes.Function("SpawnBoat"):InvokeServer()
				toast(message, ok and "good" or "bad")
				if ok then
					window.Visible = false
				end
			end)
			takeOut.Parent = topBar
			local stow = UIKit.button({
				Size = UDim2.new(0, 100, 0, 30),
				Text = "Stow Boat",
				BackgroundColor3 = UIKit.Colors.PanelLight,
				TextColor3 = UIKit.Colors.Text,
			}, function()
				local _, message = Remotes.Function("StowBoat"):InvokeServer()
				toast(message, "info")
			end)
			stow.Parent = topBar
		else
			UIKit.label({
				Size = UDim2.new(1, 0, 0, 30),
				Text = "A boat opens up the drop-off and the deep blue.",
				TextColor3 = UIKit.Colors.TextDim,
			}).Parent = topBar
		end
		for _, item in ipairs(GearData.Boats) do
			local text, color, onClick = gearButtonFor(item)
			itemRow(item.name, statLine(item), text, color, onClick)
		end
	end

	-- ---------------------------------------------------------------------

	rebuild = function()
		if not currentMode or not state.snapshot then
			return
		end
		UIKit.clear(list)
		UIKit.clear(topBar)
		if currentMode == "market" then
			buildMarket()
		elseif currentMode == "gear" then
			buildGear()
		elseif currentMode == "boats" then
			buildBoats()
		end
	end

	Remotes.Event("OpenShop").OnClientEvent:Connect(function(mode)
		currentMode = mode
		titleLabel.Text = TITLES[mode] or "Shop"
		rebuild()
		window.Visible = true
	end)

	state.changed:Connect(function()
		if window.Visible then
			rebuild()
		end
	end)

	ShopUI.IsOpen = function()
		return window.Visible
	end
end

return ShopUI
