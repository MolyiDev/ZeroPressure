local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Promise = require(ReplicatedStorage.Packages.Promise)

local TW_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local TW_IN = TweenInfo.new(10, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui") :: PlayerGui
local LogoUI = PlayerGui:WaitForChild("LogoUI") :: ScreenGui
local LogoGroup = LogoUI:WaitForChild("LogoGroup") :: CanvasGroup
local Logo = LogoGroup:WaitForChild("Logo") :: ImageLabel
local DeathLabel = Logo:WaitForChild("Death") :: TextLabel

local LogoController = {}

function LogoController.AppearAnimation(death: boolean?)
	Logo.Size = UDim2.fromScale(0.6, 0.6)

	if death then
		DeathLabel.TextTransparency = 0
	else
		DeathLabel.TextTransparency = 1
	end

	return Promise.new(function(resolve)
		local tween = TweenService:Create(LogoGroup, TW_INFO, {
			GroupTransparency = 0,
		})

		local tweenIn = TweenService:Create(Logo, TW_IN, {
			Size = UDim2.fromScale(0.9, 0.9),
		})

		if death then
			--
		end

		Promise.delay(TW_IN.Time / 1.3):andThen(resolve)

		tweenIn:Play()
		tween:Play()
	end)
end

function LogoController.Disappear()
	TweenService:Create(LogoGroup, TW_INFO, {
		GroupTransparency = 1,
	}):Play()
end

return Ignis.Register(LogoController)
