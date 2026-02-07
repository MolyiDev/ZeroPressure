local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignis = require(ReplicatedStorage.Packages.Ignis)

Ignis.LoadDescendants(script.Services)
Ignis.LoadDescendants(script.Modding)

Ignis.Ignite()
