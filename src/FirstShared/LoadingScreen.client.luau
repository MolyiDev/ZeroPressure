local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

if not game:IsLoaded() then game.Loaded:Wait() end

local Signal = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Signal"))

--== CONSTANTS ==--
local BATCH_SIZE = 50
local MAX_PARALLEL_LOADS = 8
local MAX_FILL_SCALE = 1
local SPINNER_CHARS = { "\\", "|", "/", "-" }

--== STATE ==--
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local OnCompleted = Signal.new()

--== UI SETUP ==--

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LoadingScreen"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
ScreenGui.ScreenInsets = Enum.ScreenInsets.None
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 10

local CanvasGroup = Instance.new("CanvasGroup")
CanvasGroup.Name = "MainCanvas"
CanvasGroup.BackgroundTransparency = 1
CanvasGroup.Size = UDim2.fromScale(1, 1)

local Background = Instance.new("Frame")
Background.Name = "Background"
Background.BackgroundColor3 = Color3.new(1, 1, 1)
Background.BorderSizePixel = 0
Background.Size = UDim2.fromScale(1, 1)
Background.ClipsDescendants = true

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new()),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 9, 9)),
})
UIGradient.Rotation = -90
UIGradient.Parent = Background

local Pattern = Instance.new("ImageLabel")
Pattern.Name = "Pattern"
Pattern.BackgroundTransparency = 1
Pattern.Image = "rbxassetid://101905643336935"
Pattern.ImageTransparency = 0.98
Pattern.ResampleMode = Enum.ResamplerMode.Pixelated
Pattern.ScaleType = Enum.ScaleType.Tile
Pattern.Size = UDim2.fromScale(2, 2)
Pattern.TileSize = UDim2.fromOffset(128, 128)
Pattern.Parent = Background

Background.Parent = CanvasGroup

local Info = Instance.new("Frame")
Info.Name = "Info"
Info.AnchorPoint = Vector2.new(0.5, 0.5)
Info.BackgroundTransparency = 1
Info.Position = UDim2.fromScale(0.5, 0.85)
Info.Size = UDim2.fromScale(0.8, 0.07)

local LoadingLabel = Instance.new("TextLabel")
LoadingLabel.Name = "LoadingLabel"
LoadingLabel.AnchorPoint = Vector2.new(0, 0.5)
LoadingLabel.BackgroundTransparency = 1
LoadingLabel.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
LoadingLabel.Position = UDim2.fromScale(0, 0.5)
LoadingLabel.RichText = true
LoadingLabel.Size = UDim2.fromScale(0.31, 1)
LoadingLabel.Text = "Loading... \\"
LoadingLabel.TextColor3 = Color3.new(1, 1, 1)
LoadingLabel.TextScaled = true
LoadingLabel.Parent = Info

local Bar = Instance.new("Frame")
Bar.Name = "Bar"
Bar.AnchorPoint = Vector2.new(1, 0.5)
Bar.BackgroundTransparency = 1
Bar.Position = UDim2.fromScale(1, 0.5)
Bar.Size = UDim2.fromScale(0.6, 0.8)

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingBottom = UDim.new(0.115, 0)
UIPadding.PaddingTop = UDim.new(0.115, 0)
UIPadding.PaddingLeft = UDim.new(0.008, 0)
UIPadding.PaddingRight = UDim.new(0.008, 0)
UIPadding.Parent = Bar

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.new(1, 1, 1)
UIStroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
UIStroke.Thickness = 0.05
UIStroke.Parent = Bar

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0.2, 0)
UICorner.Parent = Bar

--== MASKING SETUP ==--

local Filler = Instance.new("Frame")
Filler.Name = "Filler"
Filler.AnchorPoint = Vector2.new(0, 0.5)
Filler.BackgroundColor3 = Color3.new(1, 1, 1)
Filler.Position = UDim2.fromScale(0, 0.5)
Filler.Size = UDim2.fromScale(0, 1)
Filler.ClipsDescendants = true

local UICornerFiller = Instance.new("UICorner")
UICornerFiller.CornerRadius = UDim.new(0.2, 0)
UICornerFiller.Parent = Filler

-- 1. White Text (Static in Bar)
local QuantityLoaded_White = Instance.new("TextLabel")
QuantityLoaded_White.Name = "QuantityLoaded_White"
QuantityLoaded_White.AnchorPoint = Vector2.new(0.5, 0.5)
QuantityLoaded_White.BackgroundTransparency = 1
QuantityLoaded_White.FontFace =
	Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
QuantityLoaded_White.Position = UDim2.fromScale(0.5, 0.5)
QuantityLoaded_White.Size = UDim2.fromScale(0.8, 0.8)
QuantityLoaded_White.Text = "0 / 0"
QuantityLoaded_White.TextColor3 = Color3.new(1, 1, 1)
QuantityLoaded_White.TextScaled = true
QuantityLoaded_White.ZIndex = 1
QuantityLoaded_White.Parent = Bar

