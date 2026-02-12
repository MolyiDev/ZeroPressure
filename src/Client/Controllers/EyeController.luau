local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Ignis = require(ReplicatedStorage.Packages.Ignis)

local LERP_SPEED_MOVE = 5
local LERP_SPEED_LIDS = 10
local LERP_SPEED_LOOK = 0.1

local VISIBLE_CF = CFrame.new(0, 2, 16) * CFrame.Angles(0, math.pi, 0)
local HIDDEN_CF = CFrame.new(0, -20, 16) * CFrame.Angles(0, math.pi, 0)

local Player = Players.LocalPlayer
local EyeModel = Workspace:FindFirstChild("Eye") :: Model
local Eye = EyeModel:FindFirstChild("Eye") :: BasePart
local EyelidTop = EyeModel:FindFirstChild("EyelidTop") :: MeshPart
local EyelidBottom = EyeModel:FindFirstChild("EyelidBottom") :: MeshPart
local Light = Eye:FindFirstChild("PointLight") :: PointLight

local eyeParts: { BasePart } = {}
for _, descendant in EyeModel:GetDescendants() do
	if descendant:IsA("BasePart") then eyeParts[#eyeParts + 1] = descendant end
end

local EyeController = {}
EyeController.IsVisible = false
EyeController.IsOpen = false

local currentVisibility = 0
local currentOpenness = 0
local currentRotationCF = VISIBLE_CF.Rotation

local topPivotOffset = EyelidTop.PivotOffset
local botPivotOffset = EyelidBottom.PivotOffset

local topEyeToPivot = Eye.CFrame:Inverse() * EyelidTop:GetPivot()
local botEyeToPivot = Eye.CFrame:Inverse() * EyelidBottom:GetPivot()

RunService.Heartbeat:Connect(function(dt: number)
	local targetVis = EyeController.IsVisible and 1 or 0
	local targetOpen = EyeController.IsOpen and 1 or 0

	currentVisibility = currentVisibility + (targetVis - currentVisibility) * math.min(dt * LERP_SPEED_MOVE, 1)
	currentOpenness = currentOpenness + (targetOpen - currentOpenness) * math.min(dt * LERP_SPEED_LIDS, 1)

	-- 1. Calculate Base Position (Lerp between Hidden/Visible)
	local baseCF = HIDDEN_CF:Lerp(VISIBLE_CF, currentVisibility)

	-- 2. Calculate Look Rotation
	local targetRotation = VISIBLE_CF.Rotation -- Default to facing forward (180 deg)

	if EyeController.IsVisible and EyeController.IsOpen then
		local char = Player.Character
		if char then
			local targetPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
			if targetPart then
				-- Calculate lookAt, multiply by 180 (math.pi) because your model faces Backwards
				targetRotation = CFrame.lookAt(baseCF.Position, targetPart.Position).Rotation
					* CFrame.Angles(0, math.pi, 0)
			end
		end
	end

	-- Smoothly interpolate rotation
	currentRotationCF = currentRotationCF:Lerp(targetRotation, LERP_SPEED_LOOK)

	-- 3. Combine Pos + Rot
	local finalEyeCF = CFrame.new(baseCF.Position) * currentRotationCF
	EyeModel:PivotTo(finalEyeCF)

	-- 4. Visuals
	Light.Brightness = 1.2 * currentVisibility
	local currentTrans = 1 - currentVisibility
	for _, part in eyeParts do
		part.Transparency = currentTrans
	end

	-- 5. Calculate Eyelids (Using finalEyeCF so they stick)
	local topAngle = math.rad(45 * currentOpenness)
	local botAngle = math.rad(-45 * currentOpenness)

	local topWorldPivot = finalEyeCF * topEyeToPivot
	local botWorldPivot = finalEyeCF * botEyeToPivot

	local topRotatedPivot = topWorldPivot * CFrame.Angles(0, topAngle, 0)
	local botRotatedPivot = botWorldPivot * CFrame.Angles(0, botAngle, 0)

	-- Added your Vector3 offset fix back in
	EyelidTop.CFrame = (topRotatedPivot - Vector3.new(0, 0, 2)) * topPivotOffset:Inverse()
	EyelidBottom.CFrame = (botRotatedPivot - Vector3.new(0, 0, 2)) * botPivotOffset:Inverse()
end)
function EyeController.Appear()
	EyeController.IsVisible = true
end

function EyeController.Disappear()
	EyeController.IsVisible = false
end

function EyeController.Open()
	EyeController.IsOpen = true
end

function EyeController.Close()
	EyeController.IsOpen = false
end

function EyeController.Reset()
	EyeController.IsOpen = false
	EyeController.IsVisible = false

	EyeModel:PivotTo(HIDDEN_CF)
	Light.Brightness = 0
	for _, part in eyeParts do
		part.Transparency = 1
	end
end

return Ignis.Register(EyeController)
