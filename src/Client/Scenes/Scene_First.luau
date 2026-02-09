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
local Highlights = require(ReplicatedStorage.Shared.Utils.Highlights)
local ECharacters = require(ReplicatedStorage.Types.Enums.ECharacters)
local EDialogue = require(ReplicatedStorage.Types.Enums.EDialogue)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)
local TScene = require(ReplicatedStorage.Types.TScene)

type Scene = {
	CurrentPromise: Promise.Promise?,
} & TScene.TScene

local Scene_First = {} :: Scene
Scene_First.IsActive = false
Scene_First.CurrentPromise = nil

local function tutorial()
	EngineController.Reset()
	PressureController.Reset()
	ValveController.Reset()
	LeaksController.Reset()
	WaterController.Reset()
	LightController.Reset()

	return Promise.new(function(resolve)
		return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_0 })
			:andThen(resolve)
	end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_1 })
		end)
		:andThen(function()
			DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_2 })

			return Promise.delay(1):andThen(function()
				return Promise.new(function(resolve, _, onCancel)
					ValveController.RightSpeed = ValveController.RIGHT_SPEED_TUTORIAL
					local valve = ValveController.EnableRandomValve("Low")

					if not valve then
						ValveController.Reset()
						valve = ValveController.EnableRandomValve("Low")
					end

					if valve then Highlights.AddLoop(valve) end

					onCancel(function()
						if valve then Highlights.RemoveLoop(valve) end
					end)

					return Promise.fromEvent(ValveController.OnValveClosed :: any):andThen(function()
						if valve then Highlights.RemoveLoop(valve) end
						ValveController.Reset()
						resolve()
					end)
				end)
			end)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_3 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_4 })
		end)
		:andThen(function()
			-- TODO: Add more leaks and make the player see that the water goes up and takes out the max pressure.
			-- Then take the water out
			DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_5 })

			return Promise.delay(1)
				:andThen(function()
					LeaksController.BreakRandom()
					return Promise.fromEvent(LeaksController.OnLeakFixed :: any)
				end)
				:andThen(function()
					LeaksController.Reset()
				end)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_6 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_7 })
		end)
		:andThen(function()
			DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_8 })

			return Promise.delay(1):andThen(function()
				return Promise.new(function(resolve, _, onCancel)
					local light = LightController.BreakMainLight()

					if not light then
						LightController.Reset()
						light = LightController.BreakMainLight()
					end

					onCancel(function()
						Highlights.RemoveLoop(LightController.LightbulbCage)
						if light then Highlights.RemoveLoop(light) end
					end)

					if not LightController.HasLightbulb then
						Highlights.AddLoop(LightController.LightbulbCage)

						return Promise.fromEvent(LightController.OnBulbGrabbed :: any):andThen(function()
							Highlights.RemoveLoop(LightController.LightbulbCage)
							if light then Highlights.AddLoop(light) end

							return Promise.fromEvent(LightController.OnAnyLightFixed :: any):andThen(function()
								if light then Highlights.RemoveLoop(light) end
								LightController.Reset()
								resolve()
							end)
						end)
					else
						if light then Highlights.AddLoop(light) end

						return Promise.fromEvent(LightController.OnAnyLightFixed :: any):andThen(function()
							if light then Highlights.RemoveLoop(light) end
							LightController.Reset()
							resolve()
						end)
					end
				end)
			end)
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_9 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_10 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_11 })
		end)
		:andThen(function()
			return DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_12 })
		end)
		:andThen(function()
			DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_13 })

			return Promise.new(function(resolve, _, onCancel)
				EngineController.ChangeLeverLevel("Down")
				EngineController.StartEngine()
				PressureController.Start()

				Highlights.AddLoop(EngineController.EngineLever)

				EngineController.LevelUpStress = 40
				EngineController.LevelMiddleStress = 0
				PressureController.PressureNaturalSpeed = 50

				local connections: { Signal.Connection } = {}
				local stressDebounce = false

				local function stop()
					Highlights.RemoveLoop(EngineController.EngineLever)
					EngineController.FreeLever()
					EngineController.LevelUpStress = EngineController.LEVEL_UP_STRESS
					EngineController.LevelMiddleStress = EngineController.LEVEL_MIDDLE_STRESS
					PressureController.PressureNaturalSpeed = PressureController.PRESSURE_NATURAL_SPEED

					stressDebounce = true

					for _, connection in connections do
						connection:Disconnect()
					end

					table.clear(connections)
				end

				onCancel(function()
					stop()
				end)

				connections[#connections + 1] = EngineController.OnLevelChanged:Connect(function(_, new)
					if new ~= "Up" or stressDebounce then return end
					DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_14 })

					EngineController.StuckLever()
					EngineController.ChangeLeverLevel("Up")

					Highlights.RemoveLoop(EngineController.EngineLever)
				end)

				connections[#connections + 1] = EngineController.OnStressChanged:Connect(function(_, new)
					if new < PressureController.ENGINE_STRESS_THRESHOLD or stressDebounce then return end

					stressDebounce = true

					DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_Tutorial_15 })
						:andThen(function()
							EngineController.FreeLever()

							DialogueController.Talk({
								Id = ECharacters.Radio,
								Dialogue = EDialogue.First_Radio_Tutorial_16,
							})

							Highlights.AddLoop(EngineController.EngineLever)

							return Promise.new(function(resolveStep)
								if EngineController.LeverCurrentLevel == "Down" then
									resolveStep()
									return
								end

								local connection: Signal.Connection?
								connection = EngineController.OnLevelChanged:Connect(function(_, level)
									if level ~= "Down" then return end
									EngineController.StuckLever()
									EngineController.ChangeLeverLevel("Down")
									Highlights.RemoveLoop(EngineController.EngineLever)

									if connection then
										connection:Disconnect()
										connection = nil
									end

									resolveStep()
								end)
							end)
						end)
						:andThen(function()
							return Promise.fromEvent(PressureController.OnPressureFull :: any)
						end)
						:andThen(function()
							stop()

							return DialogueController.Question({
								Id = ECharacters.Radio,
								Dialogue = EDialogue.First_Radio_Tutorial_17,
							})
						end)
						:andThen(function(agreed)
							if agreed then
								return resolve(tutorial())
							else
								resolve()
							end
						end)
				end)
			end)
		end)
end

function Scene_First.Start()
	Scene_First.IsActive = true

	Scene_First.CurrentPromise = Promise.delay(1)
		:andThen(function()
			return DialogueController.Question({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_0 })
		end)
		:andThen(function(agreed)
			if agreed then return tutorial() end
		end)
		:andThen(function()
			DialogueController.Talk({ Id = ECharacters.Radio, Dialogue = EDialogue.First_Radio_1 })

			return EScenes.Second
		end)
		:catch(function(err)
			warn("[Scene_First] Error:", err)
		end)

	return Scene_First.CurrentPromise :: Promise.Promise
end

function Scene_First.Stop()
	Scene_First.IsActive = false

	if Scene_First.CurrentPromise then
		Scene_First.CurrentPromise:cancel()
		Scene_First.CurrentPromise = nil
	end
end

function Scene_First.Restart()
	Scene_First.Stop()

	ValveController.Reset()
	LeaksController.Reset()
	WaterController.Reset()
	EngineController.Reset()
	PressureController.Reset()
	DepthController.Reset(EScenes.First)
	InteractController.Reset()

	Scene_First.Start()
end

return Scene_First
