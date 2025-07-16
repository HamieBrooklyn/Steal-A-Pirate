local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimatedObject = require(script.AnimatedObject)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Signal = require(ReplicatedStorage.Packages.Signal)

local GuiAnimationClient = {
	animatedObject = AnimatedObject,
	animatedObjects = {} :: { [Instance]: AnimatedObject.AnimatedObject },
}
GuiAnimationClient.AnimatedObjectAdded = Signal.new()

function GuiAnimationClient.ObserveAnimatedObject(
	object: GuiObject,
	callback: (animatedObject: AnimatedObject.AnimatedObject) -> ()
): () -> ()
	if GuiAnimationClient.animatedObjects[object] then
		return GuiAnimationClient.animatedObjects[object]
	end

	local addedCon = GuiAnimationClient.AnimatedObjectAdded:Connect(
		function(name: string, animatedObject: AnimatedObject.AnimatedObject)
			if name == object then
				callback(animatedObject)
			end
		end
	)

	return function()
		addedCon:Disconnect()
	end
end

function GuiAnimationClient.init()
	Observers.observeTag("AnimatedObject", function(instance)
		if not instance:IsDescendantOf(Players.LocalPlayer) then
			return
		end

		local animated = AnimatedObject.new(instance)
		GuiAnimationClient.animatedObjects[instance] = animated
		GuiAnimationClient.AnimatedObjectAdded:Fire(instance, animated)
		return function()
			animated:Destroy()
			GuiAnimationClient.animatedObjects[instance] = nil
		end
	end)
end

return GuiAnimationClient
