local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Signal = require(ReplicatedStorage.Packages.Signal)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)
local SoundsController = require(script.Parent.SoundsController)

export type LeverLevels = "Down" | "Middle" | "Up"

local LEVER_UP_CF = (CollectionService:GetTagged("LeverUp")[1] :: Attachment).CFrame
local LEVER_MIDDLE_CF = (CollectionService:GetTagged("LeverMiddle")[1] :: Attachment).CFrame
local LEVER_DOWN_CF = (CollectionService:GetTagged("LeverDown")[1] :: Attachment).CFrame

local LEVEL_UP_STRESS = 15
local LEVEL_MIDDLE_STRESS = 5
local LEVEL_DOWN_STRESS = -25

-- for engine speeds
local LEVEL_UP_SPEED = 28
local LEVEL_MIDDLE_SPEED = 18
local LEVEL_DOWN_SPEED = 9

local SPEED_CHANGE_SPEED = 15 -- how fast the engine rpm adjusts

local ENGINE_SOUND_NO_LIGHT = 0.3
local ENGINE_SOUND_DOWN = 0.3
local ENGINE_SOUND_MIDDLE = 0.4
local ENGINE_SOUND_UP = 0.5

local MAX_STRESS = 500

local LOW_STRESS_COLOR = Color3.fromRGB(0, 255, 179)
local MID_STRESS_COLOR = Color3.fromRGB(255, 255, 0)
local HIGH_STRESS_COLOR = Color3.fromRGB(255, 0, 89)

local EngineLight = CollectionService:GetTagged("EngineLight")[1] :: { PointLight: PointLight } & BasePart
local EngineLever = CollectionService:GetTagged("Lever")[1] :: BasePart
local Connection: RBXScriptConnection?

local EngineController = {}
EngineController.OnLevelChanged = Signal.new() :: Signal.Signal<LeverLevels, LeverLevels>
EngineController.OnSpeedChanged = Signal.new() :: Signal.Signal<number, number> -- old, new
EngineController.OnStressChanged = Signal.new() :: Signal.Signal<number, number> -- old, new
EngineController.LeverCurrentLevel = "Down" :: LeverLevels
EngineController.CurrentSpeed = 0
EngineController.CurrentStress = 0
EngineController.IsEngineRunning = false
EngineController.LEVEL_UP_STRESS = LEVEL_UP_STRESS
EngineController.LEVEL_MIDDLE_STRESS = LEVEL_MIDDLE_STRESS
EngineController.LEVEL_DOWN_STRESS = LEVEL_DOWN_STRESS

EngineController.LEVEL_UP_SPEED = LEVEL_UP_SPEED
EngineController.LEVEL_MIDDLE_SPEED = LEVEL_MIDDLE_SPEED
EngineController.LEVEL_DOWN_SPEED = LEVEL_DOWN_SPEED

EngineController.LEVEL_UP_SPEED_FOURTH = LEVEL_UP_SPEED * 2
EngineController.LEVEL_MIDDLE_SPEED_FOURTH = LEVEL_MIDDLE_SPEED * 2
EngineController.LEVEL_DOWN_SPEED_FOURTH = LEVEL_DOWN_SPEED * 2

EngineController.LevelUpStress = LEVEL_UP_STRESS
EngineController.LevelMiddleStress = LEVEL_MIDDLE_STRESS
EngineController.LevelDownStress = LEVEL_DOWN_STRESS

EngineController.LevelUpSpeed = LEVEL_UP_SPEED
EngineController.LevelMiddleSpeed = LEVEL_MIDDLE_SPEED
EngineController.LevelDownSpeed = LEVEL_DOWN_SPEED

EngineController.EngineLever = EngineLever
EngineController.IsLeverStuck = false

local dragging = false
local dragConnection = nil
local currentAlpha = 0.5
local DEPTH_SENSITIVITY = 0.004

local function levelChanged(lever: BasePart, oldLevel: LeverLevels, newLevel: LeverLevels)
	EngineController.OnLevelChanged:Fire(oldLevel, newLevel)

	-- Maybe add some pitch change
	SoundsController.Play(ESounds.Lever, lever)

	local targetVol
	if newLevel == "Down" then
		targetVol = ENGINE_SOUND_DOWN
	elseif newLevel == "Middle" then
		targetVol = ENGINE_SOUND_MIDDLE
	elseif newLevel == "Up" then
		targetVol = ENGINE_SOUND_UP
	end

	if targetVol then SoundsController.FadeLoop(ESounds.EngineLoop, EngineLight, targetVol) end
end

local function getStressColor(stress: number)
	local t = math.clamp(stress / MAX_STRESS, 0, 1)
	if t < 0.5 then
		return LOW_STRESS_COLOR:Lerp(MID_STRESS_COLOR, t * 2)
	else
		return MID_STRESS_COLOR:Lerp(HIGH_STRESS_COLOR, (t - 0.5) * 2)
	end
end

function EngineController.StuckLever()
	EngineController.IsLeverStuck = true
	EngineController.LeverStop()
end

function EngineController.FreeLever()
	EngineController.IsLeverStuck = false
end

function EngineController.ChangeLeverLevel(level: LeverLevels)
	if EngineController.LeverCurrentLevel == level then return end

	local oldLevel = EngineController.LeverCurrentLevel
	EngineController.LeverCurrentLevel = level

	currentAlpha = level == "Up" and 1 or (level == "Down" and 0 or 0.5)

	local targetCF = level == "Up" and LEVER_UP_CF or (level == "Down" and LEVER_DOWN_CF or LEVER_MIDDLE_CF)

	local tween = TweenService:Create(
		EngineLever,
		TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ CFrame = targetCF }
	)
	tween:Play()

	levelChanged(EngineLever, oldLevel :: any, level :: any)
