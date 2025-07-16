local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TagModules = script.Tags:GetChildren()

local Observers = require(ReplicatedStorage.Packages.Observers)

local GuiTagClient = {}

function GuiTagClient.init()
	for _, module: ModuleScript in TagModules do
		local tag = module.Name
		module = require(module)

		Observers.observeTag(tag, function(instance: Instance)
			if not instance:IsDescendantOf(Players.LocalPlayer) then
				return
			end
			task.spawn(module.new, instance)
			-- return function()
			-- 	if module.Destroy then
			-- 		module:Destroy()
			-- 	end
			-- end
		end)
	end
end

return GuiTagClient
