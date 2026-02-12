local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CreditsController = require(script.Parent.Parent.Controllers.CreditsController)
local LogoController = require(script.Parent.Parent.Controllers.LogoController)
local CameraController = require(script.Parent.Parent.Controllers.CameraController)
local DepthController = require(script.Parent.Parent.Controllers.DepthController)
local EngineController = require(script.Parent.Parent.Controllers.EngineController)
local PressureController = require(script.Parent.Parent.Controllers.PressureController)
local LightController = require(script.Parent.Parent.Controllers.LightController)
local WaterController = require(script.Parent.Parent.Controllers.WaterController)
local ValveController = require(script.Parent.Parent.Controllers.ValveController)
local LeaksController = require(script.Parent.Parent.Controllers.LeaksController)
local InteractController = require(script.Parent.Parent.Controllers.InteractController)
local SoundsController = require(script.Parent.Parent.Controllers.SoundsController)
local EyeController = require(script.Parent.Parent.Controllers.EyeController)
local Promise = require(ReplicatedStorage.Packages.Promise)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)
local TScene = require(ReplicatedStorage.Types.TScene)

type Scene = {
	CurrentPromise: Promise.Promise?,
} & TScene.TScene

local MonsterAttachment = Workspace:FindFirstChild("Monster") :: Attachment

local Scene_Fifth = {} :: Scene
Scene_Fifth.IsActive = false
Scene_Fifth.CurrentPromise = nil

function Scene_Fifth.Start()
	Scene_Fifth.IsActive = true

	LeaksController.Reset()
	WaterController.StopRise()
	EngineController.StopEngine()
	DepthController.Stop()
	PressureController.Stop()
	LeaksController.StopRandomizer()
	ValveController.DisableAllValves()
	LightController.Stop()
	EyeController.Reset()
	EyeController.Close()

	SoundsController.Play(ESounds.RoarAwake, MonsterAttachment)

	Scene_Fifth.CurrentPromise = Promise.delay(1)
		:andThen(function()
			EyeController.Appear()
			CameraController.EnableCinematicCamera()
			CameraController.LookAt(MonsterAttachment.Position)
			LightController.BreakMainLight()
			LightController.BreakEngineLight()
			SoundsController.PlayCharacter(ESounds.SubmarineFall)
			CameraController.Shake(2, 0.1, 1, Vector3.new(0.2, 0.2, 0.2), Vector3.zero, 0.4)

			return Promise.delay(2)
		end)
		:andThen(function()
			-- hitted ground

			return Promise.delay(1)
		end)
		:andThen(function()
			-- monster opens eye
			EyeController.Open()

			return Promise.delay(1)
		end)
		:andThen(function()
			-- monster screams

			SoundsController.Play(ESounds.Roar, MonsterAttachment)
			return Promise.delay(1.3)
		end)
		:andThen(function()
			-- more shake
			CameraController.Shake(2, 0.2, 3.8, Vector3.new(0.2, 0.2, 0.2), Vector3.zero, 0.5)

			return Promise.delay(3.8)
		end)
		:andThen(function()
			-- black screen credits.
			return LogoController.AppearAnimation()
		end)
		:andThen(function()
			CreditsController.Appear()
		end)

	return Scene_Fifth.CurrentPromise :: Promise.Promise
end

function Scene_Fifth.Stop()
	Scene_Fifth.IsActive = false

	if Scene_Fifth.CurrentPromise then
		Scene_Fifth.CurrentPromise:cancel()
		Scene_Fifth.CurrentPromise = nil
	end
end

function Scene_Fifth.Restart()
	Scene_Fifth.Stop()

	ValveController.Reset()
	LeaksController.Reset()
	WaterController.Reset()
	EngineController.Reset()
	PressureController.Reset()
	DepthController.Reset(EScenes.Fifth)
	InteractController.Reset()
	LogoController.Disappear()
	CreditsController.Disappear()
	CameraController.DisableCinematicCamera()
	EyeController.Reset()

	Scene_Fifth.Start()
end

return Scene_Fifth
