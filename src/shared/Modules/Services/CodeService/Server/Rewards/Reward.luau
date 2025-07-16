local Types = require(script.Parent.Parent.Types)

local function SomeReward(player: Player, data: Types.CodeData, code: string)
	return true, "You got some reward!"
end

return SomeReward
