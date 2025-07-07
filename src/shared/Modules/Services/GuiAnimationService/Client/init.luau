local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimatedObject = require(script.AnimatedObject)

local Observers = require(ReplicatedStorage.Packages.Observers)

local GuiAnimationClient = {
	AnimatedObjects = {},
}

function GuiAnimationClient.init()
	Observers.observeTag("AnimatedObject", function(instance)
		local animated = AnimatedObject.new(instance)
		GuiAnimationClient.AnimatedObjects[instance] = animated
		return function()
			animated:Destroy()
			GuiAnimationClient.AnimatedObjects[instance] = nil
		end
	end)
end

return GuiAnimationClient
