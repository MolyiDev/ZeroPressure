local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundsController = require(script.Parent.SoundsController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)

export type Valve = { Effects: Attachment, SteamLoop: Sound } & BasePart
export type PressureLevel = "None" | "Low" | "Medium" | "High" | "Final"
export type ValveState = {
	Enabled: boolean,
	Velocity: number,
	PressureSeconds: number,
	CurrentPressure: PressureLevel,
	CurrentEffect: Attachment?,
}

local TW_EFFECT = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local FULL_ROTATION_RIGHT = math.rad(179)
local FULL_ROTATION_LEFT = math.rad(-179)
local RIGHT_SPEED_DEFAULT = (FULL_ROTATION_RIGHT - FULL_ROTATION_LEFT) / 15
local RIGHT_SPEED_TUTORIAL = (FULL_ROTATION_RIGHT - FULL_ROTATION_LEFT) / 2
local RIGHT_SPEED_SECOND_HALF = (FULL_ROTATION_RIGHT - FULL_ROTATION_LEFT) / 14
local RIGHT_SPEED_THIRD = (FULL_ROTATION_RIGHT - FULL_ROTATION_LEFT) / 13
local RIGHT_SPEED_THIRD_HALF = (FULL_ROTATION_RIGHT - FULL_ROTATION_LEFT) / 12.5
local RIGHT_SPEED_FOURTH = (FULL_ROTATION_RIGHT - FULL_ROTATION_LEFT) / 12
local RIGHT_SPEED_FOURTH_HALF = (FULL_ROTATION_RIGHT - FULL_ROTATION_LEFT) / 11
local LEFT_SPEED_ROTATION = 1.8

local AUTO_RESTORE_SMOOTHNESS = 2
local TOUCH_FRICTION = 5
local INPUT_SENSITIVITY = 8.5

local THRESHOLD_LOW = 8
local THRESHOLD_MEDIUM = 16
local THRESHOLD_HIGH = 24
local THRESHOLD_FINAL = 32

local STEAMLOOP_LOW_VOLUME = 0.1
local STEAMLOOP_MEDIUM_VOLUME = 0.2
local STEAMLOOP_HIGH_VOLUME = 0.3

local Valves = CollectionService:GetTagged("Valve") :: { Valve }
local CurrentValve: Valve?
local Connection: RBXScriptConnection?

local ValveEffects = ReplicatedStorage:FindFirstChild("Effects"):FindFirstChild("Valves") :: Folder
local ValveLowEffect = ValveEffects:FindFirstChild("Low") :: Attachment
local ValveMediumEffect = ValveEffects:FindFirstChild("Medium") :: Attachment
local ValveHighEffect = ValveEffects:FindFirstChild("High") :: Attachment

local ValveStates: {
	[Valve]: ValveState,
} = {}

local ValveController = {}
ValveController.OnValveClosed = Signal.new()
ValveController.EPressureLevels = table.freeze({
	None = "None",
	Low = "Low",
	Medium = "Medium",
	High = "High",
})
ValveController.RIGHT_SPEED_DEFAULT = RIGHT_SPEED_DEFAULT
ValveController.RIGHT_SPEED_DEFAULT = RIGHT_SPEED_DEFAULT
ValveController.RIGHT_SPEED_TUTORIAL = RIGHT_SPEED_TUTORIAL
ValveController.RIGHT_SPEED_SECOND_HALF = RIGHT_SPEED_SECOND_HALF
ValveController.RIGHT_SPEED_THIRD = RIGHT_SPEED_THIRD
ValveController.RIGHT_SPEED_THIRD_HALF = RIGHT_SPEED_THIRD_HALF
ValveController.RIGHT_SPEED_FOURTH = RIGHT_SPEED_FOURTH
ValveController.RIGHT_SPEED_FOURTH_HALF = RIGHT_SPEED_FOURTH_HALF
ValveController.RightSpeed = RIGHT_SPEED_DEFAULT
ValveController.EnabledValvesCount = 0
ValveController.ValvesCount = #Valves
ValveController.LowValvesCount = 0
ValveController.MediumValvesCount = 0
ValveController.HighValvesCount = 0

