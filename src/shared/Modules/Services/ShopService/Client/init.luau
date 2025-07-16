local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local ShopMenu = require(script.ShopMenu)

local scoped = Fusion.scoped

local ShopClient = {}

function ShopClient.init()
	local scope = scoped(Fusion)
	ShopMenu(scope, {})
end

return ShopClient
