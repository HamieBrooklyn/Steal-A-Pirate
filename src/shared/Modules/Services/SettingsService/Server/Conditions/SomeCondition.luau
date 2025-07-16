local SharedTypes = require(script.Parent.Parent.Parent.Types)

local function SomeCondition(
	player: Player,
	settingName: string,
	value: any,
	settingData: SharedTypes.SettingData
): boolean
end

return SomeCondition
