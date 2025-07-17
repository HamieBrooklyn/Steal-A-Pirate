local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Observers = require(ReplicatedStorage.Packages.Observers)

local partAttributes = {}

local AntiCheatServer = {}

function AntiCheatServer.init()
	local characters: { Model } = {}
	local function setAttrbibutes(part: BasePart)
		part:SetAttribute("Position", part:GetPivot().Position)
		part:SetAttribute("MaxSpeed", 80)
		part:SetAttribute("Time", time())
	end
	Observers.observeCharacter(function(player, character)
		characters[player.UserId] = character
		setAttrbibutes(character.PrimaryPart)
		return function()
			characters[player.UserId] = nil
		end
	end)
	RunService.Heartbeat:Connect(function()
		for _, v in characters do
			local root = v.PrimaryPart
			if not root then
				continue
			end
			local hum = v:FindFirstChildOfClass("Humanoid")
			if not hum then
				continue
			end

			setAttrbibutes(root)
		end
	end)
end

return AntiCheatServer
