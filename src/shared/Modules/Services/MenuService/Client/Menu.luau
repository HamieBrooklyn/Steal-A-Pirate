local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local scoped, peek = Fusion.scoped, Fusion.peek

local Menu = {}
Menu.__index = Menu

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	opened: Fusion.Value<boolean, any>,

	mainFrame: Fusion.Value<GuiObject?, any>,
}
export type Menu = typeof(setmetatable({} :: self, Menu))

function Menu.new(menu: ScreenGui, menus: { [string]: Menu }): Menu
	local self = setmetatable({}, Menu) :: Menu

	self.scope = scoped(Fusion) :: Fusion.Scope<any>
	self.trove = Trove.new()

	self.opened = self.scope:Value(false) :: Fusion.Value<boolean, any>
	self.scope:Observer(self.opened):onChange(function()
		if peek(self.opened) then
			for _, v in menus do
				if peek(v.mainFrame) ~= peek(self.mainFrame) and peek(v.opened) then
					v.opened:set(false)
				end
			end
		end
	end)

	self.mainFrame = self.scope:Value(menu:GetChildren()[1]) :: Fusion.Value<GuiObject?, any>
	self.trove:Add(menu.ChildAdded:Connect(function(v)
		self.mainFrame:set(v)
	end))

	local visibilityCon: RBXScriptConnection?
	self.scope:Observer(self.mainFrame):onBind(function()
		if visibilityCon then
			visibilityCon:Disconnect()
			visibilityCon = nil
		end

		local mainFrameState: GuiObject? = peek(self.mainFrame)
		if not mainFrameState then
			return
		end
		self.scope:Hydrate(mainFrameState)({
			Visible = self.opened,
		})
		visibilityCon = self.trove:Add(mainFrameState:GetPropertyChangedSignal("Visible"):Connect(function()
			self.opened:set(mainFrameState.Visible)
		end))
	end)

	return self
end

function Menu.Destroy(self: Menu): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return Menu
