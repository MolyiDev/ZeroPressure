local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local Scene_Third = {} :: Scene
Scene_Third.IsActive = false
Scene_Third.CurrentPromise = nil

function Scene_Third.Start()
	Scene_Third.IsActive = true

	WaterController.StartRise()
	EngineController.StartEngine()
	DepthController.Start()
	PressureController.Start()

	Scene_Third.CurrentPromise = Promise.delay(0.5)
		:andThen(function()
			DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.Third_Radio_0 }):andThen(function()
				return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.Third_Radio_1 })
			end)

			return Promise.delay(1)
		end)
		:andThen(function()
			return Promise.new(function(resolve, _, onCancel)
				LeaksController.EnableBlowtorch()
				LeaksController.StartRandomizer()
				LightController.Start()

				LightController.ChanceToBreak = LightController.CHANCE_TO_BREAK_THIRD

				if ValveController.EnabledValvesCount == 0 then
					ValveController.EnableRandomValve()
					ValveController.EnableRandomValve()
				elseif ValveController.EnabledValvesCount == 1 then
					ValveController.EnableRandomValve()
				end

				ValveController.EnableRandomValve()

				local debounce = false
				local halfDebounce = false
				local connection: Signal.Connection?

				connection = DepthController.OnDepthChanged:Connect(function(_, new)
					if new < DepthController.THIRD_DEPTH / 2 then return end

					if not halfDebounce then
						halfDebounce = true
						ValveController.EnableRandomValve()
						LightController.ChanceToBreak = LightController.CHANCE_TO_BREAK_THIRD_HALF
					end

					if new < DepthController.THIRD_DEPTH or debounce then return end

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
			return EScenes.Fourth
		end)

	return Scene_Third.CurrentPromise :: Promise.Promise
end

function Scene_Third.Stop()
	Scene_Third.IsActive = false

	if Scene_Third.CurrentPromise then
		Scene_Third.CurrentPromise:cancel()
		Scene_Third.CurrentPromise = nil
	end
end

function Scene_Third.Restart()
	Scene_Third.Stop()

	ValveController.Reset()
	LeaksController.Reset()
	WaterController.Reset()
	EngineController.Reset()
	PressureController.Reset()
	DepthController.Reset(EScenes.Third)
	InteractController.Reset()

	Scene_Third.Start()
end

return Scene_Third
