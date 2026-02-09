local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local DialogueUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.DialogueUI)
local Butler = require(ReplicatedStorage.Packages.Butler)
local Fluid = require(ReplicatedStorage.Packages.Fluid)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ECharacters = require(ReplicatedStorage.Types.Enums.ECharacters)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local TalkSoundsFolder = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Talk") :: Folder

local BASE_SPEED = 0.04
local BASE_PITCH = 1.0
local PITCH_VAR = 0.05
local FADE_TIME = 0.4
local INPUT_KEY = Enum.KeyCode.F
local YES_KEY = Enum.KeyCode.Y
local NO_KEY = Enum.KeyCode.N

export type Dialogue = {
	Id: number,
	Dialogue: string,
	Sound: Sound?,
}

local CHARACTERS: { [number]: { Sound: Sound } } = {
	[ECharacters.Radio] = {
		Sound = TalkSoundsFolder:WaitForChild("Radio") :: Sound,
	},
}

local DialogueController = {}
local CurrentPromise: Promise.Promise?
local CurrentButler: Butler.Butler?
local UI: DialogueUI.DialogueUIReturn

Fluid.mount(function()
	UI = DialogueUI()
	return UI.UI
end, PlayerGui)

local function ParseRichText(rawText: string)
	local cleanText = ""
	local commands = {}
	local currentIndex = 0

	local pos = 1
	while pos <= #rawText do
		local startTag, endTag = string.find(rawText, "<[^>]+>", pos)

		if not startTag or not endTag then
			cleanText = cleanText .. string.sub(rawText, pos)
			break
		end

		local preText = string.sub(rawText, pos, startTag - 1)
		cleanText = cleanText .. preText
		currentIndex = currentIndex + (utf8.len(preText) :: number)

		local tagContent = string.sub(rawText, startTag + 1, endTag - 1)
		local tagName = string.match(tagContent, "^/?(%w+)") :: string

		local isRichText = table.find({ "b", "i", "u", "s", "font", "stroke", "sc", "br" }, tagName)

		if isRichText then
			cleanText = cleanText .. string.sub(rawText, startTag, endTag)
		else
			local args = {}
			for k, v in string.gmatch(tagContent, "(%w+)=[\"']([^\"']+)[\"']") do
				args[k] = tonumber(v) or v
			end

			local isClosing = string.sub(tagContent, 1, 1) == "/"

			if not commands[currentIndex + 1] then commands[currentIndex + 1] = {} end
			table.insert(commands[currentIndex + 1], {
				Name = tagName,
				Args = args,
				IsClosing = isClosing,
			})
		end

		pos = endTag + 1
	end

	return cleanText, commands
end

