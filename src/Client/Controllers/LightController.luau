local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

type Light = {
	Break: Sound,
	PointLight: PointLight,
} & BasePart

local TW_ON = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TW_OFF = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local BRIGTHNESS = 1.8
local CHANCE_TO_BREAK_DEFAULT = 0.1

local Lights = CollectionService:GetTagged("Light") :: { Light }
local LightbulbCages = CollectionService:GetTagged("Lightbulbs")[1]
local HasLightbulb = false
local LightsBroken: { [Light]: boolean } = {}
local Connection: RBXScriptConnection?

local LightController = {}
LightController.ChanceToBreak = CHANCE_TO_BREAK_DEFAULT

function LightController.Start()
	if Connection then return end

	Connection = RunService.Heartbeat:Connect(function(dt: number)
		for _, light in Lights do
			if LightsBroken[light] then continue end
			if math.random() < (LightController.ChanceToBreak * dt) then LightController.Explode(light) end
		end
	end)
end

function LightController.Stop()
	if Connection then
		Connection:Disconnect()
		Connection = nil
	end
end

function LightController.Reset()
	table.clear(LightsBroken)

	for _, light in Lights do
		if not light:IsA("BasePart") then continue end
		light.PointLight.Brightness = BRIGTHNESS
	end

	LightController.ChanceToBreak = CHANCE_TO_BREAK_DEFAULT
end

function LightController.Explode(light: Light)
	if LightsBroken[light] then return end
	LightsBroken[light] = true

	light.Break:Play()
	TweenService:Create(light.PointLight, TW_OFF, {
		Brightness = 0,
	}):Play()
end

function LightController.Grab()
	if HasLightbulb then return end
	HasLightbulb = true
end

function LightController.Replace(light: Light)
	if not LightsBroken[light] then return end
	if not HasLightbulb then return end
	HasLightbulb = false
	LightsBroken[light] = nil

	TweenService:Create(light.PointLight, TW_ON, {
		Brightness = BRIGTHNESS,
	}):Play()
end

LightController.Start()

return LightController
