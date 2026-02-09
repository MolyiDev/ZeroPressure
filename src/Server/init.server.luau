local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignis = require(ReplicatedStorage.Packages.Ignis)

Ignis.LoadDescendants(script.Services)
Ignis.LoadDescendants(script.Modding)
Ignis.LoadDescendants(ReplicatedStorage.Shared.Core)
Ignis.LoadDescendants(ReplicatedStorage.Shared.Modding)

Ignis.Ignite()
