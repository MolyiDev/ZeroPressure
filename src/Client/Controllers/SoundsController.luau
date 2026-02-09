local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local ESounds = require(ReplicatedStorage.Types.Enums.ESounds)

type SoundData = { Sound: Sound, BaseSpeed: number }

local SoundsFolder = ReplicatedStorage:WaitForChild("Sounds")

local SoundsController = {}
local Sounds: { [number]: SoundData } = {}
local ActiveSounds: { [Sound]: boolean } = {}

for _, sound in SoundsFolder:GetDescendants() do
	if not sound:IsA("Sound") then continue end
	local id = ESounds[sound.Name]
	if not id then continue end
	Sounds[id] = { Sound = sound, BaseSpeed = sound.PlaybackSpeed }
end

function SoundsController.Clone(soundId: number, parent: any): Sound?
	local data = Sounds[soundId]
	if not data then return nil end

	local clone = data.Sound:Clone()
	clone.Parent = parent

	return clone
end

function SoundsController.Play(soundId: number, parent: any)
	local data = Sounds[soundId]
	if not data then return end

	local clone = data.Sound:Clone()
	clone.Parent = parent
	clone.Ended:Once(function()
		ActiveSounds[clone] = nil
		clone:Destroy()
	end)
	clone.PlaybackSpeed = data.BaseSpeed
	ActiveSounds[clone] = true
	clone:Play()
end

function SoundsController.PlaySound(sound: Sound)
	sound.Ended:Once(function()
		ActiveSounds[sound] = nil
		sound:Destroy()
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
