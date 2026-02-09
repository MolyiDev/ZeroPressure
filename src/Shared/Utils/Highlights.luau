local TweenService = game:GetService("TweenService")

export type PartState = {
	Highlight: Highlight,
	Loop: boolean,
	Normal: boolean,
	LoopTween: Tween?,
}

local Highlights = {}
local PartStates: { [BasePart]: PartState } = {}

local TWInfoLoop = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1)
local TWInfoNormal = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local TWInfoOut = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local function UpdateVisuals(part: BasePart, state: PartState)
	if state.Normal then
		if state.LoopTween then state.LoopTween:Cancel() end

		local tween = TweenService:Create(state.Highlight, TWInfoNormal, { OutlineTransparency = 0 })
		tween:Play()
	elseif state.Loop then
		state.Highlight.OutlineTransparency = 0
		local tween = TweenService:Create(state.Highlight, TWInfoLoop, { OutlineTransparency = 0.5 })
		tween:Play()
		state.LoopTween = tween
	else
		local fadeOut = TweenService:Create(state.Highlight, TWInfoOut, { OutlineTransparency = 1 })
		fadeOut:Play()

		PartStates[part] = nil

		task.delay(TWInfoOut.Time, function()
			if state.Highlight then state.Highlight:Destroy() end
		end)
	end
end

local function GetState(part: BasePart, color: Color3?): PartState
	local state = PartStates[part]

	if not state then
		local highlight = Instance.new("Highlight")
		highlight.FillTransparency = 1
		highlight.OutlineTransparency = 1
		highlight.OutlineColor = color or Color3.fromRGB(255, 255, 255)
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = part

		state = {
			Highlight = highlight,
			Loop = false,
			Normal = false,
			LoopTween = nil,
		}

		PartStates[part] = state :: any
	elseif color then
		state.Highlight.OutlineColor = color
	end

	return state
end

function Highlights.AddLoop(part: BasePart, color: Color3?)
	if not part then return end
	local state = GetState(part, color)
	state.Loop = true
	UpdateVisuals(part, state)
end

function Highlights.RemoveLoop(part: BasePart)
	local state = PartStates[part]
	if not state then return end
	state.Loop = false
	UpdateVisuals(part, state)
end

function Highlights.Add(part: BasePart, color: Color3?)
	if not part then return end
	local state = GetState(part, color)
	state.Normal = true
	UpdateVisuals(part, state)
end

function Highlights.Remove(part: BasePart)
	local state = PartStates[part]
	if not state then return end
	state.Normal = false
	UpdateVisuals(part, state)
end

function Highlights.RemoveAll(part: BasePart)
	local state = PartStates[part]
	if not state then return end
	state.Normal = false
	state.Loop = false
	UpdateVisuals(part, state)
end

return Highlights
