local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Fluid = require(ReplicatedStorage.Packages.Fluid)

local source = Fluid.source
local cleanup = Fluid.cleanup

local BASE_RESOLUTION = Vector2.new(1920, 1080)

return function(defaultValue: number)
	local value = source(defaultValue)

	local camera = Workspace.CurrentCamera

	local function update()
		local viewport = camera.ViewportSize
		if viewport.X == 0 or viewport.Y == 0 then return end

		local scaleX = viewport.X / BASE_RESOLUTION.X
		local scaleY = viewport.Y / BASE_RESOLUTION.Y
		local scale = math.min(scaleX, scaleY)

		value(defaultValue * scale)
	end

	update()

	local connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)

	cleanup(function()
		connection:Disconnect()
	end)

	return value
end