end

function EngineController.LeverTouched(lever: BasePart)
	if EngineController.IsLeverStuck then return end
	if dragging then return end
	dragging = true

	if EngineController.LeverCurrentLevel == "Up" then
		currentAlpha = 1
	elseif EngineController.LeverCurrentLevel == "Down" then
		currentAlpha = 0
	else
		currentAlpha = 0.5
	end

	dragConnection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then return end

		local distance = (camera.CFrame.Position - lever.Position).Magnitude
		local dynamicSens = DEPTH_SENSITIVITY * distance

		local delta = UserInputService:GetMouseDelta()
		local change = -delta.Y * dynamicSens

		currentAlpha = math.clamp(currentAlpha + change, 0, 1)

		local newLevel: LeverLevels = "Middle"
		if currentAlpha < 0.25 then
			newLevel = "Down"
		elseif currentAlpha > 0.75 then
			newLevel = "Up"
		end

		if EngineController.LeverCurrentLevel ~= newLevel then
			local oldLevel = EngineController.LeverCurrentLevel
			EngineController.LeverCurrentLevel = newLevel

			local targetCF = newLevel == "Up" and LEVER_UP_CF
				or (newLevel == "Down" and LEVER_DOWN_CF or LEVER_MIDDLE_CF)

			local tween = TweenService:Create(
				lever,
				TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ CFrame = targetCF }
			)
			tween:Play()

			levelChanged(lever, oldLevel :: any, newLevel :: any)
		end
	end)
end

function EngineController.LeverStop()
	if not dragging then return end
	if dragConnection then dragConnection:Disconnect() end

	dragging = false

	local level = EngineController.LeverCurrentLevel
	currentAlpha = level == "Up" and 1 or (level == "Down" and 0 or 0.5)
end

function EngineController.StartEngine()
	if EngineController.IsEngineRunning then return end

	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	EngineController.IsEngineRunning = true
	SoundsController.PlayLoop(ESounds.EngineLoop, EngineLight, true)

	Connection = RunService.Heartbeat:Connect(function(dt)
		local oldStress = EngineController.CurrentStress
		local oldSpeed = EngineController.CurrentSpeed

		local stressRate = 0
		if not EngineController.IsEngineRunning then
			stressRate = EngineController.LevelDownStress
		elseif EngineController.LeverCurrentLevel == "Up" then
			stressRate = EngineController.LevelUpStress
		elseif EngineController.LeverCurrentLevel == "Middle" then
			stressRate = EngineController.LevelMiddleStress
		else
			stressRate = LEVEL_DOWN_STRESS
		end

		EngineController.CurrentStress = math.clamp(EngineController.CurrentStress + (stressRate * dt), 0, MAX_STRESS)

		local targetSpeed = 0
		if EngineController.IsEngineRunning then
			if EngineController.LeverCurrentLevel == "Up" then
				targetSpeed = EngineController.LevelUpSpeed
			elseif EngineController.LeverCurrentLevel == "Middle" then
				targetSpeed = EngineController.LevelMiddleSpeed
			else
				targetSpeed = EngineController.LevelDownSpeed
			end
		end

		if EngineController.CurrentSpeed < targetSpeed then
			EngineController.CurrentSpeed =
				math.min(EngineController.CurrentSpeed + (SPEED_CHANGE_SPEED * dt), targetSpeed)
		elseif EngineController.CurrentSpeed > targetSpeed then
			EngineController.CurrentSpeed =
				math.max(EngineController.CurrentSpeed - (SPEED_CHANGE_SPEED * dt), targetSpeed)
		end

		if oldStress ~= EngineController.CurrentStress then
			EngineController.OnStressChanged:Fire(oldStress, EngineController.CurrentStress)
			local finalColor = getStressColor(EngineController.CurrentStress)
			EngineLight.Color = finalColor
			EngineLight.PointLight.Color = finalColor
		end

		if oldSpeed ~= EngineController.CurrentSpeed then
			EngineController.OnSpeedChanged:Fire(oldSpeed, EngineController.CurrentSpeed)
		end
	end)
end

function EngineController.StopEngine()
	EngineController.IsEngineRunning = false
	SoundsController.PlayLoop(ESounds.EngineLoop, EngineLight, false)
end

function EngineController.Reset()
	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	EngineController.StopEngine()
	EngineController.FreeLever()

	EngineController.CurrentStress = 0
	EngineController.CurrentSpeed = 0

	EngineLight.Color = LOW_STRESS_COLOR
	EngineLight.PointLight.Color = LOW_STRESS_COLOR

	EngineController.LeverCurrentLevel = "Down"

	EngineController.LevelUpStress = LEVEL_UP_STRESS
	EngineController.LevelMiddleStress = LEVEL_MIDDLE_STRESS
	EngineController.LevelDownStress = LEVEL_DOWN_STRESS

	EngineController.LevelUpSpeed = LEVEL_UP_SPEED
	EngineController.LevelMiddleSpeed = LEVEL_MIDDLE_SPEED
	EngineController.LevelDownSpeed = LEVEL_DOWN_SPEED

	currentAlpha = 0

	EngineLever.CFrame = LEVER_DOWN_CF
end

EngineController.StartEngine()

return EngineController
