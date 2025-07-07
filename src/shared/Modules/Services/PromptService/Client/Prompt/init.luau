local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PromptBoard = require(script.PromptBoard)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local observeCharacter = require(ReplicatedStorage.Shared.Modules.Utilities.observeCharacter)
local Observers = require(ReplicatedStorage.Packages.Observers)

local OnEvent, OnChange = Fusion.OnEvent, Fusion.OnChange
local scoped = Fusion.scoped

local Prompt = {}
Prompt.__index = Prompt

type self = {
	_scope: Fusion.Scope<any>,

	PromptBoard: BillboardGui,
}
export type Prompt = typeof(setmetatable({} :: self, Prompt))

function Prompt.new(instance: ProximityPrompt): Prompt
	local self = setmetatable({}, Prompt) :: Prompt

	local scope = scoped(Fusion, {
		PromptBoard = PromptBoard,
	})
	self._scope = scope

	local shown = scope:Value(false)
	local holding = scope:Value(false)
	local holdDuration = scope:Value(instance.HoldDuration)

	local actionText = scope:Value(instance.ActionText)
	local objectText = scope:Value(instance.ObjectText)

	Observers.observeProperty(instance, "HoldDuration", function(value)
		if value == 0 then
			return
		end
		holdDuration:set(value)
	end)

	scope:Hydrate(instance)({
		Style = Enum.ProximityPromptStyle.Custom,
		[OnEvent("PromptShown")] = function()
			shown:set(true)
		end,
		[OnEvent("PromptHidden")] = function()
			shown:set(false)
		end,

		[OnEvent("PromptButtonHoldBegan")] = function()
			holding:set(true)
		end,
		[OnEvent("PromptButtonHoldEnded")] = function()
			holding:set(false)
		end,

		[OnChange("Enabled")] = function(enabled)
			if not enabled then
				shown:set(false)
			end
		end,

		[OnChange("ActionText")] = function(text)
			actionText:set(text)
		end,
		[OnChange("ObjectText")] = function(text)
			objectText:set(text)
		end,
	})

	self.PromptBoard = scope:PromptBoard({
		Shown = shown,
		Adornee = instance.Parent,

		ActionText = actionText,
		ObjectText = objectText,

		HoldDuration = holdDuration,
		Holding = holding,
	})

	return self
end

function Prompt.Destroy(self: Prompt): ()
	self._scope:doCleanup()
end

return Prompt
