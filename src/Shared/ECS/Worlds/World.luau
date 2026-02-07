local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local Tags = require(ReplicatedStorage.Shared.ECS.Tags) -- Required for the meta

local World = jecs.world()

-- Auto
-- When the parent is deleted then the entity that is related gets deleted.
-- usage: World.add(child, pair(ChildOf, parent))
-- Now if the parent is deleted with World.delete(parent) then the 'child' will be automatically deleted.
World:add(jecs.ChildOf, jecs.pair(jecs.OnDeleteTarget, jecs.Delete))

-- Auto References
World:removed(Components.Cleanup, function(entity)
	local callback = World:get(entity, Components.Cleanup)
	if callback ~= nil then callback(entity) end
end)

return World
