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

local Scene_Second = {} :: Scene
Scene_Second.IsActive = false
Scene_Second.CurrentPromise = nil

function Scene_Second.Start()
	Scene_Second.IsActive = true

	WaterController.StartRise()
	LeaksController.EnableBlowtorch()
	DepthController.Start()
	PressureController.Start()

	Scene_Second.CurrentPromise = Promise.delay(2)
		:andThen(function()
			return Promise.new(function(resolve, _, onCancel)
				DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.Second_Radio_0 })
				CameraController.Shake(2, 0.1, 1, Vector3.new(0.2, 0.2, 0.2), Vector3.zero, 0.4)

				EngineController.StartEngine()

				EngineController.LevelUpSpeed = EngineController.LEVEL_UP_SPEED * 2
				EngineController.LevelMiddleSpeed = EngineController.LEVEL_MIDDLE_SPEED * 2
				EngineController.LevelDownSpeed = EngineController.LEVEL_DOWN_SPEED * 2

				LightController.Start()

				ValveController.EnableRandomValve()

				local debounce = false
				local halfDebounce = false
				local connection: Signal.Connection?

				connection = DepthController.OnDepthChanged:Connect(function(_, new)
					if new < DepthController.SECOND_DEPTH / 2 then return end

					if not halfDebounce then
						halfDebounce = true
						ValveController.EnableRandomValve()
					end

					if new < DepthController.SECOND_DEPTH or debounce then return end

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
			return EScenes.Third
		end)

	return Scene_Second.CurrentPromise :: Promise.Promise
end

function Scene_Second.Stop()
	Scene_Second.IsActive = false

	if Scene_Second.CurrentPromise then
		Scene_Second.CurrentPromise:cancel()
		Scene_Second.CurrentPromise = nil
	end
end

function Scene_Second.Restart()
	Scene_Second.Stop()

	ValveController.Reset()
	LeaksController.Reset()
	WaterController.Reset()
	EngineController.Reset()
	PressureController.Reset()
	DepthController.Reset(EScenes.Second)
	InteractController.Reset()

	Scene_Second.Start()
end

return Scene_Second