ValveController.BaseThresholds = {
	Low = THRESHOLD_LOW,
	Medium = THRESHOLD_MEDIUM,
	High = THRESHOLD_HIGH,
	Final = THRESHOLD_FINAL,
}

ValveController.Thresholds = table.clone(ValveController.BaseThresholds)

local function getThresholdMultiplier()
	if ValveController.RightSpeed == 0 then return 1 end
	return ValveController.RIGHT_SPEED_DEFAULT / ValveController.RightSpeed
end

local function removeCurrentEffect(valve: ValveState)
	local effect = valve.CurrentEffect
	valve.CurrentEffect = nil
	if not effect then return end

	for _, emitter in effect:GetDescendants() do
		if emitter:IsA("ParticleEmitter") then
			TweenService:Create(emitter, TW_EFFECT, { Rate = 0 }):Play()
		elseif emitter:IsA("Beam") then
			TweenService:Create(emitter, TW_EFFECT, { Width0 = 0, Width1 = 0 }):Play()
		end
	end

	task.delay(TW_EFFECT.Time * 2, function()
		effect:Destroy()
	end)
end

local function getPressureLevel(seconds: number): PressureLevel
	local mult = getThresholdMultiplier()

	if seconds >= (ValveController.BaseThresholds.High * mult) then
		return "High"
	elseif seconds >= (ValveController.BaseThresholds.Medium * mult) then
		return "Medium"
	elseif seconds >= (ValveController.BaseThresholds.Low * mult) then
		return "Low"
	else
		return "None"
	end
end

local function pressureChanged(valve: Valve, oldLevel: PressureLevel, newLevel: PressureLevel)
	if oldLevel == "Low" then
		ValveController.LowValvesCount -= 1
	elseif oldLevel == "Medium" then
		ValveController.MediumValvesCount -= 1
	elseif oldLevel == "High" then
		ValveController.HighValvesCount -= 1
	end

	if newLevel == "Low" then
		ValveController.LowValvesCount += 1
	elseif newLevel == "Medium" then
		ValveController.MediumValvesCount += 1
	elseif newLevel == "High" then
		ValveController.HighValvesCount += 1
	end

	if newLevel == "None" then ValveController.OnValveClosed:Fire() end

	-- VFX
	local state = ValveStates[valve]
	if not state then return end

	removeCurrentEffect(state)

	local template
	if newLevel == "Low" then
		template = ValveLowEffect
	elseif newLevel == "Medium" then
		template = ValveMediumEffect
	elseif newLevel == "High" then
		template = ValveHighEffect
	end

	if template then
		local effect = template:Clone()
		effect.Parent = valve.Effects
		state.CurrentEffect = effect
	end

	-- SFX
	if oldLevel == "None" then SoundsController.PlayLoop(ESounds.SteamLoop, valve, false) end

	if newLevel == "None" then
		SoundsController.Play(ESounds.SteamFree, valve)
		SoundsController.StopLoop(ESounds.SteamLoop, valve, true)
	else
		local targetVol
		if newLevel == "Low" then
			targetVol = STEAMLOOP_LOW_VOLUME
		elseif newLevel == "Medium" then
			targetVol = STEAMLOOP_MEDIUM_VOLUME
		elseif newLevel == "High" then
			targetVol = STEAMLOOP_HIGH_VOLUME
		end

		if targetVol then SoundsController.FadeLoop(ESounds.SteamLoop, valve, targetVol) end
	end
end

function ValveController.ValveTouched(valve: Valve)
	CurrentValve = valve
end

function ValveController.ValveStop()
	CurrentValve = nil
end

function ValveController.EnableValve(valve: Valve, initialPressureLevel: PressureLevel?)
	local state = ValveStates[valve]
	if not state then return end

	local oldLevel = state.CurrentPressure
	local newLevel = initialPressureLevel or "None"

	ValveController.EnabledValvesCount += 1
	state.Enabled = true
	state.CurrentPressure = newLevel :: PressureLevel

	local mult = getThresholdMultiplier()

	if newLevel == "High" then
		state.PressureSeconds = ValveController.BaseThresholds.High * mult
	elseif newLevel == "Medium" then
		state.PressureSeconds = ValveController.BaseThresholds.Medium * mult
	elseif newLevel == "Low" then
		state.PressureSeconds = ValveController.BaseThresholds.Low * mult
	else
		state.PressureSeconds = 0
	end

	if oldLevel ~= newLevel then pressureChanged(valve, oldLevel :: any, newLevel :: any) end
