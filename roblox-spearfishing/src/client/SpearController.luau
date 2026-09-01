--[[
	SpearController
	Hold click (or the mobile SPEAR button) to charge, release to fire.
	Charge scales range and catch chance. Renders the crosshair, charge
	ring, cooldown tint, and everyone's spear tracers.
]]

local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local GearData = require(ReplicatedStorage.Shared.GearData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local UIKit = require(script.Parent.UIKit)

local SpearController = {}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local CHARGE_TIME = 0.9

function SpearController.Start(state, hudGui: ScreenGui)
	local charging = false
	local chargeStart = 0
	local lastFired = 0

	-- Crosshair + charge ring -------------------------------------------
	local crosshair = UIKit.new("Frame", {
		Name = "Crosshair",
		Size = UDim2.new(0, 6, 0, 6),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.35,
		[UIKit.Children] = { UIKit.corner(3) },
	})
	crosshair.Parent = hudGui

	local chargeBar = UIKit.new("Frame", {
		Name = "ChargeBar",
		Size = UDim2.new(0, 80, 0, 6),
		Position = UDim2.new(0.5, 0, 0.5, 24),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = UIKit.Colors.Panel,
		Visible = false,
		[UIKit.Children] = { UIKit.corner(3) },
	})
	chargeBar.Parent = hudGui
	local chargeFill = UIKit.new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = UIKit.Colors.Accent,
		BorderSizePixel = 0,
		[UIKit.Children] = { UIKit.corner(3) },
	})
	chargeFill.Parent = chargeBar

	local function equippedSpear()
		local snapshot = state.snapshot
		local spear = snapshot and GearData.ById[snapshot.gear.spear]
		return spear or GearData.ById.spear_bamboo
	end

	local function canFire(): boolean
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return false
		end
		if state.uiOpen and state.uiOpen() then
			return false
		end
		return os.clock() - lastFired >= equippedSpear().reload
	end

	local function beginCharge()
		if not canFire() then
			return
		end
		charging = true
		chargeStart = os.clock()
		chargeBar.Visible = true
	end

	local function release()
		if not charging then
			return
		end
		charging = false
		chargeBar.Visible = false

		local character = player.Character
		local head = character and character:FindFirstChild("Head")
		if not head or not canFire() then
			return
		end

		local charge = math.clamp((os.clock() - chargeStart) / CHARGE_TIME, 0.15, 1)
		lastFired = os.clock()

		-- aim: from the head toward whatever is at the screen center
		local viewport = camera.ViewportSize
		local ray = camera:ViewportPointToRay(viewport.X / 2, viewport.Y / 2)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character }
		params.IgnoreWater = true
		local hit = Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
		local target = hit and hit.Position or (ray.Origin + ray.Direction * 300)
		local direction = (target - head.Position)
		if direction.Magnitude < 0.1 then
			direction = ray.Direction
		end

		Remotes.Event("ThrowSpear"):FireServer(head.Position, direction.Unit, charge)
	end

	-- Input: mouse + touch ----------------------------------------------
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			beginCharge()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			release()
		end
	end)

	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		ContextActionService:BindAction("Spear", function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				beginCharge()
			elseif inputState == Enum.UserInputState.End then
				release()
			end
			return Enum.ContextActionResult.Sink
		end, true)
		ContextActionService:SetTitle("Spear", "🔱")
		ContextActionService:SetPosition("Spear", UDim2.new(1, -90, 1, -140))
	end

	-- Charge/cooldown feedback ------------------------------------------
	RunService.RenderStepped:Connect(function()
		if charging then
			local charge = math.clamp((os.clock() - chargeStart) / CHARGE_TIME, 0, 1)
			chargeFill.Size = UDim2.new(charge, 0, 1, 0)
			chargeFill.BackgroundColor3 = charge >= 1 and UIKit.Colors.Good or UIKit.Colors.Accent
		end
		local reloading = os.clock() - lastFired < equippedSpear().reload
		crosshair.BackgroundColor3 = reloading and UIKit.Colors.Bad or Color3.new(1, 1, 1)
	end)

	-- Spear tracers (everyone's shots) ----------------------------------
	Remotes.Event("SpearVisual").OnClientEvent:Connect(function(_thrower, origin: Vector3, hitPos: Vector3)
		local distance = (hitPos - origin).Magnitude
		if distance < 0.5 then
			return
		end
		local tracer = Instance.new("Part")
		tracer.Anchored = true
		tracer.CanCollide = false
		tracer.CanQuery = false
		tracer.Material = Enum.Material.Neon
		tracer.Color = Color3.fromRGB(220, 235, 240)
		tracer.Size = Vector3.new(0.12, 0.12, distance)
		tracer.CFrame = CFrame.lookAt(origin, hitPos) * CFrame.new(0, 0, -distance / 2)
		tracer.Parent = Workspace
		TweenService:Create(tracer, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		Debris:AddItem(tracer, 0.4)

		if _thrower == player then
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxasset://sounds/impact_water.mp3"
			sound.Volume = 0.5
			sound.PlaybackSpeed = 1.4
			sound.Parent = tracer
			sound:Play()
		end
	end)
end

return SpearController
