local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local EBlur = require(ReplicatedStorage.Types.Enums.EBlur)
local ECameraFovs = require(ReplicatedStorage.Types.Enums.ECameraFovs)
local EMovementJumps = require(ReplicatedStorage.Types.Enums.Movement.EMovementJumps)
local EMovementSpeeds = require(ReplicatedStorage.Types.Enums.Movement.EMovementSpeeds)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

type TInfo = {
	Initial: number,
	Target: number,
	Tween: TweenInfo,
	TimeElapsed: number,
}

type DashInfo = {
	Direction: number,
	Time: number,
	InitialSpeed: number,
	FinalSpeed: number,
	Stun: boolean,
	TimeElapsed: number,
}

type Public = {
	ZeroTween: TweenInfo,
	IsImmobile: boolean,
	Pause: () -> (),
	Resume: () -> (),
	SetCameraFov: (value: number, tween: TweenInfo) -> (),
	SetBlur: (value: number, tween: TweenInfo) -> (),
	SetSaturation: (value: number, tween: TweenInfo) -> (),
	SetSpeed: (value: number, time: number?) -> (),
	SetJump: (value: number, time: number?) -> (),
	SetImmobile: (value: boolean, time: number?) -> (),
}

local TweensController = {}
TweensController.ZeroTween = TweenInfo.new(0.01, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
TweensController.IsImmobile = false

local Camera = Workspace.CurrentCamera
local Blur = Lighting.Blur
local ColorCorrection = Lighting.ColorCorrection
local Humanoid: Humanoid?
local UpdateConnection: RBXScriptConnection?

local CameraInfo: TInfo = {
	Initial = ECameraFovs.Default,
	Target = ECameraFovs.Default,
	Tween = TweenInfo.new(0),
	TimeElapsed = 0,
}

local BlurInfo: TInfo = {
	Initial = EBlur.Default,
	Target = EBlur.Default,
	Tween = TweenInfo.new(0),
	TimeElapsed = 0,
}

local SaturationInfo: TInfo = {
	Initial = 0,
	Target = 0,
	Tween = TweenInfo.new(0),
	TimeElapsed = 0,
}

local SpeedInfo: TInfo = {
	Initial = EMovementSpeeds.Default,
	Target = EMovementSpeeds.Default,
	Tween = TweenInfo.new(0),
	TimeElapsed = 0,
}

local JumpInfo: TInfo = {
	Initial = EMovementJumps.Default,
	Target = EMovementJumps.Default,
	Tween = TweenInfo.new(0),
	TimeElapsed = 0,
}

TweensController.OnCharacterAdded = function(character: TCharacter.TCharacter)
	Humanoid = character.Humanoid
end

TweensController.OnCharacterRemoving = function()
	Humanoid = nil
end

function TweensController.SetCameraFov(value: number, tween: TweenInfo)
	if CameraInfo.Target == value then return end

	CameraInfo.Initial = Camera.FieldOfView
	CameraInfo.Target = value
	CameraInfo.Tween = tween
	CameraInfo.TimeElapsed = 0
	TweensController.Resume()
end

function TweensController.SetBlur(value: number, tween: TweenInfo)
	if BlurInfo.Target == value then return end

	BlurInfo.Initial = Blur.Size
	BlurInfo.Target = value
	BlurInfo.Tween = tween
	BlurInfo.TimeElapsed = 0
	TweensController.Resume()
end

function TweensController.SetSaturation(value: number, tween: TweenInfo)
	if SaturationInfo.Target == value then return end

	SaturationInfo.Initial = ColorCorrection.Saturation
	SaturationInfo.Target = value
	SaturationInfo.Tween = tween
	SaturationInfo.TimeElapsed = 0
	TweensController.Resume()
end

function TweensController.SetSpeed(value: number, time: number?)
	if Humanoid == nil or TweensController.IsImmobile or SpeedInfo.Target == value then return end

	SpeedInfo.Initial = Humanoid.WalkSpeed
	SpeedInfo.Target = value

	if not time or time == 0 then
		Humanoid.WalkSpeed = value
		return
	end

	SpeedInfo.Tween = TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	SpeedInfo.TimeElapsed = 0
	TweensController.Resume()
end

function TweensController.SetJump(value: number, time: number?)
	if Humanoid == nil or TweensController.IsImmobile or JumpInfo.Target == value then return end

	JumpInfo.Initial = Humanoid.JumpHeight
	JumpInfo.Target = value

	if not time or time == 0 then
		Humanoid.JumpHeight = value
		return
	end

	JumpInfo.Tween = TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	JumpInfo.TimeElapsed = 0
	TweensController.Resume()
end

function TweensController.SetImmobile(value: boolean, time: number?)
	if value and not TweensController.IsImmobile then
		TweensController.SetJump(0, time)
		TweensController.SetSpeed(0, time)
		TweensController.IsImmobile = true
	elseif not value and TweensController.IsImmobile then
		TweensController.IsImmobile = false
		TweensController.SetJump(EMovementJumps.Default, time)
		TweensController.SetSpeed(EMovementSpeeds.Default, time)
	end
end

local function update(dt: number)
	CameraInfo.TimeElapsed = math.min(CameraInfo.TimeElapsed + dt, CameraInfo.Tween.Time)
	BlurInfo.TimeElapsed = math.min(BlurInfo.TimeElapsed + dt, BlurInfo.Tween.Time)
	SaturationInfo.TimeElapsed = math.min(SaturationInfo.TimeElapsed + dt, SaturationInfo.Tween.Time)
	SpeedInfo.TimeElapsed = math.min(SpeedInfo.TimeElapsed + dt, SpeedInfo.Tween.Time)
	JumpInfo.TimeElapsed = math.min(JumpInfo.TimeElapsed + dt, JumpInfo.Tween.Time)

	if CameraInfo.Tween.Time > 0 then
		local alphaCamera = CameraInfo.TimeElapsed / CameraInfo.Tween.Time
		local easedAlphaCamera =
			TweenService:GetValue(alphaCamera, CameraInfo.Tween.EasingStyle, CameraInfo.Tween.EasingDirection)
		Camera.FieldOfView = CameraInfo.Initial + (CameraInfo.Target - CameraInfo.Initial) * easedAlphaCamera
	end

	if BlurInfo.Tween.Time > 0 then
		local alphaCamera = BlurInfo.TimeElapsed / BlurInfo.Tween.Time
		local easedAlphaCamera =
			TweenService:GetValue(alphaCamera, BlurInfo.Tween.EasingStyle, BlurInfo.Tween.EasingDirection)
		Blur.Size = BlurInfo.Initial + (BlurInfo.Target - BlurInfo.Initial) * easedAlphaCamera
	end

	if SaturationInfo.Tween.Time > 0 then
		local alphaCamera = SaturationInfo.TimeElapsed / SaturationInfo.Tween.Time
		local easedAlphaCamera =
			TweenService:GetValue(alphaCamera, SaturationInfo.Tween.EasingStyle, SaturationInfo.Tween.EasingDirection)
		ColorCorrection.Saturation = SaturationInfo.Initial
			+ (SaturationInfo.Target - SaturationInfo.Initial) * easedAlphaCamera
	end

	if SpeedInfo.Tween.Time > 0 and Humanoid then
		local alphaCamera = SpeedInfo.TimeElapsed / SpeedInfo.Tween.Time
		local easedAlphaCamera =
			TweenService:GetValue(alphaCamera, SpeedInfo.Tween.EasingStyle, SpeedInfo.Tween.EasingDirection)
		Humanoid.WalkSpeed = SpeedInfo.Initial + (SpeedInfo.Target - SpeedInfo.Initial) * easedAlphaCamera
	end

	if JumpInfo.Tween.Time > 0 and Humanoid then
		local alphaCamera = JumpInfo.TimeElapsed / JumpInfo.Tween.Time
		local easedAlphaCamera =
			TweenService:GetValue(alphaCamera, JumpInfo.Tween.EasingStyle, JumpInfo.Tween.EasingDirection)
		Humanoid.JumpHeight = JumpInfo.Initial + (JumpInfo.Target - JumpInfo.Initial) * easedAlphaCamera
	end

	if
		UpdateConnection
		and CameraInfo.TimeElapsed == CameraInfo.Tween.Time
		and BlurInfo.TimeElapsed == BlurInfo.Tween.Time
		and SaturationInfo.TimeElapsed == SaturationInfo.Tween.Time
		and SpeedInfo.TimeElapsed == SpeedInfo.Tween.Time
		and JumpInfo.TimeElapsed == JumpInfo.Tween.Time
	then
		UpdateConnection:Disconnect()
		UpdateConnection = nil
	end
end

function TweensController.Pause()
	if not UpdateConnection then return end
	UpdateConnection:Disconnect()
	UpdateConnection = nil
end

function TweensController.Resume()
	if UpdateConnection then return end
	UpdateConnection = RunService.Heartbeat:Connect(update)
end

return Ignis.Register(TweensController) :: Public
