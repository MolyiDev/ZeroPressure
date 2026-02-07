local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignis = require(ReplicatedStorage.Packages.Ignis)

Ignis.LoadDescendants(script.Modding)
Ignis.LoadDescendants(script.Controllers)
Ignis.LoadDescendants(ReplicatedStorage.Shared.Core)

Ignis.Ignite()
