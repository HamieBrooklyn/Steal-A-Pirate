local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
-- local Players = game:GetService("Players")

-- local Services = ReplicatedStorage.Shared.Modules.Services

-- local BaseClient = require(Services.BaseService.Client)

-- local Base = require(Services.BaseService.Client.Base)

local Trove = require(ReplicatedStorage.Packages.Trove)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

-- local BasePointer = require(ReplicatedStorage.Shared.Modules.Services.PlayerService.Client.Stealing.BasePointer)
-- local Streamable = require(ReplicatedStorage.Packages.Streamable)

local Stealing = {}
Stealing.__index = Stealing

type self = {
	_trove: Trove.Trove,
	--_stealingTrove: Trove.Trove,
	_scope: Fusion.Scope<any>,
}
export type Stealing = typeof(setmetatable({} :: self, Stealing))

function Stealing.new(): Stealing
	local self = setmetatable({}, Stealing) :: Stealing

	self._trove = Trove.new()
	self._scope = Fusion.scoped(Fusion)

	-- self._stealingTrove = self._trove:Add(Trove.new()) :: Trove.Trove
	-- self._trove:Add(Players.LocalPlayer:GetAttributeChangedSignal("IsStealing"):Connect(function()
	-- 	self._stealingTrove:Clean()
	-- 	if not Players.LocalPlayer:GetAttribute("IsStealing") then
	-- 		return
	-- 	end
	-- 	BaseClient.GetBase():andThen(function(base: Base.Base)
	-- 		local entranceStream = Streamable.Streamable.new(base.model, "Entrance")
	-- 		self._stealingTrove:Add(entranceStream)
	-- 		self._stealingTrove:Add(entranceStream:Observe(function(entrancePart: Part, entranceTrove: Trove.Trove)
	-- 			entranceTrove:Add(BasePointer(self._scope, {
	-- 				Parent = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Billboards"),
	-- 				Adornee = entrancePart,
	-- 			}))
	-- 		end))
	-- 	end)
	-- end))

	self._trove:Add(Players.LocalPlayer:GetAttributeChangedSignal("IsStealing"):Connect(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, Players.LocalPlayer:GetAttribute("IsStealing") == false)
	end))

	return self
end

function Stealing.Destroy(self: Stealing): ()
	self._trove:Destroy()
	self._scope:doCleanup()
end

return Stealing
