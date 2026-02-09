local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)

local BubblesAreas = CollectionService:GetTagged("Bubbles") :: { BasePart }
local Bubbles: { ParticleEmitter } = {}

local FIRST_SCENE_SPEED = NumberRange.new(0.6, 1)
local SECOND_SCENE_SPEED = NumberRange.new(1, 1.2)
local THIRD_SCENE_SPEED = NumberRange.new(1.6, 1.8)
local FOURTH_SCENE_SPEED = NumberRange.new(2, 3)

local BubblesController = {}

return Ignis.Register(BubblesController)
