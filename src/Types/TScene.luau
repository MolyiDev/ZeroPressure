local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local TCharacter = require(script.Parent.TCharacter)

export type TScene = {
	IsActive: boolean,
	Start: () -> Promise.Promise,
	Stop: () -> (),
	Restart: () -> (),
	CharacterAdded: (character: TCharacter.TCharacter) -> (),
	CharacterDied: () -> boolean?,
}

return nil
