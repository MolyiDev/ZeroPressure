local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Fluid = require(ReplicatedStorage.Packages.Fluid)
local scaleNumber = require(StarterPlayer.StarterPlayerScripts.Client.UI.Components.scaleNumber)

export type DialogueUIReturn = {
	UI: any,
	Appear: () -> (),
	Disappear: () -> (),
	Refs: {
		Text: TextLabel,
		NextIndicator: TextLabel,
	},
}

local create = Fluid.create
local source = Fluid.source
local derive = Fluid.derive
local spring = Fluid.spring

return function(): DialogueUIReturn
	local transparencyTarget = source(1)
	local transparency = spring(transparencyTarget, 20, 0.8)
	local strokeTransparency = derive(function()
		local t = transparency()
		return math.min(1, t / 0.85)
	end)
	local textSize = scaleNumber(38)
	local strokeOther = scaleNumber(1.5)

	local dialogueLabel = create("TextLabel")({
		Name = "Dialogue",
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutoLocalize = false,
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Position = UDim2.fromScale(0.5, 0.385),
		RichText = true,
		Size = UDim2.fromScale(0.95, 0.53),
		Text = "",
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = textSize,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTransparency = transparency,

		create("UIStroke")({
			LineJoinMode = Enum.LineJoinMode.Bevel,
			Thickness = strokeOther,
			Transparency = strokeTransparency,
		}),
	})

	local nextIndicatorLabel = create("TextLabel")({
		Name = "Next",
		AnchorPoint = Vector2.new(0.5, 1),
		AutoLocalize = false,
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/Fondamento.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		Position = UDim2.fromScale(0.5, 0.93),
		RichText = true,
		Size = UDim2.fromScale(0.95, 0.15),
		Text = "Press F to skip...",
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		TextTransparency = transparency,

		create("UIStroke")({
			LineJoinMode = Enum.LineJoinMode.Bevel,
			Thickness = strokeOther,
			Transparency = strokeTransparency,
		}),
	})

	local ui = create("ScreenGui")({
		Name = "DialogueUI",
		ClipToDeviceSafeArea = false,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		create("Frame")({
			Name = "Container",
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.998),
			Size = UDim2.fromScale(0.5, 0.2),

			dialogueLabel,
			nextIndicatorLabel,
		}),
	})

	return {
		UI = ui,
		Appear = function()
			transparencyTarget(0)
		end,
		Disappear = function()
			transparencyTarget(1)
		end,
		Refs = {
			Text = dialogueLabel,
			NextIndicator = nextIndicatorLabel,
		},
	}
end
