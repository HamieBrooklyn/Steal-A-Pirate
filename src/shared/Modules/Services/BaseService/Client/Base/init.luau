local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local observeChildren = require(ReplicatedStorage.Shared.Modules.Utilities.observeChildren)

local Platform = require(script.Platform)

local Streamable = require(ReplicatedStorage.Packages.Streamable).Streamable
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Trove = require(ReplicatedStorage.Packages.Trove)
local LockButton = require(script.LockButton)

local scoped, peek = Fusion.scoped, Fusion.peek

local Base = {}
Base.__index = Base

type self = {
	_scope: Fusion.Scope<any>,
	_trove: Trove.Trove,

	Owner: Fusion.Value<string, any>,

	lastLocked: Fusion.Value<number, any>,

	Platforms: { [string]: Platform.Platform },
}
export type Base = typeof(setmetatable({} :: self, Base))

function Base.new(model: Model): Base
	local self = setmetatable({}, Base) :: Base

	self.Id = model:GetAttribute("BaseId")

	local scope = scoped(Fusion)
	self._scope = scope

	local trove = Trove.new()
	self._trove = trove

	local owner = scope:Value(nil)
	self.Owner = owner

	self.lastLocked = scope:Value(0)

	local platforms: { Platform.Platform } = {}
	trove:Add(observeChildren(model:FindFirstChild("Platforms"), function(platformModel)
		if not platformModel:IsA("Model") then
			return
		end
		local platform = Platform.new(platformModel, owner, model)
		trove:Add(platform)
		platforms[platformModel:GetAttribute("PlatformId")] = platform
	end))
	self.Platforms = platforms

	local lockButton: LockButton.LockButton?
	local lockButtonStream = Streamable.new(model, "LockBase")
	trove:Add(lockButtonStream)
	trove:Add(lockButtonStream:Observe(function(button: BasePart, lockButtonTrove: Trove.Trove)
		lockButton = LockButton.new(button, {
			lastLocked = self.lastLocked,

			owner = self.Owner,
			baseId = self.Id,
		})
		lockButtonTrove:Add(lockButton)
		lockButtonTrove:Add(function()
			lockButton = nil
		end)
	end))
	scope:Observer(self.lastLocked):onChange(function()
		if lockButton then
			lockButton:Heartbeat()
		end
	end)

	local heartbeatCon: RBXScriptConnection?
	scope:Observer(owner):onChange(function()
		if heartbeatCon then
			heartbeatCon:Disconnect()
			heartbeatCon = nil
		end
		if not peek(owner) then
			return
		end

		local lastCheck = time()
		heartbeatCon = RunService.Heartbeat:Connect(function()
			if time() - lastCheck < 1 then
				return
			end
			lastCheck = time()

			if lockButton then
				lockButton:Heartbeat()
			end

			for _, v in platforms do
				if not v.CharacterData then
					continue
				end
				v:Heartbeat()
			end
		end)
	end)

	return self
end

function Base.Reset(self: Base)
	self.Owner:set(nil)
	for _, v in self.Platforms do
		v:Reset()
	end
end

function Base.Destroy(self: Base): ()
	self._scope:doCleanup()
	self._trove:Destroy()
end

return Base
