--[[
	FishBillboards — nameplates over fish (species, size, rarity color),
	visible only when you're close. Golden fish get a shiny label.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishData = require(ReplicatedStorage.Shared.FishData)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Util = require(ReplicatedStorage.Shared.Util)

local FishBillboards = {}

local function attach(fish: Instance)
	if not fish:IsA("BasePart") then
		return
	end
	local species = FishData.ById[fish:GetAttribute("Species") or ""]
	if not species then
		return
	end
	local golden = fish:GetAttribute("Golden") == true
	local kg = fish:GetAttribute("WeightKg") or 0

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Nameplate"
	billboard.Size = UDim2.new(0, 150, 0, 34)
	billboard.StudsOffset = Vector3.new(0, 1.6, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 28

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Text = (golden and "✨ " or "") .. species.name
	nameLabel.TextColor3 = golden and Color3.fromRGB(255, 210, 70)
		or (GameConfig.RarityColors[species.rarity] or Color3.new(1, 1, 1))
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Parent = billboard

	local sizeLabel = Instance.new("TextLabel")
	sizeLabel.Size = UDim2.new(1, 0, 0.4, 0)
	sizeLabel.Position = UDim2.new(0, 0, 0.6, 0)
	sizeLabel.BackgroundTransparency = 1
	sizeLabel.Font = Enum.Font.Gotham
	sizeLabel.TextScaled = true
	sizeLabel.Text = Util.FormatKg(kg) .. " · " .. species.rarity
	sizeLabel.TextColor3 = Color3.fromRGB(220, 228, 232)
	sizeLabel.TextStrokeTransparency = 0.5
	sizeLabel.Parent = billboard

	billboard.Parent = fish
end

function FishBillboards.Start()
	CollectionService:GetInstanceAddedSignal("Fish"):Connect(attach)
	for _, fish in ipairs(CollectionService:GetTagged("Fish")) do
		attach(fish)
	end
end

return FishBillboards
