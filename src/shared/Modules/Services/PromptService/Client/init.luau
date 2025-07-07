local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedData = require(script.Parent.Data)

local Prompt = require(script.Prompt)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local scoped, peek = Fusion.scoped, Fusion.peek

local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)
local observeTag = require(ReplicatedStorage.Shared.Modules.Utilities.observeTag)

local PromptClient = {}

function PromptClient.init()
	local scope = scoped(Fusion)
	local promptBoards = scope:Value({})

	local observeCleanup: (() -> ())?
	observeCharacter(Players.LocalPlayer, function()
		promptBoards:set({})
		if observeCleanup then
			observeCleanup()
			observeCleanup = nil
		end
		scope:New("Folder")({
			Name = "PromptBoardsContainer",
			Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
			[Fusion.Children] = promptBoards,
		})
		local prompts = {}
		observeCleanup = observeTag(SharedData.Tag, function(instance)
			local prompt = Prompt.new(instance)

			local state = table.clone(peek(promptBoards))
			table.insert(state, prompt.PromptBoard)
			promptBoards:set(state)

			prompts[instance] = prompt
		end, function(instance)
			local prompt = prompts[instance]
			if prompt then
				prompt:Destroy()

				local removeState = table.clone(peek(promptBoards))
				local i = table.find(removeState, prompt.PromptBoard)
				if i then
					table.remove(removeState, i)
				end
				promptBoards:set(removeState)
			end
		end)
	end)
end

return PromptClient
