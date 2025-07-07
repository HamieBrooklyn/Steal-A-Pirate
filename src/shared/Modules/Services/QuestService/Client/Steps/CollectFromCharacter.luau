local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Services = ReplicatedStorage.Shared.Modules.Services

local BaseClient = require(Services.BaseService.Client)
local Platform = require(Services.BaseService.Client.Base.Platform)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Path = require(script.Parent.Parent.Path)
local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)
local Net = require(ReplicatedStorage.Packages.Net)
local AnimatedHighlight = require(ReplicatedStorage.Shared.Modules.Classes.AnimatedHighlight)

local innerScope, peek = Fusion.innerScope, Fusion.peek

local CollectFromCharacter = {}
CollectFromCharacter.__index = CollectFromCharacter

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	text: Fusion.Value<string, any>,

	ended: Signal.Signal,
}
export type CollectFromCharacter = typeof(setmetatable({} :: self, CollectFromCharacter))

function CollectFromCharacter.new(scope: Fusion.Scope<any>, text: Fusion.Value<string, any>, ...): CollectFromCharacter
	local self = setmetatable({}, CollectFromCharacter) :: CollectFromCharacter

	self.scope = innerScope(scope)
	self.trove = Trove.new()

	self.text = text

	self.ended = Signal.new()
	self.trove:Add(self.ended)

	return self
end

function CollectFromCharacter.Started(self: CollectFromCharacter, characterName: string, texts: { string })
	self.text:set(texts[1])

	local path: Path.Path = Path.new(self.scope)
	local hl: AnimatedHighlight.AnimatedHighlight = self.trove:Add(AnimatedHighlight.new({
		FillColor = Color3.new(1, 1, 1),
	}, Players.LocalPlayer:WaitForChild("PlayerGui")))
	hl.pulseLooping:set(true)

	local currentPlatform: Fusion.Value<Platform.Platform?, any> = self.scope:Value(nil)
	self.scope:Observer(currentPlatform):onChange(function()
		local platformState: Platform.Platform? = peek(currentPlatform)
		local collectPart = if platformState then platformState.model:WaitForChild("Collect") else nil
		path.to:set(if collectPart then collectPart else nil)
		hl.adornee:set(if collectPart then collectPart else nil)
	end)

	self.trove:Add(observeCharacter(Players.LocalPlayer, function(char)
		local root = char:WaitForChild("HumanoidRootPart")
		if not root then
			return
		end
		path.from:set(root)
	end))

	local function checkPlatforms()
		for _, v in BaseClient.GetBase().Platforms do
			local charName = peek(v.CharacterName)
			if charName == characterName then
				currentPlatform:set(v)
				break
			end
		end
	end
	checkPlatforms()
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
					currentPlatform:set(platform)
					break
				end
			end
		end)
	end))
	self.trove:Add(Net:Connect("BasePlatformSold", function(_, platformId: string)
		task.defer(function()
			local platformState: Platform.Platform? = peek(currentPlatform)
			if platformState and platformId == platformState.id then
				currentPlatform:set(nil)
				checkPlatforms()
			end
		end)
	end))
	self.trove:Add(Net:Connect("BasePlatformCollected", function(baseId: string, platformId: string)
		task.defer(function()
			local platform = BaseClient.bases[baseId].Platforms[platformId]
			if peek(platform.CharacterName) == characterName then
				self.ended:Fire()
			end
		end)
	end))
end

function CollectFromCharacter.Destroy(self: CollectFromCharacter): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return CollectFromCharacter
