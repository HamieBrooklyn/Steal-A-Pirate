local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuZone = require(script.MenuZone)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Net = require(ReplicatedStorage.Packages.Net)

local MenuServer = {
	playerInMenus = {} :: { [string]: { string } },
}
MenuServer.EnteredMenuZone = Net:RemoteEvent("EnteredMenuZone")
MenuServer.LeftMenuZone = Net:RemoteEvent("LeftMenuZone")

function MenuServer.init()
	Observers.observePlayer(function(player)
		MenuServer.playerInMenus[tostring(player.UserId)] = {}
		return function()
			MenuServer.playerInMenus[tostring(player.UserId)] = nil
		end
	end)
	Observers.observeTag("MenuZone", function(instance)
		local zone = MenuZone.new(instance)
		zone.trove:Add(zone.playerEntered:Connect(function(player: Player, menuName: string)
			table.insert(MenuServer.playerInMenus[tostring(player.UserId)], menuName)
			MenuServer.EnteredMenuZone:FireClient(player, menuName)
		end))
		zone.trove:Add(zone.playerLeft:Connect(function(player: Player, menuName: string)
			local i = table.find(MenuServer.playerInMenus[tostring(player.UserId)], menuName)
			if i then
				table.remove(MenuServer.playerInMenus[tostring(player.UserId)], i)
				MenuServer.LeftMenuZone:FireClient(player, menuName)
			end
		end))
		return function()
			zone:Destroy()
		end
	end)
end

return MenuServer
