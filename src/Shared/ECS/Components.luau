local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Butler = require(ReplicatedStorage.Packages.Butler)
local jecs = require(ReplicatedStorage.Packages.jecs)

local Components = {
	-- Player
	Player = jecs.component() :: jecs.Id<Player>,
	Model = jecs.component() :: jecs.Id<Model>,
	Animator = jecs.component() :: jecs.Id<Animator>,
	Humanoid = jecs.component() :: jecs.Id<Humanoid>,
	HumanoidRootPart = jecs.component() :: jecs.Id<BasePart>,

	-- Cleanup
	Cleanup = jecs.component() :: jecs.Id<(entity: jecs.Entity) -> ()>,
	Butler = jecs.component() :: jecs.Id<Butler.Butler>,
}

-- Names
for key, component in Components :: { [string]: jecs.Entity } do
	jecs.meta(component, jecs.Name, key)
end

return table.freeze(Components)
