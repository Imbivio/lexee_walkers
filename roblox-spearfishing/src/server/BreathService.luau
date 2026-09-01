--[[
	BreathService
	Server-authoritative freediving: tracks who is underwater, drains and
	recovers breath, awards lung XP (dive more -> hold longer), applies
	blackout damage at zero breath, and drops part of the catch bag on a
	blackout. Also applies fin swim speed while swimming.

	Client HUD reads the attributes this sets on the Player:
		Breath, MaxBreath, Depth, LungLevel, LungXP, LungNextXP
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GearData = require(ReplicatedStorage.Shared.GearData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local Signals = require(script.Parent.Signals)

local BreathService = {}

local breathState: { [Player]: { breath: number, drowning: boolean } } = {}

local dropCatch -- forward-declared

local function onCharacter(player: Player, character: Model)
	local state = breathState[player]
	if not state then
		return
	end
	local level = player:GetAttribute("LungLevel") or 0
	state.breath = GameConfig.Breath.MaxBreathForLevel(level)
	state.drowning = false

	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.Died:Connect(function()
			-- only a blackout death costs part of the bag
			local current = breathState[player]
			if current and current.drowning then
				dropCatch(player)
			end
		end)
	end
end

local function setupPlayer(player: Player)
	breathState[player] = { breath = GameConfig.Breath.BaseSeconds, drowning = false }
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

-- Drop a fraction of the catch bag when the player blacks out
dropCatch = function(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile or #profile.inventory == 0 then
		return
	end
	local toDrop = math.floor(#profile.inventory * GameConfig.Breath.BlackoutFishLoss + 0.5)
	if toDrop <= 0 then
		return
	end
	local rng = Random.new()
	for _ = 1, toDrop do
		if #profile.inventory == 0 then
			break
		end
		table.remove(profile.inventory, rng:NextInteger(1, #profile.inventory))
	end
	Remotes.Event("Notify"):FireClient(player, {
		text = ("You blacked out and dropped %d fish from your bag!"):format(toDrop),
		kind = "bad",
	})
	DataService.PushSnapshot(player)
end

local function stepPlayer(player: Player, dt: number)
	local state = breathState[player]
	local profile = DataService.GetProfile(player)
	if not state or not profile then
		return
	end

	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not head or not humanoid or humanoid.Health <= 0 then
		player:SetAttribute("Depth", 0)
		return
	end

	local level = GameConfig.Breath.LevelFromXP(profile.breathXP)
	local maxBreath = GameConfig.Breath.MaxBreathForLevel(level)
	local depth = math.max(0, GameConfig.SeaLevel - head.Position.Y)
	local underwater = depth > 0.5

	if underwater then
		-- drain faster when deep
		local drain = (1 + depth * GameConfig.Breath.DrainDepthFactor) * dt
		state.breath = math.max(0, state.breath - drain)

		-- lung training: XP for time underwater, bonus for depth
		local xpGain = GameConfig.Breath.XPPerSecond * dt * (1 + depth * GameConfig.Breath.DepthXPBonus)
		local oldLevel = level
		profile.breathXP += xpGain
		local newLevel = GameConfig.Breath.LevelFromXP(profile.breathXP)
		if newLevel > oldLevel then
			maxBreath = GameConfig.Breath.MaxBreathForLevel(newLevel)
			Remotes.Event("Notify"):FireClient(player, {
				text = ("Lung level %d! Max breath is now %ds."):format(newLevel, maxBreath),
				kind = "good",
			})
			Signals.BreathLevelUp:Fire(player, newLevel)
			DataService.PushSnapshot(player)
			level = newLevel
		end

		-- personal depth record
		if depth > (profile.maxDepth or 0) + 0.5 then
			profile.maxDepth = depth
			Signals.DepthRecord:Fire(player, depth)
		end

		-- blackout
		if state.breath <= 0 then
			humanoid:TakeDamage(GameConfig.Breath.BlackoutDamagePerSecond * dt)
			if not state.drowning then
				state.drowning = true
				Remotes.Event("Notify"):FireClient(player, {
					text = "Out of air! Surface NOW!",
					kind = "bad",
				})
			end
		end
	else
		state.breath = math.min(maxBreath, state.breath + GameConfig.Breath.SurfaceRecoveryRate * dt)
		state.drowning = false
	end

	-- fins: swim speed while in Swimming state, normal walk speed on land
	local fins = GearData.ById[profile.gear.fins]
	local swimSpeed = fins and fins.swimSpeed or GameConfig.DefaultWalkSpeed
	local swimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming
	local wantSpeed = swimming and swimSpeed or GameConfig.DefaultWalkSpeed
	if humanoid.WalkSpeed ~= wantSpeed then
		humanoid.WalkSpeed = wantSpeed
	end

	player:SetAttribute("Breath", math.floor(state.breath * 10) / 10)
	player:SetAttribute("MaxBreath", maxBreath)
	player:SetAttribute("Depth", math.floor(depth * 10) / 10)
	player:SetAttribute("LungLevel", level)
end

function BreathService.Start()
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		breathState[player] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	-- 4 Hz is plenty for breath simulation
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator >= 0.25 then
			for _, player in ipairs(Players:GetPlayers()) do
				stepPlayer(player, accumulator)
			end
			accumulator = 0
		end
	end)
end

return BreathService
