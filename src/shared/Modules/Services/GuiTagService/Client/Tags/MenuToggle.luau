local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local MenuClient = require(Services.MenuService.Client)

local Menu = MenuClient.menu

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Observers = require(ReplicatedStorage.Packages.Observers)

local scoped, peek = Fusion.scoped, Fusion.peek

local MenuToggle = {}
MenuToggle.__index = MenuToggle

type self = {
	scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	menuName: Fusion.Value<string, any>,
	menu: Fusion.Value<Menu.Menu?, any>,

	toggled: Fusion.Value<boolean, any>,
}
export type MenuToggle = typeof(setmetatable({} :: self, MenuToggle))

function MenuToggle.new(button: GuiButton): MenuToggle
	local self = setmetatable({}, MenuToggle) :: MenuToggle

	self.scope = scoped(Fusion) :: Fusion.Scope<any>
	self.trove = Trove.new()

	self.menu = self.scope:Value(nil) :: Fusion.Value<Menu.Menu?, any>
	self.menuName = self.scope:Value(button:GetAttribute("MenuName") or button.Name) :: Fusion.Value<string, any>
	Observers.observeAttribute(button, "MenuName", function(value)
		if value then
			self.menuName:set(value)
		end
	end)

	self.toggled = self.scope:Value(false) :: Fusion.Value<boolean, any>
	self.scope:Observer(self.toggled):onChange(function()
		local menuState: Menu.Menu? = peek(self.menu)
		if menuState then
			menuState.opened:set(peek(self.toggled))
		end
	end)

	self.scope:Observer(self.menuName):onBind(function()
		local menuNameState = peek(self.menuName)
		if not menuNameState then
			self.toggled:set(false)
			return
		end
		local menu = MenuClient.menus[menuNameState]
		if not menu then
			self.toggled:set(false)
			return
		end

		self.toggled:set(peek(menu.opened))
		self.menu:set(menu)
	end)

	local mainFrameCon: (() -> ())?
	self.trove:Add(MenuClient.ObserveMenu(peek(self.menuName), function(menu: Menu.Menu)
		if mainFrameCon then
			mainFrameCon()
			mainFrameCon = nil
		end

		local visibleCon: RBXScriptConnection?
		mainFrameCon = self.trove:Add(self.scope:Observer(menu.mainFrame):onBind(function()
			if visibleCon then
				visibleCon:Disconnect()
				visibleCon = nil
			end
			local mainFrame: GuiObject? = peek(menu.mainFrame)
			if not mainFrame then
				return
			end
			visibleCon = mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
				self.toggled:set(mainFrame.Visible)
			end)
		end))

		self.menu:set(menu)
	end))

	self.trove:Add(button.MouseButton1Down:Connect(function()
		self.toggled:set(not peek(self.toggled))
	end))

	return self
end

function MenuToggle.Destroy(self: MenuToggle): ()
	self.scope:doCleanup()
	self.trove:Destroy()
end

return MenuToggle
