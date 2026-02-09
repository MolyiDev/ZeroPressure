export type IdGeneratorAPI = {
	MinId: number,
	MaxId: number,
	CurrentId: number,
	Reset: (min: number?, max: number) -> (),
	Generate: (self: IdGeneratorAPI) -> number,
}

local IdGeneratorStatic = {}
local IdGenerator = {}
IdGenerator.__index = IdGenerator

local CurrentGenerators: { [string]: IdGeneratorAPI } = {}

function IdGeneratorStatic.new(name: string, min: number, max: number): IdGeneratorAPI
	local existing = CurrentGenerators[name]
	if existing then return existing end

	local self = (setmetatable({}, IdGenerator) :: any) :: IdGeneratorAPI
	self.MinId = min
	self.MaxId = max
	self.CurrentId = min

	CurrentGenerators[name] = self

	return self
end

function IdGenerator.Generate(self: IdGeneratorAPI)
	if self.CurrentId >= self.MaxId then
		self.CurrentId = self.MinId
	else
		self.CurrentId += 1
	end

	return self.CurrentId
end

function IdGenerator.Reset(self: IdGeneratorAPI, min: number?, max: number)
	local _min = min or self.MinId
	local _max = max or self.MaxId

	self.CurrentId = _min
	self.MinId = _min
	self.MaxId = _max
end

return IdGeneratorStatic
