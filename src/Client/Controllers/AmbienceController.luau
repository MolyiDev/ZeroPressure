local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local SoundsController = require(script.Parent.SoundsController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)

local CHANCE_SOUND = 0.075
local CHANCE_AMOUNT = 3
local CHECK_INTERVAL = 1 / 60

local SoundsAttachments = (Workspace:FindFirstChild("SoundsAttachments")):GetDescendants() :: { Attachment }
local Sounds = ReplicatedStorage:FindFirstChild("Sounds"):FindFirstChild("Ambience")
local RandomSounds = Sounds:FindFirstChild("Random"):GetDescendants() :: { Sound }
local AmbienceLoop1 = SoundService:FindFirstChild("AmbienceLoop1") :: Sound
local AmbienceLoop2 = SoundService:FindFirstChild("AmbienceLoop2") :: Sound
AmbienceLoop1:Play()
AmbienceLoop2:Play()

local AmbienceController = {}
AmbienceController.IsRandomizerActive = false
AmbienceController.ChanceSound = CHANCE_SOUND
AmbienceController.ChanceAmount = CHANCE_AMOUNT

local RandomizerConnection: RBXScriptConnection?
local Accumulator = 0

function AmbienceController.PlayRandom()
	local soundIndex = math.random(1, #RandomSounds)
	local attachmentIndex = math.random(1, #SoundsAttachments)

	local sound = RandomSounds[soundIndex]:Clone()
	sound.Parent = SoundsAttachments[attachmentIndex]

	SoundsController.PlaySound(sound)
end

function AmbienceController.StartRandomizer()
	if AmbienceController.IsRandomizerActive then return end
	AmbienceController.IsRandomizerActive = true

	if RandomizerConnection then
		RandomizerConnection:Disconnect()
		RandomizerConnection = nil
	end

	RandomizerConnection = RunService.Heartbeat:Connect(function(dt: number)
		Accumulator += dt

		while Accumulator >= CHECK_INTERVAL do
			Accumulator -= CHECK_INTERVAL

			for _ = 0, AmbienceController.ChanceAmount do
				if math.random() < (AmbienceController.ChanceSound * CHECK_INTERVAL) then
					AmbienceController.PlayRandom()
				end
			end
		end
	end)
end

function AmbienceController.StopRandomizer()
	if not AmbienceController.IsRandomizerActive then return end
	AmbienceController.IsRandomizerActive = false

	if RandomizerConnection then
		RandomizerConnection:Disconnect()
		RandomizerConnection = nil
	end
end

function AmbienceController.OnStart()
	AmbienceController.StartRandomizer()
end

return Ignis.Register(AmbienceController)
