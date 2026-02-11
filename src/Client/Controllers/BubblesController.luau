local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EngineController = require(script.Parent.EngineController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Tools = require(ReplicatedStorage.Shared.Utils.Tools)

local Bubbles: { ParticleEmitter } = {}

local function onBubbleAdded(bubbleArea: BasePart)
	for _, child in bubbleArea:GetDescendants() do
		if child:IsA("ParticleEmitter") then table.insert(Bubbles, child) end
	end
end

for _, area in CollectionService:GetTagged("Bubbles") do
	onBubbleAdded(area)
end

CollectionService:GetInstanceAddedSignal("Bubbles"):Connect(onBubbleAdded)

local ACCELERATION_LEVELS = {
	Default = 0.5,
	Down = 2,
	Medium = 5,
	Up = 8,
}

local RATE_LEVELS = {
	Default = 4,
	Down = 5,
	Medium = 7,
	Up = 9,
}

local BubblesController = {}

EngineController.OnSpeedChanged:Connect(function(_, currentSpeed)
	local startSpeed, endSpeed
	local startAccel, endAccel
	local startRate, endRate

	if currentSpeed <= EngineController.LevelDownSpeed then
		startSpeed, endSpeed = 0, EngineController.LevelDownSpeed
		startAccel, endAccel = ACCELERATION_LEVELS.Default, ACCELERATION_LEVELS.Down
		startRate, endRate = RATE_LEVELS.Default, RATE_LEVELS.Down
	elseif currentSpeed <= EngineController.LevelMiddleSpeed then
		startSpeed, endSpeed = EngineController.LevelDownSpeed, EngineController.LevelMiddleSpeed
		startAccel, endAccel = ACCELERATION_LEVELS.Down, ACCELERATION_LEVELS.Medium
		startRate, endRate = RATE_LEVELS.Down, RATE_LEVELS.Medium
	else
		startSpeed, endSpeed = EngineController.LevelMiddleSpeed, EngineController.LevelUpSpeed
		startAccel, endAccel = ACCELERATION_LEVELS.Medium, ACCELERATION_LEVELS.Up
		startRate, endRate = RATE_LEVELS.Medium, RATE_LEVELS.Up
	end

	local range = endSpeed - startSpeed
	local alpha = if range == 0 then 1 else math.clamp((currentSpeed - startSpeed) / range, 0, 1)

	local finalAccelY = Tools.Lerp(startAccel, endAccel, alpha)
	local finalRate = Tools.Lerp(startRate, endRate, alpha)

	local targetVector = Vector3.new(0, finalAccelY, 0)

	for _, emitter in Bubbles do
		emitter.Acceleration = targetVector

		if emitter.Name == "BubbleDouble" then
			emitter.Rate = finalRate * 2
		else
			emitter.Rate = finalRate
		end
	end
end)

return Ignis.Register(BubblesController)
