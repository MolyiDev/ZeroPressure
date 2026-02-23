local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraController = require(script.Parent.Parent.Controllers.CameraController)
local DepthController = require(script.Parent.Parent.Controllers.DepthController)
local EngineController = require(script.Parent.Parent.Controllers.EngineController)
local PressureController = require(script.Parent.Parent.Controllers.PressureController)
local WaterController = require(script.Parent.Parent.Controllers.WaterController)
local ValveController = require(script.Parent.Parent.Controllers.ValveController)
local LeaksController = require(script.Parent.Parent.Controllers.LeaksController)
local LightController = require(script.Parent.Parent.Controllers.LightController)
local InteractController = require(script.Parent.Parent.Controllers.InteractController)
local DialogueController = require(script.Parent.Parent.Controllers.DialogueController)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ECharacters = require(ReplicatedStorage.Types.Enums.ECharacters)
local EDialogue = require(ReplicatedStorage.Types.Enums.EDialogue)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)
local TScene = require(ReplicatedStorage.Types.TScene)

type Scene = {
	CurrentPromise: Promise.Promise?,
} & TScene.TScene

local Scene_Fourth = {} :: Scene
Scene_Fourth.IsActive = false
Scene_Fourth.CurrentPromise = nil

function Scene_Fourth.Start()
	Scene_Fourth.IsActive = true

	WaterController.StartRise()
	EngineController.StopEngine()
	DepthController.Start()
	PressureController.Start()
	LeaksController.StopRandomizer()
	ValveController.DisableAllValves()
	LightController.StopRandomizer()

	Scene_Fourth.CurrentPromise = Promise.delay(0.5)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.Fourth_Radio_0 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.Fourth_Radio_1 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.Fourth_Radio_2 })
		end)
		:andThen(function()
			DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.Fourth_Radio_3 })
			return Promise.delay(0.4)
		end)
		:andThen(function()
			return Promise.new(function(resolve, _, onCancel)
				-- TODO: Cut down the cable.
				CameraController.Shake(2, 0.1, 1, Vector3.new(0.2, 0.2, 0.2), Vector3.zero, 0.4)

				EngineController.StartEngine()
				LeaksController.EnableBlowtorch()
				LeaksController.StartRandomizer()
				LightController.StartRandomizer()
				ValveController.EnableAllValves()

				EngineController.LevelUpSpeed = EngineController.LEVEL_UP_SPEED_FOURTH
				EngineController.LevelMiddleSpeed = EngineController.LEVEL_MIDDLE_SPEED_FOURTH
				EngineController.LevelDownSpeed = EngineController.LEVEL_DOWN_SPEED_FOURTH

				LightController.ChanceToBreak = LightController.CHANCE_TO_BREAK_FOURTH
				LeaksController.ChanceToBreak = LeaksController.CHANCE_TO_BREAK_FOURTH
				ValveController.RightSpeed = ValveController.RIGHT_SPEED_FOURTH

				local debounce = false
				local halfDebounce = false
				local connection: Signal.Connection?

				connection = DepthController.OnDepthChanged:Connect(function(_, new)
					if new < DepthController.FOURTH_DEPTH / 2 then return end

					if not halfDebounce then
						halfDebounce = true
						LightController.ChanceToBreak = LightController.CHANCE_TO_BREAK_FOURTH_HALF
						LeaksController.ChanceToBreak = LeaksController.CHANCE_TO_BREAK_FOURTH_HALF
						ValveController.RightSpeed = ValveController.RIGHT_SPEED_FOURTH_HALF
					end

					if new < DepthController.FOURTH_DEPTH or debounce then return end

					debounce = true
					if connection then
						connection:Disconnect()
						connection = nil
					end

					resolve()
				end)

				onCancel(function()
					if connection then
						connection:Disconnect()
						connection = nil
					end
				end)
			end)
		end)
		:andThen(function()
			return EScenes.Fifth
		end)

	return Scene_Fourth.CurrentPromise :: Promise.Promise
end

function Scene_Fourth.Stop()
	Scene_Fourth.IsActive = false

	if Scene_Fourth.CurrentPromise then
		Scene_Fourth.CurrentPromise:cancel()
		Scene_Fourth.CurrentPromise = nil
	end
end

function Scene_Fourth.Restart()
	Scene_Fourth.Stop()

	ValveController.Reset()
	LeaksController.Reset()
	WaterController.Reset()
	EngineController.Reset()
	PressureController.Reset()
	DepthController.Reset(EScenes.Fourth)
	InteractController.Reset()

	Scene_Fourth.Start()
end

return Scene_Fourth
