local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EngineController = require(script.Parent.EngineController)
local LightController = require(script.Parent.LightController)
local ValveController = require(script.Parent.ValveController)
local WaterController = require(script.Parent.WaterController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)

local PRESSURE_COLOR = Color3.fromRGB(0, 242, 255)
local PRESSURE_BACKGROUND_COLOR = Color3.fromRGB(3, 50, 52)
local PRESSURE_DEGRADE_COLOR = Color3.fromRGB(255, 0, 0)

local DEFAULT_GRADIENT = ColorSequence.new({
	ColorSequenceKeypoint.new(0, PRESSURE_COLOR),
	ColorSequenceKeypoint.new(0.996, PRESSURE_COLOR),
	ColorSequenceKeypoint.new(0.997, PRESSURE_BACKGROUND_COLOR),
	ColorSequenceKeypoint.new(0.998, PRESSURE_BACKGROUND_COLOR),
	ColorSequenceKeypoint.new(0.999, PRESSURE_DEGRADE_COLOR),
	ColorSequenceKeypoint.new(1, PRESSURE_DEGRADE_COLOR),
})

local ENGINE_STRESS_THRESHOLD = 400

local ENGINE_PRESSURE_SPEED = 10
local VALVE_LOW_PRESSURE_SPEED = 1
local VALVE_MEDIUM_PRESSURE_SPEED = 3
local VALVE_HIGH_PRESSURE_SPEED = 5

local PRESSURE_NATURAL_SPEED = 15

local MAX_PRESSURE = 500
local LOWER_PRESSURE = 0

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui") :: PlayerGui
local PressureSurfaceGui = PlayerGui:WaitForChild("Pressure") :: SurfaceGui
local Gradient = PressureSurfaceGui:WaitForChild("Background"):WaitForChild("UIGradient") :: UIGradient
Gradient.Color = DEFAULT_GRADIENT

local PressureController = {}
PressureController.OnPressureFull = Signal.new()
PressureController.OnPressureZero = Signal.new()
PressureController.IsActive = false
PressureController.CurrentPressure = MAX_PRESSURE
PressureController.ENGINE_STRESS_THRESHOLD = ENGINE_STRESS_THRESHOLD
PressureController.PRESSURE_NATURAL_SPEED = PRESSURE_NATURAL_SPEED
PressureController.PressureNaturalSpeed = PRESSURE_NATURAL_SPEED

local Connection: RBXScriptConnection?

local function updateGradient(pressureVal: number, waterRatio: number)
	local pRatio = math.clamp(pressureVal / MAX_PRESSURE, 0, 1)
	local tWaterStart = math.clamp(1 - waterRatio, 0, 1)
	local tPressureEnd = math.min(pRatio, tWaterStart)

	local points = {}
	table.insert(points, ColorSequenceKeypoint.new(0, PRESSURE_COLOR))
	if (tWaterStart - tPressureEnd) < 0.005 then
		local tMeet = math.clamp(tPressureEnd, 0.001, 0.999)

		points[#points + 1] = ColorSequenceKeypoint.new(tMeet, PRESSURE_COLOR)
		points[#points + 1] = ColorSequenceKeypoint.new(tMeet, PRESSURE_DEGRADE_COLOR)
	else
		points[#points + 1] = ColorSequenceKeypoint.new(tPressureEnd, PRESSURE_COLOR)
		points[#points + 1] = ColorSequenceKeypoint.new(tPressureEnd, PRESSURE_BACKGROUND_COLOR)
		points[#points + 1] = ColorSequenceKeypoint.new(tWaterStart, PRESSURE_BACKGROUND_COLOR)
		points[#points + 1] = ColorSequenceKeypoint.new(tWaterStart, PRESSURE_DEGRADE_COLOR)
	end

	points[#points + 1] = ColorSequenceKeypoint.new(1, PRESSURE_DEGRADE_COLOR)

	Gradient.Color = ColorSequence.new(points)
end

function PressureController.Start()
	if PressureController.IsActive then return end

	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	PressureController.IsActive = true

	local wasFull = false

	Connection = RunService.Heartbeat:Connect(function(dt)
		local currentWater = WaterController.WaterLevel or 0
		local maxWater = WaterController.MAX_WATER_LEVEL or 100
		local minWater = WaterController.MIN_WATER_LEVEL or 0

		local waterRatio = 0
		if maxWater > minWater then waterRatio = math.clamp((currentWater - minWater) / (maxWater - minWater), 0, 1) end

		local maxAllowedPressure = MAX_PRESSURE * (1 - waterRatio)

		if PressureController.CurrentPressure > maxAllowedPressure then
			PressureController.CurrentPressure = maxAllowedPressure
		end

		local drain = 0
		local engineStress = EngineController.CurrentStress or 0
		if engineStress >= ENGINE_STRESS_THRESHOLD then
			drain += ENGINE_PRESSURE_SPEED
		end

		drain += (ValveController.LowValvesCount or 0) * VALVE_LOW_PRESSURE_SPEED
		drain += (ValveController.MediumValvesCount or 0) * VALVE_MEDIUM_PRESSURE_SPEED
		drain += (ValveController.HighValvesCount or 0) * VALVE_HIGH_PRESSURE_SPEED

		if drain > 0 then
			PressureController.CurrentPressure =
				math.max(LOWER_PRESSURE, PressureController.CurrentPressure - (drain * dt))
		else
			PressureController.CurrentPressure = math.min(
				maxAllowedPressure,
				PressureController.CurrentPressure + (PressureController.PressureNaturalSpeed * dt)
			)
		end

		if PressureController.CurrentPressure >= maxAllowedPressure then
			if not wasFull then
				wasFull = true
				PressureController.OnPressureFull:Fire()
			end
		else
			wasFull = false
		end

		updateGradient(PressureController.CurrentPressure, waterRatio)

		if PressureController.CurrentPressure <= 0 and PressureController.IsActive then
			PressureController.IsActive = false
			PressureController.OnPressureZero:Fire()
		end
	end)
end
function PressureController.Stop()
	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	PressureController.IsActive = false
end

function PressureController.Reset()
	PressureController.Stop()

	PressureController.CurrentPressure = MAX_PRESSURE

	local currentWater = WaterController.WaterLevel or 0
	local maxWater = WaterController.MAX_WATER_LEVEL or 100
	local minWater = WaterController.MIN_WATER_LEVEL or 0

	local waterRatio = 0
	if maxWater > minWater then waterRatio = math.clamp((currentWater - minWater) / (maxWater - minWater), 0, 1) end

	updateGradient(MAX_PRESSURE, waterRatio)
end

LightController.OnMainLightBroke:Connect(function()
	PressureSurfaceGui.Enabled = false
end)

LightController.OnMainLightFixed:Connect(function()
	PressureSurfaceGui.Enabled = true
end)

return Ignis.Register(PressureController)
