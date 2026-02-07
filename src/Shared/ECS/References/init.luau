local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jecs = require(ReplicatedStorage.Packages.jecs)

export type TRefKey = string | number | Instance

export type ReferencesStaticAPI = {
	new: (world: number) -> ReferencesAPI,
}

export type ReferencesAPI = {
	References: { [TRefKey]: jecs.Entity },
	World: jecs.World,
	EntityRef: (self: ReferencesAPI, reference: TRefKey, id: number?) -> jecs.Entity,
	Search: (self: ReferencesAPI, reference: TRefKey) -> jecs.Entity?,
	List: (self: ReferencesAPI, reference: TRefKey, entity: jecs.Entity) -> (),
	Unlist: (self: ReferencesAPI, reference: TRefKey) -> (),
	Nuke: (self: ReferencesAPI, reference: TRefKey, entity: jecs.Entity?) -> (),
}

local ReferencesStatic = {}
local References = {}
References.__index = References

function ReferencesStatic.new(world: jecs.World): ReferencesAPI
	local self = (setmetatable({}, References) :: any) :: ReferencesAPI
	self.References = {}
	self.World = world

	return self
end

--- Creates a new entity in the world and stores a reference to it.
--- @param reference - The key used to associate the entity in the references map.
--- @return The newly created entity.
function References.EntityRef(self: ReferencesAPI, reference: TRefKey, id: number?): jecs.Entity
	local entity = self.World:entity(id)
	self.References[reference] = entity
	return entity
end

--- Searches for an entity associated with a given reference key.
--- @param reference - The key to look up in the references map.
--- @return The entity if found, otherwise `nil`.
function References.Search(self: ReferencesAPI, reference: TRefKey): jecs.Entity?
	return self.References[reference]
end

function References.List(self: ReferencesAPI, reference: TRefKey, entity: jecs.Entity)
	self.References[reference] = entity
end

--- Removes the reference–entity association without deleting the entity from the world.
--- @param reference - The key to remove from the references map.
function References.Unlist(self: ReferencesAPI, reference: TRefKey): ()
	self.References[reference] = nil
end

--- Deletes the reference from references list and deletes the entity from the world.
--- @param reference - The key that was specified in the entityRef function.
--- @param entity - The entity to delete from World. Defaults to the entity found via search.
function References.Nuke(self: ReferencesAPI, reference: TRefKey, entity: jecs.Entity?): ()
	if not entity then entity = self:Search(reference) end

	self.References[reference] = nil

	if entity then self.World:delete(entity) end
end

return ReferencesStatic
