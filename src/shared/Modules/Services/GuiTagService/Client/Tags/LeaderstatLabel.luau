local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataClient = require(Services.PlayerDataService.Client)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local abbreviateNumber = require(ReplicatedStorage.Shared.Modules.Utilities.abbreviateNumber)

local scoped, peek = Fusion.scoped, Fusion.peek

local player = Players.LocalPlayer

local LeaderstatLabel = {}
LeaderstatLabel.__index = LeaderstatLabel

type self = {
	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,
}
export type LeaderstatLabel = typeof(setmetatable({} :: self, LeaderstatLabel))

function LeaderstatLabel.new(label: GuiLabel): LeaderstatLabel
	local self = setmetatable({}, LeaderstatLabel) :: LeaderstatLabel

	local scope = scoped(Fusion)
	self._scope = scope

	local trove = Trove.new()
	self._trove = trove

	local statName = scope:Value(label:GetAttribute("StatName"))
	trove:Add(label:GetAttributeChangedSignal("StatName"):Connect(function()
		statName:set(label:GetAttribute("StatName"))
	end))

	local prefix = scope:Value(label:GetAttribute("Prefix"))
	trove:Add(label:GetAttributeChangedSignal("Prefix"):Connect(function()
		prefix:set(label:GetAttribute("Prefix"))
	end))

	local secondaryColor = scope:Value(label:GetAttribute("SecondaryColor"))
	trove:Add(label:GetAttributeChangedSignal("SecondaryColor"):Connect(function()
		secondaryColor:set(label:GetAttribute("SecondaryColor"))
	end))

	local colorSpring: Fusion.Spring<any> = scope:Spring(scope:Value(label.TextColor3), 5, 1)

	local statValue = scope:Value(nil)
	local function set()
		local leaderstatsFold: Folder = player:WaitForChild("leaderstats")
		scope:Observer(statName):onBind(function()
			statValue:set(leaderstatsFold:WaitForChild(peek(statName)))
		end)
	end
	if not PlayerDataClient.loaded then
		PlayerDataClient.LeaderstatsLoaded:Once(set)
	else
		set()
	end

	local text = scope:Value("")
	local con: RBXScriptConnection?
	local lastAmount = 0
	scope:Observer(statValue):onBind(function()
		if con then
			con:Disconnect()
			con = nil
		end
		local state = peek(statValue)
		if not state then
			return
		end
		local function setText()
			text:set(`{peek(prefix) or ""}{abbreviateNumber(state.Value)}`)
			if state.Value > lastAmount then
				local colorState = peek(secondaryColor)
				if colorState then
					colorSpring:setVelocity(colorState)
				end
			end
			lastAmount = state.Value
		end
		con = state.Changed:Connect(setText)
		setText()
	end)

	scope:Hydrate(label)({
		Text = text,
		TextColor3 = colorSpring,
	})

	return self
end

function LeaderstatLabel.Destroy(self: LeaderstatLabel): ()
	self._scope:doCleanup()
end

return LeaderstatLabel
