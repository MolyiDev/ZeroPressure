local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweensController = require(script.Parent.TweensController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)
local ECameraFovs = require(ReplicatedStorage.Types.Enums.ECameraFovs)
local EDirections = require(ReplicatedStorage.Types.Enums.EDirections)
local EMovementJumps = require(ReplicatedStorage.Types.Enums.Movement.EMovementJumps)
local EMovementSpeeds = require(ReplicatedStorage.Types.Enums.Movement.EMovementSpeeds)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local FADE_OUT = 0.35
local FADE_IN = 0.35
local LIMIT = 1.32
local WALK_ANIM_SPEED = 1
local RUN_ANIM_SPEED = 1.4

local AnimationsFolder = ReplicatedStorage.Animations
local RunAnimationsFolder = AnimationsFolder.Running
local WalkAnimationsFolder = AnimationsFolder.Walking

local IdleAnim = AnimationsFolder.Idle :: Animation
local RunFrontAnim = RunAnimationsFolder.RunFront :: Animation
local WalkFrontAnim = WalkAnimationsFolder.WalkFront :: Animation
local WalkBackAnim = WalkAnimationsFolder.WalkBack :: Animation
local WalkLeftAnim = WalkAnimationsFolder.WalkLeft :: Animation
local WalkRightAnim = WalkAnimationsFolder.WalkRight :: Animation

local Idle: AnimationTrack
local RunFront: AnimationTrack
local WalkFront: AnimationTrack
local WalkBack: AnimationTrack
local WalkLeft: AnimationTrack
local WalkRight: AnimationTrack

local WalkAnimations: { [Vector3]: { AnimationTrack } } = {}

local Character: TCharacter.TCharacter
local PrevAnimation: AnimationTrack?
local PrevAnimationStop: number = 0
local PrevAnimationTimePosition: number = 0
local ShiftTouched: boolean = false

local CurrentBaseSpeed = EMovementSpeeds.Default
local CurrentBaseJump = EMovementJumps.Default

local MovementController = {}

local function stopAllAnimations(fadeOut: number)
	PrevAnimationStop = tick()
	PrevAnimationTimePosition = if PrevAnimation then PrevAnimation.TimePosition else 0

	RunFront:Stop(fadeOut)
	WalkFront:Stop(fadeOut)
	WalkBack:Stop(fadeOut)
	WalkLeft:Stop(fadeOut)
	WalkRight:Stop(fadeOut)
end

local function getAnimTime(): number
	local timeTick = tick() - PrevAnimationStop
	if not PrevAnimation or timeTick > FADE_OUT then return 0 end

	local result = PrevAnimationTimePosition + timeTick
	if result > LIMIT then
		result = result - LIMIT
	elseif result < 0 then
		result = LIMIT - math.abs(result)
	end

	return result
end

local function walkAnimSpeed()
	return ((Character.Humanoid.WalkSpeed * WALK_ANIM_SPEED) / EMovementSpeeds.Default)
end

local function runAnimSpeed()
	return ((Character.Humanoid.WalkSpeed * RUN_ANIM_SPEED) / EMovementSpeeds.Running)
end

local function moveDirection()
	local Direction = Tools.WorldMovingDirection(
		Character.HumanoidRootPart.CFrame:VectorToObjectSpace(Character.Humanoid.MoveDirection)
	)
	stopAllAnimations(FADE_OUT)
	if Direction == Vector3.zero or TweensController.IsImmobile then return end

	if ShiftTouched then
		CurrentBaseSpeed = EMovementSpeeds.Running
		CurrentBaseJump = EMovementJumps.Running
		TweensController.SetCameraFov(ECameraFovs.Running, TweenInfo.new(0.25))
		TweensController.SetSpeed(CurrentBaseSpeed, 0.25)
		TweensController.SetJump(CurrentBaseJump, 0.25)
		RunFront:Play(FADE_IN, 1, runAnimSpeed())
		if PrevAnimation == RunFront then RunFront.TimePosition = getAnimTime() end
		PrevAnimation = RunFront
	else
		CurrentBaseSpeed = EMovementSpeeds.Default
		CurrentBaseJump = EMovementJumps.Default
		TweensController.SetCameraFov(ECameraFovs.Default, TweenInfo.new(0.25))
		TweensController.SetSpeed(CurrentBaseSpeed, 0.25)
		TweensController.SetJump(CurrentBaseJump, 0.25)
		local animations = WalkAnimations[Direction]
		local syncTime = getAnimTime()

		if animations then
			for _, anim in animations do
				anim:Play(FADE_IN, 1, walkAnimSpeed())
				anim.TimePosition = syncTime
				PrevAnimation = anim
			end
		end
	end
end

local function handleRunning(input: InputObject)
	if input.KeyCode ~= Enum.KeyCode.LeftShift then return end

	if input.UserInputState == Enum.UserInputState.Begin then
		ShiftTouched = true
	else
		ShiftTouched = false
	end

	moveDirection()
end

MovementController.OnCharacterAdded = function(character: TCharacter.TCharacter, characterEntity: jecs.Entity)
	local butler = World:get(characterEntity, Components.Butler)
	local humanoid = World:get(characterEntity, Components.Humanoid)
	local animator = World:get(characterEntity, Components.Animator)

	if not humanoid or not animator or not butler then
		warn("Humanoid / HumanoidRootPart / Butler are nil")
		return
	end

	Character = character

	Idle = animator:LoadAnimation(IdleAnim)
	Idle:Play(0.1, 1, 0.65)

	-- Run animations
	RunFront = animator:LoadAnimation(RunFrontAnim)

	-- Walk animations
	WalkFront = animator:LoadAnimation(WalkFrontAnim)
	WalkBack = animator:LoadAnimation(WalkBackAnim)
	WalkLeft = animator:LoadAnimation(WalkLeftAnim)
	WalkRight = animator:LoadAnimation(WalkRightAnim)

	WalkAnimations[EDirections.Front] = { WalkFront }
	WalkAnimations[EDirections.FrontLeft] = { WalkFront, WalkLeft }
	WalkAnimations[EDirections.FrontRight] = { WalkFront, WalkRight }
	WalkAnimations[EDirections.Back] = { WalkBack }
	WalkAnimations[EDirections.BackLeft] = { WalkBack, WalkRight }
	WalkAnimations[EDirections.BackRight] = { WalkBack, WalkLeft }
	WalkAnimations[EDirections.Left] = { WalkLeft }
	WalkAnimations[EDirections.Right] = { WalkRight }

	butler:Connect(humanoid:GetPropertyChangedSignal("MoveDirection"), moveDirection)
	butler:Connect(humanoid:GetPropertyChangedSignal("WalkSpeed"), moveDirection)
	butler:Connect(UserInputService.InputBegan, handleRunning)
	butler:Connect(UserInputService.InputEnded, handleRunning)

	humanoid.WalkSpeed = EMovementSpeeds.Default
	humanoid.JumpHeight = EMovementJumps.Default
end

return Ignis.Register(MovementController)
