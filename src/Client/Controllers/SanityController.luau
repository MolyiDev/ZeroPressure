local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignis = require(ReplicatedStorage.Packages.Ignis)

local SanityController = {}
SanityController.Sanity = 100

function SanityController.SpawnScreamer()
	--
end

return Ignis.Register(SanityController)
