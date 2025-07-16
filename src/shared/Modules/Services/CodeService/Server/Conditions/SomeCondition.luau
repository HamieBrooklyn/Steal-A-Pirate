local Types = require(script.Parent.Parent.Types)

local function SomeCondition(player: Player, data: Types.CodeData, code: string)
	--return false, "This code was not redeemable because..."
	return true
end

return SomeCondition
