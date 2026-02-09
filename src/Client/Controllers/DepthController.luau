local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EngineController = require(script.Parent.EngineController)
local LightController = require(script.Parent.LightController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Signal = require(ReplicatedStorage.Packages.Signal)
local EScenes = require(ReplicatedStorage.Types.Enums.EScenes)

-- pivot positions
local FIRST_DEPTH = 0
local SECOND_DEPTH = 0.235
local THIRD_DEPTH = 0.5
local FOURTH_DEPTH = 1

local DEPTH_SPEED = 0.0001

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui") :: PlayerGui
local DepthSurfaceGui = PlayerGui:WaitForChild("Depth") :: SurfaceGui
local Pivot = DepthSurfaceGui:WaitForChild("Background"):WaitForChild("Pivot") :: Frame

local DepthController = {}
DepthController.OnDepthChanged = Signal.new() :: Signal.Signal<number, number>
DepthController.FIRST_DEPTH = FIRST_DEPTH
DepthController.SECOND_DEPTH = SECOND_DEPTH
DepthController.THIRD_DEPTH = THIRD_DEPTH
DepthController.FOURTH_DEPTH = FOURTH_DEPTH
DepthController.IsActive = false
DepthController.CurrentDepth = 0

local Connection: RBXScriptConnection?

local function changePivotPos(pos: number)
	Pivot.Position = UDim2.fromScale(0.5, pos)
end

function DepthController.Start()
	if DepthController.IsActive then return end

	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	DepthController.IsActive = true

	Connection = RunService.Heartbeat:Connect(function(dt: number)
		local oldDepth = DepthController.CurrentDepth
		local change = (EngineController.CurrentSpeed or 0) * DEPTH_SPEED * dt
		DepthController.CurrentDepth = math.clamp(DepthController.CurrentDepth + change, FIRST_DEPTH, FOURTH_DEPTH)

		if oldDepth ~= DepthController.CurrentDepth then
			DepthController.OnDepthChanged:Fire(oldDepth, DepthController.CurrentDepth)
		end

		changePivotPos(DepthController.CurrentDepth)
	end)
end

function DepthController.Stop()
	DepthController.IsActive = false

	if Connection then
		Connection:Disconnect()
		Connection = nil
	end
end

function DepthController.Reset(scene: number)
	DepthController.Stop()

	if scene == EScenes.Starting or scene == EScenes.First or scene == EScenes.Second then
		DepthController.CurrentDepth = FIRST_DEPTH
	elseif scene == EScenes.Third then
		DepthController.CurrentDepth = SECOND_DEPTH
	elseif scene == EScenes.Fourth then
		DepthController.CurrentDepth = THIRD_DEPTH
	end

	changePivotPos(DepthController.CurrentDepth)
end

LightController.OnMainLightBroke:Connect(function()
	DepthSurfaceGui.Enabled = false
end)

LightController.OnMainLightFixed:Connect(function()
	DepthSurfaceGui.Enabled = true
end)

return Ignis.Register(DepthController)
