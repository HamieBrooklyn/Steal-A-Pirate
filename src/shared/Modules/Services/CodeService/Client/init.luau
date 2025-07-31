local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ReplicatedStorage.Shared.Modules.Services

local FreeTimedCharacter = require(script.FreeCharacterBar)
local CodeMenu = require(script.CodeMenu)

local PlayerDataClient = require(Services.PlayerDataService.Client)

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Net = require(ReplicatedStorage.Packages.Net)

local Value = Fusion.Value
local scoped = Fusion.scoped

local CodeClient = {
	CodeMenu = CodeMenu,
}
CodeClient.redeemCodeAttempt = Net:RemoteFunction("RedeemCodeAttempt")

function CodeClient.init()
	local scope = scoped(Fusion, {
		CodeMenu = CodeMenu,
		FreeTimedCharacter = FreeTimedCharacter,
	})

	local codes = {}
	for _, v in script.Codes:GetChildren() do
		codes[v.Name] = require(v)
	end

	scope:CodeMenu({
		redeemCodeAttempt = function(code: string)
			return CodeClient.redeemCodeAttempt:InvokeServer(code)
		end,
		codes = codes,
	})

	local hasntClaimedFreeCharacter = Value(scope, false)
	Net:Connect("CodeRedeemed", function(code: string)
		if code == "AYCE" then
			hasntClaimedFreeCharacter:set(false)
		end
	end)

	local function load()
		scope:FreeTimedCharacter({
			firstSessionTime = tonumber(PlayerDataClient.getFirstSessionTime:InvokeServer()),
			hasntClaimed = hasntClaimedFreeCharacter,
		})
		for _, v in PlayerDataClient.getRedeemedCodes:InvokeServer() do
			if v == "AYCE" then
				return
			end
		end
		hasntClaimedFreeCharacter:set(true)
	end
	if Players.LocalPlayer:GetAttribute("ProfileLoaded") then
		load()
	end
	Net:Connect("ProfileLoaded", load)
end

return CodeClient
