local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local CharacterController = {}

local function disableTransparency(part: Instance)
	if not part:IsA("BasePart") then return end

	if part.Name == "Head" then
		part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
			part.LocalTransparencyModifier = 1
		end)
		part.LocalTransparencyModifier = 1
	else
		part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
			part.LocalTransparencyModifier = 0
		end)
		part.LocalTransparencyModifier = 0
	end
end

function CharacterController.OnCharacterAdded(character: TCharacter.TCharacter, characterEntity: jecs.Entity)
	local humanoid = World:get(characterEntity, Components.Humanoid)
	local butler = World:get(characterEntity, Components.Butler)
	if not humanoid or not butler then
		warn("Humanoid / Butler are nil")
		return
	end

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	for _, descendant in character:GetDescendants() do
		disableTransparency(descendant)
	end

	(character.Parent :: Model).DescendantAdded:Connect(function(descendant)
		disableTransparency(descendant)
	end)
end

return Ignis.Register(CharacterController)
