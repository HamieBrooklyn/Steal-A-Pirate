local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpinWheel = require(script.SpinWheel)

local Observers = require(ReplicatedStorage.Packages.Observers)

local SpinnerService = {}

function SpinnerService.init()
	Observers.observeTag("SpinWheel", function(instance)
		local spinWheel = SpinWheel.new(instance)
		return function()
			spinWheel:Destroy()
		end
	end)
end

return SpinnerService
