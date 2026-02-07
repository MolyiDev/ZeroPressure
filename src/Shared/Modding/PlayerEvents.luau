local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local WorldRef = require(ReplicatedStorage.Shared.ECS.References.WorldRef)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local Butler = require(ReplicatedStorage.Packages.Butler)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local jecs = require(ReplicatedStorage.Packages.jecs)

local PlayerEvents = {}

local onPlayerConnected = Ignis.RegisterLifecycle("OnPlayerConnected") :: Ignis.Lifecycle<Player, jecs.Entity>
local onPlayerDisconnected = Ignis.RegisterLifecycle("OnPlayerDisconnected") :: Ignis.Lifecycle<Player, jecs.Entity>

function PlayerEvents.OnStart()
	local function dispatch(player: Player)
		local alreadyCreated = WorldRef:Search(player)
		if alreadyCreated then return end

		local entity = WorldRef:EntityRef(player)

		jecs.bulk_insert(World, entity, { Components.Player, Components.Butler, Components.Cleanup }, {
			player,
			Butler.new(),
			function(playerEntity: jecs.Entity)
				local butler = World:get(playerEntity, Components.Butler) :: Butler.Butler
				if butler then butler:Destroy() end
			end,
		})

		onPlayerConnected:Fire(player, entity)
	end

	Players.PlayerAdded:Connect(function(player)
		dispatch(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		local playerEntity = WorldRef:Search(player)
		if playerEntity then onPlayerDisconnected:Fire(player, playerEntity) end

		task.spawn(WorldRef.Nuke, WorldRef, player, playerEntity)
	end)

	for _, player in Players:GetPlayers() do
		dispatch(player)
	end
end

return Ignis.Register(PlayerEvents)
