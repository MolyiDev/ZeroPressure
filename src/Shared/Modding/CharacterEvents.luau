local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local WorldRef = require(ReplicatedStorage.Shared.ECS.References.WorldRef)
local Tags = require(ReplicatedStorage.Shared.ECS.Tags)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local getCharacterEntityFromPlayer = require(ReplicatedStorage.Shared.Utils.Functions.getCharacterEntityFromPlayer)
local Butler = require(ReplicatedStorage.Packages.Butler)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local jecs = require(ReplicatedStorage.Packages.jecs)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

local CharacterEvents = {}

local onCharacterAdded =
	Ignis.RegisterLifecycle("OnCharacterAdded") :: Ignis.Lifecycle<TCharacter.TCharacter, jecs.Entity>
local onCharacterRemoving =
	Ignis.RegisterLifecycle("OnCharacterRemoving") :: Ignis.Lifecycle<TCharacter.TCharacter, jecs.Entity>

local function CharacterAdded(playerEntity: jecs.Entity, character: TCharacter.TCharacter)
	local characterEntity = WorldRef:EntityRef(character)
	local characterButler = Butler.new()

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	if humanoid.Health > 0 then
		World:add(characterEntity, Tags.Alive)
		characterButler:Once(humanoid.Died, function()
			World:remove(characterEntity, Tags.Alive)
		end)
	end

	jecs.bulk_insert(World, characterEntity, {
		Components.Model,
		Components.Butler,
		Components.Humanoid,
		Components.HumanoidRootPart,
		Components.Animator,
		Components.Cleanup,
		jecs.pair(jecs.ChildOf, playerEntity),
		Tags.Character,
	}, {
		character,
		characterButler,
		humanoid,
		character:WaitForChild("HumanoidRootPart"),
		humanoid:WaitForChild("Animator"),
		function()
			characterButler:Destroy()
		end,
	})

	onCharacterAdded:Fire(character, characterEntity)
end

CharacterEvents.OnPlayerConnected = function(player: Player, playerEntity: jecs.Entity)
	local playerButler = World:get(playerEntity, Components.Butler) :: Butler.Butler
	if player.Character then CharacterAdded(playerEntity, player.Character :: TCharacter.TCharacter) end

	playerButler:Connect(player.CharacterAdded, function(character)
		CharacterAdded(playerEntity, (character :: any) :: TCharacter.TCharacter)
	end)

	playerButler:Connect(player.CharacterRemoving, function(character: Model)
		local characterEntity = getCharacterEntityFromPlayer(player)
		if not characterEntity then return end

		onCharacterRemoving:Fire(character :: any, characterEntity)

		WorldRef:Nuke(character, characterEntity)
	end)
end

return Ignis.Register(CharacterEvents)
