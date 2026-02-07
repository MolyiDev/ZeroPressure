local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.jecs)
local WorldRef = require(ReplicatedStorage.Shared.ECS.References.WorldRef)

return function(player: Player): jecs.Entity?
	if player.Character == nil then return nil end
	return WorldRef:Search(player.Character)
end
