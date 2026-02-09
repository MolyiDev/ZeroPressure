local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local scaleNumber = require(StarterPlayer.StarterPlayerScripts.Client.UI.Components.scaleNumber)
local Fluid = require(ReplicatedStorage.Packages.Fluid)
export type CursorUIReturn = {
	UI: any,
	Appear: () -> (),
	Disappear: () -> (),
}

local create = Fluid.create
local source = Fluid.source
local derive = Fluid.derive
local spring = Fluid.spring

return function(): CursorUIReturn
	local transparencyTarget = source(1)
	local transparency = spring(transparencyTarget, 20, 0.8)
	local number = scaleNumber(6)

	local ui = create("ScreenGui")({
		Name = "CursorUI",
		ClipToDeviceSafeArea = false,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		create("Frame")({
			Name = "Cursor",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = transparency,
			BackgroundColor3 = Color3.new(1, 1, 1),
			Position = UDim2.fromScale(0.5, 0.5),

			Size = derive(function()
				local n = number()
				return UDim2.fromOffset(n, n)
			end),

			create("UICorner")({
				CornerRadius = UDim.new(1, 0),
			}),
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
	}
end
