local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)
local CameraController = require(script.Parent.CameraController)
local MouseController = require(script.Parent.MouseController)
local TweensController = require(script.Parent.TweensController)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)
local TScene = require(ReplicatedStorage.Types.TScene)

local SCENE_MODULES: { [number]: TScene.TScene } = table.freeze({
	[EScenes.First] = require(script.Parent.Parent.Scenes.Scene_First),
	[EScenes.Second] = require(script.Parent.Parent.Scenes.Scene_Second),
})

local ActiveSceneModule: TScene.TScene?
local InputBeganConnection: RBXScriptConnection?

local function startCharacter()
	MouseController.HideMouse()
	MouseController.ShowCursor()
	CameraController.AutoRotate = true
	CameraController.DisableCinematicCamera()
	TweensController.SetImmobile(false)
end

local function resetGlobalState()
	TweensController.SetImmobile(false)
end

local function getSceneModule(sceneId: number): TScene.TScene
	return SCENE_MODULES[sceneId]
end

local SceneController = {}
SceneController.OnGameStarted = Signal.new()
SceneController.OnSceneChanged = Signal.new() :: Signal.Signal<number, number> -- oldScene, newScene
SceneController.CurrentScene = EScenes.Starting

function SceneController.LoadScene(sceneId: number)
	if ActiveSceneModule and ActiveSceneModule.Stop then ActiveSceneModule.Stop() end

	resetGlobalState()

	local oldScene = SceneController.CurrentScene
	SceneController.CurrentScene = sceneId
	ActiveSceneModule = getSceneModule(sceneId)

	SceneController.OnSceneChanged:Fire(oldScene, sceneId)

	if not ActiveSceneModule or not ActiveSceneModule.Start then return end
	ActiveSceneModule.Start():andThen(function(nextSceneId: number)
		if nextSceneId and type(nextSceneId) == "number" then SceneController.LoadScene(nextSceneId) end
	end)
end

function SceneController.IsGameStarted(): boolean
	return SceneController.CurrentScene > 0
end

function SceneController.Restart()
	resetGlobalState()
	if ActiveSceneModule and ActiveSceneModule.Restart then ActiveSceneModule.Restart() end
end

SceneController.OnCharacterAdded = function(character: TCharacter.TCharacter)
	if SceneController.IsGameStarted() then
		startCharacter()

		if ActiveSceneModule and ActiveSceneModule.CharacterAdded then ActiveSceneModule.CharacterAdded(character) end
		return
	end

	if InputBeganConnection then
		InputBeganConnection:Disconnect()
		InputBeganConnection = nil
	end

	-- The game has not started.
	local cameraSpawn = CollectionService:GetTagged("CameraSpawn")[1] :: BasePart
	CameraController.EnableCinematicCamera()
	Workspace.CurrentCamera.CameraSubject = cameraSpawn
	TweensController.SetImmobile(true)

	InputBeganConnection = UserInputService.InputBegan:Connect(function(input, gp)
		if gp or input.KeyCode ~= Enum.KeyCode.F then return end

		if InputBeganConnection then
			InputBeganConnection:Disconnect()
			InputBeganConnection = nil
		end

		SceneController.OnGameStarted:Fire()
		startCharacter()
		SceneController.LoadScene(EScenes.Second)
		-- SceneController.LoadScene(EScenes.First)
	end)
end

return Ignis.Register(SceneController)
