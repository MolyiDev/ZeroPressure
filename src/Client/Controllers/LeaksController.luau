local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)

type WaterLeak = { ParticleEmitter } & Attachment

local TW_FIX = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local CHANCE_TO_BREAK_DEFAULT = 0.1
local CHANCE_BREAK_AMOUNT = 2
local FIX_TIME = 0.75
local MAX_FIX_DISTANCE = 10
local LEAK_HIT_RADIUS = 2

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local PossibleWaterLeaks = CollectionService:GetTagged("WaterLeak") :: { Attachment }
local WaterLeaksEffects = ReplicatedStorage:WaitForChild("Effects"):WaitForChild("WaterLeaks") :: Folder
local WaterLeakLevel1 = WaterLeaksEffects:WaitForChild("Level1") :: WaterLeak
local WaterLeakLevel2 = WaterLeaksEffects:WaitForChild("Level2") :: WaterLeak
local WaterLeakLevel3 = WaterLeaksEffects:WaitForChild("Level3") :: WaterLeak

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

local BlowtorchStart = SoundService:WaitForChild("BlowtorchStart") :: Sound
local BlowtorchLoop = SoundService:WaitForChild("BlowtorchLoop") :: Sound

local LeaksController = {}
LeaksController.OnLeakFixed = Signal.new() :: Signal.Signal<number>
LeaksController.OnLeakDegraded = Signal.new() :: Signal.Signal<number, number>
LeaksController.OnLeakCreated = Signal.new() :: Signal.Signal<number>
LeaksController.CanUseBlowtorch = false
LeaksController.IsRandomizedActive = false
LeaksController.ChanceToBreak = CHANCE_TO_BREAK_DEFAULT
LeaksController.ChanceBreakAmount = CHANCE_BREAK_AMOUNT

local RandomizerConnection: RBXScriptConnection?

local function stopBlowtorch()
	BlowtorchLoop:Stop()
	table.clear(LeakProgress)
	if FixConnection then
		FixConnection:Disconnect()
		FixConnection = nil
	end
end

function LeaksController.StartRandomizer()
	if LeaksController.IsRandomizedActive then return end
	LeaksController.IsRandomizedActive = true

	if RandomizerConnection then
		RandomizerConnection:Disconnect()
		RandomizerConnection = nil
	end

	RandomizerConnection = RunService.Heartbeat:Connect(function(dt: number)
		for i = 0, LeaksController.ChanceBreakAmount do
			if math.random() < (LeaksController.ChanceToBreak * dt) then LeaksController.BreakRandom() end
		end
	end)
end

function LeaksController.StopRandomizer()
	if not LeaksController.IsRandomizedActive then return end
	LeaksController.IsRandomizedActive = false

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
	params.FilterDescendantsInstances = { character, WaterLeaksEffects }
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
	LeaksController.CanUseBlowtorch = true
end

function LeaksController.DisableBlowtorch()
	LeaksController.CanUseBlowtorch = false
	stopBlowtorch()
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

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
	if not LeaksController.CanUseBlowtorch then return end

	BlowtorchStart:Play()
	BlowtorchLoop:Play()
	if not FixConnection then FixConnection = RunService.Heartbeat:Connect(UpdateFixing) end
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
	stopBlowtorch()
end)

return Ignis.Register(LeaksController)
