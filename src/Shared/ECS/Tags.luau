local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.jecs)

local Tags = {
	-- Character
	Alive = jecs.tag(), -- If the player is alive, use with(alive)
	Character = jecs.tag(),
}

-- Names
for key, component in Tags :: { [string]: jecs.Entity } do
	jecs.meta(component, jecs.Name, key)
end

return Tags
