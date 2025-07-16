local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Menu = require(script.Menu)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Net = require(ReplicatedStorage.Packages.Net)

local MenuClient = {
	menus = {} :: { [string]: Menu.Menu },
	menu = Menu,
}
MenuClient.MenuAdded = Signal.new()

export type Menu = Menu.Menu

function MenuClient.ObserveMenu(menuName: string, callback: (menu: Menu.Menu) -> ()): () -> ()
	if MenuClient.menus[menuName] then
		callback(MenuClient.menus[menuName])
	end

	local addedCon = MenuClient.MenuAdded:Connect(function(name: string, menu: Menu.Menu)
		if name == menuName then
			callback(menu)
		end
	end)

	return function()
		addedCon:Disconnect()
	end
end

function MenuClient.init()
	Net:Connect("EnteredMenuZone", function(menuName: string)
		MenuClient.menus[menuName].opened:set(true)
	end)
	Net:Connect("LeftMenuZone", function(menuName: string)
		MenuClient.menus[menuName].opened:set(false)
	end)
	Observers.observeTag("Menu", function(instance)
		if not instance:IsDescendantOf(Players.LocalPlayer) then
			return
		end

		local menu = Menu.new(instance, MenuClient.menus)
		MenuClient.menus[instance.Name] = menu

		MenuClient.MenuAdded:Fire(instance.Name, MenuClient.menus[instance.Name])

		return function()
			menu:Destroy()
			MenuClient.menus[instance.Name] = nil
		end
	end)
end

return MenuClient