-- 2. Container to counteract Filler scaling
local MaskContainer = Instance.new("Frame")
MaskContainer.Name = "MaskContainer"
MaskContainer.BackgroundTransparency = 1
MaskContainer.AnchorPoint = Vector2.new(0, 0.5)
MaskContainer.Position = UDim2.fromScale(0, 0.5)
MaskContainer.Size = UDim2.fromScale(0, 1)
MaskContainer.Parent = Filler

-- 3. Black Text (Inside MaskContainer)
local QuantityLoaded_Black = QuantityLoaded_White:Clone()
QuantityLoaded_Black.Name = "QuantityLoaded_Black"
QuantityLoaded_Black.TextColor3 = Color3.new(0, 0, 0)
QuantityLoaded_Black.ZIndex = 2
QuantityLoaded_Black.Parent = MaskContainer

Filler.Parent = Bar
Bar.Parent = Info
Info.Parent = CanvasGroup
CanvasGroup.Parent = ScreenGui
ScreenGui.Parent = PlayerGui

--== LOADING LOGIC ==--

local assets = {}

-- Flat gather (recursive not strictly needed for basic preloading unless deep hierarchy is dynamically added)
local function gatherAssets(root)
	for _, desc in root:GetDescendants() do
		assets[#assets + 1] = desc
	end
end

gatherAssets(ReplicatedStorage)
gatherAssets(Player)

local maxAssets = #assets
local loadedCount = 0
local activeThreads = 0
local batches = {}

for i = 1, #assets, BATCH_SIZE do
	local batch = {}
	for j = i, math.min(i + BATCH_SIZE - 1, #assets) do
		table.insert(batch, assets[j])
	end
	table.insert(batches, batch)
end

--== VISUAL HELPERS ==--

-- Centralized function to update Bar AND Mask
-- This ensures the black text stays aligned regardless of bar size
local function UpdateBarVisuals(scale)
	Filler.Size = UDim2.fromScale(scale, 1)

	if scale > 0.001 then
		-- Inverse scale: If Filler is 0.5 width of Bar, MaskContainer must be 2.0 width of Filler
		-- to match the original Bar width.
		MaskContainer.Size = UDim2.fromScale(MAX_FILL_SCALE / scale, 1)
	else
		MaskContainer.Size = UDim2.fromScale(0, 1)
	end
end

--== EXECUTION ==--

task.spawn(function()
	if #batches == 0 then
		OnCompleted:Fire()
		return
	end

	for _, batch in batches do
		while activeThreads >= MAX_PARALLEL_LOADS do
			RunService.Heartbeat:Wait()
		end

		activeThreads += 1
		task.spawn(function()
			pcall(function()
				ContentProvider:PreloadAsync(batch)
			end)
			loadedCount += #batch
			activeThreads -= 1

			if loadedCount >= maxAssets then OnCompleted:Fire() end
		end)
	end
end)

--== ANIMATION LOOP ==--

local spinnerIndex = 1
local lastSpinnerUpdate = 0
local patternOffset = 0
local connection

connection = RunService.RenderStepped:Connect(function(dt)
	-- Text Update
	local text = string.format("%d / %d", math.min(loadedCount, maxAssets), maxAssets)
	QuantityLoaded_White.Text = text
	QuantityLoaded_Black.Text = text

	-- Bar Interpolation
	local targetScale = (loadedCount / math.max(maxAssets, 1)) * MAX_FILL_SCALE
	local currentScale = Filler.Size.X.Scale
	local newScale = currentScale + (targetScale - currentScale) * (dt * 5)

	UpdateBarVisuals(newScale)

	-- Pattern Move
	patternOffset = (patternOffset + (0.5 * (dt * 60))) % 128
	Pattern.Position = UDim2.fromOffset(-patternOffset, -patternOffset)

	-- Spinner
	lastSpinnerUpdate += dt
	if lastSpinnerUpdate >= 0.15 then
		lastSpinnerUpdate = 0
		spinnerIndex = (spinnerIndex % #SPINNER_CHARS) + 1
		LoadingLabel.Text = `Loading...  {SPINNER_CHARS[spinnerIndex]}`
	end
end)

OnCompleted:Wait()
connection:Disconnect() -- Stop the loop so we can force set values

-- Force Final State (Fixes the "not fully filled" issue)
UpdateBarVisuals(MAX_FILL_SCALE)
QuantityLoaded_White.Text = "Done!"
QuantityLoaded_Black.Text = "Done!"
LoadingLabel.Text = "Loaded!"

-- Fade Out
local fadeTween = TweenService:Create(CanvasGroup, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { GroupTransparency = 1 })
fadeTween:Play()
fadeTween.Completed:Wait()

ScreenGui:Destroy()
OnCompleted:Destroy()
