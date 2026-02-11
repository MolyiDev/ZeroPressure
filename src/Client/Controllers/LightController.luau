local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundsController = require(script.Parent.SoundsController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)
local countMap = require(ReplicatedStorage.Shared.Utils.Functions.countMap)
local Highlights = require(ReplicatedStorage.Shared.Utils.Highlights)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)
local TCharacter = require(ReplicatedStorage.Types.TCharacter)

type Light = {
	PointLight: PointLight,
	Bulb: BasePart?,
	BrokenLightBulb: {
		Shatter: ParticleEmitter,
		Sparks: ParticleEmitter,
		Smoke: ParticleEmitter,
	},
} & BasePart

local TW_ON = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TW_OFF = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local CHANCE_TO_BREAK_DEFAULT = 0.03

local SHATTER_EMIT_COUNT = 30
local SPARKS_EMIT_COUNT = 30
local SMOKE_EMIT_COUNT = 3

local CHECK_INTERVAL = 1 / 60

local MainLight = CollectionService:GetTagged("MainLight")[1] :: Light
local EngineLight = CollectionService:GetTagged("EngineLight")[1] :: Light
local Lightbulbs = CollectionService:GetTagged("Lightbulbs")[1] :: BasePart
local Lights = { MainLight, EngineLight }
local LightsBroken: { [Light]: boolean } = {}
local Connection: RBXScriptConnection?

local LightIdleAnim = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("LightIdle")

local LightIdle: AnimationTrack
local LightBulb: BasePart

local LightController = {}
LightController.OnAnyLightFixed = Signal.new()
LightController.OnMainLightFixed = Signal.new()
LightController.OnEngineLightFixed = Signal.new()
LightController.OnMainLightBroke = Signal.new()
LightController.OnEngineLightBroke = Signal.new()
LightController.OnBulbGrabbed = Signal.new()
LightController.IsActive = false
LightController.HasLightbulb = false
LightController.CHANCE_TO_BREAK_DEFAULT = CHANCE_TO_BREAK_DEFAULT
LightController.CHANCE_TO_BREAK_THIRD = CHANCE_TO_BREAK_DEFAULT * 1.5
LightController.CHANCE_TO_BREAK_THIRD_HALF = CHANCE_TO_BREAK_DEFAULT * 2
LightController.CHANCE_TO_BREAK_FOURTH = CHANCE_TO_BREAK_DEFAULT * 2.5
LightController.CHANCE_TO_BREAK_FOURTH_HALF = CHANCE_TO_BREAK_DEFAULT * 3
LightController.ChanceToBreak = CHANCE_TO_BREAK_DEFAULT
LightController.LightbulbCage = CollectionService:GetTagged("Lightbulbs")[1]

local Accumulator = 0

function LightController.Start()
	if LightController.IsActive then return end

	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	Connection = RunService.Heartbeat:Connect(function(dt: number)
		Accumulator += dt

		while Accumulator >= CHECK_INTERVAL do
			Accumulator -= CHECK_INTERVAL

			for _, light in Lights do
				if LightsBroken[light] then continue end

				if math.random() < (LightController.ChanceToBreak * CHECK_INTERVAL) then
					LightController.Break(light)
				end
			end
		end
	end)
end

function LightController.Stop()
	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	LightController.IsActive = false
end

function LightController.Break(light: Light): Light?
	if LightsBroken[light] then return end
	LightsBroken[light] = true

	SoundsController.Play(ESounds.BreakBulb, light)
	SoundsController.Play(ESounds.ElectricShok, light)

	TweenService:Create(light.PointLight, TW_OFF, {
		Brightness = 0,
	}):Play()

	if light == MainLight :: any then
		local bulb = light:FindFirstChild("Bulb") :: BasePart
		if bulb then bulb.Transparency = 1 end
		LightController.OnMainLightBroke:Fire()
	elseif light == EngineLight :: any then
		light.Transparency = 1
		LightController.OnEngineLightBroke:Fire()
	end

	light.BrokenLightBulb.Shatter:Emit(SHATTER_EMIT_COUNT)
	light.BrokenLightBulb.Sparks:Emit(SPARKS_EMIT_COUNT)
	light.BrokenLightBulb.Smoke:Emit(SMOKE_EMIT_COUNT)

	Highlights.AddLoop(light)
	Highlights.AddLoop(Lightbulbs)

	return light
