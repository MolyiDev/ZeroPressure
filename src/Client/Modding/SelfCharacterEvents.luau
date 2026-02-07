local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local jecs = require(ReplicatedStorage.Packages.jecs)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local SelfCharacterEvents = {}

local onSelfCharacterAdded =
	Ignis.RegisterLifecycle("OnSelfCharacterAdded") :: Ignis.Lifecycle<TCharacter.TCharacter, jecs.Entity>
local onSelfCharacterRemoving =
	Ignis.RegisterLifecycle("OnSelfCharacterRemoving") :: Ignis.Lifecycle<TCharacter.TCharacter, jecs.Entity>

SelfCharacterEvents.OnCharacterAdded = function(character: TCharacter.TCharacter, characterEntity: jecs.Entity)
	if character ~= Players.LocalPlayer.Character then return end
	onSelfCharacterAdded:Fire(character, characterEntity)
end

SelfCharacterEvents.OnCharacterRemoving = function(character: TCharacter.TCharacter, characterEntity: jecs.Entity)
	if character ~= Players.LocalPlayer.Character then return end
	onSelfCharacterRemoving:Fire(character, characterEntity)
end

return Ignis.Register(SelfCharacterEvents)
