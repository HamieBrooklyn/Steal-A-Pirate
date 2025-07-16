local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local observeChildren = require(ReplicatedStorage.Shared.Modules.Utilities.observeChildren)
local Observers = require(ReplicatedStorage.Packages.Observers)

local scoped, peek = Fusion.scoped, Fusion.peek

local Gradiented = {}
Gradiented.__index = Gradiented

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	gradient: Fusion.Value<UIGradient?, any>,
	clonedGradient: Fusion.Value<UIGradient?, any>,

	enabled: Fusion.Value<boolean, any>,
}
export type Gradiented = typeof(setmetatable({} :: self, Gradiented))

function Gradiented.new(instance: GuiObject, gradient: UIGradient?): Gradiented
	local self = setmetatable({}, Gradiented) :: Gradiented

	self.scope = scoped(Fusion)
	self.trove = Trove.new()

	self.gradient = self.scope:Value(gradient) :: Fusion.Value<UIGradient?, any>
	self.clonedGradient = self.scope:Value(nil) :: Fusion.Value<UIGradient?, any>

	self.enabled = self.scope:Value(true) :: Fusion.Value<boolean, any>

	self.scope:Observer(self.gradient):onBind(function()
		if peek(self.clonedGradient) then
			peek(self.clonedGradient):Destroy()
		end

		local gradientState = peek(self.gradient)
		if gradientState then
			self.clonedGradient:set(self.scope:Hydrate(gradientState:Clone())({
				Parent = instance,
				Enabled = self.enabled,
			}))
		else
			self.clonedGradient:set(nil)
		end
	end)

	return self
end

function Gradiented.Destroy(self: Gradiented): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return Gradiented
