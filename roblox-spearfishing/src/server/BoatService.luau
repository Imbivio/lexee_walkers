--[[
	BoatService
	Spawns and simulates the player's boat. Boats are simple physics craft:
	a low-density hull (terrain water's native buoyancy keeps it afloat)
	with a VehicleSeat, driven by throttle/steer forces and held level by
	an AlignOrientation — all applied server-side for stability.

	Better boats are faster and the cruiser/sportfisher let you sell your
	catch at sea (EconomyService checks GetPlayerBoat).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local GearData = require(ReplicatedStorage.Shared.GearData)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local BoatService = {}

local boats: { [Player]: { model: Model, hull: BasePart, seat: VehicleSeat, item: any, yaw: number } } = {}

local function buildBoat(player: Player, item): Model
	local size = item.hullSize
	local model = Instance.new("Model")
	model.Name = player.Name .. "_" .. item.id

	local hull = Instance.new("Part")
	hull.Name = "Hull"
	hull.Size = size
	hull.Color = item.hullColor
	hull.Material = Enum.Material.SmoothPlastic
	-- density < 1 so terrain water floats the hull natively
	hull.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.4, 0.4)
	hull.Parent = model
	model.PrimaryPart = hull

	-- bow wedge for looks
	local bow = Instance.new("WedgePart")
	bow.Size = Vector3.new(size.Z, size.Y, size.X * 0.25)
	bow.Color = item.hullColor
	bow.Material = hull.Material
	bow.CanCollide = false
	bow.Massless = true
	bow.CFrame = hull.CFrame
		* CFrame.new(0, 0, -(size.X + size.X * 0.25) / 2)
		* CFrame.Angles(0, math.rad(90), 0)
	bow.Parent = model
	local bowWeld = Instance.new("WeldConstraint")
	bowWeld.Part0 = hull
	bowWeld.Part1 = bow
	bowWeld.Parent = bow

	local seat = Instance.new("VehicleSeat")
	seat.Size = Vector3.new(2, 1, 2)
	seat.Color = Color3.fromRGB(50, 50, 55)
	seat.MaxSpeed = 0 -- we drive with forces, not the seat motor
	seat.HeadsUpDisplay = false
	seat.CFrame = hull.CFrame * CFrame.new(0, size.Y / 2 + 0.5, size.X * 0.2)
	seat.Parent = model
	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = hull
	seatWeld.Part1 = seat
	seatWeld.Parent = seat

	local attachment = Instance.new("Attachment")
	attachment.Name = "RootAttachment"
	attachment.Parent = hull

	local thrust = Instance.new("VectorForce")
	thrust.Name = "Thrust"
	thrust.Attachment0 = attachment
	thrust.RelativeTo = Enum.ActuatorRelativeTo.World
	thrust.Force = Vector3.zero
	thrust.Parent = hull

	local orient = Instance.new("AlignOrientation")
	orient.Name = "Orient"
	orient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orient.Attachment0 = attachment
	orient.MaxTorque = 5e6
	orient.Responsiveness = 25
	orient.Parent = hull

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Stow Boat"
	prompt.ObjectText = item.name
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = hull
	prompt.Triggered:Connect(function(who)
		if who == player then
			BoatService.Stow(player)
		end
	end)

	return model
end

local function stepBoats(dt: number)
	for player, boat in pairs(boats) do
		local hull = boat.hull
		if not hull.Parent then
			boats[player] = nil
			continue
		end

		local mass = hull.AssemblyMass

		-- drive from the seat occupant's input
		local seat = boat.seat
		local throttle = 0
		local steer = 0
		if seat.Occupant then
			throttle = seat.ThrottleFloat
			steer = seat.SteerFloat
		end

		boat.yaw -= steer * boat.item.turnRate * dt * math.max(0.35, math.abs(throttle))
		hull.Orient.CFrame = CFrame.Angles(0, boat.yaw, 0)

		local forward = Vector3.new(-math.sin(boat.yaw), 0, -math.cos(boat.yaw))
		local targetVel = forward * boat.item.speed * throttle
		local planarVel = hull.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
		local accel = (targetVel - planarVel) * 2.2
		hull.Thrust.Force = accel * mass
	end
end

-- Public API -------------------------------------------------------------

function BoatService.GetPlayerBoat(player: Player)
	local boat = boats[player]
	if boat and boat.hull.Parent then
		return boat
	end
	return nil
end

function BoatService.Stow(player: Player)
	local boat = boats[player]
	if boat then
		boats[player] = nil
		boat.model:Destroy()
	end
end

function BoatService.Spawn(player: Player): (boolean, string)
	local profile = DataService.GetProfile(player)
	if not profile then
		return false, "Profile not loaded yet."
	end
	local boatId = profile.gear.boat
	local item = boatId ~= "" and GearData.ById[boatId] or nil
	if not item then
		return false, "You don't own a boat yet — see Kainoa's shop."
	end

	BoatService.Stow(player)

	local model = buildBoat(player, item)
	local spawnPos = GameConfig.DockBoatSpawn + Vector3.new(0, 2, 0)
	model:PivotTo(CFrame.new(spawnPos) * CFrame.Angles(0, math.rad(-90), 0))
	model.Parent = Workspace

	local hull = model.PrimaryPart :: BasePart
	hull:SetNetworkOwner(nil) -- server simulates for stability

	boats[player] = {
		model = model,
		hull = hull,
		seat = model:FindFirstChildOfClass("VehicleSeat") :: VehicleSeat,
		item = item,
		yaw = math.rad(-90), -- matches the spawn pivot: bow facing +X, out to sea
	}
	return true, item.name .. " is at the dock!"
end

function BoatService.Start()
	Remotes.Function("SpawnBoat").OnServerInvoke = function(player)
		return BoatService.Spawn(player)
	end
	Remotes.Function("StowBoat").OnServerInvoke = function(player)
		BoatService.Stow(player)
		return true, "Boat stowed."
	end

	Players.PlayerRemoving:Connect(function(player)
		BoatService.Stow(player)
	end)

	RunService.Heartbeat:Connect(stepBoats)
end

return BoatService