end

function ValveController.DisableValve(valve: Valve)
	local state = ValveStates[valve]
	if not state then return end

	local oldLevel = state.CurrentPressure
	ValveController.EnabledValvesCount -= 1

	state.Enabled = false
	state.PressureSeconds = 0
	state.CurrentPressure = "None"

	if oldLevel ~= "None" then pressureChanged(valve, oldLevel :: any, "None") end
end

function ValveController.EnableRandomValve(initialPressureLevel: PressureLevel?): Valve?
	local disabledValves = {}

	for _, valve in Valves do
		local state = ValveStates[valve]
		if state and not state.Enabled then disabledValves[#disabledValves + 1] = valve end
	end

	if #disabledValves > 0 then
		local randomValve = disabledValves[math.random(1, #disabledValves)]
		ValveController.EnableValve(randomValve, initialPressureLevel)
		return randomValve
	end

	return nil -- All valves are already enabled
end

function ValveController.EnableAllValves(initialPressureLevel: PressureLevel?)
	for _, valve in Valves do
		ValveController.EnableValve(valve, initialPressureLevel)
	end
end

function ValveController.DisableAllValves()
	for _, valve in Valves do
		ValveController.DisableValve(valve)
	end
end

function ValveController.OnStart()
	if Connection then Connection:Disconnect() end

	Connection = RunService.Heartbeat:Connect(function(dt: number)
		local mouseDelta = UserInputService:GetMouseDelta()

		local mult = getThresholdMultiplier()
		local currentFinalThreshold = ValveController.BaseThresholds.Final * mult

		for _, valve in Valves do
			if not valve:IsA("BasePart") then continue end

			if not ValveStates[valve] then
				ValveStates[valve] = {
					Velocity = 0,
					PressureSeconds = 0,
					CurrentPressure = "None",
					Enabled = false,
				}
			end

			local state = ValveStates[valve]

			if valve == CurrentValve :: any then
				state.Velocity = state.Velocity + (0 - state.Velocity) * (dt * TOUCH_FRICTION)

				if mouseDelta.Magnitude > 0 then
					state.Velocity = state.Velocity - (mouseDelta.Magnitude * INPUT_SENSITIVITY * dt)
				end
			else
				local targetSpeed = state.Enabled and ValveController.RightSpeed or 0

				if state.PressureSeconds >= currentFinalThreshold then targetSpeed = 0 end

				local lerpFactor = math.clamp(dt * AUTO_RESTORE_SMOOTHNESS, 0, 1)
				state.Velocity = state.Velocity + (targetSpeed - state.Velocity) * lerpFactor
			end

			valve.CFrame = valve.CFrame * CFrame.Angles(state.Velocity * dt, 0, 0)

			local divisor = (state.Velocity < 0) and LEFT_SPEED_ROTATION or ValveController.RightSpeed
			if divisor == 0 then divisor = 1 end

			local speedRatio = state.Velocity / divisor

			state.PressureSeconds = math.clamp(state.PressureSeconds + (speedRatio * dt), 0, currentFinalThreshold)

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
	ValveController.LowValvesCount = 0
	ValveController.MediumValvesCount = 0
	ValveController.HighValvesCount = 0
	ValveController.EnabledValvesCount = 0

	for _, valve in Valves do
		if not valve:IsA("BasePart") then continue end

		local state = ValveStates[valve]
		if not state then continue end

		removeCurrentEffect(state)

		state.Velocity = 0
		state.PressureSeconds = 0
		state.CurrentPressure = "None"
		state.Enabled = false
	end

	ValveController.BaseThresholds = {
		Low = THRESHOLD_LOW,
		Medium = THRESHOLD_MEDIUM,
		High = THRESHOLD_HIGH,
		Final = THRESHOLD_FINAL,
	}

	ValveController.Thresholds = table.clone(ValveController.BaseThresholds)
	ValveController.RightSpeed = RIGHT_SPEED_DEFAULT
end

return Ignis.Register(ValveController)
