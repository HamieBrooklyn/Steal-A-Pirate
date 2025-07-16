local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local observeChildren = require(ReplicatedStorage.Shared.Modules.Utilities.observeChildren)
local Observers = require(ReplicatedStorage.Packages.Observers)

local scoped, peek = Fusion.scoped, Fusion.peek

local CloseButton = {}
CloseButton.__index = CloseButton

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	objectToClose: Fusion.Value<GuiObject?, any>,
}
export type CloseButton = typeof(setmetatable({} :: self, CloseButton))

function CloseButton.new(button: GuiButton): CloseButton
	local self = setmetatable({}, CloseButton) :: CloseButton

	self.scope = scoped(Fusion) :: Fusion.Scope<any>
	self.trove = Trove.new()

	self.objectToClose = self.scope:Value(nil) :: Fusion.Value<GuiObject?, any>

	local valueCleanup: (() -> ())?
	self.trove:Add(observeChildren(button, function(closeVal: ObjectValue?)
		if closeVal.Name == "Close" and closeVal:IsA("ObjectValue") then
			if valueCleanup then
				valueCleanup()
				valueCleanup = nil
			end
			valueCleanup = self.trove:Add(Observers.observeProperty(closeVal, "Value", function(value)
				self.objectToClose:set(value)
				return function() end
			end))
		end
	end))

	self.trove:Add(button.MouseButton1Click:Connect(function()
		local objToCloseState: GuiObject? = peek(self.objectToClose)
		if objToCloseState then
			objToCloseState.Visible = false
		end
	end))

	return self
end

function CloseButton.Destroy(self: CloseButton): ()
	if self.trove then
		self.trove:Destroy()
	end
end

return CloseButton
