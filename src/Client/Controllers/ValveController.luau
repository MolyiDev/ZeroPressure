local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Ignis = require(ReplicatedStorage.Packages.Ignis)

type Valve = BasePart
type PressureLevel = "None" | "Low" | "Medium" | "High"

local Valves = CollectionService:GetTagged("Valve") :: { Valve }
local CurrentValve: BasePart?
local Connection: RBXScriptConnection?

local FULL_ROTATION_RIGHT = math.rad(179)
local FULL_ROTATION_LEFT = math.rad(-179)
local RIGHT_SPEED = (FULL_ROTATION_RIGHT - FULL_ROTATION_LEFT) / 15

local AUTO_RESTORE_SMOOTHNESS = 2
local TOUCH_FRICTION = 5
local INPUT_SENSITIVITY = 5

local THRESHOLD_LOW = 10
local THRESHOLD_MEDIUM = 17
local THRESHOLD_HIGH = 25

local ValveStates: { [Valve]: {
	Velocity: number,
	PressureSeconds: number,
	CurrentPressure: PressureLevel,
} } = {}

local ValveController = {}
ValveController.Thresholds = {
	Low = THRESHOLD_LOW,
	Medium = THRESHOLD_MEDIUM,
	High = THRESHOLD_HIGH,
}

local function getPressureLevel(seconds: number): PressureLevel
	if seconds >= ValveController.Thresholds.High then
		return "High"
	elseif seconds >= ValveController.Thresholds.Medium then
		return "Medium"
	elseif seconds >= ValveController.Thresholds.Low then
		return "Low"
	else
		return "None"
	end
end

local function pressureChanged(valve: BasePart, oldLevel: PressureLevel, newLevel: PressureLevel)
	print(string.format("Valve %s changed from %s to %s", valve.Name, oldLevel, newLevel))

	-- VFX or SFX
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
		local mouseDelta = UserInputService:GetMouseDelta()

		for _, valve in Valves do
			if not valve:IsA("BasePart") then continue end

			if not ValveStates[valve] then
				ValveStates[valve] = {
					Velocity = RIGHT_SPEED,
					PressureSeconds = 0,
					CurrentPressure = "None",
				}
			end

			local state = ValveStates[valve]

			if valve == CurrentValve then
				state.Velocity = state.Velocity + (0 - state.Velocity) * (dt * TOUCH_FRICTION)

				if mouseDelta.Magnitude > 0 then
					state.Velocity = state.Velocity - (mouseDelta.Magnitude * INPUT_SENSITIVITY * dt)
				end
			else
				local targetSpeed = RIGHT_SPEED

				if state.PressureSeconds >= ValveController.Thresholds.High then targetSpeed = 0 end

				local lerpFactor = math.clamp(dt * AUTO_RESTORE_SMOOTHNESS, 0, 1)
				state.Velocity = state.Velocity + (targetSpeed - state.Velocity) * lerpFactor
			end

			valve.CFrame = valve.CFrame * CFrame.Angles(0, 0, state.Velocity * dt)

			local speedRatio = state.Velocity / RIGHT_SPEED
			state.PressureSeconds =
				math.clamp(state.PressureSeconds + (speedRatio * dt), 0, ValveController.Thresholds.High)

			local newLevel = getPressureLevel(state.PressureSeconds)
			if newLevel ~= state.CurrentPressure then
				pressureChanged(valve, state.CurrentPressure, newLevel :: any)
				state.CurrentPressure = newLevel :: any
			end
		end
	end)
end

function ValveController.Stop()
	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	table.clear(ValveStates)
end

function ValveController.Reset()
	for _, valve in Valves do
		if not valve:IsA("BasePart") then continue end
		local yOrientation = (valve:GetAttribute("YOrientation") :: number) or 0
		valve.CFrame = CFrame.new(valve.Position) * CFrame.Angles(0, yOrientation, 0)

		ValveStates[valve] = {
			Velocity = RIGHT_SPEED,
			PressureSeconds = 0,
			CurrentPressure = "None",
		}
	end

	ValveController.Thresholds = {
		Low = THRESHOLD_LOW,
		Medium = THRESHOLD_MEDIUM,
		High = THRESHOLD_HIGH,
	}
end

ValveController.Start()

return Ignis.Register(ValveController)
