--[[
	HUD — coins, breath bar with lung level, depth meter, depth darkness
	overlay, toasts, server announcements and the catch popup.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FishData = require(ReplicatedStorage.Shared.FishData)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GearData = require(ReplicatedStorage.Shared.GearData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Util = require(ReplicatedStorage.Shared.Util)
local UIKit = require(script.Parent.UIKit)

local HUD = {}

local player = Players.LocalPlayer

function HUD.Start(state)
	local gui = UIKit.new("ScreenGui", {
		Name = "SpearfishHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 5,
	})
	gui.Parent = player:WaitForChild("PlayerGui")
	HUD.Gui = gui

	-- Darkness overlay (depth) ------------------------------------------
	local darkness = UIKit.new("Frame", {
		Name = "Darkness",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(2, 8, 16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
	})
	darkness.Parent = gui

	-- Coins --------------------------------------------------------------
	local coinsLabel = UIKit.label({
		Size = UDim2.new(0, 220, 0, 34),
		Position = UDim2.new(0, 16, 0, 14),
		Text = "🪙 0",
		Font = Enum.Font.GothamBold,
		TextSize = 22,
		TextColor3 = UIKit.Colors.Coin,
		TextStrokeTransparency = 0.5,
	})
	coinsLabel.Parent = gui

	local hintLabel = UIKit.label({
		Size = UDim2.new(0, 320, 0, 20),
		Position = UDim2.new(0, 16, 0, 48),
		Text = "[B] Bag & Fishdex   ·   Hold click to charge your spear",
		TextSize = 13,
		TextColor3 = UIKit.Colors.TextDim,
		TextStrokeTransparency = 0.6,
	})
	hintLabel.Parent = gui

	-- Breath bar ---------------------------------------------------------
	local breathFrame = UIKit.new("Frame", {
		Name = "BreathFrame",
		Size = UDim2.new(0, 320, 0, 22),
		Position = UDim2.new(0.5, 0, 1, -70),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = UIKit.Colors.Panel,
		Visible = false,
		[UIKit.Children] = { UIKit.corner(11), UIKit.stroke() },
	})
	breathFrame.Parent = gui

	local breathFill = UIKit.new("Frame", {
		Name = "Fill",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = UIKit.Colors.Accent,
		BorderSizePixel = 0,
		[UIKit.Children] = { UIKit.corner(11) },
	})
	breathFill.Parent = breathFrame

	local breathText = UIKit.label({
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.4,
		ZIndex = 3,
	})
	breathText.Parent = breathFrame

	local lungLabel = UIKit.label({
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 1, 2),
		Text = "",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = UIKit.Colors.TextDim,
		TextStrokeTransparency = 0.6,
	})
	lungLabel.Parent = breathFrame

	local depthLabel = UIKit.label({
		Size = UDim2.new(0, 120, 0, 22),
		Position = UDim2.new(0.5, 170, 1, -70),
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = UIKit.Colors.Text,
		TextStrokeTransparency = 0.5,
	})
	depthLabel.Parent = gui

	-- Toasts -------------------------------------------------------------
	local toastHolder = UIKit.new("Frame", {
		Name = "Toasts",
		Size = UDim2.new(0, 420, 0, 200),
		Position = UDim2.new(0.5, 0, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		[UIKit.Children] = {
			UIKit.new("UIListLayout", {
				Padding = UDim.new(0, 6),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	toastHolder.Parent = gui

	local TOAST_COLORS = {
		good = UIKit.Colors.Good,
		bad = UIKit.Colors.Bad,
		info = UIKit.Colors.Accent,
		quest = Color3.fromRGB(190, 140, 255),
		golden = Color3.fromRGB(255, 200, 60),
		trophy = Color3.fromRGB(255, 170, 60),
		rare = Color3.fromRGB(255, 110, 130),
	}

	local function toast(text: string, kind: string?, duration: number?)
		local color = TOAST_COLORS[kind or "info"] or UIKit.Colors.Accent
		local frame = UIKit.new("Frame", {
			Size = UDim2.new(0, 0, 0, 32),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = UIKit.Colors.Panel,
			BackgroundTransparency = 0.15,
			[UIKit.Children] = {
				UIKit.corner(8),
				UIKit.stroke(color),
				UIKit.padding(8),
				UIKit.label({
					Size = UDim2.new(0, 0, 1, -2),
					AutomaticSize = Enum.AutomaticSize.X,
					Text = text,
					TextSize = 14,
					Font = Enum.Font.GothamMedium,
					TextColor3 = color,
				}),
			},
		})
		frame.Parent = toastHolder
		task.delay(duration or 4, function()
			if frame.Parent then
				local tween = TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
				tween:Play()
				tween.Completed:Wait()
				frame:Destroy()
			end
		end)
	end
	HUD.Toast = toast

	-- Catch popup --------------------------------------------------------
	local catchCard = UIKit.new("Frame", {
		Name = "CatchCard",
		Size = UDim2.new(0, 260, 0, 96),
		Position = UDim2.new(1, -280, 0.5, -140),
		BackgroundColor3 = UIKit.Colors.Panel,
		BackgroundTransparency = 0.1,
		Visible = false,
		[UIKit.Children] = { UIKit.corner(10), UIKit.stroke(), UIKit.padding(10) },
	})
	catchCard.Parent = gui

	local catchTitle = UIKit.label({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 22),
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 17,
	})
	catchTitle.Parent = catchCard
	local catchSub = UIKit.label({
		Name = "Sub",
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 24),
		Text = "",
		TextSize = 13,
		TextColor3 = UIKit.Colors.TextDim,
	})
	catchSub.Parent = catchCard
	local catchStats = UIKit.label({
		Name = "Stats",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 46),
		Text = "",
		TextSize = 15,
	})
	catchStats.Parent = catchCard
	local catchValue = UIKit.label({
		Name = "Value",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 68),
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = UIKit.Colors.Coin,
	})
	catchValue.Parent = catchCard

	local hideCatchAt = 0
	Remotes.Event("CatchMade").OnClientEvent:Connect(function(entry)
		local species = FishData.ById[entry.species]
		if not species then
			return
		end
		local rarityColor = GameConfig.RarityColors[species.rarity] or UIKit.Colors.Text
		catchTitle.Text = (entry.golden and "✨ GOLDEN " or "") .. species.name
		catchTitle.TextColor3 = entry.golden and Color3.fromRGB(255, 200, 60) or rarityColor
		catchSub.Text = species.english .. " · " .. species.rarity
		catchStats.Text = Util.FormatCm(entry.cm) .. "  ·  " .. Util.FormatKg(entry.kg)
		catchValue.Text = "Worth 🪙 " .. Util.Comma(entry.value)
		catchCard.Visible = true
		hideCatchAt = os.clock() + 4
		task.delay(4.1, function()
			if os.clock() >= hideCatchAt then
				catchCard.Visible = false
			end
		end)
	end)

	-- Server events ------------------------------------------------------
	Remotes.Event("Notify").OnClientEvent:Connect(function(payload)
		toast(payload.text, payload.kind)
	end)
	Remotes.Event("Announce").OnClientEvent:Connect(function(payload)
		toast(payload.text, payload.kind, 6)
	end)
	Remotes.Event("QuestCompleted").OnClientEvent:Connect(function()
		-- QuestTracker refreshes from the snapshot; sound hook lives here
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.Volume = 0.6
		sound.Parent = gui
		sound:Play()
		task.delay(2, function()
			sound:Destroy()
		end)
	end)

	-- Per-frame updates --------------------------------------------------
	RunService.RenderStepped:Connect(function()
		local snapshot = state.snapshot
		if snapshot then
			coinsLabel.Text = "🪙 " .. Util.Comma(snapshot.coins)
		end

		local breath = player:GetAttribute("Breath") or 0
		local maxBreath = player:GetAttribute("MaxBreath") or GameConfig.Breath.BaseSeconds
		local depth = player:GetAttribute("Depth") or 0
		local lungLevel = player:GetAttribute("LungLevel") or 0

		local underwater = depth > 0.5
		local showBreath = underwater or breath < maxBreath - 0.5
		breathFrame.Visible = showBreath
		depthLabel.Visible = underwater
		if showBreath then
			local frac = math.clamp(breath / maxBreath, 0, 1)
			breathFill.Size = UDim2.new(frac, 0, 1, 0)
			breathFill.BackgroundColor3 = frac > 0.35 and UIKit.Colors.Accent
				or (frac > 0.15 and Color3.fromRGB(240, 180, 70) or UIKit.Colors.Bad)
			breathText.Text = Util.FormatTime(breath)
			lungLabel.Text = ("Lung Lv. %d"):format(lungLevel)
		end
		if underwater then
			depthLabel.Text = ("▼ %.1f m"):format(depth)
		end

		-- darkness by depth, cut by equipped dive light
		local lightFactor = 0
		if snapshot then
			local light = GearData.ById[snapshot.gear.light]
			lightFactor = light and light.lightFactor or 0
		end
		local darkFrac = math.clamp(
			(depth - GameConfig.DarknessStartDepth)
				/ (GameConfig.DarknessFullDepth - GameConfig.DarknessStartDepth),
			0,
			1
		) * GameConfig.MaxDarkness * (1 - lightFactor)
		darkness.BackgroundTransparency = 1 - darkFrac
	end)
end

return HUD