local function ApplyFlicker(butler: Butler.Butler, baseText: string, options: string, speed: number)
	local parts = string.split(options, "|")
	if #parts < 2 then return end

	local lastUpdate = 0
	local idx = 1

	butler:Connect(RunService.Heartbeat, function()
		if os.clock() - lastUpdate > (speed or 0.1) then
			lastUpdate = os.clock()
			idx = (idx % #parts) + 1
			if UI then UI.Refs.Text.Text = string.gsub(baseText, parts[idx == 1 and 2 or 1], parts[idx]) end
		end
	end)
end

function DialogueController.Talk(dialogue: Dialogue): Promise.Promise
	if CurrentPromise and CurrentPromise:getStatus() == Promise.Status.Started then CurrentPromise:cancel() end

	CurrentPromise = Promise.new(function(resolve, _, onCancel)
		local butler = Butler.new()
		CurrentButler = butler

		onCancel(function()
			butler:Clean()
			if UI then UI.Disappear() end
		end)

		local charData = CHARACTERS[dialogue.Id]
		local refs = UI.Refs

		refs.Text.MaxVisibleGraphemes = 0

		local indicatorBaseText = "Press F to skip"

		local dotTask = task.spawn(function()
			while true do
				for i = 1, 3 do
					refs.NextIndicator.Text = indicatorBaseText .. string.rep(".", i)
					task.wait(0.5)
				end
			end
		end)
		butler:Add(function()
			if coroutine.status(dotTask) ~= "dead" then task.cancel(dotTask) end
		end)

		local cleanText, commands = ParseRichText(dialogue.Dialogue)

		-- FIX: Strip ALL tags to get the true "visible" length for the loop
		local visibleText = string.gsub(cleanText, "<[^>]+>", "")
		local totalGraphemes = utf8.len(visibleText) :: number

		refs.Text.Text = cleanText

		UI.Appear()
		task.wait(FADE_TIME)

		local currentGrapheme = 0
		local currentSpeed = BASE_SPEED
		local currentPitch = BASE_PITCH
		local isSkipped = false

		local skipCn
		skipCn = butler:Connect(UserInputService.InputBegan, function(input)
			if input.KeyCode == INPUT_KEY then
				isSkipped = true
				butler:Remove(skipCn)
			end
		end)

		while currentGrapheme < totalGraphemes do
			if isSkipped then
				refs.Text.MaxVisibleGraphemes = -1
				break
			end

			currentGrapheme += 1

			if commands[currentGrapheme] then
				for _, cmd in ipairs(commands[currentGrapheme]) do
					if cmd.Name == "speed" then
						currentSpeed = cmd.IsClosing and BASE_SPEED or (tonumber(cmd.Args.val) or BASE_SPEED)
					elseif cmd.Name == "pitch" then
						currentPitch = cmd.IsClosing and BASE_PITCH or (tonumber(cmd.Args.val) or BASE_PITCH)
					elseif cmd.Name == "flicker" then
						ApplyFlicker(butler, cleanText, cmd.Args.text :: string, tonumber(cmd.Args.speed) :: number)
					end
				end
			end

			refs.Text.MaxVisibleGraphemes = currentGrapheme
			local sound = dialogue.Sound or charData.Sound

			-- Sound logic is fine, but now it only runs for visible characters
			if sound and currentGrapheme % 2 == 0 then
				local s = sound:Clone()
				s.Parent = UI.UI
				s.PlaybackSpeed = currentPitch + ((math.random() - 0.5) * PITCH_VAR)
				s:Play()
				game.Debris:AddItem(s, 1)
			end

			task.wait(currentSpeed)
		end

		if skipCn then butler:Remove(skipCn) end

		indicatorBaseText = "Press F to next"

		local finished = false
		butler:Connect(UserInputService.InputBegan, function(input)
			if input.KeyCode == INPUT_KEY then finished = true end
		end)

		while not finished do
			RunService.Heartbeat:Wait()
		end

		UI.Disappear()
		task.wait(FADE_TIME)

		butler:Clean()
		resolve()
	end)

	return CurrentPromise :: Promise.Promise
end

function DialogueController.Question(dialogue: Dialogue): Promise.Promise
	if CurrentPromise and CurrentPromise:getStatus() == Promise.Status.Started then CurrentPromise:cancel() end

	CurrentPromise = Promise.new(function(resolve, _, onCancel)
		local butler = Butler.new()
		CurrentButler = butler

		onCancel(function()
			butler:Clean()
			if UI then UI.Disappear() end
		end)

		local charData = CHARACTERS[dialogue.Id]
		local refs = UI.Refs

		refs.Text.MaxVisibleGraphemes = 0

		local indicatorBaseText = "Press F to skip"

		local dotTask = task.spawn(function()
			while true do
				for i = 1, 3 do
					refs.NextIndicator.Text = indicatorBaseText .. string.rep(".", i)
					task.wait(0.5)
				end
			end
		end)
		butler:Add(function()
			if coroutine.status(dotTask) ~= "dead" then task.cancel(dotTask) end
		end)

		local cleanText, commands = ParseRichText(dialogue.Dialogue)
		local visibleText = string.gsub(cleanText, "<[^>]+>", "")
		local totalGraphemes = utf8.len(visibleText) :: number

		refs.Text.Text = cleanText

		UI.Appear()
		task.wait(FADE_TIME)

		local currentGrapheme = 0
		local currentSpeed = BASE_SPEED
		local currentPitch = BASE_PITCH
		local isSkipped = false

		local skipCn
		skipCn = butler:Connect(UserInputService.InputBegan, function(input)
			if input.KeyCode == INPUT_KEY then
				isSkipped = true
				butler:Remove(skipCn)
			end
		end)

		while currentGrapheme < totalGraphemes do
			if isSkipped then
				refs.Text.MaxVisibleGraphemes = -1
				break
			end

			currentGrapheme += 1

			if commands[currentGrapheme] then
				for _, cmd in ipairs(commands[currentGrapheme]) do
					if cmd.Name == "speed" then
						currentSpeed = cmd.IsClosing and BASE_SPEED or (tonumber(cmd.Args.val) or BASE_SPEED)
					elseif cmd.Name == "pitch" then
						currentPitch = cmd.IsClosing and BASE_PITCH or (tonumber(cmd.Args.val) or BASE_PITCH)
					elseif cmd.Name == "flicker" then
						ApplyFlicker(butler, cleanText, cmd.Args.text :: string, tonumber(cmd.Args.speed) :: number)
					end
				end
			end

			refs.Text.MaxVisibleGraphemes = currentGrapheme
			local sound = dialogue.Sound or charData.Sound

			if sound and currentGrapheme % 2 == 0 then
				local s = sound:Clone()
				s.Parent = UI.UI
				s.PlaybackSpeed = currentPitch + ((math.random() - 0.5) * PITCH_VAR)
				s:Play()
				game.Debris:AddItem(s, 1)
			end

			task.wait(currentSpeed)
		end

		if skipCn then butler:Remove(skipCn) end

		task.cancel(dotTask)
		refs.NextIndicator.Text = '[Y] <font color="#07ff8f">Yes</font>   |   [N] <font color="#ff013c">No</font>'

		local result = nil
		butler:Connect(UserInputService.InputBegan, function(input)
			if input.KeyCode == YES_KEY then
				refs.NextIndicator.Text =
					'[Y] <font color="#07ff8f">Yes</font>   |   [N] <font color="#FFFFFF">No</font>'
				result = true
			elseif input.KeyCode == NO_KEY then
				refs.NextIndicator.Text =
					'[Y] <font color="#FFFFFF">Yes</font>   |   [N] <font color="#ff013c">No</font>'
				result = false
			end
		end)

		while result == nil do
			RunService.Heartbeat:Wait()
		end

		UI.Disappear()
		task.wait(FADE_TIME)

		butler:Clean()
		resolve(result)
	end)

	return CurrentPromise :: Promise.Promise
end
function DialogueController.Stop(yield: boolean)
	if CurrentPromise then
		CurrentPromise:cancel()
		CurrentPromise = nil
	end

	if CurrentButler then
		CurrentButler:Clean()
		CurrentButler = nil
	end

	if UI then
		UI.Disappear()
		if yield then task.wait(FADE_TIME) end
	end
end

return Ignis.Register(DialogueController)
