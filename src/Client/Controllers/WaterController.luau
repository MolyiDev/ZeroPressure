local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Ignis = require(ReplicatedStorage.Packages.Ignis)

type WaterLeak = { ParticleEmitter } & Attachment

local TW_FIX = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local CHANCE_TO_BREAK_DEFAULT = 0.1
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

local WaterController = {}
WaterController.ChanceToBreak = CHANCE_TO_BREAK_DEFAULT

function WaterController.Fix(leak: WaterLeak)
	if not CurrentLeaks[leak] then return end
	CurrentLeaks[leak] = nil
	LeakProgress[leak] = nil

	for _, emitter in leak:GetDescendants() do
		if emitter:IsA("ParticleEmitter") then
			TweenService:Create(emitter, TW_FIX, {
				Rate = 0,
			}):Play()
		elseif emitter:IsA("Beam") then
			TweenService:Create(emitter, TW_FIX, {
				Width0 = 0,
				Width1 = 0,
			}):Play()
		end
	end

	local currentLevel = LevelByName[leak.Name] or 1

	if currentLevel > 1 then
		local newLevel = currentLevel - 1
		local downGradedLeak = LeaksPerLevel[newLevel]:Clone()
		downGradedLeak.Parent = leak.Parent
		CurrentLeaks[downGradedLeak] = true
	else
		PossibleWaterLeaks[#PossibleWaterLeaks + 1] = leak.Parent :: any
	end

	task.delay(TW_FIX.Time, function()
		leak:Destroy()
	end)
end

function WaterController.Break(attachment: Attachment, level: number)
	local waterLeak = LeaksPerLevel[level]
	if not waterLeak then return end

	local index = table.find(PossibleWaterLeaks, attachment)
	if index then table.remove(PossibleWaterLeaks, index) end

	local newLeak = waterLeak:Clone()
	newLeak.Parent = attachment
	CurrentLeaks[newLeak] = true
end

function WaterController.BreakRandom()
	if #PossibleWaterLeaks == 0 then return end

	local index = math.random(1, #PossibleWaterLeaks)
	local randomAttachment = PossibleWaterLeaks[index]

	WaterController.Break(randomAttachment, 3)
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

	for leak, _ in CurrentLeaks do
		local isBeingFixed = false

		if hitPosition then
			local dist = (hitPosition - leak.WorldPosition).Magnitude
			if dist <= LEAK_HIT_RADIUS then isBeingFixed = true end
		end

		if isBeingFixed then
			local progress = (LeakProgress[leak] or 0) + dt
			LeakProgress[leak] = progress

			if progress >= FIX_TIME then WaterController.Fix(leak) end
		else
			LeakProgress[leak] = 0
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end

	BlowtorchStart:Play()
	BlowtorchLoop:Play()
	if not FixConnection then FixConnection = RunService.Heartbeat:Connect(UpdateFixing) end
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end

	BlowtorchLoop:Stop()

	table.clear(LeakProgress)

	if FixConnection then
		FixConnection:Disconnect()
		FixConnection = nil
	end
end)

WaterController.BreakRandom()
WaterController.BreakRandom()
WaterController.BreakRandom()
WaterController.BreakRandom()

return Ignis.Register(WaterController)
