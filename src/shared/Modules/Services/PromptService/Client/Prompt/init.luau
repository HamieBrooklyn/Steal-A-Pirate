local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PromptBoard = require(script.PromptBoard)

local Observers = require(ReplicatedStorage.Packages.Observers)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)

local OnEvent, OnChange, Observer = Fusion.OnEvent, Fusion.OnChange, Fusion.Observer
local scoped, peek = Fusion.scoped, Fusion.peek

local Prompt = {}
Prompt.__index = Prompt

type self = {
	_scope: Fusion.Scope<any>,
	trove: Trove.Trove,

	PromptBoard: BillboardGui,
}
export type Prompt = typeof(setmetatable({} :: self, Prompt))

function Prompt.new(instance: ProximityPrompt): Prompt
	local self = setmetatable({}, Prompt) :: Prompt

	local scope = scoped(Fusion)
	self._scope = scope
	self.trove = Trove.new()

	local shown = scope:Value(false)
	local holding = scope:Value(false)
	local holdDuration = scope:Value(instance.HoldDuration)

	local actionText = scope:Value(instance.ActionText)
	local objectText = scope:Value(instance.ObjectText)

	local hl: Highlight?
	Observer(self._scope, shown):onBind(function()
		if hl then
			hl:Destroy()
			hl = nil
		end

		local shownState = peek(shown)
		if not shownState then
			return
		end

		local model = instance:FindFirstAncestorOfClass("Model")
		if model then
			hl = Instance.new("Highlight")
			hl.FillTransparency = 1
			hl.DepthMode = Enum.HighlightDepthMode.Occluded
			hl.Parent = model
		end
	end)

	Observers.observeProperty(instance, "HoldDuration", function(value)
		if value == 0 then
			return
		end
		holdDuration:set(value)
		return function() end
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

	self.PromptBoard = PromptBoard(scope, {
		Shown = shown,
		Adornee = instance.Parent,

		ActionText = actionText,
		ObjectText = objectText,

		HoldDuration = holdDuration,
		Holding = holding,

		startHolding = function()
			instance:InputHoldBegin()
		end,
		endHolding = function()
			instance:InputHoldEnd()
		end,
	})

	return self
end

function Prompt.Destroy(self: Prompt): ()
	self._scope:doCleanup()
end

return Prompt
