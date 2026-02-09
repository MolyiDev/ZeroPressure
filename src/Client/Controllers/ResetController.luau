local SceneController = require(script.Parent.SceneController)

local resetBindable = Instance.new("BindableEvent")

resetBindable.Event:Connect(function()
	SceneController.Restart()
end)

while true do
	local success, _ = pcall(function()
		game:GetService("StarterGui"):SetCore("ResetButtonCallback", resetBindable)
	end)

	if success then break end
	task.wait()
end

return nil
