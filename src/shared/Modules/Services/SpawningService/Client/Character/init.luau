local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedTypes = require(script.Parent.Parent.Types)

local InfoBoard = require(script.InfoBoard)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local scoped = Fusion.scoped

local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)
local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Observers = require(ReplicatedStorage.Packages.Observers)

local player = Players.LocalPlayer

local Character = {}
Character.__index = Character

type self = {
	id: string,

	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,

	model: Model,
}
export type Character = typeof(setmetatable({} :: self, Character))

function Character.new(model: Model, data: SharedTypes.CharacterData): Character
	local self = setmetatable({}, Character) :: Character

	self.id = model:GetAttribute("CharacterId")

	local scope = scoped(Fusion, {
		InfoBoard = InfoBoard,
	})
	self._scope = scope

	local trove = Trove.new()
	self._trove = trove

	self.model = model

	scope:InfoBoard({
		Parent = player:WaitForChild("PlayerGui"):WaitForChild("Billboards"),
		ResetOnSpawn = false,
		Adornee = model,

		Name = model.Name,
		Data = data,
	})

	local prompt: ProximityPrompt?
	trove:Add(Streamable.primary(model):Observe(function(root: BasePart, rootTrove)
		rootTrove:Add(Streamable.new(root, "PirateInteract"):Observe(function(...)
			prompt = ...
			prompt.Enabled = model:GetAttribute("Player") ~= player.Name
		end))
	end))
	trove:Add(Observers.observeAttribute(model, "Player", function(value)
		if prompt then
			prompt.Enabled = value ~= player.Name
		end
	end))

	return self
end

function Character.Destroy(self: Character): ()
	self._scope:doCleanup()
	self._trove:Destroy()
end

return Character
