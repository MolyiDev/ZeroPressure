local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LeaksController = require(script.Parent.LeaksController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local ECameraFovs = require(ReplicatedStorage.Types.Enums.ECameraFovs)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

type ShakeInstance = {
	Magnitude: number,
	Roughness: number,
	Duration: number,
	FadeOut: number,
	PosInf: Vector3,
	RotInf: Vector3,
	StartTime: number,
	Seed: number,
}

local DEFAULT_POS = Vector3.new(0.5, 0.5, 0.5)
local DEFAULT_ROT = Vector3.new(0.05, 0.05, 0.05)

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = Workspace.CurrentCamera

local AccumulatedTime = 0

local CameraSensitivity = 0.15
local MaxOffset = 25

local ActiveShakes: { ShakeInstance } = {}

local humanoid: Humanoid
local root: BasePart

local CameraController = {}
CameraController.AutoRotate = false
CameraController.CameraLocked = false
CameraController.CinematicCameraActive = false
CameraController.IsFlying = false
CameraController.ShakeMultiplier = 1

local TransitionStartCFrame: CFrame? = nil
local TransitionAlpha = 1
local TRANSITION_SPEED = 4

function CameraController.LockCamera()
	CameraController.CameraLocked = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function CameraController.UnlockCamera()
	CameraController.CameraLocked = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function CameraController.EnableCinematicCamera()
	LeaksController.DisableBlowtorch()

	CameraController.UnlockCamera()
	CameraController.CinematicCameraActive = true
	TransitionAlpha = 1
end

function CameraController.DisableCinematicCamera()
	LeaksController.EnableBlowtorch()

	TransitionStartCFrame = Camera.CFrame
	TransitionAlpha = 0

	CameraController.LockCamera()
	Camera.CameraSubject = if Player.Character then Player.Character:FindFirstChild("Head") else nil
	CameraController.CinematicCameraActive = false
end

function CameraController.ToggleCameraLock()
	if CameraController.CameraLocked then
		CameraController.UnlockCamera()
	else
		CameraController.LockCamera()
	end
end

function CameraController.Shake(
	magnitude: number,
	roughness: number,
	duration: number,
	positionInfluence: Vector3?,
	rotationInfluence: Vector3?,
	fadeOut: number?
)
	ActiveShakes[#ActiveShakes + 1] = {
		Magnitude = magnitude,
		Roughness = roughness,
		Duration = duration,
		FadeOut = fadeOut or 0,
		PosInf = positionInfluence or DEFAULT_POS,
		RotInf = rotationInfluence or DEFAULT_ROT,
		StartTime = AccumulatedTime,
		Seed = math.random() * 1000,
	}
end

local function computeShakeOffset(): CFrame
	if #ActiveShakes == 0 then return CFrame.identity end

	local now = AccumulatedTime
	local totalPos = Vector3.zero
	local totalRot = Vector3.zero

	for i = #ActiveShakes, 1, -1 do
		local shake = ActiveShakes[i]
		local elapsed = now - shake.StartTime

		if elapsed >= shake.Duration then
			table.remove(ActiveShakes, i)
			continue
		end

		local alpha = 1 - (elapsed / shake.Duration)
		local currentMag = shake.Magnitude * alpha * CameraController.ShakeMultiplier

		local freq = 4 / math.max(shake.Roughness, 0.01)
		local t = now * freq

		local nX = (math.noise(t, shake.Seed, 1) * 2)
		local nY = (math.noise(t, shake.Seed, 2) * 2)
		local nZ = (math.noise(t, shake.Seed, 3) * 2)

		local pX = (math.noise(t, shake.Seed, 4) * 2)
		local pY = (math.noise(t, shake.Seed, 5) * 2)
		local pZ = (math.noise(t, shake.Seed, 6) * 2)

		totalRot += Vector3.new(nX, nY, nZ) * shake.RotInf * currentMag
		totalPos += Vector3.new(pX, pY, pZ) * shake.PosInf * currentMag
	end

	return CFrame.new(totalPos) * CFrame.Angles(math.rad(totalRot.X), math.rad(totalRot.Y), math.rad(totalRot.Z))
end

CameraController.OnCharacterAdded = function(character: TCharacter.TCharacter, characterEntity: jecs.Entity)
	local butler = World:get(characterEntity, Components.Butler)
	root = World:get(characterEntity, Components.HumanoidRootPart) :: BasePart
	humanoid = World:get(characterEntity, Components.Humanoid) :: Humanoid
	if not humanoid or not root or not butler then
		warn("Humanoid / HumanoidRootPart / Butler are nil")
		return
	end

	humanoid.AutoRotate = false
	humanoid.CameraOffset = Vector3.new(0, -0.5, -1)

	local spawn = CollectionService:GetTagged("Spawn")[1] :: Attachment
	if spawn then root.CFrame = spawn.WorldCFrame end

	Camera.FieldOfView = ECameraFovs.Default
	Camera.CameraSubject = character:WaitForChild("Head")
	Camera.Focus = Camera.CameraSubject.CFrame
	Camera.CFrame = Camera.Focus

	butler:Connect(RunService.PreRender, function(dt)
		AccumulatedTime += dt

		UserInputService.MouseBehavior = if CameraController.CameraLocked
			then Enum.MouseBehavior.LockCenter
			else Enum.MouseBehavior.Default

		if CameraController.IsFlying then
			if Camera.CameraType ~= Enum.CameraType.Scriptable then Camera.CameraType = Enum.CameraType.Scriptable end
			return
		end

		if CameraController.CinematicCameraActive then
			if Camera.CameraType ~= Enum.CameraType.Scriptable then Camera.CameraType = Enum.CameraType.Scriptable end

			local viewportSize = Camera.ViewportSize
			local OffsetX = ((Mouse.X - viewportSize.X / 2) / (viewportSize.X / 2)) * MaxOffset
			local OffsetY = ((Mouse.Y - viewportSize.Y / 2) / (viewportSize.Y / 2)) * MaxOffset

			local rotation =
				CFrame.Angles(math.rad(-OffsetY * CameraSensitivity), math.rad(-OffsetX * CameraSensitivity), 0)
			local baseCFrame = Camera.CameraSubject.CFrame * rotation

			local _, y, _ = baseCFrame:ToOrientation()
			local flatRot = CFrame.Angles(0, y, 0)

			local relativeOffset = flatRot * humanoid.CameraOffset

			Camera.Focus = Camera.CameraSubject.CFrame
			Camera.CFrame = baseCFrame + relativeOffset

			return
		end

		if Camera.CameraType == Enum.CameraType.Scriptable then Camera.CameraType = Enum.CameraType.Custom end

		local shakeCF = computeShakeOffset()

		local _, y, _ = Camera.CFrame:ToOrientation()

		local flatRot = CFrame.Angles(0, y, 0)
		local relativeOffset = flatRot * humanoid.CameraOffset

		local head = Camera.CameraSubject
		if not head then return end

		local TargetCFrame = CFrame.new(head.CFrame.Position) * (Camera.CFrame - Camera.CFrame.Position) * shakeCF
			+ relativeOffset

		if TransitionAlpha < 1 then
			TransitionAlpha = math.min(TransitionAlpha + (dt * TRANSITION_SPEED), 1)
			if TransitionStartCFrame then
				Camera.CFrame = TransitionStartCFrame:Lerp(TargetCFrame, TransitionAlpha)
			else
				Camera.CFrame = TargetCFrame
			end
		else
			Camera.CFrame = TargetCFrame
		end

		if CameraController.AutoRotate then
			character.HumanoidRootPart.CFrame = CFrame.new(character.HumanoidRootPart.Position) * CFrame.Angles(0, y, 0)
		end
	end)
end

return Ignis.Register(CameraController)
