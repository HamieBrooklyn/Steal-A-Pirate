local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local TimedMessage = {}
TimedMessage.__index = TimedMessage

type self = {
	currentText: Fusion.Value<string, any>,

	_trove: Trove.Trove,
}
export type TimedMessage = typeof(setmetatable({} :: self, TimedMessage))

function TimedMessage.new(currentText: Fusion.Value<string, any>, texts: { [string]: string }, ...): TimedMessage
	local self = setmetatable({}, TimedMessage) :: TimedMessage

	self._trove = Trove.new()

	self.currentText = currentText

	return self
end

function TimedMessage.Start(self: TimedMessage, texts: { [string]: string }, ...): ()
	self.currentText:set(texts["Main"])
end

function TimedMessage.Clean(self: TimedMessage): ()
	self._trove:Destroy()
end

return TimedMessage
