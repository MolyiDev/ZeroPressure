local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Ignis = require(ReplicatedStorage.Packages.Ignis)

local Valves = CollectionService:GetTagged("Valve")
local CurrentValve: BasePart?
local Connection: RBXScriptConnection?

local FULL_ROTATION_RIGHT = math.rad(179)
local FULL_ROTATION_LEFT = math.rad(-179)
local SPEED = (FULL_ROTATION_RIGHT - FULL_ROTATION_LEFT) / 15

local ValveController = {}

local function rotateValve(valve: BasePart, targetAngle: number, dt: number, speedMult: number)
	local currentCF = valve.CFrame
	local _, _, currentZ = currentCF:ToEulerAnglesYXZ()

	local diff = targetAngle - currentZ
	local step = dt * (SPEED * (speedMult or 1))

	if math.abs(diff) < step then
		valve.CFrame = valve.CFrame * CFrame.Angles(0, 0, diff)
	else
		local dir = diff > 0 and 1 or -1
		valve.CFrame = valve.CFrame * CFrame.Angles(0, 0, step * dir)
	end
end

function ValveController.ValveTouched(valve: BasePart)
	CurrentValve = valve
end

function ValveController.ValveStop()
	CurrentValve = nil
end

function ValveController.Start()
	if Connection then Connection:Disconnect() end

	Connection = RunService.Heartbeat:Connect(function(dt: number)
		-- Rotate right
		for _, valve in Valves do
			if not valve:IsA("BasePart") then continue end
			if CurrentValve == valve then continue end

			rotateValve(valve, FULL_ROTATION_RIGHT, dt, 1)
		end

		-- Rotate left (player interaction)
		if not CurrentValve then return end

		local mouseDelta = UserInputService:GetMouseDelta()
		if mouseDelta.Magnitude > 0.1 then
			rotateValve(CurrentValve, FULL_ROTATION_LEFT, dt, mouseDelta.Magnitude * 2)
		end
	end)
end

function ValveController.Stop()
	if Connection then
		Connection:Disconnect()
		Connection = nil
	end
end

function ValveController.Reset()
	for _, valve in Valves do
		if not valve:IsA("BasePart") then continue end
		valve.CFrame = valve.CFrame * CFrame.Angles(0, 0, FULL_ROTATION_RIGHT)
	end
end

ValveController.Start()

return Ignis.Register(ValveController)
