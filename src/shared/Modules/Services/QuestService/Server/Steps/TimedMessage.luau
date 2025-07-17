local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)

local TimedMessage = {}
TimedMessage.__index = TimedMessage

type self = {
	_trove: Trove.Trove,
}
export type TimedMessage = typeof(setmetatable({} :: self, TimedMessage))

function TimedMessage.new(player: Player, texts: { [string]: string }, ...): TimedMessage
	local self = setmetatable({}, TimedMessage) :: TimedMessage

	self._trove = Trove.new()

	return self
end

function TimedMessage.Start(
	self: TimedMessage,
	finished: () -> (),
	player: Player,
	texts: { [string]: string },
	duration: number
): ()
	task.delay(duration, finished)
end

function TimedMessage.Clean(self: TimedMessage): ()
	self._trove:Destroy()
end

return TimedMessage
