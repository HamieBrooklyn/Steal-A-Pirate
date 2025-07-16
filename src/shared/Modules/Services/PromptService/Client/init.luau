local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Prompt = require(script.Prompt)

local Observers = require(ReplicatedStorage.Packages.Observers)

local PromptClient = {}

function PromptClient.init()
	Observers.observeTag("CustomPrompt", function(instance)
		local prompt = Prompt.new(instance)
		return function()
			prompt:Destroy()
		end
	end)
end

return PromptClient
