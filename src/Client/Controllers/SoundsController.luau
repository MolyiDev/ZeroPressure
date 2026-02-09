local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)

local TW_FADE = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local SoundsFolder = ReplicatedStorage:WaitForChild("Sounds")

local SoundsController = {}
local Sounds: { [number]: Sound } = {}
local ActiveSounds: { [Sound]: boolean } = {}

for _, sound in SoundsFolder:GetDescendants() do
	if not sound:IsA("Sound") then continue end
	local id = ESounds[sound.Name]
	if not id then continue end
	Sounds[id] = sound
end

function SoundsController.Clone(soundId: number, parent: any): Sound?
	local sound = Sounds[soundId]
	if not sound then return nil end

	local clone = sound:Clone()
	clone.Parent = parent

	return clone
end

function SoundsController.PlayLoop(soundId: number, parent: Instance, fade: boolean)
	local sound = Sounds[soundId]
	if not sound then return end

	if parent:FindFirstChild(sound.Name) then return end

	local clone = sound:Clone()
	clone.Parent = parent
	clone.Looped = true
	clone.Volume = 0
	ActiveSounds[clone] = true
	clone:Play()

	if fade then TweenService:Create(clone, TW_FADE, {
		Volume = sound.Volume,
	}):Play() end
end

function SoundsController.FadeLoop(soundId: number, parent: Instance, volume: number)
	local sound = Sounds[soundId]
	if not sound then return end

	local activeSound = parent:FindFirstChild(sound.Name) :: Sound
	if activeSound then TweenService:Create(activeSound, TW_FADE, { Volume = volume }):Play() end
end

function SoundsController.StopLoop(soundId: number, parent: any, fade: boolean)
	local sound = Sounds[soundId]
	if not sound then return end

	local oldSound = parent:FindFirstChild(sound.Name) :: Sound
	if not oldSound then return end

	if fade then
		oldSound.Name = "Fading_" .. oldSound.Name

		local tween = TweenService:Create(oldSound, TW_FADE, {
			Volume = 0,
		})

		tween.Completed:Once(function()
			ActiveSounds[oldSound] = nil
			if oldSound then oldSound:Destroy() end
		end)

		tween:Play()
	else
		ActiveSounds[oldSound] = nil
		oldSound:Destroy()
	end
end

function SoundsController.Play(soundId: number, parent: any)
	local sound = Sounds[soundId]
	if not sound then return end

	local clone = sound:Clone()
	clone.Parent = parent
	clone.Ended:Once(function()
		ActiveSounds[clone] = nil
		if clone then clone:Destroy() end
	end)
	ActiveSounds[clone] = true
	clone:Play()
end

function SoundsController.PlaySound(sound: Sound)
	sound.Ended:Once(function()
		ActiveSounds[sound] = nil
		if sound then sound:Destroy() end
	end)
	ActiveSounds[sound] = true
	sound:Play()
end

function SoundsController.PlayCharacter(soundId: number)
	SoundsController.Play(soundId, SoundService)
end

function SoundsController.AddSound(sound: Sound)
	ActiveSounds[sound] = true
end

function SoundsController.RemoveSound(sound: Sound)
	ActiveSounds[sound] = nil
end

function SoundsController.Reset()
	for sound, _ in ActiveSounds do
		sound:Destroy()
	end

	table.clear(ActiveSounds)
end

return Ignis.Register(SoundsController)
