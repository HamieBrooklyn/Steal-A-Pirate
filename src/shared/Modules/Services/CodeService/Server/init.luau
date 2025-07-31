local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ReplicatedStorage.Shared.Modules.Services

local PlayerDataServer = require(Services.PlayerDataService.Server)
local Codes = require(ServerScriptService.Server.Data.Codes)

local Types = require(script.Types)

local Net = require(ReplicatedStorage.Packages.Net)

local CodeServer = {}
CodeServer.CodeRedeemed = Net:RemoteEvent("CodeRedeemed")

function CodeServer.init()
	local rewardTypes = {}
	for _, v in script.Rewards:GetChildren() do
		if v:IsA("ModuleScript") then
			rewardTypes[v.Name] = require(v)
		end
	end
	local conditionTypes = {}
	for _, v in script.Conditions:GetChildren() do
		if v:IsA("ModuleScript") then
			conditionTypes[v.Name] = require(v)
		end
	end

	Net:Handle("RedeemCodeAttempt", function(player: Player, code: string)
		assert(code and typeof(code) == "string", "Sent code was not of type string")

		if not player:IsInGroup(36075879) then
			return false, "Please join the group to enter codes!"
		end

		local codeData: Types.CodeData = Codes[code]
		if not codeData then
			return false, "This is not a valid code"
		end

		local profile = PlayerDataServer.GetPlayerProfile(player)
		if not profile then
			return false, "Your data has not synced, try waiting or rejoining."
		end
		if table.find(profile.Data.CodesRedeemed, code) then
			return false, "You already used this code"
		end

		local codeConditionTypes = codeData.ConditionTypes
		if codeConditionTypes then
			for _, v in codeConditionTypes do
				local success, message = conditionTypes[v](player, codeData, code)
				if not success then
					return false, message
				end
			end
		end

		local rewardType = codeData.RewardType
		if rewardType and rewardTypes[rewardType] then
			local success, message = rewardTypes[rewardType](player, codeData, code)
			if success then
				table.insert(profile.Data.CodesRedeemed, code)
				CodeServer.CodeRedeemed:FireClient(player, code, message)
				return true, message
			end
		end

		return false, "Something went wrong"
	end)
end

return CodeServer
