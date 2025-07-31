local ReplicatedStorage = game:GetService("ReplicatedStorage")

local formatTime = require(ReplicatedStorage.Shared.Modules.Utilities.formatTime)
local getSecondsUntilDate = require(ReplicatedStorage.Shared.Modules.Utilities.getSecondsUntilDate)

local TextBoard = require(ReplicatedStorage.Shared.Modules.Components.UI.TextBoard)

local Fusion = require(ReplicatedStorage.Packages.Fusion)

local CountdownUntilDate = {}
CountdownUntilDate.__index = CountdownUntilDate

type self = {
	year: number,
	month: number,
	day: number,

	countdownText: Fusion.Value<string>,

	_scope: Fusion.Scope,
}

export type CountdownUntilDate = typeof(setmetatable({} :: self, CountdownUntilDate)) & CountdownUntilDate

function CountdownUntilDate.new(parent: Instance): CountdownUntilDate
	local self = setmetatable({} :: CountdownUntilDate, CountdownUntilDate)

	self.year = parent:GetAttribute("Year")
	self.month = parent:GetAttribute("Month")
	self.day = parent:GetAttribute("Day")

	self._scope = Fusion.scoped(Fusion)

	self.countdownText = self._scope:Value("")
	self:Update()

	TextBoard(self._scope, {
		adornee = parent,
		text = self.countdownText,
		textColor = Color3.fromRGB(27, 63, 141),
		native = {
			Name = "FreeSpinCountdown",
			StudsOffset = Vector3.new(0, 22, 0),
			Size = UDim2.fromScale(25, 4),
		},
	}).Parent =
		parent

	return self
end

function CountdownUntilDate.Update(self: CountdownUntilDate): ()
	self.countdownText:set(formatTime(getSecondsUntilDate(self.year, self.month, self.day), {
		mode = "text",
		showDays = true,
		showHours = true,
		showMinutes = true,
		showSeconds = true,
		showMilliseconds = false,
	}))
end

function CountdownUntilDate.Destroy(self: CountdownUntilDate): ()
	self._scope:doCleanup()
end

return CountdownUntilDate
