local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)

local SharedData = require(script.Parent.Parent.Parent.Data)
local Types = require(script.Parent.Parent.Types)

local function Character(player: Player, data: Types.CodeData, code: string)
	local profile = PlayerDataServer.Profiles[player]

	local secondsLeft = os.time() - profile.FirstSessionTime
	if secondsLeft < SharedData.FreeCharacterSeconds then
		return false, "You need to wait " .. secondsLeft .. " more seconds"
	end

	return true
end

return Character