end

function LightController.BreakEngineLight()
	return LightController.Break(EngineLight)
end

function LightController.BreakMainLight()
	return LightController.Break(MainLight)
end

function LightController.BreakRandom(): Light?
	local available = {}
	for _, light in ipairs(Lights) do
		if not LightsBroken[light] then table.insert(available, light) end
	end

	if #available > 0 then return LightController.Break(available[math.random(1, #available)]) end
	return nil
end

function LightController.GrabBulb()
	if LightController.HasLightbulb then return end
	LightController.HasLightbulb = true
	SoundsController.PlayCharacter(ESounds.Equip)
	LightController.OnBulbGrabbed:Fire()

	if LightIdle then LightIdle:Play(0.2, 1, 0.3) end
	if LightBulb then LightBulb.Transparency = 0 end
end

function LightController.RemoveBulb()
	if not LightController.HasLightbulb then return end
	LightController.HasLightbulb = false

	if LightIdle then LightIdle:Stop(0.2) end
	if LightBulb then LightBulb.Transparency = 1 end
end

function LightController.Fix(light: Light)
	if not LightsBroken[light] then return end
	if not LightController.HasLightbulb then return end

	LightController.RemoveBulb()
	LightsBroken[light] = nil

	SoundsController.Play(ESounds.PlaceBulb, light)
	local brightness = (light:GetAttribute("Brightness") :: number) or 1

	TweenService:Create(light.PointLight, TW_ON, {
		Brightness = brightness,
	}):Play()

	if light == MainLight :: any then
		local bulb = light:FindFirstChild("Bulb") :: BasePart
		if bulb then bulb.Transparency = 0 end
		LightController.OnMainLightFixed:Fire()
	elseif light == EngineLight :: any then
		light.Transparency = 0
		LightController.OnEngineLightFixed:Fire()
	end

	Highlights.RemoveLoop(light)
	if countMap(LightsBroken) == 0 then Highlights.RemoveLoop(Lightbulbs) end

	light.BrokenLightBulb.Sparks:Emit(SPARKS_EMIT_COUNT)
	light.BrokenLightBulb.Smoke:Emit(SMOKE_EMIT_COUNT)

	LightController.OnAnyLightFixed:Fire()
end

function LightController.Reset()
	for _, light in ipairs(Lights) do
		if not light:IsA("BasePart") then continue end

		local brightness = (light:GetAttribute("Brightness") :: number) or 1
		light.PointLight.Brightness = brightness

		if light == MainLight :: any then
			local bulb = light:FindFirstChild("Bulb") :: BasePart
			if bulb then bulb.Transparency = 0 end
		elseif light == EngineLight :: any then
			light.Transparency = 0
		end
	end

	table.clear(LightsBroken)
	LightController.ChanceToBreak = CHANCE_TO_BREAK_DEFAULT
	LightController.RemoveBulb()
	LightController.Stop()
end

LightController.OnCharacterAdded = function(character: TCharacter.TCharacter, characterEntity: jecs.Entity)
	local animator = World:get(characterEntity, Components.Animator)

	if not animator then
		warn("Humanoid / HumanoidRootPart / Butler are nil")
		return
	end

	LightIdle = animator:LoadAnimation(LightIdleAnim)
	LightBulb = character:WaitForChild("Bulb") :: BasePart

	if LightBulb then LightBulb.Transparency = 1 end
end

return Ignis.Register(LightController)
