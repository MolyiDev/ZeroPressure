local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Ignis = require(ReplicatedStorage.Packages.Ignis)

local TW_INFO = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui") :: PlayerGui
local CreditsUI = PlayerGui:WaitForChild("CreditsUI") :: ScreenGui
local CreditsGroup = CreditsUI:WaitForChild("CreditsGroup") :: CanvasGroup

local CreditsController = {}

function CreditsController.Appear()
	TweenService:Create(CreditsGroup, TW_INFO, {
		GroupTransparency = 0,
	}):Play()
end

function CreditsController.Disappear()
	TweenService:Create(CreditsGroup, TW_INFO, {
		GroupTransparency = 1,
	}):Play()
end

return Ignis.Register(CreditsController)
