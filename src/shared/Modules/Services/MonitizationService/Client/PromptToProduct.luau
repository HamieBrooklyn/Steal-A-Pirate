local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Observers = require(ReplicatedStorage.Packages.Observers)

local scoped, peek = Fusion.scoped, Fusion.peek

local PromptToProduct = {}
PromptToProduct.__index = PromptToProduct

type self = {
	prompt: ProximityPrompt,

	_scope: Fusion.Scope<any>,
}
export type PromptToProduct = typeof(setmetatable({} :: self, PromptToProduct))

function PromptToProduct.new(attachment: Attachment, promptPurchase: (id: number) -> ()): PromptToProduct
	local BaseClient = require(Services.BaseService.Client)
	local Base = require(Services.BaseService.Client.Base)

	local self = setmetatable({}, PromptToProduct) :: PromptToProduct

	self._scope = scoped(Fusion)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = attachment:GetAttribute("ActionText")
	prompt.ObjectText = attachment:GetAttribute("ObjectText")
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 1
	prompt.Parent = attachment
	prompt:AddTag("CustomPrompt")
	self.prompt = prompt

	Observers.observeAttribute(attachment, "CheckFullBase", function(value)
		if value then
			BaseClient.GetBase():andThen(function(base: Base.Base)
				self._scope:Observer(base.isFull):onBind(function()
					prompt.Enabled = not peek(base.isFull)
				end)
			end)
		end
	end)

	prompt.Triggered:Connect(function()
		promptPurchase(tonumber(attachment:GetAttribute("Id")))
	end)

	return self
end

function PromptToProduct.Destroy(self: PromptToProduct): ()
	self._scope:doCleanup()
	self.prompt:Destroy()
end

return PromptToProduct
