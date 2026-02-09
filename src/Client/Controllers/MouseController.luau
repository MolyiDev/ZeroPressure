local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")
local CursorUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CursorUI)
local Fluid = require(ReplicatedStorage.Packages.Fluid)
local Ignis = require(ReplicatedStorage.Packages.Ignis)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local MouseController = {}
MouseController.IsMouseActive = true
local UI: CursorUI.CursorUIReturn

Fluid.mount(function()
	UI = CursorUI()
	return UI.UI
end, PlayerGui)

function MouseController.HideMouse()
	UserInputService.MouseIconEnabled = false
end

function MouseController.ShowMouse()
	UserInputService.MouseIconEnabled = true
end

function MouseController.ShowCursor()
	UI.Appear()
end

function MouseController.HideCursor()
	UI.Disappear()
end

return Ignis.Register(MouseController)
