local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LightController = require(script.Parent.LightController)
local ValveController = require(script.Parent.ValveController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Highlight = require(ReplicatedStorage.Shared.Utils.Highlight)

local MAX_DISTANCE = 10

local Camera = Workspace.CurrentCamera
local InteractablesList = CollectionService:GetTagged("Interactable")
local Interactables: { [BasePart]: boolean } = {}
local CurrentPart: BasePart?
local Hold = false
local RayParams = RaycastParams.new()
RayParams.FilterDescendantsInstances = { InteractablesList }
RayParams.FilterType = Enum.RaycastFilterType.Include
RayParams.IgnoreWater = true

for _, interactable in InteractablesList do
	if not interactable:IsA("BasePart") then continue end
	Interactables[interactable] = true
end

local InteractController = {}

local function getObject(hit: BasePart): BasePart?
	if not hit:IsA("BasePart") then return end
	local model = hit.Parent
	if not model or not model:IsA("Model") then return end
	return model.PrimaryPart
end

RunService.Heartbeat:Connect(function()
	local origin = Camera.CFrame.Position
	local direction = Camera.CFrame.LookVector * MAX_DISTANCE

	local result = workspace:Raycast(origin, direction, RayParams)
	local hit = result and result.Instance

	if hit == CurrentPart then return end

	if Hold then return end

	if CurrentPart then
		local object = getObject(CurrentPart)
		if not object then return end

		Highlight.Remove(object)
		CurrentPart = nil
	end

	if hit then
		local object = getObject(hit)
		if not object then return end

		Highlight.Add(object)
		CurrentPart = hit
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if not CurrentPart then return end
	local object = getObject(CurrentPart)
	if not object then return end

	if object:HasTag("Valve") then
		Hold = true
		ValveController.ValveTouched(object)
	elseif object:HasTag("Lightbulbs") then
		LightController.Grab()
	elseif object:HasTag("Light") then
		LightController.Replace(object :: any)
	end
end)

UserInputService.InputEnded:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if not CurrentPart then return end
	local object = getObject(CurrentPart)
	if not object then return end

	if object:HasTag("Valve") then ValveController.ValveStop() end
	Hold = false
end)

return Ignis.Register(InteractController)
