local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local SoundsController = require(script.Parent.SoundsController)
local Ignis = require(ReplicatedStorage.Packages.Ignis)
local jecs = require(ReplicatedStorage.Packages.jecs)
local Components = require(ReplicatedStorage.Shared.ECS.Components)
local World = require(ReplicatedStorage.Shared.ECS.Worlds.World)

local AnimatorConnection: RBXScriptConnection?
local EffectsGroup = SoundService:WaitForChild("Effects") :: SoundGroup
local FootstepsSounds = ReplicatedStorage:WaitForChild("Sounds"):WaitForChild("Footsteps") :: { [string]: Sound }
local AnimationNames = {
	RunFront = true,
	WalkFront = true,
	WalkBack = true,
	WalkLeft = true,
	WalkRight = true,
}

local MIN_TREMOLO = 0.65
local MAX_TREMOLO = 0.95
local MIN_SPEED = 0.94
local MAX_SPEED = 1.06
local FOOTSTEP_DEBOUNCE = 0.1

local FootstepsController = {}

function FootstepsController.OnCharacterAdded(_, characterEntity: jecs.Entity)
	local humanoid = World:get(characterEntity, Components.Humanoid)
	local humanoidRootPart = World:get(characterEntity, Components.HumanoidRootPart)
	local animator = World:get(characterEntity, Components.Animator)
	local butler = World:get(characterEntity, Components.Butler)

	if not humanoid or not humanoidRootPart or not animator or not butler then
		warn("Humanoid / HumanoidRootPart / Animator / Butler are nil")
		return
	end

	local lastFootstep = 0

	butler:Connect(animator.AnimationPlayed, function(animationTrack: AnimationTrack)
		if not AnimationNames[animationTrack.Animation.Name] then return end

		local cn = butler:Connect(animationTrack:GetMarkerReachedSignal("Footstep"), function()
			if tick() - lastFootstep < FOOTSTEP_DEBOUNCE then return end
			lastFootstep = tick()

			local materialName = humanoid.FloorMaterial.Name
			if materialName ~= "Metal" then return end

			local Sounds = FootstepsSounds[materialName]:GetChildren()
			local selectedSound = Sounds[math.random(1, #Sounds)]:Clone() :: Sound

			selectedSound.Parent = humanoidRootPart
			selectedSound.SoundGroup = EffectsGroup

			local randomSpeed = math.random() * (MAX_SPEED - MIN_SPEED) + MIN_SPEED
			selectedSound.PlaybackSpeed = math.round(randomSpeed * 1000) / 1000

			local tremoloSound = Instance.new("TremoloSoundEffect")
			local randomTremolo = math.random() * (MAX_TREMOLO - MIN_TREMOLO) + MIN_TREMOLO
			tremoloSound.Depth = math.round(randomTremolo * 1000) / 1000
			tremoloSound.Parent = selectedSound

			SoundsController.AddSound(selectedSound)

			butler:Once(selectedSound.Ended, function()
				SoundsController.RemoveSound(selectedSound)
				selectedSound:Destroy()
			end)

			selectedSound:Play()
		end)

		butler:Once(animationTrack.Stopped, function()
			butler:Remove(cn)
		end)
	end)
end

function FootstepsController.OnCharacterRemoving()
	if not AnimatorConnection then return end
	AnimatorConnection:Disconnect()
	AnimatorConnection = nil
end

return Ignis.Register(FootstepsController)
