--[[
	Remotes
	Creates (server) / fetches (client) all RemoteEvents & RemoteFunctions
	under ReplicatedStorage.Remotes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	"ThrowSpear", -- C->S (origin, direction, charge)
	"SpearVisual", -- S->C broadcast (thrower, origin, hitPos)
	"CatchMade", -- S->C (catch entry) for the catch popup
	"Notify", -- S->C ({ text, kind })
	"Announce", -- S->all ({ text, kind }) server-wide moments
	"ProfileChanged", -- S->C (snapshot)
	"OpenShop", -- S->C (shopType) triggered by NPC prompts
	"QuestCompleted", -- S->C (questId)
}

local FUNCTIONS = {
	"GetSnapshot", -- C->S -> snapshot
	"BuyGear", -- C->S (gearId) -> ok, message
	"EquipGear", -- C->S (gearId) -> ok, message
	"SellFish", -- C->S (uids? nil = all) -> ok, message, coinsGained
	"SpawnBoat", -- C->S () -> ok, message
	"StowBoat", -- C->S () -> ok, message
}

local Remotes = {}

local function getFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild("Remotes")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = ReplicatedStorage
			for _, name in ipairs(EVENTS) do
				local remote = Instance.new("RemoteEvent")
				remote.Name = name
				remote.Parent = folder
			end
			for _, name in ipairs(FUNCTIONS) do
				local remote = Instance.new("RemoteFunction")
				remote.Name = name
				remote.Parent = folder
			end
		end
		return folder
	else
		return ReplicatedStorage:WaitForChild("Remotes")
	end
end

function Remotes.Event(name: string): RemoteEvent
	local remote = getFolder():WaitForChild(name)
	assert(remote:IsA("RemoteEvent"), name .. " is not a RemoteEvent")
	return remote
end

function Remotes.Function(name: string): RemoteFunction
	local remote = getFolder():WaitForChild(name)
	assert(remote:IsA("RemoteFunction"), name .. " is not a RemoteFunction")
	return remote
end

return Remotes
