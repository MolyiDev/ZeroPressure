local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local SoundsController = require(script.Parent.SoundsController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

type WaterLeak = { ParticleEmitter } & Attachment

local TW_FIX = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local CHANCE_TO_BREAK_DEFAULT = 0.03
local CHANCE_BREAK_AMOUNT = 2
local FIX_TIME = 0.6
local MAX_FIX_DISTANCE = 10
local LEAK_HIT_RADIUS = 2
local CHECK_INTERVAL = 1 / 60

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local EffectsFolder = ReplicatedStorage:FindFirstChild("Effects")
local Colliders = Workspace:FindFirstChild("Submarine"):FindFirstChild("Colliders") :: Model
local PossibleWaterLeaks = CollectionService:GetTagged("WaterLeak") :: { Attachment }
local WaterLeaksEffects = EffectsFolder:FindFirstChild("WaterLeaks") :: Folder
local WaterLeakLevel1 = WaterLeaksEffects:FindFirstChild("Level1") :: WaterLeak
local WaterLeakLevel2 = WaterLeaksEffects:FindFirstChild("Level2") :: WaterLeak
local WaterLeakLevel3 = WaterLeaksEffects:FindFirstChild("Level3") :: WaterLeak

local LeaksPerLevel = {
	[1] = WaterLeakLevel1,
	[2] = WaterLeakLevel2,
	[3] = WaterLeakLevel3,
}

local LevelByName = {
	["Level1"] = 1,
	["Level2"] = 2,
	["Level3"] = 3,
}

local CurrentLeaks: { [WaterLeak]: boolean } = {}
local LeakProgress: { [WaterLeak]: number } = {}
local FixConnection: RBXScriptConnection?

local BlowtorchAnimations = ReplicatedStorage:FindFirstChild("Animations"):FindFirstChild("Blowtorch")
local BlowtorchIdleAnim = BlowtorchAnimations:FindFirstChild("Idle")
local BlowtorchUseAnim = BlowtorchAnimations:FindFirstChild("Use")

local BlowtorchIdle: AnimationTrack
local BlowtorchUse: AnimationTrack

local BlowtorchEffects: Attachment

local LeaksController = {}
LeaksController.OnLeakFixed = Signal.new() :: Signal.Signal<number>
LeaksController.OnLeakDegraded = Signal.new() :: Signal.Signal<number, number>
LeaksController.OnLeakCreated = Signal.new() :: Signal.Signal<number>
LeaksController.CanUseBlowtorch = false
LeaksController.IsRandomizerActive = false
LeaksController.ChanceToBreak = CHANCE_TO_BREAK_DEFAULT
LeaksController.ChanceBreakAmount = CHANCE_BREAK_AMOUNT
LeaksController.CHANCE_TO_BREAK_DEFAULT = CHANCE_TO_BREAK_DEFAULT
LeaksController.CHANCE_TO_BREAK_THIRD_HALF = CHANCE_TO_BREAK_DEFAULT * 1.5
LeaksController.CHANCE_TO_BREAK_FOURTH = CHANCE_TO_BREAK_DEFAULT * 2
LeaksController.CHANCE_TO_BREAK_FOURTH_HALF = CHANCE_TO_BREAK_DEFAULT * 2.5

local RandomizerConnection: RBXScriptConnection?
local Accumulator = 0

local function stopBlowtorch()
	SoundsController.StopLoop(ESounds.BlowtorchLoop, SoundService, true)

	table.clear(LeakProgress)
	if FixConnection then
		FixConnection:Disconnect()
		FixConnection = nil
	end

	if BlowtorchUse and BlowtorchUse.IsPlaying then BlowtorchUse:Stop(0.2) end

	if BlowtorchEffects then
		for _, emitter in BlowtorchEffects:GetDescendants() do
			if emitter:IsA("ParticleEmitter") then emitter.Enabled = false end
		end
	end
end

function LeaksController.StartRandomizer()
	if LeaksController.IsRandomizerActive then return end
	LeaksController.IsRandomizerActive = true

	if RandomizerConnection then
		RandomizerConnection:Disconnect()
		RandomizerConnection = nil
	end

	RandomizerConnection = RunService.Heartbeat:Connect(function(dt: number)
		Accumulator += dt

		while Accumulator >= CHECK_INTERVAL do
			Accumulator -= CHECK_INTERVAL
			for _ = 0, LeaksController.ChanceBreakAmount do
				if math.random() < (LeaksController.ChanceToBreak * CHECK_INTERVAL) then
					LeaksController.BreakRandom()
				end
			end
		end
	end)
end

function LeaksController.StopRandomizer()
	if not LeaksController.IsRandomizerActive then return end
	LeaksController.IsRandomizerActive = false

	if RandomizerConnection then
		RandomizerConnection:Disconnect()
		RandomizerConnection = nil
	end
end

function LeaksController.Fix(leak: WaterLeak)
	if not CurrentLeaks[leak] then return end
	CurrentLeaks[leak] = nil
	LeakProgress[leak] = nil

	for _, emitter in leak:GetDescendants() do
		if emitter:IsA("ParticleEmitter") then
			TweenService:Create(emitter, TW_FIX, { Rate = 0 }):Play()
		elseif emitter:IsA("Beam") then
			TweenService:Create(emitter, TW_FIX, { Width0 = 0, Width1 = 0 }):Play()
		end
	end

	local currentLevel = LevelByName[leak.Name] or 1

	if currentLevel > 1 then
		local newLevel = currentLevel - 1
		local downGradedLeak = LeaksPerLevel[newLevel]:Clone()
		downGradedLeak.Parent = leak.Parent
		CurrentLeaks[downGradedLeak] = true
		LeaksController.OnLeakDegraded:Fire(currentLevel, newLevel)
	else
		PossibleWaterLeaks[#PossibleWaterLeaks + 1] = leak.Parent :: any
		LeaksController.OnLeakFixed:Fire(currentLevel)
	end

	task.delay(TW_FIX.Time * 2, function()
		leak:Destroy()
	end)
end

function LeaksController.Break(attachment: Attachment, level: number)
	local waterLeak = LeaksPerLevel[level]
	if not waterLeak then return end

	local index = table.find(PossibleWaterLeaks, attachment)
	if index then table.remove(PossibleWaterLeaks, index) end

	local newLeak = waterLeak:Clone()
	newLeak.Parent = attachment
	CurrentLeaks[newLeak] = true

	SoundsController.Play(ESounds.MetalHit1, newLeak)
	SoundsController.Play(ESounds.MetalHit2, newLeak)

	LeaksController.OnLeakCreated:Fire(level)
end

function LeaksController.BreakRandom()
	if #PossibleWaterLeaks == 0 then return end
	local index = math.random(1, #PossibleWaterLeaks)
	LeaksController.Break(PossibleWaterLeaks[index], math.random(1, 3))
end

local function UpdateFixing(dt: number)
	local character = Player.Character
	if not character then return end

	local origin = Camera.CFrame.Position
	local direction = Camera.CFrame.LookVector * MAX_FIX_DISTANCE
	local params = RaycastParams.new()

	params.FilterDescendantsInstances = { character, WaterLeaksEffects, Colliders }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(origin, direction, params)
	local hitPosition = result and result.Position

	local leaksToFix = {}

	for leak, _ in CurrentLeaks do
		local isBeingFixed = false
		if hitPosition then
			local dist = (hitPosition - leak.WorldPosition).Magnitude
			if dist <= LEAK_HIT_RADIUS then isBeingFixed = true end
		end

		if isBeingFixed then
			local progress = (LeakProgress[leak] or 0) + dt
			LeakProgress[leak] = progress
			if progress >= FIX_TIME then table.insert(leaksToFix, leak) end
		else
			LeakProgress[leak] = 0
		end
	end

	for _, leak in leaksToFix do
		LeaksController.Fix(leak)
	end
end

function LeaksController.EnableBlowtorch()
	if LeaksController.CanUseBlowtorch then return end
	LeaksController.CanUseBlowtorch = true
	SoundsController.PlayCharacter(ESounds.Equip)

	if BlowtorchIdle then BlowtorchIdle:Play(0.2, 1, 0.3) end
end

function LeaksController.DisableBlowtorch()
	if not LeaksController.CanUseBlowtorch then return end
	LeaksController.CanUseBlowtorch = false
	stopBlowtorch()

	if BlowtorchIdle then BlowtorchIdle:Stop(0.2) end
end

function LeaksController.Reset()
	LeaksController.StopRandomizer()

	LeaksController.ChanceToBreak = CHANCE_TO_BREAK_DEFAULT
	for leak, _ in CurrentLeaks do
		if leak.Parent then PossibleWaterLeaks[#PossibleWaterLeaks + 1] = leak.Parent :: WaterLeak end
		leak:Destroy()
	end

	LeaksController.DisableBlowtorch()
	table.clear(CurrentLeaks)
end

LeaksController.OnCharacterAdded = function(character: TCharacter.TCharacter, characterEntity: jecs.Entity)
	local animator = World:get(characterEntity, Components.Animator)

	if not animator then
		warn("Humanoid / HumanoidRootPart / Butler are nil")
		return
	end

	BlowtorchIdle = animator:LoadAnimation(BlowtorchIdleAnim)
	BlowtorchUse = animator:LoadAnimation(BlowtorchUseAnim)

	BlowtorchEffects = character
		:WaitForChild("Blowtorch")
		:WaitForChild("Pipe")
		:WaitForChild("Effects")
		:WaitForChild("Effects") :: Attachment

	if BlowtorchEffects then
		for _, emitter in BlowtorchEffects:GetDescendants() do
			if emitter:IsA("ParticleEmitter") then emitter.Enabled = false end
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
	if not LeaksController.CanUseBlowtorch then return end

	SoundsController.PlayCharacter(ESounds.BlowtorchStart)
	SoundsController.PlayLoop(ESounds.BlowtorchLoop, SoundService, true)
	if BlowtorchUse then BlowtorchUse:Play(0.2, 1, 1) end

	if BlowtorchEffects then
		for _, emitter in BlowtorchEffects:GetDescendants() do
			if emitter:IsA("ParticleEmitter") then emitter.Enabled = true end
		end
	end

	if not FixConnection then FixConnection = RunService.Heartbeat:Connect(UpdateFixing) end
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
	stopBlowtorch()
end)

return Ignis.Register(LeaksController)
