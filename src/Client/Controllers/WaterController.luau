local AssetService = game:GetService("AssetService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LeaksController = require(script.Parent.LeaksController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)

local WATER_RISE_SPEED = {
	[1] = 0.001,
	[2] = 0.002,
	[3] = 0.003,
}
local WATER_MOVE_SPEED = 2
local WAVE_AMPLITUDE = 0.0001
local WAVE_FREQUENCY = 1.2
local WAVE_SCALE = 3.5
local MIN_WATER_LEVEL = -3.06
local MAX_WATER_LEVEL = 0.75

local WaterMesh
local WaterMeshPart
local VertexIds = {}
local VertexOrigins = {}
local WaterTime = 0

local UnderwaterCC
local UnderwaterBlur

local WaterController = {}
WaterController.MAX_WATER_LEVEL = MAX_WATER_LEVEL
WaterController.MIN_WATER_LEVEL = MIN_WATER_LEVEL
WaterController.WaterLevel = MIN_WATER_LEVEL
WaterController.IsRiseActive = false
WaterController.RiseSpeed = 0

local function AdjustRiseSpeed(amount)
	WaterController.RiseSpeed += amount

	if math.abs(WaterController.RiseSpeed) < 1e-4 then WaterController.RiseSpeed = 0 end
end

local function SetupLighting()
	if UnderwaterCC then UnderwaterCC:Destroy() end
	if UnderwaterBlur then UnderwaterBlur:Destroy() end

	UnderwaterCC = Instance.new("ColorCorrectionEffect")
	UnderwaterCC.Name = "UnderwaterCC"
	UnderwaterCC.TintColor = Color3.fromRGB(50, 150, 255)
	UnderwaterCC.Brightness = -0.1
	UnderwaterCC.Parent = Lighting
	UnderwaterCC.Enabled = false

	UnderwaterBlur = Instance.new("BlurEffect")
	UnderwaterBlur.Name = "UnderwaterBlur"
	UnderwaterBlur.Size = 6
	UnderwaterBlur.Parent = Lighting
	UnderwaterBlur.Enabled = false
end

local function CreateWaterMesh()
	local success, result = pcall(function()
		return AssetService:CreateEditableMesh()
	end)

	if not success then
		warn("Failed to create EditableMesh:", result)
		return
	end

	WaterMesh = result
	local gridSize = 20

	local tempVertexLookup = {}

	for x = -gridSize, gridSize do
		for z = -gridSize, gridSize do
			local pos = Vector3.new(x, 0, z)

			local vid = WaterMesh:AddVertex(pos)
			local u = (x + gridSize) / (gridSize * 2)
			local v = (z + gridSize) / (gridSize * 2)
			local uvid = WaterMesh:AddUV(Vector2.new(u, v))

			tempVertexLookup[pos] = { vid = vid, uvid = uvid }

			table.insert(VertexIds, vid)
			table.insert(VertexOrigins, pos)
		end
	end

	for x = -gridSize, gridSize - 1 do
		for z = -gridSize, gridSize - 1 do
			local pos = Vector3.new(x, 0, z)

			local curr = tempVertexLookup[pos]
			local right = tempVertexLookup[pos + Vector3.new(1, 0, 0)]
			local front = tempVertexLookup[pos + Vector3.new(0, 0, 1)]
			local diag = tempVertexLookup[pos + Vector3.new(1, 0, 1)]

			if curr and right and front and diag then
				WaterMesh:AddTriangle(curr.vid, front.vid, diag.vid, curr.uvid, front.uvid, diag.uvid)
				WaterMesh:AddTriangle(curr.vid, diag.vid, right.vid, curr.uvid, diag.uvid, right.uvid)
			end
		end
	end

	table.clear(tempVertexLookup)

	local meshSuccess, meshPart = pcall(function()
		return AssetService:CreateMeshPartAsync(Content.fromObject(WaterMesh))
	end)

	if not meshSuccess then return end

	WaterMeshPart = meshPart
	WaterMeshPart.Name = "Water"
	WaterMeshPart.Anchored = true
	WaterMeshPart.CanCollide = false
	WaterMeshPart.CastShadow = false
	WaterMeshPart.Material = Enum.Material.Glass
	WaterMeshPart.Transparency = 0.4
	WaterMeshPart.Color = Color3.fromRGB(46, 119, 153)
	WaterMeshPart.Size = Vector3.new(15, 1, 38)
	WaterMeshPart.CFrame = CFrame.new(0, MIN_WATER_LEVEL, -8)

	WaterMeshPart.Parent = Workspace
end

local function UpdateWaterMesh(dt: number)
	if not WaterMesh or not WaterMeshPart then return end

	WaterTime += dt

	if WaterController.IsRiseActive and WaterController.RiseSpeed > 0 then
		WaterController.WaterLevel += WaterController.RiseSpeed * dt
	end

	WaterController.WaterLevel = math.clamp(WaterController.WaterLevel, MIN_WATER_LEVEL, MAX_WATER_LEVEL)

	WaterMeshPart.CFrame =
		WaterMeshPart.CFrame:Lerp(CFrame.new(0, WaterController.WaterLevel, -8), WATER_MOVE_SPEED * dt)

	for i = 1, #VertexIds do
		local vertexId = VertexIds[i]
		local basePos = VertexOrigins[i]

		local xOffset = basePos.X / WAVE_SCALE
		local zOffset = basePos.Z / WAVE_SCALE

		local wave1 = math.sin(WaterTime * WAVE_FREQUENCY + xOffset + zOffset) * WAVE_AMPLITUDE
		local wave2 = math.sin(WaterTime * WAVE_FREQUENCY * 0.7 - xOffset * 1.3) * WAVE_AMPLITUDE * 0.6
		local wave3 = math.cos(WaterTime * WAVE_FREQUENCY * 1.3 + zOffset * 0.8) * WAVE_AMPLITUDE * 0.4

		local waveHeight = wave1 + wave2 + wave3
		WaterMesh:SetPosition(vertexId, Vector3.new(basePos.X, waveHeight, basePos.Z))
	end

	local camera = Workspace.CurrentCamera
	if not camera then return end

	local isUnderwater = camera.CFrame.Position.Y < (WaterController.WaterLevel - 0.15)

	if UnderwaterCC then UnderwaterCC.Enabled = isUnderwater end
	if UnderwaterBlur then UnderwaterBlur.Enabled = isUnderwater end

	if isUnderwater then
		Lighting.FogColor = Color3.fromRGB(20, 60, 90)
		Lighting.FogEnd = 50
	else
		Lighting.FogEnd = 10000
	end
end

function WaterController.StartRise()
	if WaterController.IsRiseActive then return end
	WaterController.IsRiseActive = true
end

function WaterController.StopRise()
	if not WaterController.IsRiseActive then return end
	WaterController.IsRiseActive = false
end

function WaterController.Reset()
	WaterController.RiseSpeed = 0
	WaterController.WaterLevel = MIN_WATER_LEVEL

	WaterController.StopRise()
end

function WaterController.SetRiseSpeed(speed: number)
	WaterController.RiseSpeed = speed
end

function WaterController.SetLevel(level)
	WaterController.WaterLevel = level
end

function WaterController.OnStart()
	SetupLighting()
	CreateWaterMesh()
	RunService.Heartbeat:Connect(UpdateWaterMesh)
end

LeaksController.OnLeakCreated:Connect(function(level: number)
	local speed = WATER_RISE_SPEED[level] or 0
	AdjustRiseSpeed(speed)
end)

LeaksController.OnLeakDegraded:Connect(function(oldLevel, newLevel)
	local oldSpeed = WATER_RISE_SPEED[oldLevel] or 0
	local newSpeed = WATER_RISE_SPEED[newLevel] or 0

	AdjustRiseSpeed(newSpeed - oldSpeed)
end)

LeaksController.OnLeakFixed:Connect(function(level: number)
	local speed = WATER_RISE_SPEED[level] or 0
	AdjustRiseSpeed(-speed)
end)

return Ignis.Register(WaterController)
