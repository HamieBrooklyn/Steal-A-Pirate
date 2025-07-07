local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local BaseClient = require(Services.BaseService.Client)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Net = require(ReplicatedStorage.Packages.Net)

local innerScope, peek = Fusion.innerScope, Fusion.peek

local RetrieveCharacter = {}
RetrieveCharacter.__index = RetrieveCharacter

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	text: Fusion.Value<string, any>,

	ended: Signal.Signal,
}
export type RetrieveCharacter = typeof(setmetatable({} :: self, RetrieveCharacter))

function RetrieveCharacter.new(scope: Fusion.Scope<any>, text: Fusion.Value<string, any>, ...): RetrieveCharacter
	local self = setmetatable({}, RetrieveCharacter) :: RetrieveCharacter

	self.scope = innerScope(scope)
	self.trove = Trove.new()

	self.text = text

	self.ended = Signal.new()
	self.trove:Add(self.ended)

	return self
end

function RetrieveCharacter.Started(self: RetrieveCharacter, characterName: string, texts: { string })
	self.text:set(texts[1])
	self.trove:Add(Net:Connect("BasePlatformCharacterSet", function(platforms: {
		{
			baseId: string,
			platformId: string,
		}
	})
		task.defer(function()
			for _, v in platforms do
				local platform = BaseClient.bases[v.baseId].Platforms[v.platformId]
				local charName = peek(platform.CharacterName)
				if charName == characterName then
					self.ended:Fire()
					break
				end
			end
		end)
	end))
end

function RetrieveCharacter.Destroy(self: RetrieveCharacter): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return RetrieveCharacter
