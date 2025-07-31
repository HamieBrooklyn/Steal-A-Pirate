local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local SharedSpawningData = require(Services.SpawningService.Data)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local InfoBoard = require(ReplicatedStorage.Shared.Modules.Services.SpawningService.Client.PirateInfo.InfoBoard)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Streamable = require(ReplicatedStorage.Packages.Streamable)
local Observers = require(ReplicatedStorage.Packages.Observers)

local scoped, peek = Fusion.scoped, Fusion.peek

local PirateInfo = {}
PirateInfo.__index = PirateInfo

type self = {
	instance: BillboardGui,

	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,
}
export type PirateInfo = typeof(setmetatable({} :: self, PirateInfo))

function PirateInfo.new(character: Model): PirateInfo
	local self = setmetatable({}, PirateInfo) :: PirateInfo

	self._scope = scoped(Fusion)
	local name = character:GetAttribute("PirateName")

	self._trove = Trove.new()

	local mutations = self._scope:Value({})
	self._trove:Add(Observers.observeAttribute(character, "Mutations", function(mutationString: string?)
		if mutationString then
			local mutAction = {}
			for _, v in mutationString:split(",") do
				table.insert(mutAction, v)
			end
			mutations:set(mutAction)
		end
	end))

	local headStream = self._trove:Add(Streamable.Streamable.new(character, "Head"))
	self._trove:Add(headStream:Observe(function(head: BasePart, headTrove: Trove.Trove)
		self.instance = headTrove:Add(InfoBoard(self._scope, {
			Parent = character,
			Adornee = head,

			StudsOffset = Vector3.new(0, 6, 0),

			Mutations = mutations,
			Name = name,
			Data = SharedSpawningData.Characters.Info[name],
		}))
	end))

	return self
end

function PirateInfo.Destroy(self: PirateInfo): ()
	self._scope:doCleanup()
	self._trove:Destroy()
end

return PirateInfo
